import haxe.Timer;
import haxe.Unserializer;
import lime.app.Application;
import lime.net.LocalServer;
import lime.net.LocalSocket;
import lime.system.System;
import lime.utils.Bytes;

/**
	Local sockets between two processes. With no arguments, this starts a copy
	of itself with `--serve` and checks what it echoes. Any other program that
	speaks native-ipc's protocol can be either end:

	- `--serve <name>` listens on `name` and answers each message with
	  `echo:` and the message, until a client sends `quit`.
	- `--connect <name>` sends messages to the server on `name` and checks
	  that each comes back as `--serve` answers it.
	- `--channel <name>` listens on `name` for one message in CrossByte
	  SharedChannel's format (see native-ipc's PROTOCOL.md), and checks that
	  it calls `receive("hello", 42)`.

	Exits with 0 when everything checked out, and 1 otherwise.
**/
class Main extends Application
{
	private static inline var TIMEOUT = 20.0;

	private var deadline:Float;
	private var child:sys.io.Process;
	private var finished = false;

	public function new()
	{
		super();

		deadline = Timer.stamp() + TIMEOUT;
		onUpdate.add(function(_) if (!finished && Timer.stamp() > deadline) fail("timed out"));

		if (!LocalSocket.isSupported)
		{
			fail("local sockets are not supported here");
			return;
		}

		var args = Sys.args();
		var mode = args.length > 0 ? args[0] : "";
		var name = args.length > 1 ? args[1] : "lime-local-socket-" + Std.random(0x3FFFFFFF);

		switch (mode)
		{
			case "--serve":
				serve(name);
			case "--connect":
				connect(name, false);
			case "--channel":
				channel(name);
			default:
				// A copy of this program serves, and this one connects to it.
				child = new sys.io.Process(Sys.programPath(), ["--serve", name]);
				connect(name, true);
		}
	}

	private function serve(name:String):Void
	{
		var server = new LocalServer();
		server.onConnect.add(function(socket)
		{
			socket.onData.add(function(data)
			{
				if (data.toString() == "quit")
				{
					socket.close();
					server.close();
					pass();
					return;
				}

				var reply = Bytes.alloc(5 + data.length);
				reply.blit(0, Bytes.ofString("echo:"), 0, 5);
				reply.blit(5, data, 0, data.length);
				socket.send(reply);
			});
		});

		if (!server.listen(name)) fail("could not listen on " + name + ": " + server.error);
		else Sys.println("serving " + name);
	}

	private function connect(name:String, waitForServer:Bool):Void
	{
		var messages = [Bytes.ofString("ping"), Bytes.alloc(0), pattern(1024 * 1024)];
		var next = 0;
		var socket = new LocalSocket();

		socket.onError.add(function(error) fail("connect to " + name + ": error " + error));
		socket.onData.add(function(data)
		{
			var expected = messages[next];
			var reply = Bytes.alloc(5 + expected.length);
			reply.blit(0, Bytes.ofString("echo:"), 0, 5);
			reply.blit(5, expected, 0, expected.length);

			if (data.compare(reply) != 0)
			{
				fail("message " + next + " came back changed (" + data.length + " bytes)");
				return;
			}

			Sys.println("echoed " + expected.length + " bytes");
			next++;

			if (next < messages.length)
			{
				socket.send(messages[next]);
			}
			else
			{
				socket.send(Bytes.ofString("quit"));
				pass();
			}
		});
		socket.onConnect.add(function() socket.send(messages[0]));

		// A server started alongside takes a moment to listen.
		socket.connect(name, waitForServer ? 10000 : 5000);
	}

	private function channel(name:String):Void
	{
		var server = new LocalServer();
		server.onConnect.add(function(socket)
		{
			socket.onData.add(function(data)
			{
				// Little-endian lengths, then the method, then its arguments in
				// Haxe serialization.
				var methodLength = data.getInt32(0);
				var method = data.getString(4, methodLength);
				var argumentsLength = data.getInt32(4 + methodLength);
				var args:Array<Dynamic> = Unserializer.run(data.getString(8 + methodLength, argumentsLength));

				Sys.println("called " + method + " " + Std.string(args));

				if (method == "receive" && args.length == 2 && args[0] == "hello" && args[1] == 42)
				{
					server.close();
					pass();
				}
				else
				{
					fail("unexpected call " + method + " " + Std.string(args));
				}
			});
		});

		if (!server.listen(name)) fail("could not listen on " + name + ": " + server.error);
		else Sys.println("listening for a channel message on " + name);
	}

	private function pass():Void
	{
		finish(0);
	}

	private function fail(message:String):Void
	{
		Sys.println("FAILED: " + message);
		finish(1);
	}

	private function finish(code:Int):Void
	{
		if (finished) return;
		finished = true;

		if (child != null)
		{
			var childCode = child.exitCode(true);
			if (childCode != 0)
			{
				Sys.println("FAILED: the serving copy exited with " + childCode);
				code = 1;
			}
		}

		Sys.println(code == 0 ? "OK" : "FAILED");
		Sys.stdout().flush();
		System.exit(code);
	}

	private static function pattern(length:Int):Bytes
	{
		var bytes = Bytes.alloc(length);
		for (i in 0...length)
		{
			bytes.set(i, (i * 131) & 0xFF);
		}
		return bytes;
	}
}
