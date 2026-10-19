package app;

import haxe.Timer;
import lime.app.Future;
import lime.app.Promise;
import lime.system.WorkOutput;
import utest.Assert;
import utest.Test;

/**
	Futures run with `new Future(work, true)` or `Promise.completeAsync()` report
	back when the pool behind them updates. Waiting on them with `ready()` or
	`result()` blocks the application's loop, so it updates the pool itself.
**/
class FutureTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_threads && !html5)
	public function testThreadedFuturesCanBeWaitedFor():Void
	{
		var future = new Future(function() return 42, true);
		Assert.equals(42, future.result(3000), "Future.result() gave up waiting for its threaded work");
	}

	public function testThreadedFutureErrorsCanBeWaitedFor():Void
	{
		var future = new Future(function():Int
		{
			throw "failed";
		}, true);

		future.ready(3000);
		Assert.isTrue(future.isError, "Future.ready() gave up waiting for its threaded work to fail");
		Assert.equals("failed", future.error);
	}

	public function testThreadedPromiseWorkReportsProgressAndCompletes():Void
	{
		var promise = new Promise<Int>();
		var progress = [];
		promise.future.onProgress(function(loaded, total) progress.push(loaded + "/" + total));
		promise.completeAsync(countToThree, {count: 0}, MULTI_THREADED);

		Assert.equals(3, promise.future.result(3000), "Future.result() gave up waiting for threaded work");
		Assert.equals("1/3,2/3", progress.join(","));
	}

	public function testSingleThreadedPromiseWorkCanBeWaitedFor():Void
	{
		var promise = new Promise<Int>();
		promise.completeAsync(countToThree, {count: 0}, SINGLE_THREADED);
		Assert.equals(3, promise.future.result(3000), "Future.result() gave up waiting for single-threaded work");
	}

	public function testFuturesCanBeWaitedForWhileHandlingAnother():Void
	{
		var first = new Future(function() return 1, true);
		var second = new Future(function() return 2, true);
		var nested:Null<Int> = null;
		first.onComplete(function(value) nested = second.result(3000));

		Assert.equals(1, first.result(3000));
		Assert.equals(2, nested, "a future waited for while handling another gave up");
	}

	public function testWaitingReturnsAtOnceForOtherFutures():Void
	{
		// Nothing runs that would complete this future, so waiting can't help
		var promise = new Promise<Int>();
		var start = Timer.stamp();

		Assert.isNull(promise.future.result(2000));
		Assert.isTrue(Timer.stamp() - start < 0.5, "Future.result() waited " + Math.round((Timer.stamp() - start) * 1000) + " ms for a future nothing would complete");
	}

	public function testWaitingDoesNotWaitByDefault():Void
	{
		var future = new Future(function()
		{
			Sys.sleep(0.5);
			return true;
		}, true);

		var start = Timer.stamp();
		Assert.isNull(future.result());
		Assert.isTrue(Timer.stamp() - start < 0.25, "Future.result() waited without a wait time");

		Assert.isTrue(future.result(3000));
	}

	private static function countToThree(state:Dynamic, output:WorkOutput):Void
	{
		state.count++;

		if (state.count < 3)
		{
			output.sendProgress({progress: state.count, total: 3});
		}
		else
		{
			output.sendComplete(state.count);
		}
	}
	#end
}
