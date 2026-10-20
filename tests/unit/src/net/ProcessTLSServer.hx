package net;

import sys.thread.Thread;

/** An independent TLS fixture for Neko, whose SSL server can raise SIGPIPE. */
class ProcessTLSServer
{
	private static var active:Array<ProcessTLSServer> = [];
	public var url(default, null):String;

	private var process:sys.io.Process;
	private var directory:String;
	private var stopped:Bool = false;
	private var exit = new sys.thread.Lock();
	private var outputDone = new sys.thread.Lock();
	private var errorDone = new sys.thread.Lock();
	private var exitCode:Int;
	private var errors:String = "";
	private var port:Int;
	private var outputRead:Bool = false;
	private var outputError:String = "";
	private var firstLine:String = "";

	public function new(certificate:String, key:String)
	{
		do directory = haxe.io.Path.join([Sys.getCwd(), "lime-test-tls-" + Std.random(0x3FFFFFFF)])
		while (sys.FileSystem.exists(directory));
		sys.FileSystem.createDirectory(directory);
		var script = haxe.io.Path.join([directory, "server.py"]);
		var certificatePath = haxe.io.Path.join([directory, "certificate.pem"]);
		var keyPath = haxe.io.Path.join([directory, "key.pem"]);
		try
		{
			var source = haxe.Resource.getString("lime-test-tls-server");
			if (source == null) throw "Missing embedded TLS fixture; build with tests/unit/project.xml.";
			sys.io.File.saveContent(script, source);
			sys.io.File.saveContent(certificatePath, certificate);
			sys.io.File.saveContent(keyPath, key);
			var python = Sys.getEnv("LIME_TEST_PYTHON");
			if (python == null || python == "") python = Sys.systemName() == "Windows" ? "python" : "python3";
			process = new sys.io.Process(python, ["-u", script, certificatePath, keyPath]);
			Thread.create(function()
			{
				try
				{
					firstLine = process.stdout.readLine();
					port = Std.parseInt(firstLine);
				}
				catch (error:Dynamic) outputError = Std.string(error);
				outputRead = true;
				outputDone.release();
			});
			Thread.create(function()
			{
				try
				{
					while (true)
					{
						var line = process.stderr.readLine();
						if (errors.length < 8192) errors += line + "\n";
					}
				}
				catch (_:Dynamic) {}
				errorDone.release();
			});
			Thread.create(function()
			{
				try exitCode = process.exitCode() catch (_:Dynamic) exitCode = -1;
				exit.release();
			});
			if (!outputDone.wait(10) || port == null || port < 1 || port > 65535)
				throw "Loopback TLS fixture did not start using " + python + ". Output: " + firstLine + "; read error: " + outputError;
			url = "https://127.0.0.1:" + port + "/";
			active.push(this);
		}
		catch (error:Dynamic)
		{
			try stop() catch (_:Dynamic) {}
			throw Std.string(error) + (errors == "" ? "" : "\n" + errors);
		}
	}

	public function stop():Void
	{
		if (stopped) return;
		stopped = true;
		active.remove(this);
		if (process != null)
		{
			try { process.stdin.writeString("q"); process.stdin.flush(); } catch (_:Dynamic) {}
			if (!exit.wait(7))
			{
				try process.kill() catch (_:Dynamic) {}
				exit.wait(3);
			}
			if (!outputRead) outputDone.wait(1);
			errorDone.wait(1);
			process.close();
		}
		for (file in sys.FileSystem.readDirectory(directory)) sys.FileSystem.deleteFile(haxe.io.Path.join([directory, file]));
		sys.FileSystem.deleteDirectory(directory);
		if (process != null && exitCode != 0) throw "TLS fixture exited with code " + exitCode + ": " + errors;
	}

	public static function closeAll():Void
	{
		var failure:Dynamic = null;
		for (server in active.copy()) try server.stop() catch (error:Dynamic) failure = error;
		if (failure != null) throw failure;
	}
}
