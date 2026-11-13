package app;

import haxe.Timer;
import lime.app.Future;
import lime.app.Promise;
import lime.system.WorkOutput;
import lime.system.WorkOutput.ThreadMode;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	A `Promise` sets the outcome of its `Future`. The docs describe a future as
	immutable once it has finished, so these take the first outcome a promise is
	given to be the one that stays, as other promise libraries do.
**/
class PromiseTest extends Test
{
	public function new()
	{
		super();
	}

	#if neko
	@Ignored("Waiting on #2146")
	#end
	public function testPromiseStartsUnresolved():Void
	{
		var promise = new Promise<Int>();

		Assert.notNull(promise.future);
		Assert.equals(false, promise.isComplete, "isComplete");
		Assert.equals(false, promise.isError, "isError");
		Assert.equals(false, promise.future.isComplete, "future.isComplete");
		Assert.equals(false, promise.future.isError, "future.isError");
	}

	public function testCompleteNotifiesListenersAddedBefore():Void
	{
		var promise = new Promise<Int>();
		var received:Array<Int> = [];
		var errors = 0;

		promise.future.onComplete(function(value) received.push(value));
		promise.future.onError(function(_) errors++);

		Assert.equals(promise, promise.complete(4));
		Assert.same([4], received);
		Assert.equals(0, errors);
		Assert.isTrue(promise.isComplete);
		assertUnset(promise.isError);
		Assert.equals(4, promise.future.value);
	}

	public function testErrorNotifiesListenersAddedBefore():Void
	{
		var promise = new Promise<Int>();
		var received:Array<String> = [];
		var completions = 0;

		promise.future.onError(function(error) received.push(error));
		promise.future.onComplete(function(_) completions++);

		Assert.equals(promise, promise.error("failed"));
		Assert.same(["failed"], received);
		Assert.equals(0, completions);
		Assert.isTrue(promise.isError);
		assertUnset(promise.isComplete);
		Assert.equals("failed", promise.future.error);
	}

	public function testProgressReachesListenersInOrder():Void
	{
		var promise = new Promise<Int>();
		var progress:Array<String> = [];

		promise.future.onProgress(function(loaded, total) progress.push(loaded + "/" + total));

		Assert.equals(promise, promise.progress(1, 3));
		promise.progress(2, 3);
		Assert.same(["1/3", "2/3"], progress);
		assertUnset(promise.isComplete);
	}

	@Ignored("Waiting on #2146")
	public function testCompletingTwiceKeepsTheFirstValue():Void
	{
		var promise = new Promise<Int>();
		var received:Array<Int> = [];

		promise.future.onComplete(function(value) received.push(value));
		promise.complete(1);
		promise.complete(2);

		Assert.equals(1, promise.future.value);
		Assert.same([1], received);
	}

	public function testErrorAfterCompletionIsIgnored():Void
	{
		var promise = new Promise<Int>();
		var errors:Array<String> = [];

		promise.future.onError(function(error) errors.push(error));
		promise.complete(1);
		promise.error("late");

		Assert.isTrue(promise.isComplete);
		assertUnset(promise.isError);
		Assert.isNull(promise.future.error);
		Assert.same([], errors);
	}

	public function testCompletionAfterAnErrorIsIgnored():Void
	{
		// A String, since an unset Int value reads as 0 rather than null on static targets
		var promise = new Promise<String>();
		var received:Array<String> = [];

		promise.future.onComplete(function(value) received.push(value));
		promise.error("failed");
		promise.complete("done");

		Assert.isTrue(promise.isError);
		assertUnset(promise.isComplete);
		Assert.equals("failed", promise.future.error);
		Assert.isNull(promise.future.value);
		Assert.same([], received);
	}

	@Ignored("Waiting on #2146")
	public function testFailingTwiceKeepsTheFirstError():Void
	{
		var promise = new Promise<Int>();
		var errors:Array<String> = [];

		promise.future.onError(function(error) errors.push(error));
		promise.error("first");
		promise.error("second");

		Assert.equals("first", promise.future.error);
		Assert.same(["first"], errors);
	}

	public function testProgressAfterCompletionIsNotReported():Void
	{
		var promise = new Promise<Int>();
		var progress:Array<String> = [];

		promise.future.onProgress(function(loaded, total) progress.push(loaded + "/" + total));
		promise.progress(1, 2);
		promise.complete(1);
		promise.progress(2, 2);

		Assert.same(["1/2"], progress);
	}

	public function testProgressAfterAnErrorIsNotReported():Void
	{
		var promise = new Promise<Int>();
		var progress:Array<String> = [];

		promise.future.onProgress(function(loaded, total) progress.push(loaded + "/" + total));
		promise.error("failed");
		promise.progress(1, 2);

		Assert.same([], progress);
	}

	public function testCompleteWithForwardsALaterValueAndProgress():Void
	{
		var promise = new Promise<Int>();
		var other = new Promise<Int>();
		var progress:Array<String> = [];

		promise.future.onProgress(function(loaded, total) progress.push(loaded + "/" + total));
		Assert.equals(promise, promise.completeWith(other.future));
		assertUnset(promise.isComplete);

		other.progress(1, 2);
		other.complete(3);

		Assert.same(["1/2"], progress);
		Assert.isTrue(promise.isComplete);
		Assert.equals(3, promise.future.value);
	}

	public function testCompleteWithForwardsALaterError():Void
	{
		var promise = new Promise<Int>();
		var other = new Promise<Int>();

		promise.completeWith(other.future);
		other.error("failed");

		Assert.isTrue(promise.isError);
		Assert.equals("failed", promise.future.error);
	}

	public function testCompleteWithAFinishedFutureResolvesAtOnce():Void
	{
		var promise = new Promise<Int>();
		promise.completeWith(Future.withValue(8));

		Assert.isTrue(promise.isComplete);
		Assert.equals(8, promise.future.value);
	}

	public function testCompleteWithAFailedFutureFailsAtOnce():Void
	{
		var promise = new Promise<Int>();
		promise.completeWith(cast Future.withError("failed"));

		Assert.isTrue(promise.isError);
		Assert.equals("failed", promise.future.error);
	}

	#if (lime_threads && !html5)
	// Unlike FutureTest, which blocks with result(), these leave the work to be
	// reported by the application's own loop
	@:timeout(5000)
	public function testCompleteAsyncReportsThroughTheApplicationLoop(async:Async):Void
	{
		expectCountToThree(MULTI_THREADED, async);
	}

	@:timeout(5000)
	public function testSingleThreadedCompleteAsyncReportsThroughTheApplicationLoop(async:Async):Void
	{
		expectCountToThree(SINGLE_THREADED, async);
	}

	@:timeout(5000)
	public function testCompleteAsyncReportsErrorsSent(async:Async):Void
	{
		var promise = new Promise<Int>();

		promise.future.onComplete(function(value)
		{
			Assert.fail("completed with " + value + " after its work sent an error");
			async.done();
		});
		promise.future.onError(function(error)
		{
			Assert.equals("failed", error);
			Assert.isTrue(promise.isError);
			async.done();
		});

		promise.completeAsync(sendError, {}, MULTI_THREADED);
	}

	@:timeout(5000)
	public function testCompletingWhileAsyncWorkRunsKeepsThatValue(async:Async):Void
	{
		var promise = new Promise<Int>();
		var received:Array<Int> = [];

		promise.future.onComplete(function(value) received.push(value));
		promise.completeAsync(completeAfterAWhile, {seconds: 0.1}, MULTI_THREADED);
		promise.complete(2);

		Timer.delay(function()
		{
			Assert.equals(2, promise.future.value);
			Assert.same([2], received);
			async.done();
		}, 500);
	}

	private static function expectCountToThree(mode:ThreadMode, async:Async):Void
	{
		var promise = new Promise<Int>();
		var progress:Array<String> = [];

		promise.future.onProgress(function(loaded, total) progress.push(loaded + "/" + total));
		promise.future.onComplete(function(value)
		{
			Assert.equals(3, value);
			Assert.equals("1/3,2/3", progress.join(","));
			Assert.isTrue(promise.isComplete);
			async.done();
		});
		promise.future.onError(function(error)
		{
			Assert.fail("failed with " + error);
			async.done();
		});

		promise.completeAsync(countToThree, {count: 0}, mode);
		assertUnset(promise.isComplete, "completeAsync() finished before returning");
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

	private static function sendError(state:Dynamic, output:WorkOutput):Void
	{
		output.sendError("failed");
	}

	private static function completeAfterAWhile(state:Dynamic, output:WorkOutput):Void
	{
		Sys.sleep(state.seconds);
		output.sendComplete(1);
	}
	#end

	// Only whether a flag was set; that the flags start out false is tested on its own
	private static function assertUnset(flag:Bool, ?message:String, ?pos:haxe.PosInfos):Void
	{
		Assert.isTrue(flag != true, message != null ? message : "the flag was set", pos);
	}
}
