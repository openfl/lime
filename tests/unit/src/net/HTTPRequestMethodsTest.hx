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
	What native HTTP requests send: each method's request line, the content
	of those that carry it, form data encoded as
	`application/x-www-form-urlencoded`, and the header fields the application
	asks for.
**/
class HTTPRequestMethodsTest extends Test
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

	@:timeout(15000)
	public function testEachMethodSendsItsOwnRequestLine(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var methods:Array<HTTPRequestMethod> = [GET, HEAD, POST, PUT, DELETE, OPTIONS];

		ScriptedServer.each(methods, function(method, next)
		{
			var request = new HTTPRequest<String>();
			request.method = method;
			LoadOutcome.watch(request.load(server.url("/method/" + method)), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, method + " " + outcome);
				var received = last(server);
				Assert.equals(Std.string(method), received.method);
				Assert.equals("/method/" + method, received.target);
				Assert.isTrue(StringTools.startsWith(received.version, "HTTP/1."), method + " was sent as " + received.version);
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	public function testAHeadRequestReadsNoBody(async:Async):Void
	{
		// RFC 9110 section 9.3.2: a response to HEAD has no content, though its
		// Content-Length is that of a GET. The connection stays open, so a
		// client that waits for content waits until it times out.
		var server = serve(function(_)
		{
			var response = ScriptedResponse.text(200, StringTools.lpad("", "x", 1000));
			response.hold = true;
			return response;
		});

		var text = new HTTPRequest<String>();
		text.method = HEAD;
		text.timeout = 5000;
		LoadOutcome.watch(text.load(server.url("/head")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, "HEAD as text " + outcome);
			Assert.equals("", outcome.value);
			Assert.equals(200, text.responseStatus);
			Assert.isTrue(outcome.seconds < 2, "HEAD as text took " + outcome.seconds + " s");

			var binary = new HTTPRequest<Bytes>();
			binary.method = HEAD;
			binary.timeout = 5000;
			LoadOutcome.watch(binary.load(server.url("/head")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, "HEAD as bytes " + outcome);
				Assert.notNull(outcome.value, "HEAD as bytes gave null");
				if (outcome.value != null) Assert.equals(0, outcome.value.length);
				Assert.isTrue(outcome.seconds < 2, "HEAD as bytes took " + outcome.seconds + " s");
				async.done();
			});
		});
	}

	@:timeout(15000)
	public function testRequestsWithoutContentSendNoBody(async:Async):Void
	{
		// RFC 9110 section 8.6: no Content-Length when there is no content and
		// the method does not anticipate any
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var methods:Array<HTTPRequestMethod> = [GET, HEAD, DELETE, OPTIONS];

		ScriptedServer.each(methods, function(method, next)
		{
			var request = new HTTPRequest<String>();
			request.method = method;
			LoadOutcome.watch(request.load(server.url("/empty")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, method + " " + outcome);
				var received = last(server);
				Assert.equals(0, received.body.length, method + " sent a body");
				Assert.isFalse(received.chunked, method + " sent a chunked body");
				var length = received.header("Content-Length");
				Assert.isTrue(length == null || length == "0", method + " sent Content-Length: " + length);
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	public function testAPostWithoutContentSaysItsLengthIsZero(async:Async):Void
	{
		// RFC 9110 section 8.6: a user agent normally sends Content-Length in a
		// POST even when the value is 0
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var request = new HTTPRequest<String>();
		request.method = POST;
		LoadOutcome.watch(request.load(server.url("/post")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			var received = last(server);
			Assert.equals("POST", received.method);
			Assert.isFalse(received.chunked, "the empty POST was sent chunked");
			Assert.equals("0", received.header("Content-Length"));
			Assert.equals(0, received.body.length);
			async.done();
		});
	}

	@:timeout(15000)
	public function testPostAndPutSendTheirDataAsIs(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var data = Bytes.alloc(4096);
		for (i in 0...data.length) data.set(i, i & 0xFF);
		var methods:Array<HTTPRequestMethod> = [POST, PUT];

		ScriptedServer.each(methods, function(method, next)
		{
			var request = new HTTPRequest<String>();
			request.method = method;
			request.data = data;
			LoadOutcome.watch(request.load(server.url("/data")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, method + " " + outcome);
				var received = last(server);
				Assert.equals(Std.string(method), received.method);
				Assert.equals(data.length, received.body.length, method + " sent another length");
				Assert.equals(0, data.compare(received.body), method + " changed the data");
				Assert.equals(Std.string(data.length), received.header("Content-Length"));
				// URLRequest.contentType: the type of the data, which defaults to
				// application/x-www-form-urlencoded
				Assert.same(["application/x-www-form-urlencoded"], received.headerValues("Content-Type"));
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	public function testContentTypeNamesTheData(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var request = new HTTPRequest<String>();
		request.method = POST;
		request.contentType = "application/json; charset=utf-8";
		request.data = Bytes.ofString('{"name":"value"}');
		LoadOutcome.watch(request.load(server.url("/json")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			var received = last(server);
			Assert.same(["application/json; charset=utf-8"], received.headerValues("Content-Type"));
			Assert.equals('{"name":"value"}', received.body.toString());
			async.done();
		});
	}

	@:timeout(10000)
	public function testGetFormDataGoesInTheQuery(async:Async):Void
	{
		// URLRequest.data: with GET, the variables are appended to the URL in
		// query string syntax
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var request = new HTTPRequest<String>();
		request.formData = trickyFields();
		LoadOutcome.watch(request.load(server.url("/form")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			var received = last(server);
			Assert.equals("GET", received.method);
			Assert.equals("/form", received.path);
			assertValidTarget(received.target);
			Assert.same(expectedFields(trickyFields()), sortedFields(received.query));
			Assert.equals(0, received.body.length, "the form data was also sent as content");
			async.done();
		});
	}

	@:timeout(10000)
	public function testGetFormDataJoinsAnExistingQuery(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var request = new HTTPRequest<String>();
		request.formData.set("z", "3");
		LoadOutcome.watch(request.load(server.url("/form?x=1&y=two")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			var received = last(server);
			Assert.equals("/form", received.path);
			Assert.equals(1, received.target.split("?").length - 1, "the target " + received.target + " has more than one ?");
			Assert.same([field("x", "1"), field("y", "two"), field("z", "3")], sortedFields(received.query));
			async.done();
		});
	}

	@:timeout(10000)
	public function testAGetWithoutFormDataAddsNoQuery(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/plain")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("/plain", last(server).target);

			LoadOutcome.watch(request.load(server.url("/plain?kept=1")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, Std.string(outcome));
				Assert.equals("/plain?kept=1", last(server).target);
				async.done();
			});
		});
	}

	@:timeout(15000)
	public function testPostAndPutFormDataGoesInTheBody(async:Async):Void
	{
		// URLRequest.data: with other methods, URLVariables are encoded as
		// application/x-www-form-urlencoded and sent as the content
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var methods:Array<HTTPRequestMethod> = [POST, PUT];

		ScriptedServer.each(methods, function(method, next)
		{
			var fields = trickyFields();
			fields.set("number", 42);
			fields.set("flag", true);

			var request = new HTTPRequest<String>();
			request.method = method;
			request.formData = fields;
			LoadOutcome.watch(request.load(server.url("/form")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, method + " " + outcome);
				var received = last(server);
				Assert.equals(Std.string(method), received.method);
				Assert.equals("/form", received.target, method + " put the form data in the URL");
				Assert.same(["application/x-www-form-urlencoded"], received.headerValues("Content-Type"));
				Assert.same(expectedFields(fields), sortedFields(received.body.toString()));
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	public function testCustomHeadersAreSent(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var methods:Array<HTTPRequestMethod> = [GET, POST];

		ScriptedServer.each(methods, function(method, next)
		{
			var request = new HTTPRequest<String>();
			request.method = method;
			if (method == POST) request.data = Bytes.ofString("content");
			request.headers.push(new HTTPRequestHeader("X-Custom", "custom value"));
			request.headers.push(new HTTPRequestHeader("X-Repeat", "first"));
			request.headers.push(new HTTPRequestHeader("X-Repeat", "second"));
			LoadOutcome.watch(request.load(server.url("/headers")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, method + " " + outcome);
				var received = last(server);
				Assert.same(["custom value"], received.headerValues("X-Custom"), method + " " + received.head);
				// RFC 9110 section 5.3: repeated fields mean the same as one field
				// whose values are joined with commas
				Assert.equals("first, second", received.headerValues("X-Repeat").join(", "), method + " " + received.head);
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	public function testTheUserAgentIsSent(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var request = new HTTPRequest<String>();
		request.userAgent = "LimeTest/8.4 (unit)";
		LoadOutcome.watch(request.load(server.url("/agent")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.same(["LimeTest/8.4 (unit)"], last(server).headerValues("User-Agent"));
			async.done();
		});
	}

	private static function assertValidTarget(target:String, ?pos:haxe.PosInfos):Void
	{
		// RFC 9112 section 3.2.1 and RFC 3986 section 3.4: an origin-form target
		// holds only unreserved and reserved characters and percent-encodings
		var valid = ~/^\/([A-Za-z0-9\-._~!$&'()*+,;=:@\/?]|%[0-9A-Fa-f]{2})*$/;
		Assert.isTrue(valid.match(target), "the request target " + target + " is not valid", pos);
	}

	private static function expectedFields(fields:Map<String, Dynamic>):Array<{name:String, value:String}>
	{
		var expected = [for (name in fields.keys()) field(name, Std.string(fields.get(name)))];
		expected.sort(compareFields);
		return expected;
	}

	private static function field(name:String, value:String):{name:String, value:String}
	{
		return {name: name, value: value};
	}

	private static function compareFields(a:{name:String, value:String}, b:{name:String, value:String}):Int
	{
		return a.name < b.name ? -1 : a.name > b.name ? 1 : 0;
	}

	private static function last(server:ScriptedServer):RecordedRequest
	{
		var requests = server.requests();
		return requests.length > 0 ? requests[requests.length - 1] : new RecordedRequest();
	}

	private function serve(answer:RecordedRequest->ScriptedResponse):ScriptedServer
	{
		var server = new ScriptedServer(answer);
		servers.push(server);
		return server;
	}

	private static function sortedFields(text:String):Array<{name:String, value:String}>
	{
		var fields = RecordedRequest.formFields(text);
		fields.sort(compareFields);
		return fields;
	}

	private static function trickyFields():Map<String, Dynamic>
	{
		// Names and values with the characters that separate fields, spaces,
		// plus signs, reserved characters and text outside ASCII
		var fields = new Map<String, Dynamic>();
		fields.set("plain", "value");
		fields.set("with space", "a b");
		fields.set("amp&ersand", "x&y");
		fields.set("equals=sign", "1+1=2");
		fields.set("unicode é", "ü 中 \u{1F600}");
		fields.set("reserved", ":/?#[]@!$'()*,;%");
		fields.set("empty", "");
		return fields;
	}
	#end
}
