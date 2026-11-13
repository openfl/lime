package app;

import haxe.Timer;
import lime.app.Event;
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

	// Documented as Bools, so false rather than null on every target
	#if neko
	@Ignored("Waiting on #2146")
	#end
	public function testStateFlagsAreFalseUntilSet():Void
	{
		var pending = new Future<Int>();
		Assert.equals(false, pending.isComplete, "isComplete of a pending future");
		Assert.equals(false, pending.isError, "isError of a pending future");
		Assert.equals(false, Future.withValue(1).isError, "isError of a complete future");
		Assert.equals(false, Future.withError("failed").isComplete, "isComplete of a failed future");
	}

	public function testWithValueIsAlreadyComplete():Void
	{
		var future = Future.withValue(5);

		Assert.isTrue(future.isComplete);
		assertUnset(future.isError);
		Assert.equals(5, future.value);
		Assert.isNull(future.error);
	}

	public function testWithErrorIsAlreadyFailed():Void
	{
		var future = Future.withError("failed");

		Assert.isTrue(future.isError);
		assertUnset(future.isComplete);
		Assert.equals("failed", future.error);
		Assert.isNull(future.value);
	}

	public function testWorkWithoutThreadsRunsAtOnce():Void
	{
		var future = new Future(function() return 3);

		Assert.isTrue(future.isComplete);
		Assert.equals(3, future.value);
	}

	// Documented for threaded work only, and tested in the threaded tests above
	public function testWorkWithoutThreadsThatThrowsFails():Void
	{
		var future = new Future(function():Int
		{
			throw "failed";
		});

		Assert.isTrue(future.isError);
		assertUnset(future.isComplete);
		Assert.equals("failed", future.error);
	}

	public function testCompleteListenersAddedAfterCompletionRunOnce():Void
	{
		var future = Future.withValue("done");
		var received:Array<String> = [];

		Assert.equals(future, future.onComplete(function(value) received.push("first " + value)));
		Assert.same(["first done"], received);

		future.onComplete(function(value) received.push("second " + value));
		Assert.same(["first done", "second done"], received);
	}

	public function testErrorListenersAddedAfterFailureRunOnce():Void
	{
		var future = Future.withError("failed");
		var received:Array<String> = [];

		Assert.equals(future, future.onError(function(error) received.push("first " + error)));
		Assert.same(["first failed"], received);

		future.onError(function(error) received.push("second " + error));
		Assert.same(["first failed", "second failed"], received);
	}

	public function testListenersForTheOtherOutcomeAreNotCalled():Void
	{
		var calls = 0;

		Future.withValue(1).onError(function(_) calls++);
		Future.withError("failed").onComplete(function(_) calls++);

		Assert.equals(0, calls);
	}

	public function testProgressListenersAddedAfterCompletionAreNotCalled():Void
	{
		var future = Future.withValue(1);
		var calls = 0;

		Assert.equals(future, future.onProgress(function(loaded, total) calls++));
		Assert.equals(0, calls);
	}

	public function testReadyAndResultReturnAtOnceForCompleteFutures():Void
	{
		var future = Future.withValue(7);
		var start = Timer.stamp();

		Assert.equals(future, future.ready());
		Assert.equals(future, future.ready(1000));
		Assert.equals(7, future.result());
		Assert.equals(7, future.result(1000));
		Assert.isTrue(Timer.stamp() - start < 0.5, "waiting on a complete future took " + Math.round((Timer.stamp() - start) * 1000) + " ms");
	}

	public function testResultIsNullForFailedFutures():Void
	{
		var future = Future.withError("failed");
		var start = Timer.stamp();

		Assert.equals(future, future.ready(1000));
		Assert.isNull(future.result());
		Assert.isNull(future.result(1000));
		Assert.isTrue(Timer.stamp() - start < 0.5, "waiting on a failed future took " + Math.round((Timer.stamp() - start) * 1000) + " ms");
	}

	public function testThenMapsTheValue():Void
	{
		var future = Future.withValue(2).then(function(value) return Future.withValue("value " + (value * 10)));

		Assert.isTrue(future.isComplete);
		Assert.equals("value 20", future.value);
	}

	public function testThenWaitsForBothFutures():Void
	{
		var first = new Promise<Int>();
		var second = new Promise<String>();
		var received:Array<Int> = [];

		var chained = first.future.then(function(value)
		{
			received.push(value);
			return second.future;
		});

		assertUnset(chained.isComplete);
		first.complete(1);
		Assert.same([1], received);
		assertUnset(chained.isComplete, "the chained future completed before the future its callback returned");

		second.complete("two");
		Assert.isTrue(chained.isComplete);
		Assert.equals("two", chained.value);
	}

	public function testThenCallbacksRunOncePerChain():Void
	{
		var promise = new Promise<Int>();
		var calls = 0;
		var received:Array<Int> = [];

		promise.future.then(function(value)
		{
			calls++;
			return Future.withValue(value + 1);
		}).onComplete(function(value) received.push(value));

		promise.complete(1);
		promise.complete(5);
		Assert.equals(1, calls);
		Assert.same([2], received);
	}

	public function testThenIsSkippedAfterAnError():Void
	{
		var called = false;
		var chained = Future.withError("failed").then(function(value)
		{
			called = true;
			return Future.withValue(1);
		});

		Assert.isFalse(called);
		Assert.isTrue(chained.isError);
		assertUnset(chained.isComplete);
		Assert.equals("failed", chained.error);
	}

	public function testErrorsPropagateThroughAChain():Void
	{
		var promise = new Promise<Int>();
		var calls = 0;
		var errors:Array<String> = [];

		promise.future.then(function(value)
		{
			calls++;
			return Future.withValue(value + 1);
		}).then(function(value)
		{
			calls++;
			return Future.withValue(value + 1);
		}).onError(function(error) errors.push(error));

		promise.error("failed");
		Assert.equals(0, calls);
		Assert.same(["failed"], errors);
	}

	public function testThenTakesTheErrorOfTheFutureItsCallbackReturns():Void
	{
		var chained = Future.withValue(1).then(function(value):Future<Int>
		{
			return cast Future.withError("inner");
		});

		Assert.isTrue(chained.isError);
		Assert.equals("inner", chained.error);
	}

	// The docs say errors propagate along a chain; as with other promise
	// libraries, an exception from a callback is taken to be that error
	@Ignored("Waiting on #2147")
	public function testThenCallbackThatThrowsFailsTheChain():Void
	{
		var chained:Future<Int> = null;
		var escaped:Dynamic = null;

		try
		{
			chained = Future.withValue(1).then(function(value):Future<Int>
			{
				throw "thrown";
			});
		}
		catch (e:Dynamic)
		{
			escaped = e;
		}

		Assert.isNull(escaped, "the exception escaped then(): " + escaped);

		if (chained != null)
		{
			Assert.isTrue(chained.isError);
			Assert.equals("thrown", chained.error);
		}
	}

	@Ignored("Waiting on #2147")
	public function testThenCallbackThatThrowsLaterFailsTheChain():Void
	{
		var promise = new Promise<Int>();
		var errors:Array<String> = [];
		var escaped:Dynamic = null;

		promise.future.then(function(value):Future<Int>
		{
			throw "thrown";
		}).onError(function(error) errors.push(Std.string(error)));

		try
		{
			promise.complete(1);
		}
		catch (e:Dynamic)
		{
			escaped = e;
		}

		Assert.isNull(escaped, "the exception escaped Promise.complete(): " + escaped);
		Assert.same(["thrown"], errors);
		Assert.isTrue(promise.future.isComplete, "the first future did not keep its value");
	}

	// ofEvents() takes an Event<T->Void>, which Event's generic build makes a class
	// of its own that no concrete event is, so it can't be called without a cast,
	// and the cast only holds where fields are looked up by name
	#if (neko || js)
	public function testOfEventsCompletesWithTheCompleteEvent():Void
	{
		var complete = new Event<Int->Void>();
		var error = new Event<Dynamic->Void>();
		var progress = new Event<Int->Int->Void>();
		var future:Future<Int> = Future.ofEvents(cast complete, error, progress);
		var progressed:Array<String> = [];

		future.onProgress(function(loaded, total) progressed.push(loaded + "/" + total));
		assertUnset(future.isComplete);

		progress.dispatch(1, 2);
		complete.dispatch(5);

		Assert.isTrue(future.isComplete);
		Assert.equals(5, future.value);
		Assert.same(["1/2"], progressed);
	}

	#if neko
	@Ignored("Waiting on #2148")
	#end
	public function testOfEventsForwardsEveryProgressUpdate():Void
	{
		var complete = new Event<Int->Void>();
		var progress = new Event<Int->Int->Void>();
		var future:Future<Int> = Future.ofEvents(cast complete, null, progress);
		var progressed:Array<String> = [];

		future.onProgress(function(loaded, total) progressed.push(loaded + "/" + total));

		progress.dispatch(1, 3);
		progress.dispatch(2, 3);
		complete.dispatch(3);

		Assert.same(["1/3", "2/3"], progressed);
	}

	public function testOfEventsFailsWithTheErrorEvent():Void
	{
		var complete = new Event<Int->Void>();
		var error = new Event<Dynamic->Void>();
		var future:Future<Int> = Future.ofEvents(cast complete, error);

		error.dispatch("failed");

		Assert.isTrue(future.isError);
		assertUnset(future.isComplete);
		Assert.equals("failed", future.error);
	}

	public function testOfEventsWorksWithACompleteEventAlone():Void
	{
		var complete = new Event<String->Void>();
		var future:Future<String> = Future.ofEvents(cast complete);

		complete.dispatch("done");
		Assert.equals("done", future.value);
	}

	public function testOfEventsKeepsTheFirstOutcome():Void
	{
		var complete = new Event<Int->Void>();
		var error = new Event<Dynamic->Void>();
		var progress = new Event<Int->Int->Void>();
		var future:Future<Int> = Future.ofEvents(cast complete, error, progress);
		var calls:Array<String> = [];

		future.onComplete(function(value) calls.push("complete " + value));
		future.onError(function(error) calls.push("error " + error));
		future.onProgress(function(loaded, total) calls.push("progress " + loaded));

		complete.dispatch(5);
		complete.dispatch(6);
		error.dispatch("late");
		progress.dispatch(3, 3);

		Assert.equals(5, future.value);
		assertUnset(future.isError);
		Assert.same(["complete 5"], calls);
	}
	#end

	// Only whether a flag was set; that the flags start out false is tested on its own
	private static function assertUnset(flag:Bool, ?message:String, ?pos:haxe.PosInfos):Void
	{
		Assert.isTrue(flag != true, message != null ? message : "the flag was set", pos);
	}
}
