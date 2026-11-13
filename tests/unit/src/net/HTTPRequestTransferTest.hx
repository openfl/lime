package net;

import haxe.io.Bytes;
import utest.Assert;
import utest.Async;
import utest.Test;
#if (lime_cffi && lime_curl)
import lime.net.HTTPRequest;
#end
#if (lime_cffi && lime_curl && sys && target.threaded)
import net.ScriptedServer;
#end

/**
	Native HTTP requests that cannot finish fail rather than wait: refused
	connections, names that do not resolve, servers that close early or go
	quiet, and requests that are cancelled. Requests that can finish do, many at
	a time.
**/
class HTTPRequestTransferTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_curl && sys && target.threaded)
	private var servers:Array<ScriptedServer>;

	public function setup():Void
	{
		servers = [];
	}

	public function teardown():Void
	{
		for (server in servers) server.stop();
	}

	@:timeout(10000)
	public function testARefusedConnectionFails(async:Async):Void
	{
		// HTTPStatusEvent.status is 0 when no status came back
		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(ScriptedServer.refusedURL()), async, function(outcome)
		{
			Assert.isTrue(outcome.failed, Std.string(outcome));
			Assert.notNull(outcome.error);
			Assert.equals(0, request.responseStatus);
			Assert.isTrue(outcome.seconds < 5, "the refusal took " + outcome.seconds + " s");
			async.done();
		});
	}

	@:timeout(25000)
	public function testANameThatDoesNotResolveFails(async:Async):Void
	{
		// RFC 6761 section 6.4: names under .invalid never resolve
		var request = new HTTPRequest<String>();
		request.timeout = 20000;
		LoadOutcome.watch(request.load("http://lime-unit-test.invalid/"), async, function(outcome)
		{
			Assert.isTrue(outcome.failed, Std.string(outcome));
			Assert.notNull(outcome.error);
			Assert.equals(0, request.responseStatus);
			async.done();
		});
	}

	@:timeout(10000)
	public function testAServerThatClosesWithoutAnsweringFails(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.rawText(""));
		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/nothing")), async, function(outcome)
		{
			Assert.isTrue(outcome.failed, Std.string(outcome));
			Assert.equals(0, request.responseStatus);
			async.done();
		});
	}

	@:timeout(10000)
	@Ignored("libcurl 8.23 reports a response cut off in its headers as complete")
	public function testAServerThatClosesPartwayThroughTheHeaderFails(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.rawText("HTTP/1.1 200 OK\r\nContent-Type: text/pl"));
		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/cut")), async, function(outcome)
		{
			Assert.isTrue(outcome.failed, Std.string(outcome));
			async.done();
		});
	}

	@:timeout(10000)
	public function testABodyShorterThanItsContentLengthFails(async:Async):Void
	{
		// RFC 9112 section 8: a message whose connection closes before the
		// Content-Length is received is incomplete
		var server = serve(function(_)
		{
			var response = ScriptedResponse.text(200, StringTools.lpad("", "x", 1000));
			response.cutAfter = 400;
			return response;
		});

		ScriptedServer.each(["text", "bytes"], function(type, next)
		{
			var future:lime.app.Future<Dynamic> = type == "text" ? cast new HTTPRequest<String>().load(server.url("/short")) : cast new HTTPRequest<Bytes>().load(server.url("/short"));
			LoadOutcome.watch(future, async, function(outcome)
			{
				Assert.isTrue(outcome.failed, type + " " + outcome);
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	public function testAChunkedBodyWithoutItsLastChunkFails(async:Async):Void
	{
		// RFC 9112 section 8: a chunked message is incomplete until its
		// zero-sized last chunk arrives
		var server = serve(function(_)
		{
			var response = new ScriptedResponse(200);
			response.chunks = [Bytes.ofString("first "), Bytes.ofString("second")];
			response.finishChunks = false;
			return response;
		});

		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/chunks")), async, function(outcome)
		{
			Assert.isTrue(outcome.failed, Std.string(outcome));
			async.done();
		});
	}

	@:timeout(5000)
	@Ignored("Waiting on #2193")
	public function testAServerThatNeverAnswersTimesOut(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.unanswered());
		var request = new HTTPRequest<String>();
		request.timeout = 400;
		LoadOutcome.watch(request.load(server.url("/quiet")), async, function(outcome)
		{
			Assert.isTrue(outcome.failed, Std.string(outcome));
			Assert.equals(0, request.responseStatus);
			Assert.isTrue(outcome.seconds >= 0.3 && outcome.seconds < 3, "the timeout of 400 ms took " + outcome.seconds + " s");
			async.done();
		});
	}

	@:timeout(5000)
	@Ignored("Waiting on #2193")
	public function testABodyThatStopsComingTimesOut(async:Async):Void
	{
		var server = serve(function(_)
		{
			var response = ScriptedResponse.text(200, StringTools.lpad("", "x", 1000));
			response.cutAfter = 100;
			response.hold = true;
			return response;
		});

		var request = new HTTPRequest<String>();
		request.timeout = 400;
		LoadOutcome.watch(request.load(server.url("/stalled")), async, function(outcome)
		{
			Assert.isTrue(outcome.failed, Std.string(outcome));
			Assert.isTrue(outcome.seconds >= 0.3 && outcome.seconds < 3, "the timeout of 400 ms took " + outcome.seconds + " s");
			async.done();
		});
	}

	@:timeout(10000)
	public function testAnAnswerWithinTheTimeoutCompletes(async:Async):Void
	{
		var server = serve(function(_)
		{
			var response = ScriptedResponse.text(200, StringTools.lpad("", "y", 4000));
			response.delay = 0.2;
			response.pieceSize = 1000;
			response.pause = 0.05;
			return response;
		});

		var request = new HTTPRequest<String>();
		request.timeout = 3000;
		LoadOutcome.watch(request.load(server.url("/slow")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals(4000, outcome.value == null ? -1 : outcome.value.length);
			async.done();
		});
	}

	@:timeout(10000)
	public function testCancellingBeforeLoadingChangesNothing(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "loaded"));
		var request = new HTTPRequest<String>();
		request.cancel();
		LoadOutcome.watch(request.load(server.url("/after-cancel")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("loaded", outcome.value);
			async.done();
		});
	}

	@:timeout(15000)
	@Ignored("Waiting on #2194")
	public function testCancellingStopsTheTransfer(async:Async):Void
	{
		// URLLoader.close(): a load in progress is terminated at once, and
		// nothing completes afterwards
		var server = serve(function(_) return ScriptedResponse.unanswered());
		var request = new HTTPRequest<String>();
		var outcome:LoadOutcome<String> = null;
		LoadOutcome.watch(request.load(server.url("/cancelled")), async, function(result) outcome = result);

		ScriptedServer.poll(function() return server.requests().length > 0, 5, function(arrived)
		{
			Assert.isTrue(arrived, "the request never reached the server");
			request.cancel();

			ScriptedServer.poll(function() return server.countDisconnects() > 0, 3, function(closed)
			{
				Assert.isTrue(closed, "the connection stayed open after cancelling");

				// A moment for a late completion to show
				haxe.Timer.delay(function()
				{
					Assert.isFalse(outcome != null && outcome.completed, "the cancelled load " + outcome);
					async.done();
				}, 300);
			});
		});
	}

	@:timeout(10000)
	@Ignored("Waiting on #2194")
	public function testACancelledLoadDoesNotComplete(async:Async):Void
	{
		// URLLoader.close() and XMLHttpRequest.abort(): an answer that comes
		// after cancelling is not delivered
		var server = serve(function(_)
		{
			var response = ScriptedResponse.text(200, "too late");
			response.delay = 0.5;
			return response;
		});

		var request = new HTTPRequest<String>();
		var outcome:LoadOutcome<String> = null;
		LoadOutcome.watch(request.load(server.url("/late")), async, function(result) outcome = result);

		ScriptedServer.poll(function() return server.requests().length > 0, 5, function(arrived)
		{
			Assert.isTrue(arrived, "the request never reached the server");
			request.cancel();

			// Longer than the server takes to answer
			haxe.Timer.delay(function()
			{
				Assert.isFalse(outcome != null && outcome.completed, "the cancelled load " + outcome);
				Assert.isNull(request.responseData, "the cancelled load set responseData");
				async.done();
			}, 1200);
		});
	}

	@:timeout(15000)
	public function testARequestLoadsAgainAfterCancelling(async:Async):Void
	{
		var server = serve(function(request)
		{
			if (request.path == "/held") return ScriptedResponse.unanswered();
			return ScriptedResponse.text(200, "answered " + request.path);
		});

		var request = new HTTPRequest<String>();
		var first:LoadOutcome<String> = null;
		LoadOutcome.watch(request.load(server.url("/held")), async, function(result) first = result);

		ScriptedServer.poll(function() return server.requests().length > 0, 5, function(arrived)
		{
			Assert.isTrue(arrived, "the first request never reached the server");
			request.cancel();

			LoadOutcome.watch(request.load(server.url("/second")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, Std.string(outcome));
				Assert.equals("answered /second", outcome.value);
				Assert.equals(200, request.responseStatus);
				Assert.isFalse(first != null && first.completed, "the cancelled load " + first);
				async.done();
			});
		});
	}

	@:timeout(10000)
	public function testTwoRequestsLoadAtOnce(async:Async):Void
	{
		var server = serve(function(request)
		{
			var response = ScriptedResponse.text(200, "answer for " + request.path);
			response.delay = 0.3;
			return response;
		});

		var results = new Map<String, String>();
		var finished = 0;

		for (path in ["/first", "/second"])
		{
			var request = new HTTPRequest<String>();
			LoadOutcome.watch(request.load(server.url(path)), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, path + " " + outcome);
				Assert.equals(200, request.responseStatus);
				results.set(path, outcome.value);
				if (++finished == 2)
				{
					Assert.equals("answer for /first", results.get("/first"));
					Assert.equals("answer for /second", results.get("/second"));
					async.done();
				}
			});
		}
	}

	@:timeout(20000)
	public function testManyRequestsLoadInParallel(async:Async):Void
	{
		var count = 24;
		var server = serve(function(request)
		{
			var response = ScriptedResponse.text(200, "answer for " + request.path);
			response.delay = 0.1;
			return response;
		});

		var finished = 0;
		var mismatched = [];
		var failed = [];

		for (i in 0...count)
		{
			var request = new HTTPRequest<String>();
			LoadOutcome.watch(request.load(server.url("/parallel/" + i)), async, function(outcome)
			{
				if (!outcome.completed) failed.push(i + ": " + outcome);
				else if (outcome.value != "answer for /parallel/" + i) mismatched.push(i + ": " + outcome.value);

				if (++finished == count)
				{
					Assert.same([], failed, "requests failed");
					Assert.same([], mismatched, "requests got another's answer");
					Assert.equals(count, server.requests().length);
					async.done();
				}
			});
		}
	}

	private function serve(answer:RecordedRequest->ScriptedResponse):ScriptedServer
	{
		var server = new ScriptedServer(answer);
		servers.push(server);
		return server;
	}
	#end
}
