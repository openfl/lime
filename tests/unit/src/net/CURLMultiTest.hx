package net;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.Timer;
import utest.Assert;
import utest.Test;
#if (lime_cffi && lime_curl)
import lime.net.curl.CURL;
import lime.net.curl.CURLCode;
import lime.net.curl.CURLMulti;
import lime.net.curl.CURLMultiCode;
import lime.net.curl.CURLMultiMessage;
#end
#if (lime_cffi && lime_curl && sys && target.threaded)
import net.ScriptedServer;
import sys.thread.Lock;
import sys.thread.Thread;
#end

/**
	Lime's bindings of curl's multi interface run several transfers at once,
	count those still running, and report how each one ended, as libcurl
	documents.
**/
class CURLMultiTest extends Test
{
	// Longer than any test takes, so a loop that never ends stops the run
	private static inline var WATCHDOG_SECONDS = 30;

	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_curl && sys && target.threaded)
	private var handles:Array<CURL>;
	private var multis:Array<CURLMulti>;
	private var servers:Array<ScriptedServer>;
	private var watchdog:Lock;

	public function setup():Void
	{
		handles = [];
		multis = [];
		servers = [];

		watchdog = new Lock();
		var finished = watchdog;
		Thread.create(function()
		{
			if (finished.wait(WATCHDOG_SECONDS)) return;
			Sys.stderr().writeString("CURLMultiTest: a test did not end in " + WATCHDOG_SECONDS + " s\n");
			Sys.stderr().flush();
			Sys.exit(1);
		});
	}

	public function teardown():Void
	{
		// curl_easy_cleanup expects the handle to be out of any multi handle
		for (multi in multis)
		{
			for (curl in handles) multi.removeHandle(curl);
		}
		for (curl in handles) curl.cleanup();
		for (server in servers) server.stop();
		watchdog.release();
	}

	public function testAHandleCannotBeAddedTwice():Void
	{
		// CURLM_ADDED_ALREADY: an easy handle already added to a multi handle
		var multi = newMulti();
		var curl = handle(ScriptedServer.refusedURL(), null);
		assertMultiCode(OK, multi.addHandle(curl));
		assertMultiCode(ADDED_ALREADY, multi.addHandle(curl));
		assertMultiCode(OK, multi.removeHandle(curl));
	}

	public function testPerformCountsTheRunningTransfers():Void
	{
		var server = delaying(0.5);
		var multi = newMulti();
		var bodies = [for (i in 0...3) new BytesBuffer()];
		for (i in 0...3) multi.addHandle(handle(server.url("/count/" + i), bodies[i]));

		assertMultiCode(OK, multi.perform());
		Assert.equals(3, multi.runningHandles);

		Assert.isTrue(drive(multi, 5), "the transfers did not finish");
		Assert.equals(0, multi.runningHandles);
		for (i in 0...3) Assert.equals("answer for /count/" + i, bodies[i].getBytes().toString());
	}

	public function testInfoReadReportsHowEachTransferEnded():Void
	{
		// curl_multi_info_read: a CURLMSG_DONE message for each finished
		// transfer, with its easy handle and result, then NULL
		var server = serve(function(request)
		{
			if (request.path == "/quiet") return ScriptedResponse.unanswered();
			return ScriptedResponse.text(200, "ok");
		});

		var multi = newMulti();
		var good = handle(server.url("/good"), null);
		var refused = handle(ScriptedServer.refusedURL(), null);
		var slow = handle(server.url("/quiet"), null);
		slow.setOption(TIMEOUT_MS, 300);
		for (curl in [good, refused, slow]) multi.addHandle(curl);

		Assert.isTrue(drive(multi, 5), "the transfers did not finish");

		var messages = readAll(multi);
		Assert.equals(3, messages.length);
		assertResult(OK, messages, good, "the good transfer");
		assertResult(COULDNT_CONNECT, messages, refused, "the refused transfer");
		assertResult(OPERATION_TIMEDOUT, messages, slow, "the transfer that timed out");
		Assert.isNull(multi.infoRead());
	}

	public function testTransfersRunAtOnce():Void
	{
		// Each is answered after 0.4 s, so one after another they would take 2 s
		var server = delaying(0.4);
		var multi = newMulti();
		var bodies = [for (i in 0...5) new BytesBuffer()];
		for (i in 0...5) multi.addHandle(handle(server.url("/together/" + i), bodies[i]));

		var start = Timer.stamp();
		Assert.isTrue(drive(multi, 5), "the transfers did not finish");
		var took = Timer.stamp() - start;

		Assert.isTrue(took < 1.5, "five transfers of 0.4 s took " + took + " s");
		for (i in 0...5) Assert.equals("answer for /together/" + i, bodies[i].getBytes().toString());
		Assert.equals(5, readAll(multi).length);
	}

	public function testARemovedTransferStopsAndIsNotReported():Void
	{
		// curl_multi_remove_handle: a transfer in progress is stopped, and has
		// no message
		var server = serve(function(request)
		{
			if (request.path == "/held") return ScriptedResponse.unanswered();
			return ScriptedResponse.text(200, "ok");
		});

		var multi = newMulti();
		var held = handle(server.url("/held"), null);
		var quick = handle(server.url("/quick"), null);
		multi.addHandle(held);
		multi.addHandle(quick);

		var end = Timer.stamp() + 5;
		var messages = [];
		while (messages.length == 0 && Timer.stamp() < end)
		{
			multi.wait(20);
			multi.perform();
			messages = messages.concat(readAll(multi));
		}

		Assert.equals(1, messages.length);
		if (messages.length > 0) Assert.isTrue(messages[0].curl == quick, "the message is not the quick transfer's");

		assertMultiCode(OK, multi.removeHandle(held));
		multi.perform();
		Assert.equals(0, multi.runningHandles);
		Assert.isNull(multi.infoRead());

		end = Timer.stamp() + 3;
		while (server.countDisconnects() == 0 && Timer.stamp() < end) Sys.sleep(0.01);
		Assert.equals(1, server.countDisconnects(), "the removed transfer's connection stayed open");
	}

	public function testAFinishedHandleCanBeAddedAgain():Void
	{
		var server = serve(function(request) return ScriptedResponse.text(200, "answer for " + request.path));
		var multi = newMulti();
		var body = new BytesBuffer();
		var curl = handle(server.url("/first"), body);

		multi.addHandle(curl);
		Assert.isTrue(drive(multi, 5), "the first transfer did not finish");
		assertResult(OK, readAll(multi), curl, "the first transfer");
		assertMultiCode(OK, multi.removeHandle(curl));

		var second = new BytesBuffer();
		collectInto(curl, second);
		curl.setOption(URL, server.url("/second"));
		assertMultiCode(OK, multi.addHandle(curl));
		Assert.isTrue(drive(multi, 5), "the second transfer did not finish");
		assertResult(OK, readAll(multi), curl, "the second transfer");

		Assert.equals("answer for /first", body.getBytes().toString());
		Assert.equals("answer for /second", second.getBytes().toString());
	}

	public function testWaitingWithNothingToDoReturns():Void
	{
		// curl_multi_wait returns when the timeout expires, with nothing to wait on
		var multi = newMulti();
		var start = Timer.stamp();
		assertMultiCode(OK, multi.wait(50));
		Assert.isTrue(Timer.stamp() - start < 2, "waiting 50 ms took " + (Timer.stamp() - start) + " s");
	}

	private static function assertMultiCode(expected:CURLMultiCode, actual:CURLMultiCode, ?pos:haxe.PosInfos):Void
	{
		Assert.equals((expected : Int), (actual : Int), pos);
	}

	private static function assertResult(expected:CURLCode, messages:Array<CURLMultiMessage>, curl:CURL, name:String, ?pos:haxe.PosInfos):Void
	{
		var found = [for (message in messages) if (message.curl == curl) message];
		Assert.equals(1, found.length, name + " has " + found.length + " messages", pos);
		if (found.length > 0)
		{
			Assert.equals((expected : Int), (found[0].result : Int), name + " ended with " + CURL.strerror(found[0].result), pos);
		}
	}

	private static function collectInto(curl:CURL, body:BytesBuffer):Void
	{
		curl.setOption(WRITEFUNCTION, function(_, output:Bytes):Int
		{
			if (body != null) body.addBytes(output, 0, output.length);
			return output.length;
		});
	}

	private function delaying(seconds:Float):ScriptedServer
	{
		return serve(function(request)
		{
			var response = ScriptedResponse.text(200, "answer for " + request.path);
			response.delay = seconds;
			return response;
		});
	}

	private static function drive(multi:CURLMulti, seconds:Float):Bool
	{
		var end = Timer.stamp() + seconds;

		do
		{
			multi.wait(20);
			multi.perform();
		}
		while (multi.runningHandles > 0 && Timer.stamp() < end);

		return multi.runningHandles == 0;
	}

	private function handle(url:String, body:BytesBuffer):CURL
	{
		var curl = new CURL();
		handles.push(curl);
		curl.setOption(URL, url);
		curl.setOption(NOSIGNAL, true);
		curl.setOption(TIMEOUT_MS, 8000);
		collectInto(curl, body);
		return curl;
	}

	private static function readAll(multi:CURLMulti):Array<CURLMultiMessage>
	{
		var messages = [];
		var message = multi.infoRead();
		while (message != null)
		{
			messages.push(message);
			message = multi.infoRead();
		}
		return messages;
	}

	private function newMulti():CURLMulti
	{
		var multi = new CURLMulti();
		multis.push(multi);
		return multi;
	}

	private function serve(answer:RecordedRequest->ScriptedResponse):ScriptedServer
	{
		var server = new ScriptedServer(answer);
		servers.push(server);
		return server;
	}
	#end
}
