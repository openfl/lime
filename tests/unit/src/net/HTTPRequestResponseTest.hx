package net;

import haxe.crypto.Crc32;
import haxe.io.Bytes;
import utest.Assert;
import utest.Async;
import utest.Test;
#if (lime_cffi && lime_curl)
import lime.net.HTTPRequest;
import lime.net.HTTPRequestHeader;
#end
#if (lime_cffi && lime_curl && sys && target.threaded)
import net.ScriptedServer;
#end

/**
	What native HTTP requests make of responses: which status codes complete
	the load and which fail it, the response header fields, and bodies that are
	empty, binary, large, chunked, compressed or text.
**/
class HTTPRequestResponseTest extends Test
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
	public function testSuccessfulStatusesComplete(async:Async):Void
	{
		// RFC 9110 section 15: an unknown code is treated as the x00 of its
		// class, so 299 is a success
		var server = serve(function(request) return statusResponse(request));

		ScriptedServer.each([200, 201, 204, 299], function(status, next)
		{
			var request = new HTTPRequest<String>();
			LoadOutcome.watch(request.load(server.url("/status/" + status)), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, status + " " + outcome);
				Assert.equals(status, request.responseStatus);
				Assert.equals(status == 204 ? "" : "status " + status, outcome.value);
				next();
			});
		}, function() async.done());
	}

	@:timeout(15000)
	public function testErrorStatusesFail(async:Async):Void
	{
		// URLLoader: an HTTP error status ends a load with an IOErrorEvent. 499
		// and 599 are client and server errors by their class.
		var server = serve(function(request) return statusResponse(request));

		ScriptedServer.each([400, 404, 410, 499, 500, 503, 599], function(status, next)
		{
			var request = new HTTPRequest<String>();
			LoadOutcome.watch(request.load(server.url("/status/" + status)), async, function(outcome)
			{
				Assert.isTrue(outcome.failed, status + " " + outcome);
				Assert.equals(status, request.responseStatus);
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	@Ignored("Waiting on #2195")
	public function testTheErrorOfAnErrorStatusNamesIt(async:Async):Void
	{
		var server = serve(function(request) return statusResponse(request));

		ScriptedServer.each([404, 500], function(status, next)
		{
			var request = new HTTPRequest<String>();
			LoadOutcome.watch(request.load(server.url("/status/" + status)), async, function(outcome)
			{
				Assert.notNull(outcome.error, status + " failed with no error");
				Assert.isTrue(Std.string(outcome.error).indexOf(Std.string(status)) > -1, status + " failed with " + outcome.error);
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	#if (neko || hl)
	@Ignored("Waiting on #2195")
	#end
	public function testAnErrorResponseKeepsItsBody(async:Async):Void
	{
		// As XMLHttpRequest keeps responseText whatever the status
		var server = serve(function(request) return statusResponse(request));
		var text = new HTTPRequest<String>();
		LoadOutcome.watch(text.load(server.url("/status/404")), async, function(outcome)
		{
			Assert.isTrue(outcome.failed, Std.string(outcome));
			Assert.equals("status 404", text.responseData);

			var binary = new HTTPRequest<Bytes>();
			LoadOutcome.watch(binary.load(server.url("/status/500")), async, function(outcome)
			{
				Assert.isTrue(outcome.failed, Std.string(outcome));
				Assert.notNull(binary.responseData);
				if (binary.responseData != null) Assert.equals("status 500", binary.responseData.toString());
				async.done();
			});
		});
	}

	@:timeout(10000)
	public function testAnEmptyBodyIsEmpty(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, ""));
		var text = new HTTPRequest<String>();
		LoadOutcome.watch(text.load(server.url("/empty")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("", outcome.value);

			var binary = new HTTPRequest<Bytes>();
			LoadOutcome.watch(binary.load(server.url("/empty")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, Std.string(outcome));
				Assert.notNull(outcome.value, "an empty body gave null");
				if (outcome.value != null) Assert.equals(0, outcome.value.length);
				async.done();
			});
		});
	}

	@:timeout(10000)
	public function testA204IsNotWaitedOn(async:Async):Void
	{
		// RFC 9112 section 6.3: a 204 ends at its header section. The
		// connection stays open, so a client that reads on waits.
		var server = serve(function(_)
		{
			var response = ScriptedResponse.text(204, "");
			response.hold = true;
			return response;
		});
		var request = new HTTPRequest<String>();
		request.timeout = 5000;
		LoadOutcome.watch(request.load(server.url("/nothing")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals(204, request.responseStatus);
			Assert.isTrue(outcome.seconds < 2, "the 204 took " + outcome.seconds + " s");
			async.done();
		});
	}

	@:timeout(10000)
	public function testBinaryBodiesArriveWhole(async:Async):Void
	{
		var data = Bytes.alloc(70000);
		for (i in 0...data.length) data.set(i, (i * 7 + (i >> 9)) & 0xFF);
		for (i in 0...64) data.set(i, 0);
		var server = serve(function(_) return ScriptedResponse.bytes(200, data, ["Content-Type: application/octet-stream"]));

		var request = new HTTPRequest<Bytes>();
		LoadOutcome.watch(request.load(server.url("/binary")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals(describe(data), describe(outcome.value));
			Assert.equals(outcome.value, request.responseData);

			var limeBytes = new HTTPRequest<lime.utils.Bytes>();
			LoadOutcome.watch(limeBytes.load(server.url("/binary")), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, Std.string(outcome));
				Assert.equals(describe(data), describe(outcome.value));
				async.done();
			});
		});
	}

	@:timeout(20000)
	public function testALargeBodyReportsItsProgressInOrder(async:Async):Void
	{
		// Flash's ProgressEvent and XMLHttpRequest's progress events: bytes
		// loaded only grow, the total is the Content-Length, and the last report
		// before completion has every byte
		var size = 4 * 1024 * 1024 + 123;
		var data = Bytes.alloc(size);
		for (i in 0...size) data.set(i, (i ^ (i >> 11)) & 0xFF);
		var server = serve(function(_)
		{
			var response = ScriptedResponse.bytes(200, data);
			response.pieceSize = 256 * 1024;
			response.pause = 0.01;
			return response;
		});

		var request = new HTTPRequest<Bytes>();
		LoadOutcome.watch(request.load(server.url("/large")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals(describe(data), describe(outcome.value));
			Assert.isTrue(outcome.progress.length > 0, "no progress was reported");

			var previous = -1;
			for (report in outcome.progress)
			{
				Assert.isTrue(report[0] >= previous, "progress went from " + previous + " to " + report[0]);
				Assert.isTrue(report[1] == size || report[1] == 0, "progress reported a total of " + report[1] + " for " + size);
				Assert.isTrue(report[0] <= size, "progress reported " + report[0] + " of " + size);
				previous = report[0];
			}

			if (outcome.progress.length > 0)
			{
				Assert.same([size, size], outcome.progress[outcome.progress.length - 1], "the last progress report");
			}
			async.done();
		});
	}

	@:timeout(10000)
	public function testChunkedBodiesAreDecoded(async:Async):Void
	{
		// RFC 9112 section 7.1, with chunk extensions and a trailer section
		var pieces = ["first ", "second, longer than the first ", "", "third"];
		var server = serve(function(_)
		{
			var response = new ScriptedResponse(200);
			response.chunks = [for (piece in pieces) if (piece != "") Bytes.ofString(piece)];
			response.chunkExtensions = true;
			response.trailers = ["X-Checksum: 1234"];
			response.pause = 0.02;
			return response;
		});

		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/chunked")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals(pieces.join(""), outcome.value);

			for (report in outcome.progress)
			{
				Assert.isTrue(report[1] == 0 || report[0] <= report[1], "progress reported " + report[0] + " of " + report[1]);
			}
			async.done();
		});
	}

	@:timeout(10000)
	public function testABodyEndedByClosingIsRead(async:Async):Void
	{
		// RFC 9112 section 6.3, rule 8: with no Content-Length and no chunked
		// coding, the content runs until the connection closes
		var data = Bytes.alloc(50000);
		for (i in 0...data.length) data.set(i, (i * 13) & 0xFF);
		var server = serve(function(_)
		{
			var response = ScriptedResponse.bytes(200, data);
			response.closeDelimited = true;
			response.pieceSize = 8192;
			response.pause = 0.005;
			return response;
		});

		var request = new HTTPRequest<Bytes>();
		LoadOutcome.watch(request.load(server.url("/closing")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals(describe(data), describe(outcome.value));
			async.done();
		});
	}

	@:timeout(10000)
	public function testGzipContentIsDecodedWhenAskedFor(async:Async):Void
	{
		// RFC 9110 section 12.5.3: gzip is sent only to a client that accepts
		// it, and section 8.4: the client removes the coding
		var text = StringTools.lpad("", "compressible text ", 20000) + "end";
		var accepted:String = null;
		var server = serve(function(request)
		{
			accepted = request.header("Accept-Encoding");
			if (accepted != null && accepted.toLowerCase().indexOf("gzip") > -1)
			{
				return ScriptedResponse.bytes(200, ScriptedResponse.gzip(Bytes.ofString(text)), ["Content-Encoding: gzip", "Content-Type: text/plain"]);
			}
			return ScriptedResponse.text(200, text, ["Content-Type: text/plain"]);
		});

		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/gzip")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals(text.length, outcome.value == null ? -1 : outcome.value.length, "with Accept-Encoding: " + accepted);
			Assert.isTrue(outcome.value == text, "the text was not decoded, with Accept-Encoding: " + accepted);
			async.done();
		});
	}

	@:timeout(10000)
	public function testTextIsDecodedAsUTF8(async:Async):Void
	{
		var text = "ASCII, é, \u{4E2D}\u{6587}, \u{1F600} and \u{10FFFF}";
		var server = serve(function(_) return ScriptedResponse.text(200, text, ["Content-Type: text/plain"]));
		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/utf8")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals(text, outcome.value);
			async.done();
		});
	}

	@:timeout(10000)
	@Ignored("Waiting on #2198")
	public function testAByteOrderMarkIsNotPartOfTheText(async:Async):Void
	{
		// The Encoding Standard's UTF-8 decode, as XMLHttpRequest's text, and
		// Flash's text loading, take a leading BOM as a marker
		var body = new haxe.io.BytesBuffer();
		for (byte in [0xEF, 0xBB, 0xBF]) body.addByte(byte);
		body.addString("héllo");
		var data = body.getBytes();
		var server = serve(function(_) return ScriptedResponse.bytes(200, data, ["Content-Type: text/plain"]));

		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/bom")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("héllo", outcome.value);
			async.done();
		});
	}

	@:timeout(10000)
	#if (neko || hl)
	@Ignored("Waiting on #2198")
	#end
	public function testInvalidUTF8BecomesReplacementCharacters(async:Async):Void
	{
		// The Encoding Standard's UTF-8 decode, as XMLHttpRequest's text: each
		// invalid sequence becomes U+FFFD, and the text around it is kept
		var body = new haxe.io.BytesBuffer();
		body.addString("a");
		body.addByte(0xFF);
		body.addString("b");
		body.addByte(0xC3);
		body.addString("c");
		var data = body.getBytes();
		var server = serve(function(_) return ScriptedResponse.bytes(200, data, ["Content-Type: text/plain; charset=utf-8"]));

		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/invalid")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("a\u{FFFD}b\u{FFFD}c", outcome.value);
			async.done();
		});
	}

	@:timeout(10000)
	public function testACharsetParameterIsUnderstood(async:Async):Void
	{
		// RFC 9110 section 8.3.2: charset names are case-insensitive, and
		// section 5.6.6: a parameter value can be quoted
		var text = "caf\u{E9} \u{1F600}";
		var types = ["text/plain; charset=UTF-8", "text/plain;charset=\"utf-8\"", "application/json; charset=Utf-8"];
		var server = serve(function(request) return ScriptedResponse.text(200, text, ["Content-Type: " + types[Std.parseInt(request.path.substr(1))]]));

		ScriptedServer.each([0, 1, 2], function(index, next)
		{
			var request = new HTTPRequest<String>();
			LoadOutcome.watch(request.load(server.url("/" + index)), async, function(outcome)
			{
				Assert.isTrue(outcome.completed, types[index] + " " + outcome);
				Assert.equals(text, outcome.value, types[index]);
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	public function testResponseHeadersAreReportedWhenEnabled(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "ok", [
			"Content-Type: text/plain",
			"X-Plain: value",
			"X-Padded:   value with spaces   ",
			"X-Multi: first",
			"X-Multi: second",
			"Set-Cookie: one=1",
			"Set-Cookie: two=2"
		]));

		var request = new HTTPRequest<String>();
		request.enableResponseHeaders = true;
		LoadOutcome.watch(request.load(server.url("/headers")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			var headers = request.responseHeaders;
			Assert.notNull(headers, "no response headers");
			if (headers == null)
			{
				async.done();
				return;
			}

			Assert.same(["text/plain"], values(headers, "Content-Type"));
			Assert.same(["value"], values(headers, "X-Plain"));
			// RFC 9110 section 5.5: a field value has no leading or trailing
			// whitespace
			Assert.same(["value with spaces"], values(headers, "X-Padded"));
			// Section 5.3: repeated fields may be joined with commas, except
			// Set-Cookie
			Assert.equals("first, second", values(headers, "X-Multi").join(", "));
			Assert.same(["one=1", "two=2"], values(headers, "Set-Cookie"));

			for (header in headers)
			{
				Assert.isTrue(~/^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$/.match(header.name), "a response header is named \"" + header.name + "\"");
			}
			async.done();
		});
	}

	@:timeout(10000)
	@Ignored("Waiting on #2196")
	public function testResponseHeaderValuesNeedNoSpaceAndCanHoldColons(async:Async):Void
	{
		// RFC 9112 section 5.1: field-line = field-name ":" OWS field-value OWS,
		// and a value can hold any visible character
		var server = serve(function(_) return ScriptedResponse.text(200, "ok", ["X-Tight:value", "X-Note: one: two", "X-Time: 12:30:00"]));
		var request = new HTTPRequest<String>();
		request.enableResponseHeaders = true;
		LoadOutcome.watch(request.load(server.url("/headers")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.same(["value"], values(request.responseHeaders, "X-Tight"), describeHeaders(request.responseHeaders));
			Assert.same(["one: two"], values(request.responseHeaders, "X-Note"), describeHeaders(request.responseHeaders));
			Assert.same(["12:30:00"], values(request.responseHeaders, "X-Time"), describeHeaders(request.responseHeaders));
			async.done();
		});
	}

	@:timeout(10000)
	public function testResponseHeadersAreLeftOutUnlessEnabled(async:Async):Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "ok", ["X-Plain: value"]));
		var request = new HTTPRequest<String>();
		LoadOutcome.watch(request.load(server.url("/headers")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.isTrue(request.responseHeaders == null || request.responseHeaders.length == 0, "response headers: " + describeHeaders(request.responseHeaders));
			async.done();
		});
	}

	@:timeout(10000)
	@Ignored("Waiting on #2196")
	public function testInterimResponsesAreNotTheResponse(async:Async):Void
	{
		// RFC 9110 section 15.2: a client parses 1xx responses that come
		// before the final response, even one it did not expect
		var server = serve(function(_)
		{
			var response = ScriptedResponse.text(200, "final", ["X-Final: yes"]);
			response.interim = ["HTTP/1.1 103 Early Hints\r\nX-Interim: yes\r\n\r\n"];
			return response;
		});

		var request = new HTTPRequest<String>();
		request.enableResponseHeaders = true;
		LoadOutcome.watch(request.load(server.url("/interim")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("final", outcome.value);
			Assert.equals(200, request.responseStatus);
			Assert.same(["yes"], values(request.responseHeaders, "X-Final"));
			Assert.same([], values(request.responseHeaders, "X-Interim"));
			async.done();
		});
	}

	@:timeout(10000)
	public function testImagesLoadFromTheirBytes(async:Async):Void
	{
		// HTTPRequest<T> makes a T of a type with fromBytes()
		var image = new lime.graphics.Image(null, 0, 0, 3, 2);
		for (x in 0...3)
		{
			for (y in 0...2) image.setPixel32(x, y, 0x336699FF, RGBA32);
		}
		image.setPixel32(2, 1, 0xFF0000FF, RGBA32);
		var png = image.encode(PNG);
		var server = serve(function(_) return ScriptedResponse.bytes(200, png, ["Content-Type: image/png"]));

		var request = new HTTPRequest<lime.graphics.Image>();
		LoadOutcome.watch(request.load(server.url("/image.png")), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			var loaded = outcome.value;
			Assert.notNull(loaded);
			if (loaded != null)
			{
				Assert.equals(3, loaded.width);
				Assert.equals(2, loaded.height);
				Assert.equals(StringTools.hex(0x336699FF, 8), StringTools.hex(loaded.getPixel32(0, 0, RGBA32), 8));
				Assert.equals(StringTools.hex(0xFF0000FF, 8), StringTools.hex(loaded.getPixel32(2, 1, RGBA32), 8));
			}
			async.done();
		});
	}

	@:timeout(10000)
	public function testTheURIGivenAtConstructionIsLoaded(async:Async):Void
	{
		var server = serve(function(request) return ScriptedResponse.text(200, "at " + request.target));
		var request = new HTTPRequest<String>(server.url("/constructed"));
		LoadOutcome.watch(request.load(), async, function(outcome)
		{
			Assert.isTrue(outcome.completed, Std.string(outcome));
			Assert.equals("at /constructed", outcome.value);
			Assert.equals(server.url("/constructed"), request.uri);
			async.done();
		});
	}

	private static function describe(bytes:Bytes):String
	{
		return bytes == null ? "null" : bytes.length + " bytes, CRC-32 " + StringTools.hex(Crc32.make(bytes), 8);
	}

	private static function describeHeaders(headers:Array<HTTPRequestHeader>):String
	{
		return headers == null ? "null" : [for (header in headers) header.name + ": " + header.value].join(" | ");
	}

	private function serve(answer:RecordedRequest->ScriptedResponse):ScriptedServer
	{
		var server = new ScriptedServer(answer);
		servers.push(server);
		return server;
	}

	private static function statusResponse(request:RecordedRequest):ScriptedResponse
	{
		// Answers /status/N with status N and a body naming it
		var status = Std.parseInt(request.path.split("/").pop());
		return ScriptedResponse.text(status, status == 204 ? "" : "status " + status);
	}

	private static function values(headers:Array<HTTPRequestHeader>, name:String):Array<String>
	{
		if (headers == null) return [];
		return [for (header in headers) if (header.name.toLowerCase() == name.toLowerCase()) header.value];
	}
	#end
}
