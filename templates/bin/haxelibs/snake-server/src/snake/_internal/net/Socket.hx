package snake._internal.net;

#if (eval && (haxe_ver >= 4.2))
import eval.luv.Handle;
import eval.luv.Loop;
import eval.luv.Loop.RunMode;
import eval.luv.SockAddr;
import eval.luv.Stream;
import eval.luv.Tcp;
import haxe.Exception;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Output;
import sys.net.Host;

using eval.luv.Result.ResultTools;

/**
	A shim for sys.net.Socket on the eval/interp target that ensures that
	SO_REUSEADDR is used so that exiting and restarting the server can
	immediately use the same port without the following exception:

	Unix.Unix_error(Unix.EADDRINUSE, "bind", "")

	See also: https://github.com/HaxeFoundation/haxe/pull/12958
**/
class Socket {
	private static final POLL_INTERVAL = 0.001;

	private static function fromTcp(loop:Loop, tcp:Tcp):Socket {
		var socket = Type.createEmptyInstance(Socket);
		socket.initLuv(loop, tcp);
		return socket;
	}

	public static function select(read:Array<Socket>, write:Array<Socket>, others:Array<Socket>,
			?timeout:Float):{read:Array<Socket>, write:Array<Socket>, others:Array<Socket>} {
		var loop = findLoop(read, write, others);
		var deadline = timeout == null || timeout < 0 ? -1.0 : haxe.Timer.stamp() + timeout;
		while (true) {
			var readyRead = ready(read);
			var readyWrite = writable(write);
			var readyOthers:Array<Socket> = [];
			if (readyRead.length > 0 || readyWrite.length > 0 || readyOthers.length > 0) {
				return {read: readyRead, write: readyWrite, others: readyOthers};
			}
			if (timeout == 0 || (deadline >= 0 && haxe.Timer.stamp() >= deadline)) {
				return {read: [], write: [], others: []};
			}
			if (loop != null) {
				loop.run(RunMode.NOWAIT);
			}
			Sys.sleep(POLL_INTERVAL);
		}
	}

	private static function ready(sockets:Array<Socket>):Array<Socket> {
		if (sockets == null) {
			return [];
		}
		return sockets.filter(socket -> socket.isReadyToRead());
	}

	private static function writable(sockets:Array<Socket>):Array<Socket> {
		if (sockets == null) {
			return [];
		}
		return sockets.filter(socket -> !socket.listening && !socket.closed);
	}

	private static function findLoop(read:Array<Socket>, write:Array<Socket>, others:Array<Socket>):Loop {
		for (group in [read, write, others]) {
			if (group != null && group.length > 0) {
				for (socket in group) {
					return socket.loop;
				}
			}
		}
		return null;
	}

	private var loop:Loop;
	private var tcp:Tcp;
	private var pending:Array<Socket>;
	private var readBuffer:BytesBuffer;
	private var readOffset = 0;
	private var listening:Bool;
	private var reading:Bool;
	private var closed:Bool;
	private var readClosed:Bool;
	private var timeout:Null<Float> = null;
	private var localAddress:{host:Host, port:Int};
	private var peerAddress:{host:Host, port:Int};

	public var input(default, null):Input;
	public var output(default, null):Output;
	public var custom:Dynamic;

	public function new() {
		var loop = Loop.defaultLoop();
		initLuv(loop, Tcp.init(loop).resolve());
	}

	private function initLuv(loop:Loop, tcp:Tcp):Void {
		this.loop = loop;
		this.tcp = tcp;
		pending = [];
		readBuffer = new BytesBuffer();
		readOffset = 0;
		listening = false;
		reading = false;
		closed = false;
		readClosed = false;
		input = new LuvSocketInput(this);
		output = new LuvSocketOutput(this);
	}

	public function close():Void {
		if (closed) {
			return;
		}
		closed = true;
		Handle.close(tcp, () -> {});
	}

	public function read():String {
		return input.readAll().toString();
	}

	public function write(content:String):Void {
		output.writeString(content);
	}

	public function connect(host:Host, port:Int):Void {
		var done = false;
		var failure:Dynamic = null;
		tcp.connect(sockAddr(host, port), result -> {
			try {
				result.resolve();
			} catch (e:Dynamic) {
				failure = e;
			}
			done = true;
		});
		waitUntil(() -> done, timeout);
		if (failure != null) {
			throw failure;
		}
		localAddress = null;
		peerAddress = {host: host, port: port};
		startRead();
	}

	public function listen(connections:Int):Void {
		listening = true;
		Stream.listen(tcp, result -> {
			result.resolve();
			var client = Socket.fromTcp(loop, Tcp.init(loop).resolve());
			Stream.accept(tcp, client.tcp).resolve();
			client.localAddress = client.readLocalAddress();
			client.peerAddress = client.readPeerAddress();
			client.startRead();
			pending.push(client);
		}, connections);
	}

	public function shutdown(read:Bool, write:Bool):Void {
		if (write) {
			Stream.shutdown(tcp, _ -> close());
		}
		if (read) {
			readClosed = true;
		}
	}

	public function bind(host:Host, port:Int):Void {
		tcp.bind(sockAddr(host, port)).resolve();
		localAddress = readLocalAddress();
	}

	public function accept():Socket {
		if (pending.length == 0) {
			select([this], null, null, timeout);
		}
		if (pending.length == 0) {
			throw new Exception("No pending connection");
		}
		return pending.shift();
	}

	public function peer():{host:Host, port:Int} {
		if (peerAddress == null) {
			peerAddress = readPeerAddress();
		}
		return peerAddress;
	}

	public function host():{host:Host, port:Int} {
		if (localAddress == null) {
			localAddress = readLocalAddress();
		}
		return localAddress;
	}

	public function setTimeout(timeout:Float):Void {
		this.timeout = timeout;
	}

	public function waitForRead():Void {
		select([this], null, null, timeout);
	}

	public function setBlocking(b:Bool):Void {}

	public function setFastSend(b:Bool):Void {
		tcp.noDelay(b).resolve();
	}

	private function isReadyToRead():Bool {
		pump();
		return listening ? pending.length > 0 : available() > 0 || readClosed;
	}

	private function startRead():Void {
		if (reading) {
			return;
		}
		reading = true;
		Stream.readStart(tcp, result -> {
			switch (result) {
				case Ok(buffer):
					if (buffer.size() > 0) {
						readBuffer.add(buffer.toBytes());
					}
				case Error(_):
					readClosed = true;
			}
		});
	}

	private function readBytesInto(bytes:Bytes, pos:Int, len:Int):Int {
		waitUntil(() -> available() > 0 || readClosed, timeout);
		var availableBytes = available();
		if (availableBytes == 0) {
			throw new Eof();
		}
		var count = len < availableBytes ? len : availableBytes;
		bytes.blit(pos, readBuffer.getBytes(), readOffset, count);
		readOffset += count;
		return count;
	}

	private function writeBytesFrom(bytes:Bytes, pos:Int, len:Int):Int {
		var chunk = bytes.sub(pos, len);
		var done = false;
		var failure:Dynamic = null;
		var queued = Stream.write(tcp, [chunk], (result, _) -> {
			switch (result) {
				case Error(e):
					failure = e;
				case Ok(_) | null:
			}
			done = true;
		});
		switch (queued) {
			case Error(e):
				throw e;
			case Ok(_) | null:
		}
		waitUntil(() -> done, timeout);
		if (failure != null) {
			throw failure;
		}
		return len;
	}

	private function waitUntil(condition:() -> Bool, timeout:Null<Float>):Void {
		var deadline = timeout == null || timeout < 0 ? -1.0 : haxe.Timer.stamp() + timeout;
		while (!condition()) {
			if (deadline >= 0 && haxe.Timer.stamp() >= deadline) {
				return;
			}
			pump();
			Sys.sleep(POLL_INTERVAL);
		}
	}

	private function pump():Void {
		if (!closed) {
			loop.run(RunMode.NOWAIT);
		}
	}

	private function available():Int {
		return readBuffer.length - readOffset;
	}

	private function readLocalAddress():{host:Host, port:Int} {
		return socketAddress(tcp.getSockName().resolve());
	}

	private function readPeerAddress():{host:Host, port:Int} {
		return socketAddress(tcp.getPeerName().resolve());
	}

	private static function sockAddr(host:Host, port:Int):SockAddr {
		var address:String = host.toString();
		if (address.indexOf(":") == -1) {
			var ipv4:String = address;
			return SockAddr.ipv4(ipv4, port).resolve();
		}
		var ipv6:String = address;
		return SockAddr.ipv6(ipv6, port).resolve();
	}

	private static function socketAddress(address:SockAddr):{host:Host, port:Int} {
		var text = address.toString();
		var colon = text.lastIndexOf(":");
		var host = colon == -1 ? text : text.substr(0, colon);
		var port = address.port == null ? 0 : address.port;
		return {host: new Host(host), port: port};
	}
}

@:access(snake._internal.net.Socket)
private class LuvSocketInput extends Input {
	private final socket:Socket;

	public function new(socket:Socket) {
		this.socket = socket;
	}

	override public function readBytes(buf:Bytes, pos:Int, len:Int):Int {
		return socket.readBytesInto(buf, pos, len);
	}

	override public function close():Void {
		socket.close();
	}
}

@:access(snake._internal.net.Socket)
private class LuvSocketOutput extends Output {
	private final socket:Socket;

	public function new(socket:Socket) {
		this.socket = socket;
	}

	override public function writeBytes(buf:Bytes, pos:Int, len:Int):Int {
		return socket.writeBytesFrom(buf, pos, len);
	}

	override public function writeByte(c:Int):Void {
		var bytes = Bytes.alloc(1);
		bytes.set(0, c);
		socket.writeBytesFrom(bytes, 0, 1);
	}

	override public function close():Void {
		socket.close();
	}
}
#end
