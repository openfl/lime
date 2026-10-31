package net;

import haxe.Timer;
import lime.net.WebSocket;
import lime.net.WebSocketError;
import lime.net.WebSocketServer;
import lime.utils.Bytes;
import utest.Assert;
import utest.Test;

/**
	WebSockets between a server and its clients in this process, over
	loopback TCP. Their events are dispatched as the application's loop
	runs, and these tests run that part of it themselves while they wait,
	through the hook the loop calls once there is a WebSocket.
**/
@:access(lime._internal.backend.native.NativeApplication)
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime._internal.backend.native.NativeWebSocket)
@:access(lime.net.WebSocket)
@:access(net.HTTPSTest)
@:access(wsproto.Session)
class WebSocketTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && sys)
	private var servers:Array<WebSocketServer>;
	private var sockets:Array<WebSocket>;

	public function setup():Void
	{
		servers = [];
		sockets = [];
	}

	public function teardown():Void
	{
		for (socket in sockets) socket.close();
		for (server in servers) server.close();
		pump(function() return false, 0.05);
	}

	public function testIsSupported():Void
	{
		Assert.isTrue(WebSocket.isSupported);
		Assert.isTrue(WebSocketServer.isSupported);
	}

	public function testMessagesGoBothWays():Void
	{
		var server = echoServer();
		var client = track(new WebSocket());
		var connected = false;
		var texts:Array<String> = [];
		var datas:Array<Bytes> = [];
		client.onConnect.add(function() connected = true);
		client.onText.add(function(text) texts.push(text));
		client.onData.add(function(data) datas.push(data));
		client.connect("ws://127.0.0.1:" + server.localPort + "/echo");

		Assert.isFalse(client.sendText("too early"));
		Assert.isTrue(pump(function() return connected), "the client did not connect");
		Assert.isTrue(client.connected);
		Assert.equals("127.0.0.1", client.remoteAddress);
		Assert.equals(server.localPort, client.remotePort);

		var sent = [pattern(10, 1), Bytes.alloc(0), pattern(70000, 2), pattern(3 * 1024 * 100, 3)];
		Assert.isTrue(client.sendText("héllo \u{1F600}"));
		for (message in sent) Assert.isTrue(client.send(message));

		Assert.isTrue(pump(function() return texts.length == 1 && datas.length == sent.length), "the echoes did not all arrive");
		Assert.equals("héllo \u{1F600}", texts[0]);
		for (i in 0...sent.length)
		{
			if (i < datas.length) Assert.equals(0, sent[i].compare(datas[i]), "message " + i + " came back changed");
		}
	}

	public function testASubprotocolIsAgreed():Void
	{
		var server = echoServer();
		server.protocols = ["chat.v2", "chat.v1"];
		var client = track(new WebSocket());
		var connected = false;
		client.onConnect.add(function() connected = true);
		client.connect("ws://127.0.0.1:" + server.localPort + "/", ["chat.v1", "chat.v2"]);
		Assert.isTrue(pump(function() return connected));
		Assert.equals("chat.v1", client.protocol);
	}

	public function testTheClosingHandshakeReportsThePeersCode():Void
	{
		var server = new WebSocketServer();
		servers.push(server);
		var serverClose:Array<Dynamic> = null;
		server.onConnect.add(function(socket)
		{
			socket.onClose.add(function(code, reason) serverClose = [code, reason]);
		});
		Assert.isTrue(server.listen(0, "127.0.0.1"));

		var client = track(new WebSocket());
		var connected = false;
		var clientClose:Array<Dynamic> = null;
		client.onConnect.add(function() connected = true);
		client.onClose.add(function(code, reason) clientClose = [code, reason]);
		client.connect("ws://127.0.0.1:" + server.localPort + "/");
		Assert.isTrue(pump(function() return connected));

		client.close(4001, "done here");
		Assert.isFalse(client.connected);
		Assert.isTrue(pump(function() return clientClose != null && serverClose != null), "the close was not reported at both ends");
		Assert.equals(4001, serverClose[0]);
		Assert.equals("done here", serverClose[1]);
		Assert.equals(4001, clientClose[0]);
	}

	public function testAConnectNobodyAnswersFails():Void
	{
		// A port that was free a moment ago
		var probe = new WebSocketServer();
		Assert.isTrue(probe.listen(0, "127.0.0.1"));
		var port = probe.localPort;
		probe.close();

		var client = track(new WebSocket());
		var errors:Array<WebSocketError> = [];
		var closed = -1;
		client.onError.add(function(error, _) errors.push(error));
		client.onClose.add(function(code, _) closed = code);
		client.connect("ws://127.0.0.1:" + port + "/", null, 5000);
		Assert.isTrue(pump(function() return closed != -1, 10), "the failed connect was not reported");
		Assert.equals(1006, closed);
		Assert.equals(1, errors.length);
		Assert.equals(WebSocketError.CONNECT_FAILED, errors[0]);
	}

	public function testAConnectThatTakesTooLongTimesOut():Void
	{
		// An address nothing answers from, so the connect would wait for as
		// long as the system lets it
		var client = track(new WebSocket());
		var errors:Array<WebSocketError> = [];
		var closed = -1;
		client.onError.add(function(error, _) errors.push(error));
		client.onClose.add(function(code, _) closed = code);
		var started = Timer.stamp();
		client.connect("ws://10.255.255.1:81/", null, 300);
		Assert.isTrue(pump(function() return closed != -1, 5), "the connect did not time out");
		Assert.equals(1006, closed);
		Assert.equals(1, errors.length);
		Assert.equals(WebSocketError.TIMEOUT, errors[0]);
		Assert.isTrue(Timer.stamp() - started < 3, "took " + (Timer.stamp() - started) + " s");
	}

	public function testANonsenseURLFails():Void
	{
		var client = track(new WebSocket());
		var errors:Array<WebSocketError> = [];
		var closed = -1;
		client.onError.add(function(error, _) errors.push(error));
		client.onClose.add(function(code, _) closed = code);
		client.connect("http://127.0.0.1/");
		Assert.equals(1, errors.length);
		Assert.equals(WebSocketError.CONNECT_FAILED, errors[0]);
		Assert.equals(1006, closed);
	}

	public function testAServerThatDoesNotSpeakWebSocketIsRefused():Void
	{
		// A plain TCP listener that answers the upgrade with something else
		var listener = new sys.net.Socket();
		listener.bind(new sys.net.Host("127.0.0.1"), 0);
		listener.listen(1);
		listener.setBlocking(false);
		var port = listener.host().port;

		var client = track(new WebSocket());
		var errors:Array<WebSocketError> = [];
		var messages:Array<String> = [];
		var closed = -1;
		client.onError.add(function(error, message)
		{
			errors.push(error);
			messages.push(message);
		});
		client.onClose.add(function(code, _) closed = code);
		client.connect("ws://127.0.0.1:" + port + "/");

		var accepted:sys.net.Socket = null;
		Assert.isTrue(pump(function()
		{
			if (accepted == null)
			{
				try
				{
					accepted = listener.accept();
					accepted.output.writeString("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n");
				}
				catch (_:Dynamic) {}
			}
			return closed != -1;
		}), "the refusal was not reported");
		Assert.equals(1006, closed);
		Assert.equals(1, errors.length);
		Assert.equals(WebSocketError.REFUSED, errors[0]);
		Assert.isTrue(messages.length > 0 && messages[0].indexOf("404") >= 0, messages.join("; "));
		if (accepted != null) accepted.close();
		listener.close();
	}

	public function testAPingIsAnswered():Void
	{
		var server = echoServer();
		var client = track(new WebSocket());
		var connected = false;
		client.onConnect.add(function() connected = true);
		client.connect("ws://127.0.0.1:" + server.localPort + "/");
		Assert.isTrue(pump(function() return connected));

		var native:lime._internal.backend.native.NativeWebSocket = client.__backend;
		var connection = native.connection;
		connection.__hasTimeoutPotential = true;
		client.ping(Bytes.ofString("are you there"));
		Assert.isTrue(pump(function() return !connection.__hasTimeoutPotential), "no pong came back");
	}

	public function testAMessageTooLongClosesWith1009():Void
	{
		var server = new WebSocketServer();
		servers.push(server);
		var serverClose = -1;
		server.onConnect.add(function(socket)
		{
			socket.maxMessageSize = 1000;
			socket.onClose.add(function(code, _) serverClose = code);
		});
		Assert.isTrue(server.listen(0, "127.0.0.1"));

		var client = track(new WebSocket());
		var connected = false;
		var clientClose = -1;
		client.onConnect.add(function() connected = true);
		client.onClose.add(function(code, _) clientClose = code);
		client.connect("ws://127.0.0.1:" + server.localPort + "/");
		Assert.isTrue(pump(function() return connected));

		client.send(Bytes.alloc(1001));
		Assert.isTrue(pump(function() return serverClose != -1 && clientClose != -1));
		Assert.equals(1009, serverClose);
		Assert.equals(1009, clientClose);
	}

	// Neko's TLS checks a certificate however verifyCertificates is set
	#if !neko
	public function testSecureWebSocketsGoThroughTLS():Void
	{
		var server = echoServer(true);
		var client = track(new WebSocket());
		// The server's certificate is self-signed
		client.verifyCertificates = false;
		var echoed:String = null;
		client.onConnect.add(function() client.sendText("over TLS"));
		client.onText.add(function(text) echoed = text);
		client.connect("wss://127.0.0.1:" + server.localPort + "/");
		Assert.isTrue(pump(function() return echoed != null, 10), "nothing came back over wss://");
		Assert.equals("over TLS", echoed);
	}
	#end

	public function testSecureWebSocketsCheckCertificates():Void
	{
		var server = echoServer(true);
		var client = track(new WebSocket());
		var errors:Array<WebSocketError> = [];
		var closed = -1;
		client.onError.add(function(error, _) errors.push(error));
		client.onClose.add(function(code, _) closed = code);
		client.connect("wss://127.0.0.1:" + server.localPort + "/");
		Assert.isTrue(pump(function() return closed != -1, 10), "the untrusted certificate was not reported");
		Assert.equals(1006, closed);
		Assert.isFalse(client.connected);
		Assert.equals(1, errors.length);
		Assert.equals(WebSocketError.CONNECT_FAILED, errors[0]);
	}

	public function testTimingIsInMilliseconds():Void
	{
		var client = new WebSocket();
		Assert.equals(30000, client.pingInterval);
		Assert.equals(60000, client.idleTimeout);
		client.pingInterval = 1500;
		client.idleTimeout = 2500;
		Assert.equals(1500, client.pingInterval);
		Assert.equals(2500, client.idleTimeout);
	}

	public function testAQuietPeerTimesOut():Void
	{
		var peer = new SilentPeer();
		var client = track(new WebSocket());
		client.pingInterval = 100;
		client.idleTimeout = 400;
		var opened = 0.0;
		var errors:Array<WebSocketError> = [];
		var closed = -1;
		client.onConnect.add(function() opened = Timer.stamp());
		client.onError.add(function(error, _) errors.push(error));
		client.onClose.add(function(code, _) closed = code);
		client.connect("ws://127.0.0.1:" + peer.port + "/");

		var done = pump(function()
		{
			peer.step();
			return closed != -1;
		});
		var took = Timer.stamp() - opened;
		peer.close();

		Assert.isTrue(done, "the quiet peer was not given up on");
		Assert.isTrue(opened > 0, "the upgrade was not answered");
		Assert.equals(1, errors.length);
		Assert.equals(WebSocketError.TIMEOUT, errors[0]);
		Assert.equals(1006, closed);
		Assert.isTrue(took >= 0.3 && took < 3, "took " + took + " s");
	}

	public function testAPeerThatStopsReadingOverflows():Void
	{
		Assert.equals(16 * 1024 * 1024, new WebSocket().maxQueuedBytes);

		var peer = new SilentPeer();
		var client = track(new WebSocket());
		client.maxQueuedBytes = 256 * 1024;
		var connected = false;
		var errors:Array<WebSocketError> = [];
		var closed = -1;
		client.onConnect.add(function() connected = true);
		client.onError.add(function(error, _) errors.push(error));
		client.onClose.add(function(code, _) closed = code);
		client.connect("ws://127.0.0.1:" + peer.port + "/");
		Assert.isTrue(pump(function()
		{
			peer.step();
			return connected;
		}), "the upgrade was not answered");

		// Until the system's buffers are full, and then past the limit
		var chunk = Bytes.alloc(64 * 1024);
		var sent = 0;
		while (sent < 256 * 1024 * 1024 && client.send(chunk))
		{
			sent += chunk.length;
		}
		peer.close();

		Assert.isFalse(client.connected);
		Assert.equals(1, errors.length);
		Assert.equals(WebSocketError.OVERFLOW, errors[0]);
		Assert.equals(1011, closed);
		Assert.equals(0, client.bytesPending);
	}

	public function testAServerThatCannotListenSaysWhy():Void
	{
		var server = new WebSocketServer();
		servers.push(server);
		// An address of no machine's: TEST-NET-1
		Assert.isFalse(server.listen(0, "192.0.2.1"));
		Assert.equals(WebSocketError.LISTEN_FAILED, server.error);
		Assert.isFalse(server.listening);
		Assert.isTrue(server.listen(0, "127.0.0.1"));
		Assert.equals(WebSocketError.NONE, server.error);
	}

	public function testAWebSocketConnectsAgain():Void
	{
		var server = echoServer();
		var serverCloses:Array<Int> = [];
		server.onConnect.add(function(socket) socket.onClose.add(function(code, _) serverCloses.push(code)));
		var client = track(new WebSocket());
		var opened = 0;
		var closes = 0;
		var texts:Array<String> = [];
		client.onConnect.add(function() opened++);
		client.onClose.add(function(_, _) closes++);
		client.onText.add(function(text) texts.push(text));
		var url = "ws://127.0.0.1:" + server.localPort + "/";
		client.connect(url);
		Assert.isTrue(pump(function() return opened == 1), "the first connect did not open");

		client.connect(url);
		Assert.isFalse(client.connected);
		Assert.isTrue(pump(function() return opened == 2 && serverCloses.length == 1), "the second connect did not replace the first");
		Assert.equals(1000, serverCloses[0]);
		Assert.equals(0, closes);

		Assert.isTrue(client.sendText("second"));
		Assert.isTrue(pump(function() return texts.length == 1));
		Assert.equals("second", texts[0]);
	}

	public function testMasksAndKeysAreRandom():Void
	{
		var first = Bytes.alloc(32);
		var second = Bytes.alloc(32);
		Assert.isTrue(lime._internal.backend.native.NativeCFFI.lime_system_get_secure_random_bytes(first, 0, 32));
		Assert.isTrue(lime._internal.backend.native.NativeCFFI.lime_system_get_secure_random_bytes(second, 0, 32));
		Assert.notEquals(first.toHex(), second.toHex());
		Assert.isFalse(lime._internal.backend.native.NativeCFFI.lime_system_get_secure_random_bytes(first, 30, 8));
	}

	private function echoServer(secure:Bool = false):WebSocketServer
	{
		var server = new WebSocketServer();
		servers.push(server);
		if (secure)
		{
			server.setCertificate(sys.ssl.Certificate.fromString(HTTPSTest.SELF_SIGNED_CERTIFICATE), sys.ssl.Key.readPEM(HTTPSTest.SELF_SIGNED_KEY, false));
		}
		server.onConnect.add(function(socket)
		{
			socket.maxMessageSize = 0;
			socket.onText.add(function(text) socket.sendText(text));
			socket.onData.add(function(data) socket.send(data));
		});
		Assert.isTrue(server.listen(0, "127.0.0.1"), "the server did not listen");
		Assert.isTrue(server.listening);
		Assert.isTrue(server.localPort > 0);
		return server;
	}

	private function track(socket:WebSocket):WebSocket
	{
		sockets.push(socket);
		return socket;
	}

	private static function pump(done:Void->Bool, seconds:Float = 5):Bool
	{
		var deadline = Timer.stamp() + seconds;
		while (!done())
		{
			if (Timer.stamp() >= deadline) return false;
			// What the application's loop calls once a frame, set once there
			// is a WebSocket or a server
			var update = lime._internal.backend.native.NativeApplication.__updateWebSockets;
			if (update != null) update();
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
	#end
}

#if (lime_cffi && sys)
/**
	A server that answers a WebSocket upgrade, then neither reads nor writes:
	a peer gone quiet, or one that stopped reading.
**/
private class SilentPeer
{
	public var port(default, null):Int;

	private var answered:Bool = false;
	private var connection:sys.net.Socket;
	private var head:String = "";
	private var listener:sys.net.Socket;

	public function new()
	{
		listener = new sys.net.Socket();
		listener.bind(new sys.net.Host("127.0.0.1"), 0);
		listener.listen(1);
		listener.setBlocking(false);
		port = listener.host().port;
	}

	public function close():Void
	{
		if (connection != null) try connection.close() catch (_:Dynamic) {}
		try listener.close() catch (_:Dynamic) {}
	}

	// Takes the connection, and answers its upgrade, as far as it can
	// without waiting
	public function step():Void
	{
		if (answered) return;

		if (connection == null)
		{
			try
			{
				connection = listener.accept();
			}
			catch (_:Dynamic) {}
			if (connection == null) return;
			connection.setBlocking(false);
		}

		var buffer = Bytes.alloc(4096);
		while (head.indexOf("\r\n\r\n") < 0)
		{
			var count = 0;
			try
			{
				count = connection.input.readBytes(buffer, 0, buffer.length);
			}
			catch (_:Dynamic)
			{
				return;
			}
			if (count <= 0) return;
			head += buffer.getString(0, count);
		}

		var key = ~/sec-websocket-key:\s*([^\r\n]+)/i;
		if (!key.match(head)) return;

		var response = wsproto.Handshake.serverResponse(StringTools.trim(key.matched(1)));
		connection.setBlocking(true);
		connection.output.writeFullBytes(response, 0, response.length);
		connection.setBlocking(false);
		answered = true;
	}
}
#end
