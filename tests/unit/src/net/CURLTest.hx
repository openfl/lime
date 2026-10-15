package net;

import haxe.io.Bytes;
import haxe.Timer;
import utest.Assert;
import utest.Test;
#if (lime_cffi && lime_curl)
import lime.net.curl.CURL;
import lime.net.curl.CURLMulti;
#end
#if (lime_cffi && lime_curl && sys && target.threaded)
import sys.net.Host;
import sys.net.Socket;
import sys.thread.Deque;
import sys.thread.Thread;
#end

/**
	Lime runs HTTP requests with curl's multi interface on a thread of its own,
	which must not hold up the application's collector.
**/
class CURLTest extends Test
{
	// CURL_VERSION_ASYNCHDNS
	private static inline var ASYNCHDNS = 1 << 7;

	private static inline var CHUNKS = 40;
	private static inline var CHUNK_SIZE = 1024;

	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_curl)
	public function testNamesAreLookedUpOnAThreadOfTheirOwn():Void
	{
		// Looked up as part of a transfer, a slow name held up
		// curl_multi_perform, and the collector waited for it
		var info:Dynamic = CURL.versionInfo(FOURTH);
		Assert.notNull(info, "CURL.versionInfo() gave nothing");
		if (info == null) return;

		Assert.isTrue((info.features & ASYNCHDNS) != 0, "curl looks names up as part of transfers, with features " + info.features);
	}
	#end

	#if (lime_cffi && lime_curl && sys && target.threaded)
	public function testCollectingWhileATransferRunsOnAnotherThread():Void
	{
		// The collector, and the finalizers of dropped handles, run while
		// another thread is in curl_multi_perform, which shares a lock with them
		var server = new TricklingServer();
		var results = new Deque<Int>();
		var url = server.url;
		Thread.create(function() results.add(download(url)));

		var received:Null<Int> = null;
		var longest = 0.0;
		var end = Timer.stamp() + 10;

		while (received == null && Timer.stamp() < end)
		{
			// A handle for the collector to finalize
			new CURL();

			var start = Timer.stamp();
			collect();
			var took = Timer.stamp() - start;
			if (took > longest) longest = took;

			received = results.pop(false);
			Sys.sleep(0.005);
		}

		server.stop();

		Assert.equals(CHUNKS * CHUNK_SIZE, received, "the transfer did not finish");
		Assert.isTrue(longest < 0.25, "a collection took " + Math.round(longest * 1000) + " ms while the transfer ran");
	}

	private static function collect():Void
	{
		#if cpp
		cpp.vm.Gc.run(true);
		#elseif neko
		neko.vm.Gc.run(true);
		#elseif hl
		hl.Gc.major();
		#end
	}

	private static function download(url:String):Int
	{
		var received = 0;
		var curl = new CURL();
		curl.setOption(URL, url);
		curl.setOption(NOSIGNAL, true);
		curl.setOption(WRITEFUNCTION, function(curl:CURL, output:Bytes):Int
		{
			received += output.length;
			return output.length;
		});

		var multi = new CURLMulti();
		multi.addHandle(curl);

		do
		{
			multi.wait(50);
			multi.perform();
		}
		while (multi.runningHandles > 0);

		multi.removeHandle(curl);
		curl.cleanup();
		return received;
	}
	#end
}

#if (lime_cffi && lime_curl && sys && target.threaded)
/**
	Answers each request on a local port with a response sent a little at a
	time, so that a transfer takes a while.
**/
private class TricklingServer
{
	public var url(default, null):String;

	private var listener:Socket;
	private var stopped:Bool;

	public function new()
	{
		listener = new Socket();
		listener.bind(new Host("127.0.0.1"), 0);
		listener.listen(4);
		url = "http://127.0.0.1:" + listener.host().port + "/";

		Thread.create(acceptConnections);
	}

	public function stop():Void
	{
		stopped = true;
	}

	private function acceptConnections():Void
	{
		while (!stopped)
		{
			// Waits briefly, so stopping is seen
			if (Socket.select([listener], [], [], 0.05).read.length == 0) continue;

			var connection = listener.accept();
			Thread.create(function() serve(connection));
		}

		listener.close();
	}

	private function serve(connection:Socket):Void
	{
		try
		{
			while (connection.input.readLine() != "") {}

			connection.output.writeString("HTTP/1.1 200 OK
Connection: close
Content-Length: " + (@:privateAccess CURLTest.CHUNKS * @:privateAccess CURLTest.CHUNK_SIZE) + "

");

			var chunk = Bytes.alloc(@:privateAccess CURLTest.CHUNK_SIZE);
			chunk.fill(0, chunk.length, 65);

			for (i in 0...@:privateAccess CURLTest.CHUNKS)
			{
				if (stopped) break;
				connection.output.write(chunk);
				connection.output.flush();
				Sys.sleep(0.02);
			}
		}
		catch (e:Dynamic) {}

		connection.close();
	}
}
#end
