package net;

import haxe.Timer;
import lime.app.Application;
import lime.net.LocalServer;
import lime.net.LocalSocket;
import lime.net.LocalSocketError;
import lime.utils.Bytes;
import utest.Assert;
import utest.Test;

/**
	Local sockets between a server and its clients in this process, over the
	same named pipes and Unix sockets as between processes. Their events are
	dispatched as the application's loop runs, and these tests dispatch them
	themselves while they wait.
**/
@:access(lime._internal.backend.native.NativeApplication)
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.app.Application)
class LocalSocketTest extends Test
{
	private static var counter = 0;

	public function new()
	{
		super();
	}

	#if (lime_cffi && (windows || mac || linux))
	public function setup():Void
	{
		// The runner can run these before the application's loop starts, which
		// is where Lime registers its event handlers, so the same one is
		// registered here
		var backend = Application.current.__backend;
		lime._internal.backend.native.NativeCFFI.lime_local_socket_event_manager_register(backend.handleLocalSocketEvent, backend.localSocketEventInfo);
	}

	public function testIsSupported():Void
	{
		Assert.isTrue(LocalSocket.isSupported);
		Assert.isTrue(LocalServer.isSupported);
	}

	public function testMessagesArriveWholeAndInOrder():Void
	{
		var name = uniqueName("order");
		var server = new LocalServer();
		var taken:LocalSocket = null;
		var received:Array<Bytes> = [];
		server.onConnect.add(function(socket)
		{
			taken = socket;
			socket.onData.add(function(data) received.push(data));
		});
		Assert.isTrue(server.listen(name), "the server did not listen: " + server.error);
		Assert.isTrue(server.listening);

		var client = new LocalSocket();
		var connected = false;
		var replies:Array<Bytes> = [];
		client.onConnect.add(function() connected = true);
		client.onData.add(function(data) replies.push(data));
		client.connect(name, 3000);

		// Sent before the connection is made: goes once it is.
		var sent = [pattern(10, 1), Bytes.alloc(0), pattern(1, 2), pattern(70000, 3), pattern(3 * 1024 * 1024, 4)];
		for (message in sent)
		{
			Assert.isTrue(client.send(message));
		}

		Assert.isTrue(pump(function() return connected && received.length == sent.length), "the messages did not all arrive");
		Assert.isTrue(client.connected);
		Assert.notNull(taken);
		Assert.equals(sent.length, received.length);
		for (i in 0...sent.length)
		{
			if (i < received.length) Assert.equals(0, sent[i].compare(received[i]), "message " + i + " arrived changed");
		}

		if (taken != null)
		{
			Assert.isTrue(taken.connected);
			Assert.equals(name, taken.name);
			Assert.isTrue(taken.send(Bytes.ofString("reply"), 0, 5));
			Assert.isTrue(pump(function() return replies.length == 1));
			if (replies.length == 1) Assert.equals("reply", replies[0].toString());
		}

		client.close();
		if (taken != null) taken.close();
		server.close();
		Assert.isFalse(server.listening);
	}

	public function testPartOfABufferIsSent():Void
	{
		var name = uniqueName("part");
		var server = new LocalServer();
		var received:Bytes = null;
		server.onConnect.add(function(socket) socket.onData.add(function(data) received = data));
		server.listen(name);

		var client = new LocalSocket();
		client.connect(name, 3000);
		var data = Bytes.ofString("0123456789");
		Assert.isTrue(client.send(data, 2, 5));
		Assert.isFalse(client.send(data, 8, 5), "a range past the end was sent");
		Assert.isFalse(client.send(data, -1, 2), "a negative offset was sent");
		Assert.isFalse(client.send(null));
		Assert.isFalse(client.send(Bytes.alloc(LocalSocket.MAX_MESSAGE_SIZE + 1)), "a message too long was sent");

		Assert.isTrue(pump(function() return received != null));
		if (received != null) Assert.equals("23456", received.toString());

		client.close();
		server.close();
	}

	public function testANameInUseIsRefused():Void
	{
		var name = uniqueName("inuse");
		var first = new LocalServer();
		var second = new LocalServer();

		Assert.isTrue(first.listen(name));
		Assert.isFalse(second.listen(name));
		Assert.equals(LocalSocketError.NAME_IN_USE, second.error);
		Assert.isFalse(second.listening);

		// Free again once closed.
		first.close();
		Assert.isTrue(second.listen(name));
		Assert.equals(LocalSocketError.NONE, second.error);
		second.close();
	}

	public function testAConnectNothingTakesEndsAtItsTimeout():Void
	{
		var client = new LocalSocket();
		var errors:Array<LocalSocketError> = [];
		var closed = false;
		client.onError.add(function(error) errors.push(error));
		client.onClose.add(function() closed = true);

		var start = Timer.stamp();
		client.connect(uniqueName("nobody"), 200);
		Assert.isTrue(pump(function() return closed), "the connect never ended");
		var took = Timer.stamp() - start;

		Assert.equals(1, errors.length);
		if (errors.length == 1) Assert.equals(LocalSocketError.TIMEOUT, errors[0]);
		Assert.isFalse(client.connected);
		Assert.isTrue(took < 2, "a connect with a 200 ms timeout took " + took + " s");
		Assert.isFalse(client.send(Bytes.ofString("late")));
	}

	public function testClosingOneEndClosesTheOther():Void
	{
		var name = uniqueName("close");
		var server = new LocalServer();
		var taken:LocalSocket = null;
		var serverClosed = false;
		server.onConnect.add(function(socket)
		{
			taken = socket;
			socket.onClose.add(function() serverClosed = true);
		});
		server.listen(name);

		var client = new LocalSocket();
		var clientClosed = false;
		client.onClose.add(function() clientClosed = true);
		client.connect(name, 3000);
		Assert.isTrue(pump(function() return taken != null && client.connected));

		client.close();
		Assert.isTrue(pump(function() return serverClosed), "the server's end did not see the client go");
		Assert.isFalse(clientClosed, "onClose was dispatched for close()");
		if (taken != null) Assert.isFalse(taken.connected);

		// And the other way.
		var second = new LocalSocket();
		var secondClosed = false;
		taken = null;
		second.onClose.add(function() secondClosed = true);
		second.connect(name, 3000);
		Assert.isTrue(pump(function() return taken != null && second.connected));
		if (taken != null) taken.close();
		Assert.isTrue(pump(function() return secondClosed), "the client did not see the server's end go");

		server.close();
	}

	public function testAServerTakesManyClients():Void
	{
		var name = uniqueName("many");
		var server = new LocalServer();
		var seen = [for (i in 0...6) false];
		var taken:Array<LocalSocket> = [];
		server.onConnect.add(function(socket)
		{
			taken.push(socket);
			socket.onData.add(function(data) if (data.length == 1 && data.get(0) < seen.length) seen[data.get(0)] = true);
		});
		server.listen(name);

		var clients = [];
		for (i in 0...seen.length)
		{
			var client = new LocalSocket();
			client.connect(name, 3000);
			var byte = Bytes.alloc(1);
			byte.set(0, i);
			client.send(byte);
			clients.push(client);
		}

		Assert.isTrue(pump(function() return seen.indexOf(false) < 0), "not every client's message arrived");
		Assert.equals(seen.length, taken.length);

		for (client in clients) client.close();
		for (socket in taken) socket.close();
		server.close();
	}

	public function testAPeerThatStopsReadingIsAnOverflow():Void
	{
		var name = uniqueName("overflow");
		var server = new LocalServer();
		var taken:LocalSocket = null;
		server.onConnect.add(function(socket) taken = socket);
		server.listen(name);

		var client = new LocalSocket();
		var errors:Array<LocalSocketError> = [];
		var closed = false;
		client.onError.add(function(error) errors.push(error));
		client.onClose.add(function() closed = true);
		client.maxQueuedBytes = 256 * 1024;
		client.connect(name, 3000);
		Assert.isTrue(pump(function() return taken != null && client.connected));
		if (taken == null) return;

		// The server's end holds little, and the loop does not run while the
		// client sends, so what it sends piles up past its limit.
		taken.maxQueuedBytes = 1024;
		var chunk = Bytes.alloc(64 * 1024);
		var refused = false;
		for (i in 0...1000)
		{
			if (!client.send(chunk))
			{
				refused = true;
				break;
			}
			Sys.sleep(0.001);
		}

		Assert.isTrue(refused, "a send past the limit was taken");
		Assert.isTrue(pump(function() return closed), "the client was not closed");
		Assert.equals(1, errors.length);
		if (errors.length == 1) Assert.equals(LocalSocketError.OVERFLOW, errors[0]);

		taken.close();
		server.close();
	}

	public function testAHeldBackPeerSendsEverythingOnceRead():Void
	{
		var name = uniqueName("pressure");
		var server = new LocalServer();
		var taken:LocalSocket = null;
		var received = 0;
		server.onConnect.add(function(socket)
		{
			taken = socket;
			socket.maxQueuedBytes = 8 * 1024;
			socket.onData.add(function(_) received++);
		});
		server.listen(name);

		var client = new LocalSocket();
		client.maxQueuedBytes = 0;
		client.connect(name, 3000);
		Assert.isTrue(pump(function() return taken != null && client.connected));

		var count = 200;
		var message = Bytes.alloc(4096);
		for (i in 0...count)
		{
			Assert.isTrue(client.send(message));
		}

		Assert.isTrue(pump(function() return received == count), "only " + received + " of " + count + " messages arrived");
		Assert.isTrue(pump(function() return client.bytesPending == 0), "the client still holds " + client.bytesPending + " bytes");

		client.close();
		if (taken != null) taken.close();
		server.close();
	}

	public function testAClosedServerKeepsTheConnectionsItTook():Void
	{
		var name = uniqueName("keeps");
		var server = new LocalServer();
		var taken:LocalSocket = null;
		var received:String = null;
		server.onConnect.add(function(socket)
		{
			taken = socket;
			socket.onData.add(function(data) received = data.toString());
		});
		server.listen(name);

		var client = new LocalSocket();
		client.connect(name, 3000);
		Assert.isTrue(pump(function() return taken != null && client.connected));

		server.close();
		client.send(Bytes.ofString("still here"));
		Assert.isTrue(pump(function() return received != null));
		Assert.equals("still here", received);

		client.close();
		if (taken != null) taken.close();
	}

	private static function pump(done:Void->Bool, seconds:Float = 5):Bool
	{
		var deadline = Timer.stamp() + seconds;
		while (!done())
		{
			if (Timer.stamp() >= deadline) return false;
			lime._internal.backend.native.NativeCFFI.lime_local_socket_update();
			Sys.sleep(0.001);
		}
		return true;
	}

	private static function pattern(length:Int, seed:Int):Bytes
	{
		var bytes = Bytes.alloc(length);
		for (i in 0...length)
		{
			bytes.set(i, (i * 131 + seed * 7) & 0xFF);
		}
		return bytes;
	}

	private static function uniqueName(what:String):String
	{
		return "lime-test-" + what + "-" + Std.random(0x3FFFFFFF) + "-" + (++counter);
	}
	#else
	public function testIsNotSupported():Void
	{
		Assert.isFalse(LocalSocket.isSupported);
		Assert.isFalse(new LocalServer().listen("x"));
	}
	#end
}
