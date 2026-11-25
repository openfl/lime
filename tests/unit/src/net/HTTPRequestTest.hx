package net;

import haxe.crypto.Crc32;
import haxe.io.Bytes;
import utest.Assert;
import utest.Async;
import utest.Test;
#if (lime_cffi && lime_curl)
import lime.net.HTTPRequest;
#end
#if (lime_cffi && lime_curl && sys && target.threaded)
import sys.net.Host;
import sys.net.Socket;
import sys.thread.Thread;
#end

/**
	Native HTTP requests send their whole body, and a request can be loaded
	again, from its last load's handlers or before that load has finished.
**/
class HTTPRequestTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_curl && sys && target.threaded)
	@:timeout(20000)
	public function testPostSendsTheWholeBody(async:Async):Void
	{
		// Bodies across the sizes of curl's upload buffer and of a TLS record
		postEach(new ReceivingServer(false), [1, 16385, 65537, 1048577], async);
	}

	#if !neko
	@:timeout(20000)
	public function testPostSendsTheWholeBodyOverHTTPS(async:Async):Void
	{
		postEach(new ReceivingServer(true), [1, 16385, 65537, 1048577], async);
	}
	#end

	@:timeout(10000)
	public function testTextRequestsSendTheirBodyAsIs(async:Async):Void
	{
		// Text requests asked curl for ASCII transfers, and curl 8 converts
		// their uploads to CRLF line endings outside Windows, as a body of
		// unknown length, so they went out chunked
		var server = new ReceivingServer(false);
		var text = "one\ntwo\r\nthree\n";
		var methods:Array<lime.net.HTTPRequestMethod> = [POST, PUT];

		function next():Void
		{
			if (methods.length == 0)
			{
				server.stop();
				async.done();
				return;
			}

			var method = methods.shift();
			var request = new HTTPRequest<String>();
			request.method = method;
			request.data = Bytes.ofString(text);
			request.load(server.url).onComplete(function(answer)
			{
				Assert.equals(ReceivingServer.describe(Bytes.ofString(text)), answer, method + " changed the body");
				next();
			}).onError(function(error)
			{
				Assert.fail(method + " failed with status " + request.responseStatus + ": " + error);
				next();
			});
		}

		next();
	}

	@:timeout(10000)
	public function testLoadingAgainSendsTheNewBody(async:Async):Void
	{
		// The handle of the first load was cleaned up when it finished, and the
		// second load set up the freed handle again, so it never reached the server
		var server = new ReceivingServer(false);
		var request = new HTTPRequest<Bytes>();
		request.method = POST;

		var first = body(5000, 1);
		request.data = first;
		request.load(server.url).onComplete(function(answer)
		{
			assertReceived(first, answer);

			var second = body(7000, 2);
			request.data = second;
			request.load(server.url).onComplete(function(answer)
			{
				assertReceived(second, answer);
				server.stop();
				async.done();
			}).onError(function(error)
			{
				Assert.fail("the second load failed: " + error);
				server.stop();
				async.done();
			});
		}).onError(function(error)
		{
			Assert.fail("the first load failed: " + error);
			server.stop();
			async.done();
		});
	}

	@:timeout(10000)
	public function testLoadingAgainWhileALoadRuns(async:Async):Void
	{
		// The first load is answered after the second, and is dropped
		var server = new ReceivingServer(false);
		var request = new HTTPRequest<Bytes>();
		request.method = POST;
		request.enableResponseHeaders = true;

		request.data = body(3000, 1);
		request.load(server.url + ReceivingServer.SLOW).onComplete(function(_)
		{
			Assert.fail("the first load completed after the request was loaded again");
		});

		var second = body(4000, 2);
		request.data = second;
		request.load(server.url).onComplete(function(answer)
		{
			assertReceived(second, answer);

			// Lets the first load be answered and dropped
			haxe.Timer.delay(function()
			{
				Assert.equals("/", pathHeader(request.responseHeaders), "the response headers are not the second load's");
				Assert.equals(200, request.responseStatus);
				server.stop();
				async.done();
			}, Std.int(ReceivingServer.SLOW_DELAY * 2000));
		}).onError(function(error)
		{
			Assert.fail("the second load failed: " + error);
			server.stop();
			async.done();
		});
	}

	@:timeout(10000)
	public function testLoadingAgainAfterAnErrorStatus(async:Async):Void
	{
		var server = new ReceivingServer(false);
		var request = new HTTPRequest<String>();
		request.method = POST;

		request.data = Bytes.ofString("first");
		request.load(server.url + ReceivingServer.MISSING).onComplete(function(_)
		{
			Assert.fail("a 404 completed");
			server.stop();
			async.done();
		}).onError(function(_)
		{
			Assert.equals(404, request.responseStatus);

			request.data = Bytes.ofString("second");
			request.load(server.url).onComplete(function(answer)
			{
				Assert.equals(ReceivingServer.describe(Bytes.ofString("second")), answer);
				Assert.equals(200, request.responseStatus);
				server.stop();
				async.done();
			}).onError(function(error)
			{
				Assert.fail("the load after the 404 failed: " + error);
				server.stop();
				async.done();
			});
		});
	}

	@:timeout(15000)
	public function testLoadingAgainAfterAFailedConnection(async:Async):Void
	{
		// Nothing listens on the port of a closed socket
		var closed = new Socket();
		closed.bind(new Host("127.0.0.1"), 0);
		var refusedURL = "http://127.0.0.1:" + closed.host().port + "/";
		closed.close();

		var server = new ReceivingServer(false);
		var request = new HTTPRequest<String>();
		request.method = POST;

		request.data = Bytes.ofString("first");
		request.load(refusedURL).onComplete(function(_)
		{
			Assert.fail("a load from a closed port completed");
			server.stop();
			async.done();
		}).onError(function(_)
		{
			request.data = Bytes.ofString("second");
			request.load(server.url).onComplete(function(answer)
			{
				Assert.equals(ReceivingServer.describe(Bytes.ofString("second")), answer);
				server.stop();
				async.done();
			}).onError(function(error)
			{
				Assert.fail("the load after the failed connection failed: " + error);
				server.stop();
				async.done();
			});
		});
	}

	@:timeout(10000)
	public function testLoadingAFileAgain(async:Async):Void
	{
		var first = Sys.getCwd() + "lime-test-http-request-1.txt";
		var second = Sys.getCwd() + "lime-test-http-request-2.txt";
		sys.io.File.saveContent(first, "first");
		sys.io.File.saveContent(second, "second");

		function finish():Void
		{
			sys.FileSystem.deleteFile(first);
			sys.FileSystem.deleteFile(second);
			async.done();
		}

		var request = new HTTPRequest<String>();
		request.load(first).onComplete(function(content)
		{
			Assert.equals("first", content);

			request.load(first + ".missing").onComplete(function(_)
			{
				Assert.fail("a missing file loaded");
				finish();
			}).onError(function(_)
			{
				request.load(second).onComplete(function(content)
				{
					Assert.equals("second", content);
					finish();
				}).onError(function(error)
				{
					Assert.fail("the load after the missing file failed: " + error);
					finish();
				});
			});
		}).onError(function(error)
		{
			Assert.fail("the first file did not load: " + error);
			finish();
		});
	}

	private static function pathHeader(headers:Array<lime.net.HTTPRequestHeader>):String
	{
		var path = null;
		for (header in headers)
		{
			if (header.name == ReceivingServer.PATH_HEADER)
			{
				Assert.isNull(path, "the response headers hold more than one " + ReceivingServer.PATH_HEADER);
				path = header.value;
			}
		}
		return path;
	}

	private static function postEach(server:ReceivingServer, sizes:Array<Int>, async:Async):Void
	{
		if (sizes.length == 0)
		{
			server.stop();
			async.done();
			return;
		}

		var size = sizes.shift();
		var sent = body(size, size);
		var request = new HTTPRequest<Bytes>();
		request.method = POST;
		request.data = sent;
		request.verifyCertificates = false;
		request.load(server.url).onComplete(function(answer)
		{
			assertReceived(sent, answer);
			postEach(server, sizes, async);
		}).onError(function(error)
		{
			Assert.fail("POST of " + size + " bytes failed: " + error);
			postEach(server, sizes, async);
		});
	}

	private static function body(length:Int, seed:Int):Bytes
	{
		var bytes = Bytes.alloc(length);
		for (i in 0...length)
		{
			bytes.set(i, (i + (i >> 8) + seed) & 0xFF);
		}
		return bytes;
	}

	private static function assertReceived(sent:Bytes, answer:Bytes, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(ReceivingServer.describe(sent), answer == null ? null : answer.toString(), "the server got other bytes than were sent", pos);
	}
	#end
}

#if (lime_cffi && lime_curl && sys && target.threaded)
/**
	Answers each request on a local port with the length and CRC-32 of the
	body it was sent and its path in `PATH_HEADER`, a while later for requests
	to `SLOW`, with a 404 for requests to `MISSING`, and with a 411 for
	chunked request bodies.

	The answers stay small, as HashLink's TLS sockets send without letting the
	garbage collector go on, so a server waiting to send would stop every
	thread.
**/
private class ReceivingServer
{
	public static inline var MISSING = "missing";
	public static inline var PATH_HEADER = "X-Path";
	public static inline var SLOW = "slow";
	public static inline var SLOW_DELAY = 0.5;

	public var url(default, null):String;

	private var listener:Socket;
	private var secure:Bool;
	private var stopped:Bool;

	public static function describe(body:Bytes):String
	{
		return body.length + " bytes, CRC-32 " + StringTools.hex(Crc32.make(body), 8);
	}

	public function new(secure:Bool)
	{
		this.secure = secure;

		#if !neko
		if (secure)
		{
			var tls = new sys.ssl.Socket();
			tls.verifyCert = false;
			tls.setCertificate(sys.ssl.Certificate.fromString(@:privateAccess HTTPSTest.SELF_SIGNED_CERTIFICATE),
				sys.ssl.Key.readPEM(@:privateAccess HTTPSTest.SELF_SIGNED_KEY, false));
			listener = tls;
		}
		else
		#end
		{
			listener = new Socket();
		}

		listener.bind(new Host("127.0.0.1"), 0);
		listener.listen(4);
		url = (secure ? "https" : "http") + "://127.0.0.1:" + listener.host().port + "/";

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

			try
			{
				var connection = listener.accept();
				Thread.create(function() serve(connection));
			}
			catch (e:Dynamic) {}
		}

		listener.close();
	}

	private function serve(connection:Socket):Void
	{
		try
		{
			#if !neko
			if (secure) (cast connection : sys.ssl.Socket).handshake();
			#end

			var path = connection.input.readLine().split(" ")[1];
			var length = 0;
			var chunked = false;

			while (true)
			{
				var line = connection.input.readLine();
				if (line == "") break;

				var header = line.toLowerCase();
				if (StringTools.startsWith(header, "content-length:"))
				{
					length = Std.parseInt(StringTools.trim(line.substr(15)));
				}
				else if (StringTools.startsWith(header, "transfer-encoding:") && header.indexOf("chunked") > -1)
				{
					chunked = true;
				}
			}

			// Like many servers, it takes no request body of unknown length
			var body = chunked ? Bytes.alloc(0) : connection.input.read(length);
			if (path == "/" + SLOW) Sys.sleep(SLOW_DELAY);

			var status = chunked ? "411 Length Required" : path == "/" + MISSING ? "404 Not Found" : "200 OK";
			var answer = Bytes.ofString(describe(body));
			connection.output.writeString("HTTP/1.1 " + status + "\r\nConnection: close\r\n" + PATH_HEADER + ": " + path + "\r\nContent-Length: "
				+ answer.length + "\r\n\r\n");
			connection.output.write(answer);
			connection.output.flush();
		}
		catch (e:Dynamic) {}

		try connection.close() catch (e:Dynamic) {}
	}
}
#end
