package lime._internal.backend.html5;

import haxe.Timer;
import js.Browser;
import lime.net.LocalSocket;
import lime.net.LocalSocketError;
import lime.utils.Bytes;

/**
	Connections between pages of the same origin, on a `BroadcastChannel`
	named for the server's name, which every page that opens it shares. Each
	message is an object with a type `t`:

	- `probe` (`s`): a server starts listening, and asks whether the name is taken
	- `taken` (`s`, `to`): the server listening on the name answers the probe of `to`
	- `connect` (`c`): a socket asks for connection `c`, again until it is answered
	- `accept` (`c`, `s`): server `s` takes connection `c`
	- `data` (`c`, `s`, `f`, `d`): an `ArrayBuffer` sent on the connection, from
	  the server's end when `f` is `1`
	- `close` (`c`, `s`, `f`): one end closed the connection

	The browser delivers messages in order, and only to other `BroadcastChannel`
	objects, so each end of a connection has its own.
**/
@:access(lime.net.LocalSocket)
class HTML5LocalSocket
{
	private static inline var CONNECT_RETRY_MS:Int = 250;
	// Two messages of the largest size, as on native targets
	private static inline var DEFAULT_MAX_QUEUED:Int = 2 * LocalSocket.MAX_MESSAGE_SIZE;
	private static inline var PREFIX:String = "lime-local-socket:";

	private static var openSockets:Array<HTML5LocalSocket> = [];
	private static var unloadListening:Bool = false;

	public var connected(default, null):Bool = false;
	public var maxQueuedBytes(default, null):Int = DEFAULT_MAX_QUEUED;

	private var channel:Dynamic;
	private var connectionID:String;
	private var connecting:Bool = false;
	private var parent:LocalSocket;
	private var queue:Array<Dynamic> = [];
	private var queuedBytes:Int = 0;
	private var retryTimer:Timer;
	private var serverID:String;
	private var serverSide:Bool = false;
	private var timeoutTimer:Timer;

	public function new(parent:LocalSocket)
	{
		this.parent = parent;
	}

	public function close():Void
	{
		if (channel != null && serverID != null && (connected || serverSide))
		{
			post({t: "close", c: connectionID, s: serverID, f: serverSide ? 1 : 0});
		}

		closeChannel();
	}

	public function connect(name:String, timeout:Int):Void
	{
		close();

		if (!isSupported())
		{
			parent.onError.dispatch(LocalSocketError.FAILED);
			parent.onClose.dispatch();
			return;
		}

		openChannel(name);
		connectionID = createID();
		connecting = true;

		// A server that starts listening later only hears a request made after it does
		var request = function() post({t: "connect", c: connectionID});
		request();
		retryTimer = new Timer(CONNECT_RETRY_MS);
		retryTimer.run = request;

		if (timeout > 0)
		{
			timeoutTimer = Timer.delay(function()
			{
				if (!connecting) return;
				closeChannel();
				parent.onError.dispatch(LocalSocketError.TIMEOUT);
				parent.onClose.dispatch();
			}, timeout);
		}
	}

	public function getBytesPending():Int
	{
		// The browser takes messages at once, so only those sent before connecting wait
		return queuedBytes;
	}

	public static function isSupported():Bool
	{
		return #if haxe4 js.Syntax.typeof(untyped BroadcastChannel) #else untyped __typeof__(BroadcastChannel) #end != "undefined";
	}

	public function send(data:Bytes, offset:Int, length:Int):Bool
	{
		if (channel == null) return false;

		// The receiver gets its own copy of the buffer, so only the bytes sent are copied
		var buffer = data.getData().slice(offset, offset + length);

		if (connected)
		{
			post({t: "data", c: connectionID, s: serverID, f: serverSide ? 1 : 0, d: buffer});
			return true;
		}

		if (maxQueuedBytes > 0 && queuedBytes + length > maxQueuedBytes)
		{
			closeChannel();
			parent.onError.dispatch(LocalSocketError.OVERFLOW);
			parent.onClose.dispatch();
			return false;
		}

		queue.push(buffer);
		queuedBytes += length;
		return true;
	}

	public function setMaxQueuedBytes(value:Int):Void
	{
		maxQueuedBytes = value;
	}

	// The server's end of a connection it took
	@:noCompletion private function adopt(name:String, connectionID:String, serverID:String):Void
	{
		parent.name = name;
		openChannel(name);
		this.connectionID = connectionID;
		this.serverID = serverID;
		serverSide = true;
		connected = true;
	}

	@:noCompletion private static function channelName(name:String):String
	{
		return PREFIX + name;
	}

	@:noCompletion private function closeChannel():Void
	{
		if (retryTimer != null)
		{
			retryTimer.stop();
			retryTimer = null;
		}

		if (timeoutTimer != null)
		{
			timeoutTimer.stop();
			timeoutTimer = null;
		}

		if (channel != null)
		{
			channel.onmessage = null;
			channel.close();
			channel = null;
		}

		openSockets.remove(this);
		connected = false;
		connecting = false;
		serverID = null;
		serverSide = false;
		queue = [];
		queuedBytes = 0;
	}

	@:noCompletion private static function createID():String
	{
		var crypto:Dynamic = untyped Browser.window.crypto;
		if (crypto != null && crypto.randomUUID != null) return crypto.randomUUID();
		return StringTools.hex(Std.random(0x7FFFFFFF), 8) + StringTools.hex(Std.random(0x7FFFFFFF), 8) + StringTools.hex(Std.int(Date.now().getTime()) & 0x7FFFFFFF, 8);
	}

	@:noCompletion private function handleMessage(event:Dynamic):Void
	{
		var message:Dynamic = event.data;
		if (message == null || message.c != connectionID) return;

		switch (message.t)
		{
			case "accept":
				if (serverSide) return;

				if (!connecting)
				{
					// Another server took the same request, so its end is closed
					if (message.s != serverID) post({t: "close", c: connectionID, s: message.s, f: 0});
					return;
				}

				serverID = message.s;
				connecting = false;
				connected = true;

				if (retryTimer != null)
				{
					retryTimer.stop();
					retryTimer = null;
				}

				if (timeoutTimer != null)
				{
					timeoutTimer.stop();
					timeoutTimer = null;
				}

				// What was sent before the connection was made goes first
				var queued = queue;
				queue = [];
				queuedBytes = 0;

				for (buffer in queued)
				{
					post({t: "data", c: connectionID, s: serverID, f: 0, d: buffer});
				}

				parent.onConnect.dispatch();

			case "data":
				if (!connected || message.s != serverID || message.f == (serverSide ? 1 : 0)) return;
				parent.onData.dispatch(Bytes.ofData(message.d));

			case "close":
				if (!connected || message.s != serverID || message.f == (serverSide ? 1 : 0)) return;
				closeChannel();
				parent.onClose.dispatch();

			default:
		}
	}

	@:noCompletion private function openChannel(name:String):Void
	{
		channel = untyped #if haxe4 js.Syntax.code #else __js__ #end ("new BroadcastChannel({0})", channelName(name));
		channel.onmessage = handleMessage;
		openSockets.push(this);
		listenForUnload();
	}

	@:noCompletion private function post(message:Dynamic):Void
	{
		if (channel != null) channel.postMessage(message);
	}

	// The other end of each connection hears that it closed when the page goes
	@:noCompletion private static function listenForUnload():Void
	{
		if (unloadListening) return;
		unloadListening = true;

		Browser.window.addEventListener("pagehide", function(_)
		{
			for (socket in openSockets.copy())
			{
				socket.close();
			}
		});
	}
}
