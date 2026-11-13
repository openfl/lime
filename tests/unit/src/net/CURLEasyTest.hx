package net;

import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.Timer;
import utest.Assert;
import utest.Test;
#if (lime_cffi && lime_curl)
import lime.net.curl.CURL;
import lime.net.curl.CURLCode;
import lime.net.curl.CURLInfo;
import lime.net.curl.CURLOption;
import lime.net.curl.CURLVersion;
#end
#if (lime_cffi && lime_curl && sys && target.threaded)
import net.ScriptedServer;
import sys.thread.Lock;
import sys.thread.Thread;
#end

/**
	Lime's bindings of curl's easy interface behave as libcurl documents its
	functions, options and transfer information.
**/
class CURLEasyTest extends Test
{
	// CURL_VERSION_SSL
	private static inline var FEATURE_SSL = 1 << 2;

	// Longer than any test takes, so a transfer that never ends stops the run
	private static inline var WATCHDOG_SECONDS = 30;

	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_curl && sys && target.threaded)
	private var handles:Array<CURL>;
	private var servers:Array<ScriptedServer>;
	private var watchdog:Lock;

	public function setup():Void
	{
		handles = [];
		servers = [];

		// Transfers block, so a hang is ended from another thread
		watchdog = new Lock();
		var finished = watchdog;
		Thread.create(function()
		{
			if (finished.wait(WATCHDOG_SECONDS)) return;
			Sys.stderr().writeString("CURLEasyTest: a transfer did not end in " + WATCHDOG_SECONDS + " s\n");
			Sys.stderr().flush();
			Sys.exit(1);
		});
	}

	public function teardown():Void
	{
		for (curl in handles) curl.cleanup();
		for (server in servers) server.stop();
		watchdog.release();
	}

	public function testAHandleGetsAURL():Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "hello", ["Content-Type: text/plain"]));
		var curl = handle();
		var result = run(curl, server.url("/hello"));

		assertCode(OK, result.code);
		Assert.equals("hello", result.body.toString());
		Assert.equals(200, curl.getInfo(RESPONSE_CODE));
		Assert.same(["GET /hello"], lines(server));
	}

	public function testTheResponseCodeIsZeroBeforeAResponse():Void
	{
		// CURLINFO_RESPONSE_CODE: zero if no server response code has been received
		var curl = handle();
		Assert.equals(0, curl.getInfo(RESPONSE_CODE));

		run(curl, ScriptedServer.refusedURL());
		Assert.equals(0, curl.getInfo(RESPONSE_CODE));
	}

	public function testPerformReportsARefusedConnection():Void
	{
		var result = run(handle(), ScriptedServer.refusedURL());
		assertCode(COULDNT_CONNECT, result.code);
	}

	public function testPerformReportsANameThatDoesNotResolve():Void
	{
		// RFC 6761 section 6.4: names under .invalid never resolve
		var curl = handle();
		curl.setOption(TIMEOUT_MS, 20000);
		var result = run(curl, "http://lime-unit-test.invalid/");
		assertCode(COULDNT_RESOLVE_HOST, result.code);
	}

	public function testPerformReportsATimeout():Void
	{
		var server = serve(function(_) return ScriptedResponse.unanswered());
		var curl = handle();
		curl.setOption(TIMEOUT_MS, 300);

		var start = Timer.stamp();
		var result = run(curl, server.url("/quiet"));
		var took = Timer.stamp() - start;

		assertCode(OPERATION_TIMEDOUT, result.code);
		Assert.isTrue(took >= 0.25 && took < 3, "TIMEOUT_MS of 300 took " + took + " s");
	}

	public function testPerformReportsBadURLs():Void
	{
		assertCode(URL_MALFORMAT, run(handle(), "http://").code, "http://");
		assertCode(UNSUPPORTED_PROTOCOL, run(handle(), "nope://127.0.0.1/").code, "nope://");

		// curl_easy_perform with no URL set
		var curl = handle();
		curl.setOption(WRITEFUNCTION, function(_, output:Bytes) return output.length);
		assertCode(URL_MALFORMAT, curl.perform(), "no URL");
	}

	public function testErrorStatusesAreTransfersThatWorked():Void
	{
		// CURLOPT_FAILONERROR: off by default, when a 404 is a successful transfer
		var server = serve(function(_) return ScriptedResponse.text(404, "missing"));
		var curl = handle();
		var result = run(curl, server.url("/missing"));
		assertCode(OK, result.code);
		Assert.equals(404, curl.getInfo(RESPONSE_CODE));
		Assert.equals("missing", result.body.toString());

		var failing = handle();
		failing.setOption(FAILONERROR, true);
		assertCode(HTTP_RETURNED_ERROR, run(failing, server.url("/missing")).code);
	}

	public function testStrerrorDescribesEachCode():Void
	{
		var codes:Array<CURLCode> = [OK, URL_MALFORMAT, COULDNT_RESOLVE_HOST, COULDNT_CONNECT, OPERATION_TIMEDOUT, WRITE_ERROR, ABORTED_BY_CALLBACK];
		var seen = new Map<String, Int>();

		for (code in codes)
		{
			var text = CURL.strerror(code);
			Assert.notNull(text, "no text for " + code);
			if (text == null) continue;
			Assert.isTrue(text.length > 0, "empty text for " + code);
			Assert.equals(text, CURL.strerror(code));
			Assert.isFalse(seen.exists(text), code + " has the text of " + seen.get(text) + ": " + text);
			seen.set(text, code);
		}

		// Codes libcurl does not know have a text too
		Assert.notNull(CURL.strerror(cast 9999));
	}

	public function testResetForgetsTheOptions():Void
	{
		// curl_easy_reset: every option goes back to its default
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var curl = handle();
		curl.setOption(HTTPHEADER, ["X-Before: 1"]);
		curl.setOption(USERAGENT, "before/1");
		curl.setOption(CUSTOMREQUEST, "PATCH");
		curl.setOption(FAILONERROR, true);

		curl.reset();
		curl.setOption(TIMEOUT_MS, 8000);
		var result = run(curl, server.url("/after-reset"));

		assertCode(OK, result.code);
		var received = last(server);
		Assert.equals("GET", received.method);
		Assert.isNull(received.header("X-Before"));
		Assert.isNull(received.header("User-Agent"), "User-Agent: " + received.header("User-Agent"));
	}

	public function testACloneKeepsTheOptions():Void
	{
		// curl_easy_duphandle: a new handle with the same options, after which
		// the two are independent
		var server = serve(function(request) return ScriptedResponse.text(200, "answer for " + request.path));
		var curl = handle();
		curl.setOption(URL, server.url("/cloned"));
		curl.setOption(HTTPHEADER, ["X-Cloned: yes"]);
		curl.setOption(USERAGENT, "cloned/1");
		curl.setOption(CUSTOMREQUEST, "PATCH");
		curl.setOption(POSTFIELDS, "a=1&b=2");

		var clone = track(curl.clone());
		Assert.notNull(clone);
		curl.setOption(URL, server.url("/original"));
		curl.setOption(USERAGENT, "original/1");

		var result = run(clone, null);
		assertCode(OK, result.code);
		Assert.equals("answer for /cloned", result.body.toString());

		var received = last(server);
		Assert.equals("PATCH /cloned", received.method + " " + received.target);
		Assert.equals("yes", received.header("X-Cloned"));
		Assert.equals("cloned/1", received.header("User-Agent"));
		Assert.equals("a=1&b=2", received.body.toString());

		result = run(curl, null);
		assertCode(OK, result.code);
		Assert.equals("answer for /original", result.body.toString());
		Assert.equals("original/1", last(server).header("User-Agent"));
	}

	#if lime_test_crashes
	// Ends the process: the clone sends the header list that setting the
	// original's HTTPHEADER again frees (#2200). Runs only with -Dlime_test_crashes.
	public function testACloneKeepsItsHeadersWhenTheOriginalsChange():Void
	{
		// curl_easy_duphandle: after duplicating, the two handles are independent
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var curl = handle();
		curl.setOption(HTTPHEADER, ["X-Cloned: yes"]);

		var clone = track(curl.clone());
		curl.setOption(HTTPHEADER, ["X-Original: yes"]);

		assertCode(OK, run(clone, server.url("/cloned")).code);
		var received = last(server);
		Assert.equals("yes", received.header("X-Cloned"));
		Assert.isNull(received.header("X-Original"));
	}
	#end

	@Ignored("Waiting on #2200")
	public function testACloneWritesToTheSameFunction():Void
	{
		// curl_easy_duphandle copies CURLOPT_WRITEFUNCTION with the rest
		var server = serve(function(request) return ScriptedResponse.text(200, "answer for " + request.path));
		var written = new BytesBuffer();
		var curl = handle();
		curl.setOption(URL, server.url("/cloned"));
		curl.setOption(WRITEFUNCTION, function(_, output:Bytes):Int
		{
			written.addBytes(output, 0, output.length);
			return output.length;
		});

		var clone = track(curl.clone());
		assertCode(OK, clone.perform());
		Assert.equals("answer for /cloned", written.getBytes().toString());
	}

	public function testPostFieldsArePostedAsAForm():Void
	{
		// CURLOPT_POSTFIELDS: a POST with Content-Type
		// application/x-www-form-urlencoded
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var curl = handle();
		curl.setOption(POSTFIELDS, "name=value&other=2");
		assertCode(OK, run(curl, server.url("/form")).code);

		var received = last(server);
		Assert.equals("POST", received.method);
		Assert.equals("application/x-www-form-urlencoded", received.header("Content-Type"));
		Assert.equals("18", received.header("Content-Length"));
		Assert.equals("name=value&other=2", received.body.toString());
	}

	public function testPostFieldSizeLimitsWhatIsSent():Void
	{
		// CURLOPT_POSTFIELDSIZE: the size of the data, instead of its length
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var curl = handle();
		curl.setOption(POSTFIELDS, "abcdef");
		curl.setOption(POSTFIELDSIZE, 3);
		assertCode(OK, run(curl, server.url("/form")).code);

		var received = last(server);
		Assert.equals("3", received.header("Content-Length"));
		Assert.equals("abc", received.body.toString());
	}

	#if (neko || lime_test_crashes)
	// Ends the C++ process: the fields reach curl as a pointer into a string
	// the collector frees, as they do on HashLink (#2201). Runs there only with
	// -Dlime_test_crashes.
	public function testPostFieldsLastUntilTheTransfer():Void
	{
		// libcurl does not copy CURLOPT_POSTFIELDS, which must stay as they are
		// until the transfer, though the application keeps no reference to them
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var curl = handle();
		var expected = setFreshPostFields(curl);

		for (i in 0...4)
		{
			var garbage = [for (j in 0...2000) Std.string(j * i) + "garbage"];
			garbage = null;
			collect();
		}

		assertCode(OK, run(curl, server.url("/form")).code);
		Assert.equals(expected, describe(last(server).body));
	}
	#end

	public function testHTTPHeaderSendsEachLine():Void
	{
		// CURLOPT_HTTPHEADER: "Accept:" removes a header curl would add, and
		// "X-Empty;" sends one with no value
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var curl = handle();
		curl.setOption(HTTPHEADER, ["X-One: 1", "X-Two: two words", "Accept:", "X-Empty;"]);
		assertCode(OK, run(curl, server.url("/headers")).code);

		var received = last(server);
		Assert.same(["1"], received.headerValues("X-One"));
		Assert.same(["two words"], received.headerValues("X-Two"));
		Assert.same([], received.headerValues("Accept"));
		Assert.same([""], received.headerValues("X-Empty"));
	}

	@Ignored("Waiting on #2204")
	public function testACookieIsSent():Void
	{
		// CURLOPT_COOKIE: sent as the Cookie header
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var curl = handle();
		assertCode(OK, curl.setOption(COOKIE, "first=1; second=2"), "setting COOKIE");
		assertCode(OK, run(curl, server.url("/cookie")).code);
		Assert.equals("first=1; second=2", last(server).header("Cookie"));
	}

	@Ignored("Waiting on #2199")
	public function testFollowLocationFollowsRedirects():Void
	{
		var server = redirecting();
		var curl = handle();
		curl.setOption(FOLLOWLOCATION, true);
		var result = run(curl, server.url("/start"));

		assertCode(OK, result.code);
		Assert.equals("final", result.body.toString());
		Assert.equals(200, curl.getInfo(RESPONSE_CODE));
		Assert.equals(server.url("/final"), curl.getInfo(EFFECTIVE_URL));
		Assert.equals(1, curl.getInfo(REDIRECT_COUNT));
	}

	@Ignored("Waiting on #2199")
	public function testRedirectsAreNotFollowedByDefault():Void
	{
		// CURLOPT_FOLLOWLOCATION defaults to 0, and CURLINFO_REDIRECT_URL is
		// where a redirect would have gone
		var server = redirecting();
		var curl = handle();
		var result = run(curl, server.url("/start"));

		assertCode(OK, result.code);
		Assert.equals(302, curl.getInfo(RESPONSE_CODE));
		Assert.equals(server.url("/start"), curl.getInfo(EFFECTIVE_URL));
		Assert.equals(server.url("/final"), curl.getInfo(REDIRECT_URL));
		Assert.same(["GET /start"], lines(server));
	}

	public function testNoBodyMakesAHeadRequest():Void
	{
		// CURLOPT_NOBODY: for HTTP, a HEAD request, with no body to download
		var server = serve(function(_)
		{
			var response = ScriptedResponse.text(200, StringTools.lpad("", "x", 1000));
			response.hold = true;
			return response;
		});
		var curl = handle();
		curl.setOption(NOBODY, true);
		var result = run(curl, server.url("/head"));

		assertCode(OK, result.code);
		Assert.equals("HEAD", last(server).method);
		Assert.equals(0, result.body.length);
		Assert.equals(200, curl.getInfo(RESPONSE_CODE));
		Assert.equals(1000.0, curl.getInfo(CONTENT_LENGTH_DOWNLOAD));
	}

	public function testCustomRequestSetsTheMethod():Void
	{
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var patch = handle();
		patch.setOption(CUSTOMREQUEST, "PATCH");
		patch.setOption(POSTFIELDS, "patched");
		assertCode(OK, run(patch, server.url("/patch")).code);
		Assert.equals("PATCH", last(server).method);
		Assert.equals("patched", last(server).body.toString());

		var delete = handle();
		delete.setOption(CUSTOMREQUEST, "DELETE");
		assertCode(OK, run(delete, server.url("/delete")).code);
		Assert.equals("DELETE", last(server).method);
		Assert.equals(0, last(server).body.length);
	}

	public function testTheWriteFunctionGetsTheWholeBody():Void
	{
		var data = Bytes.alloc(200000);
		for (i in 0...data.length) data.set(i, (i * 31 + (i >> 8)) & 0xFF);
		for (i in 0...100) data.set(i * 1000, 0);
		var server = serve(function(_)
		{
			var response = ScriptedResponse.bytes(200, data);
			response.pieceSize = 16384;
			return response;
		});

		var calls = 0;
		var empty = 0;
		var received = new BytesBuffer();
		var curl = handle();
		curl.setOption(URL, server.url("/binary"));
		curl.setOption(WRITEFUNCTION, function(_, output:Bytes):Int
		{
			calls++;
			if (output.length == 0) empty++;
			received.addBytes(output, 0, output.length);
			return output.length;
		});

		assertCode(OK, curl.perform());
		Assert.equals(describe(data), describe(received.getBytes()));
		Assert.isTrue(calls > 0);
		Assert.equals(0, empty, "the write function was called with nothing");
	}

	@Ignored("Waiting on #2202")
	public function testAShortWriteAbortsTheTransfer():Void
	{
		// CURLOPT_WRITEFUNCTION: returning less than it was given aborts the
		// transfer with CURLE_WRITE_ERROR
		var server = serve(function(_) return ScriptedResponse.text(200, StringTools.lpad("", "z", 100000)));

		for (shortBy in [1, -1])
		{
			var calls = 0;
			var curl = handle();
			curl.setOption(URL, server.url("/short"));
			curl.setOption(WRITEFUNCTION, function(_, output:Bytes):Int
			{
				calls++;
				return shortBy > 0 ? output.length - shortBy : 0;
			});

			assertCode(WRITE_ERROR, curl.perform(), shortBy > 0 ? "returning one short" : "returning 0");
			Assert.equals(1, calls, "the write function was called after it came up short");
		}
	}

	public function testTheHeaderFunctionGetsEachLine():Void
	{
		// CURLOPT_HEADERFUNCTION: called once for each whole header line,
		// including the status line and the blank line that ends the header
		var server = serve(function(_) return ScriptedResponse.text(200, "ok", ["X-Test: value"]));
		var received = [];
		var curl = handle();
		curl.setOption(HEADERFUNCTION, function(_, line:String):Void
		{
			received.push(line);
		});
		assertCode(OK, run(curl, server.url("/headers")).code);

		Assert.isTrue(received.length >= 4, "header lines: " + received.join(""));
		if (received.length == 0) return;

		Assert.isTrue(StringTools.startsWith(received[0], "HTTP/1.1 200"), "the first line is " + received[0]);
		Assert.isTrue(received.indexOf("X-Test: value\r\n") > -1, "header lines: " + received.join(""));
		Assert.equals("\r\n", received[received.length - 1]);
		for (line in received)
		{
			Assert.isTrue(StringTools.endsWith(line, "\r\n"), "the line \"" + line + "\" is not whole");
		}
	}

	@Ignored("Waiting on #2202")
	public function testTheTransferInfoFunctionIsNotCalledWithProgressOff():Void
	{
		// CURLOPT_XFERINFOFUNCTION is only called while CURLOPT_NOPROGRESS is 0.
		// Lime turns progress on when the function is set.
		var server = serve(function(_) return ScriptedResponse.text(200, "ok"));
		var calls = 0;
		var curl = handle();
		curl.setOption(XFERINFOFUNCTION, function(_, dltotal:Int, dlnow:Int, ultotal:Int, ulnow:Int):Int
		{
			calls++;
			return 0;
		});
		curl.setOption(NOPROGRESS, true);
		assertCode(OK, run(curl, server.url("/quiet")).code);
		Assert.equals(0, calls);
	}

	public function testTheTransferInfoFunctionReportsProgress():Void
	{
		var size = 300000;
		var server = serve(function(_)
		{
			var response = ScriptedResponse.bytes(200, Bytes.alloc(size));
			response.pieceSize = 50000;
			response.pause = 0.01;
			return response;
		});

		var reports:Array<Array<Int>> = [];
		var curl = handle();
		curl.setOption(NOPROGRESS, false);
		curl.setOption(XFERINFOFUNCTION, function(_, dltotal:Int, dlnow:Int, ultotal:Int, ulnow:Int):Int
		{
			reports.push([dltotal, dlnow, ultotal, ulnow]);
			return 0;
		});
		assertCode(OK, run(curl, server.url("/progress")).code);

		Assert.isTrue(reports.length > 0, "no progress was reported");
		var previous = 0;
		for (report in reports)
		{
			Assert.isTrue(report[1] >= previous, "dlnow went from " + previous + " to " + report[1]);
			Assert.isTrue(report[0] == 0 || report[0] == size, "dltotal was " + report[0]);
			previous = report[1];
		}
		if (reports.length > 0) Assert.same([size, size, 0, 0], reports[reports.length - 1]);
	}

	@Ignored("Waiting on #2202")
	public function testTheTransferInfoFunctionAbortsWhenItReturnsNonZero():Void
	{
		// CURLOPT_XFERINFOFUNCTION: a non-zero return aborts the transfer with
		// CURLE_ABORTED_BY_CALLBACK
		var server = serve(function(_)
		{
			var response = ScriptedResponse.text(200, StringTools.lpad("", "x", 100000));
			response.pieceSize = 10000;
			response.pause = 0.01;
			return response;
		});

		var curl = handle();
		curl.setOption(NOPROGRESS, false);
		curl.setOption(XFERINFOFUNCTION, function(_, dltotal:Int, dlnow:Int, ultotal:Int, ulnow:Int):Int return 1);
		assertCode(ABORTED_BY_CALLBACK, run(curl, server.url("/abort")).code);
	}

	@Ignored("Waiting on #2199")
	public function testInfoHasTheTypesLibcurlGives():Void
	{
		var body = StringTools.lpad("", "i", 12345);
		var server = serve(function(_)
		{
			var response = ScriptedResponse.text(200, body, ["Content-Type: text/plain; charset=utf-8"]);
			response.delay = 0.2;
			return response;
		});
		var curl = handle();
		assertCode(OK, run(curl, server.url("/info")).code);

		var code:Dynamic = curl.getInfo(RESPONSE_CODE);
		Assert.isTrue(Std.isOfType(code, Int), "RESPONSE_CODE is " + code);
		Assert.equals(200, code);

		var url:Dynamic = curl.getInfo(EFFECTIVE_URL);
		Assert.isTrue(Std.isOfType(url, String), "EFFECTIVE_URL is " + url);
		Assert.equals(server.url("/info"), url);

		Assert.equals("text/plain; charset=utf-8", curl.getInfo(CONTENT_TYPE));

		var size:Dynamic = curl.getInfo(SIZE_DOWNLOAD);
		Assert.isTrue(Std.isOfType(size, Float), "SIZE_DOWNLOAD is " + size);
		Assert.equals(12345.0, size);

		var sizeT:Dynamic = curl.getInfo(SIZE_DOWNLOAD_T);
		Assert.isTrue(Std.isOfType(sizeT, Int), "SIZE_DOWNLOAD_T is " + sizeT);
		Assert.equals(12345, sizeT);

		// In seconds, and at least as long as the server waited
		var time:Dynamic = curl.getInfo(TOTAL_TIME);
		Assert.isTrue(Std.isOfType(time, Float), "TOTAL_TIME is " + time);
		Assert.isTrue(time >= 0.15 && time < 5, "TOTAL_TIME is " + time);
	}

	@Ignored("Waiting on #2199")
	public function testTheContentTypeIsNullWithoutOne():Void
	{
		// CURLINFO_CONTENT_TYPE: NULL if the server sent no valid Content-Type
		var server = serve(function(_) return ScriptedResponse.text(200, "untyped"));
		var curl = handle();
		assertCode(OK, run(curl, server.url("/untyped")).code);
		Assert.isNull(curl.getInfo(CONTENT_TYPE));
	}

	#if !neko
	@Ignored("Waiting on #2203")
	#end
	public function testEscapeEncodesAllButUnreservedCharacters():Void
	{
		// curl_easy_escape: every character but a-z, A-Z, 0-9, '-', '.', '_'
		// and '~' becomes %NN, of its UTF-8 bytes
		var curl = handle();
		assertSameIgnoringHexCase("a%20b%26c%3Dd%2Fe%3Ff%23g%25h%2Bi~j-k.l_m", curl.escape("a b&c=d/e?f#g%h+i~j-k.l_m", 0));
		assertSameIgnoringHexCase("%C3%A9%E4%B8%AD%F0%9F%98%80", curl.escape("é\u{4E2D}\u{1F600}", 0));
		Assert.equals("", curl.escape("", 0));

		// A length counts bytes of the input
		Assert.equals("abc", curl.escape("abcdef", 3));
	}

	@Ignored("Waiting on #2203")
	public function testUnescapeDecodesPercentEncoding():Void
	{
		// curl_easy_unescape: %NN becomes the byte, and '+' stays as it is
		var curl = handle();
		Assert.equals("a b&c+d", curl.unescape("a%20b%26c+d", 0, 0));
		Assert.equals("é\u{4E2D}", curl.unescape("%C3%A9%E4%B8%AD", 0, 0));
		Assert.equals("é", curl.unescape("%c3%a9", 0, 0));

		// %00 decodes to a zero byte, which the output keeps. Compared as
		// codes, as a report cannot print the zero.
		var decoded = curl.unescape("a%00b", 0, 0);
		Assert.same([97, 0, 98], decoded == null ? null : [for (i in 0...decoded.length) decoded.charCodeAt(i)]);
	}

	#if !neko
	@Ignored("Waiting on #2203")
	#end
	public function testEscapeAndUnescapeRoundTrip():Void
	{
		var curl = handle();
		var texts = [
			"plain",
			"spaces and+plus",
			"reserved :/?#[]@!$&'()*+,;=%",
			"é \u{4E2D}\u{6587} \u{1F600}",
			"tab\tline\nreturn\r",
			"%41 is not unescaped twice"
		];

		for (text in texts)
		{
			Assert.equals(text, curl.unescape(curl.escape(text, 0), 0, 0));
		}
	}

	public function testVersionInfoDescribesTheLibrary():Void
	{
		// CURL.versionInfo(): curl_version_info's age, versionNum and features
		var info:Dynamic = CURL.versionInfo(FOURTH);
		Assert.notNull(info);
		if (info == null) return;

		Assert.isTrue(Std.isOfType(info.age, Int), "age is " + info.age);
		Assert.isTrue(info.age >= (CURLVersion.FOURTH : Int), "age is " + info.age);

		// 0xXXYYZZ, as in the text of curl_version(), and at least the 8.23.0
		// that the 8.4.0 changelog names
		Assert.isTrue(Std.isOfType(info.versionNum, Int), "versionNum is " + info.versionNum);
		var version = ~/libcurl\/(\d+)\.(\d+)\.(\d+)/;
		Assert.isTrue(version.match(CURL.version()), "CURL.version() is " + CURL.version());
		if (version.matched(0) != null)
		{
			var number = (Std.parseInt(version.matched(1)) << 16) | (Std.parseInt(version.matched(2)) << 8) | Std.parseInt(version.matched(3));
			Assert.equals(StringTools.hex(number, 6), StringTools.hex(info.versionNum, 6));
		}
		Assert.isTrue(info.versionNum >= 0x081700, "versionNum is " + StringTools.hex(info.versionNum, 6));

		Assert.isTrue(Std.isOfType(info.features, Int), "features is " + info.features);
		Assert.isTrue((info.features & FEATURE_SSL) != 0, "features " + StringTools.hex(info.features) + " have no SSL");

		// The library is the same whichever age of the call is asked for
		var first:Dynamic = CURL.versionInfo(FIRST);
		Assert.notNull(first);
		if (first != null) Assert.equals(info.versionNum, first.versionNum);
	}

	@Ignored("Waiting on #2204")
	public function testOptionAndInfoNumbersAreLibcurls():Void
	{
		// curl.h numbers each option from its type, and each info from the type
		// of its value
		var LONG = 0, OBJECTPOINT = 10000, FUNCTIONPOINT = 20000, OFF_T = 30000;
		var STRINGPOINT = OBJECTPOINT, SLISTPOINT = OBJECTPOINT;

		var options:Array<{name:String, value:Int, expected:Int}> = [
			{name: "URL", value: CURLOption.URL, expected: STRINGPOINT + 2},
			{name: "PORT", value: CURLOption.PORT, expected: LONG + 3},
			{name: "WRITEFUNCTION", value: CURLOption.WRITEFUNCTION, expected: FUNCTIONPOINT + 11},
			{name: "READFUNCTION", value: CURLOption.READFUNCTION, expected: FUNCTIONPOINT + 12},
			{name: "POSTFIELDS", value: CURLOption.POSTFIELDS, expected: OBJECTPOINT + 15},
			{name: "USERAGENT", value: CURLOption.USERAGENT, expected: STRINGPOINT + 18},
			{name: "COOKIE", value: CURLOption.COOKIE, expected: STRINGPOINT + 22},
			{name: "HTTPHEADER", value: CURLOption.HTTPHEADER, expected: SLISTPOINT + 23},
			{name: "COOKIEFILE", value: CURLOption.COOKIEFILE, expected: STRINGPOINT + 31},
			{name: "CUSTOMREQUEST", value: CURLOption.CUSTOMREQUEST, expected: STRINGPOINT + 36},
			{name: "NOPROGRESS", value: CURLOption.NOPROGRESS, expected: LONG + 43},
			{name: "NOBODY", value: CURLOption.NOBODY, expected: LONG + 44},
			{name: "FAILONERROR", value: CURLOption.FAILONERROR, expected: LONG + 45},
			{name: "UPLOAD", value: CURLOption.UPLOAD, expected: LONG + 46},
			{name: "FOLLOWLOCATION", value: CURLOption.FOLLOWLOCATION, expected: LONG + 52},
			{name: "POSTFIELDSIZE", value: CURLOption.POSTFIELDSIZE, expected: LONG + 60},
			{name: "SSL_VERIFYPEER", value: CURLOption.SSL_VERIFYPEER, expected: LONG + 64},
			{name: "CAINFO", value: CURLOption.CAINFO, expected: STRINGPOINT + 65},
			{name: "MAXREDIRS", value: CURLOption.MAXREDIRS, expected: LONG + 68},
			{name: "HEADERFUNCTION", value: CURLOption.HEADERFUNCTION, expected: FUNCTIONPOINT + 79},
			{name: "COOKIEJAR", value: CURLOption.COOKIEJAR, expected: STRINGPOINT + 82},
			{name: "HTTP_VERSION", value: CURLOption.HTTP_VERSION, expected: LONG + 84},
			{name: "NOSIGNAL", value: CURLOption.NOSIGNAL, expected: LONG + 99},
			{name: "ACCEPT_ENCODING", value: CURLOption.ACCEPT_ENCODING, expected: STRINGPOINT + 102},
			{name: "INFILESIZE_LARGE", value: CURLOption.INFILESIZE_LARGE, expected: OFF_T + 115},
			{name: "POSTFIELDSIZE_LARGE", value: CURLOption.POSTFIELDSIZE_LARGE, expected: OFF_T + 120},
			{name: "IGNORE_CONTENT_LENGTH", value: CURLOption.IGNORE_CONTENT_LENGTH, expected: LONG + 136},
			{name: "TIMEOUT_MS", value: CURLOption.TIMEOUT_MS, expected: LONG + 155},
			{name: "CONNECTTIMEOUT_MS", value: CURLOption.CONNECTTIMEOUT_MS, expected: LONG + 156},
			{name: "POSTREDIR", value: CURLOption.POSTREDIR, expected: LONG + 161},
			{name: "RESOLVE", value: CURLOption.RESOLVE, expected: SLISTPOINT + 203},
			{name: "XFERINFOFUNCTION", value: CURLOption.XFERINFOFUNCTION, expected: FUNCTIONPOINT + 219},
			{name: "CONNECT_TO", value: CURLOption.CONNECT_TO, expected: SLISTPOINT + 243},
			{name: "MIMEPOST", value: CURLOption.MIMEPOST, expected: OBJECTPOINT + 269}
		];

		for (option in options)
		{
			Assert.equals(option.expected, option.value, "CURLOption." + option.name);
		}

		var STRING = 0x100000, INFO_LONG = 0x200000, DOUBLE = 0x300000, INFO_OFF_T = 0x600000;

		var infos:Array<{name:String, value:Int, expected:Int}> = [
			{name: "EFFECTIVE_URL", value: CURLInfo.EFFECTIVE_URL, expected: STRING + 1},
			{name: "RESPONSE_CODE", value: CURLInfo.RESPONSE_CODE, expected: INFO_LONG + 2},
			{name: "TOTAL_TIME", value: CURLInfo.TOTAL_TIME, expected: DOUBLE + 3},
			{name: "SIZE_UPLOAD_T", value: CURLInfo.SIZE_UPLOAD_T, expected: INFO_OFF_T + 7},
			{name: "SIZE_DOWNLOAD", value: CURLInfo.SIZE_DOWNLOAD, expected: DOUBLE + 8},
			{name: "SIZE_DOWNLOAD_T", value: CURLInfo.SIZE_DOWNLOAD_T, expected: INFO_OFF_T + 8},
			{name: "CONTENT_LENGTH_DOWNLOAD", value: CURLInfo.CONTENT_LENGTH_DOWNLOAD, expected: DOUBLE + 15},
			{name: "CONTENT_LENGTH_DOWNLOAD_T", value: CURLInfo.CONTENT_LENGTH_DOWNLOAD_T, expected: INFO_OFF_T + 15},
			{name: "CONTENT_LENGTH_UPLOAD_T", value: CURLInfo.CONTENT_LENGTH_UPLOAD_T, expected: INFO_OFF_T + 16},
			{name: "CONTENT_TYPE", value: CURLInfo.CONTENT_TYPE, expected: STRING + 18},
			{name: "REDIRECT_COUNT", value: CURLInfo.REDIRECT_COUNT, expected: INFO_LONG + 20},
			{name: "REDIRECT_URL", value: CURLInfo.REDIRECT_URL, expected: STRING + 31},
			{name: "PRIMARY_PORT", value: CURLInfo.PRIMARY_PORT, expected: INFO_LONG + 40},
			{name: "SCHEME", value: CURLInfo.SCHEME, expected: STRING + 49}
		];

		for (info in infos)
		{
			Assert.equals(StringTools.hex(info.expected, 6), StringTools.hex(info.value, 6), "CURLInfo." + info.name);
		}
	}

	private static function assertCode(expected:CURLCode, actual:CURLCode, ?message:String, ?pos:haxe.PosInfos):Void
	{
		Assert.equals((expected : Int), (actual : Int), (message != null ? message + ": " : "") + "expected " + expected + " (" + CURL.strerror(expected) + ") but got " + actual + " (" + CURL.strerror(actual) + ")", pos);
	}

	private static function assertSameIgnoringHexCase(expected:String, actual:String, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(expected.toUpperCase(), actual == null ? null : actual.toUpperCase(), "escaped as " + actual, pos);
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

	private static function describe(bytes:Bytes):String
	{
		return bytes == null ? "null" : bytes.length + " bytes, CRC-32 " + StringTools.hex(Crc32.make(bytes), 8);
	}

	private function handle():CURL
	{
		var curl = track(new CURL());
		curl.setOption(NOSIGNAL, true);
		curl.setOption(TIMEOUT_MS, 8000);
		return curl;
	}

	private static function last(server:ScriptedServer):RecordedRequest
	{
		var requests = server.requests();
		return requests.length > 0 ? requests[requests.length - 1] : new RecordedRequest();
	}

	private static function lines(server:ScriptedServer):Array<String>
	{
		return [for (request in server.requests()) request.method + " " + request.target];
	}

	private function redirecting():ScriptedServer
	{
		return serve(function(request)
		{
			if (request.path == "/start") return ScriptedResponse.redirect(302, "/final");
			return ScriptedResponse.text(200, "final");
		});
	}

	private static function run(curl:CURL, url:String):{code:CURLCode, body:Bytes}
	{
		// Performs the transfer, collecting the body, at the URL if one is given
		var body = new BytesBuffer();
		if (url != null) curl.setOption(URL, url);
		curl.setOption(WRITEFUNCTION, function(_, output:Bytes):Int
		{
			body.addBytes(output, 0, output.length);
			return output.length;
		});
		var code = curl.perform();
		return {code: code, body: body.getBytes()};
	}

	private function serve(answer:RecordedRequest->ScriptedResponse):ScriptedServer
	{
		var server = new ScriptedServer(answer);
		servers.push(server);
		return server;
	}

	private static function setFreshPostFields(curl:CURL):String
	{
		// Made here, so that nothing but curl's handle refers to them afterwards
		var text = new StringBuf();
		for (i in 0...5000) text.add(StringTools.hex(i * 0x9E3779B1, 8));
		var fields = text.toString();
		curl.setOption(POSTFIELDS, fields);
		return describe(Bytes.ofString(fields));
	}

	private function track(curl:CURL):CURL
	{
		if (curl != null) handles.push(curl);
		return curl;
	}
	#end
}
