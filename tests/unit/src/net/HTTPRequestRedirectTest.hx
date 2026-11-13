package net;

import haxe.io.Bytes;
import utest.Assert;
import utest.Async;
import utest.Test;
#if (lime_cffi && lime_curl)
import lime.net.HTTPRequest;
import lime.net.HTTPRequestHeader;
import lime.net.HTTPRequestMethod;
#end
#if (lime_cffi && lime_curl && sys && target.threaded)
import net.ScriptedServer;
#end

/**
	How native HTTP requests follow redirects, as RFC 9110 section 15.4 has
	each status change the method and content or keep them, and how they
	manage the cookies responses set on the way.
**/
class HTTPRequestRedirectTest extends Test
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
	public function testRedirectsAreFollowedByDefault(async:Async):Void
	{
		var server = redirecting(302);
		var request = new HTTPRequest<String>();
		Assert.isTrue(request.followRedirects);
		LoadOutcome.watch(request.load(server.url("/start")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("GET /final", outcome.value);
			Assert.equals(200, request.responseStatus);
			Assert.same(["GET /start", "GET /final"], lines(server));
			async.done();
		});
	}

	@:timeout(15000)
	public function testAGetStaysAGetThroughEachRedirect(async:Async):Void
	{
		ScriptedServer.each([301, 302, 303, 307, 308], function(status, next)
		{
			var server = redirecting(status);
			var request = new HTTPRequest<String>();
			LoadOutcome.watch(request.load(server.url("/start")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, status + " " + outcome);
				Assert.same(["GET /start", "GET /final"], lines(server), "through a " + status);
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	@Ignored("Waiting on #2197")
	public function testA303TurnsAPostIntoAGet(async:Async):Void
	{
		// RFC 9110 section 15.4.4: the user agent retrieves the other URI with
		// GET or HEAD, without the content
		var server = redirecting(303);
		var request = new HTTPRequest<String>();
		request.method = POST;
		request.data = Bytes.ofString("posted content");
		LoadOutcome.watch(request.load(server.url("/start")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			var requests = server.requests();
			Assert.equals(2, requests.length);
			if (requests.length == 2)
			{
				Assert.equals("POST", requests[0].method);
				Assert.equals("posted content", requests[0].body.toString());
				Assert.isTrue(requests[1].method == "GET" || requests[1].method == "HEAD", "the 303 was followed with " + requests[1].method);
				assertNoContent(requests[1]);
			}
			async.done();
		});
	}

	@:timeout(10000)
	@Ignored("Waiting on #2197")
	public function testA303TurnsAPutIntoAGet(async:Async):Void
	{
		// RFC 9110 section 15.4.4 applies to any method
		var server = redirecting(303);
		var request = new HTTPRequest<String>();
		request.method = PUT;
		request.data = Bytes.ofString("put content");
		LoadOutcome.watch(request.load(server.url("/start")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			var requests = server.requests();
			Assert.equals(2, requests.length);
			if (requests.length == 2)
			{
				Assert.equals("PUT", requests[0].method);
				Assert.isTrue(requests[1].method == "GET" || requests[1].method == "HEAD", "the 303 was followed with " + requests[1].method);
				assertNoContent(requests[1]);
			}
			async.done();
		});
	}

	@:timeout(20000)
	public function testA307Or308KeepsTheMethodAndContent(async:Async):Void
	{
		// RFC 9110 sections 15.4.8 and 15.4.9: the user agent MUST NOT change
		// the request method
		var cases:Array<{status:Int, method:HTTPRequestMethod}> = [
			{status: 307, method: POST},
			{status: 308, method: POST},
			{status: 307, method: PUT},
			{status: 308, method: PUT},
			{status: 307, method: DELETE}
		];

		ScriptedServer.each(cases, function(item, next)
		{
			var server = redirecting(item.status);
			var request = new HTTPRequest<String>();
			request.method = item.method;
			var content = item.method == DELETE ? null : Bytes.ofString(item.method + " content through a " + item.status);
			request.data = content;
			LoadOutcome.watch(request.load(server.url("/start")), async, function(outcome)
			{
				var name = item.method + " through a " + item.status;
				Assert.isTrue(outcome.completed, name + " " + outcome);
				var requests = server.requests();
				Assert.equals(2, requests.length, name);
				if (requests.length == 2)
				{
					Assert.equals(Std.string(item.method), requests[1].method, name);
					Assert.equals(content == null ? "" : content.toString(), requests[1].body.toString(), name);
				}
				next();
			});
		}, function() async.done());
	}

	@:timeout(15000)
	@Ignored("Waiting on #2197")
	public function testA301Or302RepeatsAPostOrTurnsItIntoAGet(async:Async):Void
	{
		// RFC 9110 sections 15.4.2 and 15.4.3: a user agent MAY change POST to
		// GET, which then has no content, or else repeats the POST with its content
		ScriptedServer.each([301, 302], function(status, next)
		{
			var server = redirecting(status);
			var request = new HTTPRequest<String>();
			request.method = POST;
			request.data = Bytes.ofString("posted through a " + status);
			LoadOutcome.watch(request.load(server.url("/start")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, status + " " + outcome);
				var requests = server.requests();
				Assert.equals(2, requests.length);
				if (requests.length == 2)
				{
					var followed = requests[1];
					if (followed.method == "GET")
					{
						assertNoContent(followed);
					}
					else
					{
						Assert.equals("POST", followed.method, "the " + status + " was followed with " + followed.method);
						Assert.equals("posted through a " + status, followed.body.toString());
					}
				}
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	public function testRelativeLocationsResolveAgainstTheTarget(async:Async):Void
	{
		// RFC 9110 section 10.2.2 and RFC 3986 section 5.2
		var server = serve(function(request)
		{
			return switch (request.path)
			{
				case "/a/b/start": ScriptedResponse.redirect(302, "next?x=1");
				case "/a/b/next": ScriptedResponse.redirect(302, "../up");
				case "/a/up": ScriptedResponse.redirect(302, "/final");
				default: ScriptedResponse.text(200, request.method + " " + request.target);
			}
		});

		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/a/b/start")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.same(["GET /a/b/start", "GET /a/b/next?x=1", "GET /a/up", "GET /final"], lines(server));
			Assert.equals("GET /final", outcome.value);
			async.done();
		});
	}

	@:timeout(10000)
	public function testARedirectToAnotherServerIsFollowed(async:Async):Void
	{
		var other = serve(function(request) return ScriptedResponse.text(200, "other " + request.target));
		var server = serve(function(_) return ScriptedResponse.redirect(302, other.url("/there?y=2")));
		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/here")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("other /there?y=2", outcome.value);
			Assert.equals(1, other.requests().length);
			async.done();
		});
	}

	@:timeout(20000)
	public function testARedirectLoopFails(async:Async):Void
	{
		// RFC 9110 section 15.4: a client SHOULD detect and intervene in
		// cyclical redirections
		var server = serve(function(_) return ScriptedResponse.redirect(302, "/loop"));
		var request = new HTTPRequest<String>();
		request.timeout = 15000;
		LoadOutcome.watch(request.load(server.url("/loop")), async, function(outcome)
		{
			Assert.isTrue(outcome.failed, Std.string(outcome));
			var count = server.requests().length;
			Assert.isTrue(count > 1 && count <= 100, "the loop was followed " + count + " times");
			async.done();
		});
	}

	@:timeout(10000)
	public function testRedirectsAreNotFollowedWhenTurnedOff(async:Async):Void
	{
		// A 3xx is not an error status, so with redirects off it is the response
		var server = redirecting(302);
		var request = new HTTPRequest<String>();
		request.followRedirects = false;
		request.enableResponseHeaders = true;
		LoadOutcome.watch(request.load(server.url("/start")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("moved", outcome.value);
			Assert.equals(302, request.responseStatus);
			Assert.same(["GET /start"], lines(server));
			Assert.same(["/final"], values(request.responseHeaders, "Location"));
			async.done();
		});
	}

	@:timeout(10000)
	@Ignored("Waiting on #2196")
	public function testResponseHeadersAfterARedirectAreTheFinalResponses(async:Async):Void
	{
		var server = serve(function(request)
		{
			if (request.path == "/start") return ScriptedResponse.redirect(302, "/final", ["X-Hop: first", "X-Redirect-Only: yes"]);
			return ScriptedResponse.text(200, "final", ["X-Hop: final"]);
		});

		var request = new HTTPRequest<String>();
		request.enableResponseHeaders = true;
		LoadOutcome.watch(request.load(server.url("/start")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.same(["final"], values(request.responseHeaders, "X-Hop"));
			Assert.same([], values(request.responseHeaders, "X-Redirect-Only"));
			Assert.same([], values(request.responseHeaders, "Location"));
			async.done();
		});
	}

	@:timeout(10000)
	public function testCookiesSetOnTheWayAreSent(async:Async):Void
	{
		// URLRequest.manageCookies, true by default: cookies are added to the
		// request and response cookies are remembered
		var server = cookieServer("redirected", "/cookies-redirected");
		var request = new HTTPRequest<String>();
		Assert.isTrue(request.manageCookies);
		LoadOutcome.watch(request.load(server.url("/cookies-redirected/set")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("redirected=1", cookie(server, "/cookies-redirected/check", "redirected"));
			async.done();
		});
	}

	@:timeout(10000)
	public function testCookiesAreRememberedForLaterRequests(async:Async):Void
	{
		var server = cookieServer("remembered", "/cookies-remembered");
		var first = new HTTPRequest<String>();
		LoadOutcome.watch(first.load(server.url("/cookies-remembered/set")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));

			var second = new HTTPRequest<String>();
			LoadOutcome.watch(second.load(server.url("/cookies-remembered/later")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, Std.string(outcome));
				Assert.equals("remembered=1", cookie(server, "/cookies-remembered/later", "remembered"));
				async.done();
			});
		});
	}

	@:timeout(10000)
	public function testCookiesAreLeftAloneWhenNotManaged(async:Async):Void
	{
		// URLRequest.manageCookies false: cookies are not added to the request
		// and response cookies are not remembered
		var server = cookieServer("unmanaged", "/cookies-unmanaged");
		var request = new HTTPRequest<String>();
		request.manageCookies = false;
		LoadOutcome.watch(request.load(server.url("/cookies-unmanaged/set")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.isNull(cookie(server, "/cookies-unmanaged/check", "unmanaged"), "the cookie was sent on the redirect");

			var later = new HTTPRequest<String>();
			LoadOutcome.watch(later.load(server.url("/cookies-unmanaged/later")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, Std.string(outcome));
				Assert.isNull(cookie(server, "/cookies-unmanaged/later", "unmanaged"), "the cookie was remembered");
				async.done();
			});
		});
	}

	@:timeout(10000)
	public function testACookieHeaderCanBeSentByHand(async:Async):Void
	{
		// URLRequest.manageCookies: users can manage cookies themselves by
		// setting the header
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var request = new HTTPRequest<String>();
		request.manageCookies = false;
		request.headers.push(new HTTPRequestHeader("Cookie", "byhand=1"));
		LoadOutcome.watch(request.load(server.url("/cookies-by-hand")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("byhand=1", cookie(server, "/cookies-by-hand", "byhand"));
			async.done();
		});
	}

	private static function assertNoContent(request:RecordedRequest, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(0, request.body.length, request.method + " carried content", pos);
		var length = request.header("Content-Length");
		Assert.isTrue(length == null || length == "0", request.method + " carried Content-Length: " + length, pos);
		Assert.isNull(request.header("Content-Type"), request.method + " carried Content-Type: " + request.header("Content-Type"), pos);
	}

	private static function cookie(server:ScriptedServer, path:String, name:String):String
	{
		// The cookie of that name sent with the last request for the path
		var found:String = null;
		for (request in server.requests())
		{
			if (request.path != path) continue;
			found = null;
			for (header in request.headerValues("Cookie"))
			{
				for (pair in header.split(";"))
				{
					pair = StringTools.trim(pair);
					if (StringTools.startsWith(pair, name + "=")) found = pair;
				}
			}
		}
		return found;
	}

	private function cookieServer(name:String, scope:String):ScriptedServer
	{
		// scope/set sets a cookie for scope and redirects to scope/check. Each
		// test sets its own cookie for its own path, as cookies are shared by
		// the ports of a host.
		return serve(function(request)
		{
			if (request.path == scope + "/set")
			{
				return ScriptedResponse.redirect(302, scope + "/check", ["Set-Cookie: " + name + "=1; Path=" + scope]);
			}
			return ScriptedResponse.text(200, "ok");
		});
	}

	private static function lines(server:ScriptedServer):Array<String>
	{
		return [for (request in server.requests()) request.method + " " + request.target];
	}

	private function redirecting(status:Int):ScriptedServer
	{
		// Redirects /start to /final with the status, and answers the rest with
		// the method and target
		return serve(function(request)
		{
			if (request.path == "/start") return ScriptedResponse.redirect(status, "/final");
			return ScriptedResponse.text(200, request.method + " " + request.target);
		});
	}

	private function serve(answer:RecordedRequest->ScriptedResponse):ScriptedServer
	{
		var server = new ScriptedServer(answer);
		servers.push(server);
		return server;
	}

	private static function values(headers:Array<HTTPRequestHeader>, name:String):Array<String>
	{
		if (headers == null) return [];
		return [for (header in headers) if (header.name.toLowerCase() == name.toLowerCase()) header.value];
	}
	#end
}
