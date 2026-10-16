package system;

import haxe.Timer;
import lime.system.ThreadPool;
import lime.system.WorkOutput;
import utest.Assert;
import utest.Test;
#if target.threaded
import sys.thread.Mutex;
import sys.thread.Tls;
#end

/**
	Jobs are run on the main thread or on threads of the pool's own, and report
	back on the main thread when the pool updates, which the tests do themselves
	as the application's loop would.
**/
class ThreadPoolTest extends Test
{
	// Starting threads can take a while on a busy CI runner
	private static inline var TIMEOUT = 10;

	#if target.threaded
	private static var concurrencyMutex:Mutex = new Mutex();
	private static var running:Int = 0;
	private static var mostRunning:Int = 0;
	private static var jobsOnThread:Tls<Null<Int>> = new Tls();
	#end

	public function new()
	{
		super();
	}

	#if target.threaded
	public function testSingleThreadedJobsRunOnTheMainThread():Void
	{
		var pool = new ThreadPool(0, 1, SINGLE_THREADED);
		var events = [];
		pool.onRun.add(function(state) events.push("run"));
		pool.onProgress.add(function(message) events.push("progress " + Std.string(message)));
		pool.onComplete.add(function(message) events.push("complete " + Std.string(message)));

		pool.run(countToThree, {count: 0, onMainThread: true});
		pumpUntil(pool, function() return events.length >= 4);

		Assert.equals("run,progress 1,progress 2,complete main", events.join(","));
		Assert.equals(0, pool.activeJobs);
	}

	public function testMultiThreadedJobsRunOnAThreadAndReportOnTheMainThread():Void
	{
		var pool = new ThreadPool(0, 1, MULTI_THREADED);
		var workedOnMainThread:Null<Bool> = null;
		var reportedOnMainThread = false;
		pool.onComplete.add(function(message)
		{
			workedOnMainThread = message;
			reportedOnMainThread = ThreadPool.isMainThread();
		});

		pool.run(reportThread);
		pumpUntil(pool, function() return workedOnMainThread != null);

		Assert.isFalse(workedOnMainThread, "the job ran on the main thread");
		Assert.isTrue(reportedOnMainThread, "onComplete was dispatched on another thread");
	}

	public function testProgressArrivesInOrderBeforeCompletion():Void
	{
		var pool = new ThreadPool(0, 1, MULTI_THREADED);
		var events = [];
		pool.onProgress.add(function(message) events.push("progress " + Std.string(message)));
		pool.onComplete.add(function(message) events.push("complete " + Std.string(message)));

		pool.run(countToThree, {count: 0, onMainThread: false});
		pumpUntil(pool, function() return events.length >= 3);

		Assert.equals("progress 1,progress 2,complete worker", events.join(","));
	}

	public function testJobsBeyondMaxThreadsWaitTheirTurn():Void
	{
		var pool = new ThreadPool(0, 2, MULTI_THREADED);
		var completed = 0;
		var mostThreads = 0;
		pool.onComplete.add(function(message) completed++);

		resetConcurrency();
		for (i in 0...8)
		{
			pool.run(sleepBriefly, {seconds: 0.02});
		}

		pumpUntil(pool, function()
		{
			if (pool.currentThreads > mostThreads) mostThreads = pool.currentThreads;
			return completed == 8;
		});

		Assert.equals(8, completed);
		Assert.isTrue(mostRunning <= 2, mostRunning + " jobs ran at once with maxThreads 2");
		Assert.isTrue(mostThreads <= 2, mostThreads + " threads were started with maxThreads 2");
	}

	public function testEveryJobCompletesOnceWithItsOwnState():Void
	{
		var pool = new ThreadPool(0, 4, MULTI_THREADED);
		var results = [for (i in 0...50) 0];
		var mismatched = 0;
		pool.onComplete.add(function(message:Int)
		{
			results[message]++;
			if (pool.activeJob == null || pool.activeJob.state.index != message) mismatched++;
		});

		for (i in 0...50)
		{
			pool.run(echoIndex, {index: i});
		}

		pumpUntil(pool, function() return Lambda.fold(results, function(count, total) return total + count, 0) >= 50);

		Assert.equals(0, mismatched, "activeJob did not match the completing job");
		for (i in 0...50)
		{
			Assert.equals(1, results[i], "job " + i + " completed " + results[i] + " times");
		}
	}

	public function testErrorsAreReportedInsteadOfCompletion():Void
	{
		var pool = new ThreadPool(0, 1, MULTI_THREADED);
		var errors = [];
		var completed = 0;
		pool.onError.add(function(message) errors.push(message));
		pool.onComplete.add(function(message) completed++);

		pool.run(failWithError);
		pumpUntil(pool, function() return errors.length > 0);

		Assert.equals("failed", errors.join(","));
		Assert.equals(0, completed);
	}

	#if (haxe_ver >= 4.1)
	public function testUncaughtErrorsAreReported():Void
	{
		var pool = new ThreadPool(0, 1, MULTI_THREADED);
		var messages = [];
		pool.onUncaughtError.add(function(error) messages.push(error.message));

		pool.run(throwError);
		pumpUntil(pool, function() return messages.length > 0);

		Assert.equals("thrown", messages.join(","));
	}
	#end

	public function testCanceledJobsReportNothingMore():Void
	{
		var pool = new ThreadPool(0, 1, MULTI_THREADED);
		var runs = 0;
		var progress = 0;
		pool.onRun.add(function(state) runs++);
		pool.onProgress.add(function(message) progress++);

		var running = pool.run(progressForever, {});
		var queued = pool.run(progressForever, {});
		pumpUntil(pool, function() return progress > 0);

		Assert.isTrue(pool.cancelJob(queued), "the queued job was not canceled");
		Assert.isTrue(pool.cancelJob(running), "the running job was not canceled");
		var progressWhenCanceled = progress;
		pumpFor(pool, 0.3);

		Assert.equals(1, runs, "the canceled queued job started");
		Assert.isTrue(progress <= progressWhenCanceled + 1, "the canceled job kept reporting progress");
		Assert.equals(0, pool.activeJobs);
	}

	public function testCancelReportsItsErrorForEachJob():Void
	{
		var pool = new ThreadPool(0, 1, MULTI_THREADED);
		var errors = [];
		pool.onError.add(function(message) errors.push(message));
		var progress = 0;
		pool.onProgress.add(function(message) progress++);

		for (i in 0...3)
		{
			pool.run(progressForever, {});
		}

		pumpUntil(pool, function() return progress > 0);
		pool.cancel("stopped");
		pumpFor(pool, 0.2);

		Assert.equals("stopped,stopped,stopped", errors.join(","));
		Assert.equals(0, pool.activeJobs);
	}

	public function testIdleThreadsBeyondTheMinimumExit():Void
	{
		for (minThreads in [0, 2])
		{
			var pool = new ThreadPool(minThreads, 4, MULTI_THREADED);
			var completed = 0;
			pool.onComplete.add(function(message) completed++);

			for (i in 0...4)
			{
				pool.run(sleepBriefly, {seconds: 0.02});
			}

			pumpUntil(pool, function() return completed == 4 && pool.currentThreads <= minThreads);

			Assert.equals(4, completed);
			Assert.equals(minThreads, pool.currentThreads, "threads left with minThreads " + minThreads);
		}
	}

	public function testIdleThreadsWaitForMoreWork():Void
	{
		// A job that comes soon after another goes to the same thread
		var pool = new ThreadPool(0, 1, MULTI_THREADED);
		pool.idleTimeout = 5;
		var results = [];
		pool.onComplete.add(function(message) results.push(message));

		pool.run(countJobsOnThread);
		pumpUntil(pool, function() return results.length == 1);
		pumpFor(pool, 0.1);
		Assert.equals(1, pool.currentThreads, "the idle thread exited before its timeout");

		pool.run(countJobsOnThread);
		pumpUntil(pool, function() return results.length == 2);
		Assert.equals(2, results[1], "the second job ran on a thread of its own");

		pool.idleTimeout = 0;
		pumpUntil(pool, function() return pool.currentThreads == 0);
	}

	public function testIdleThreadsExitAfterTheirTimeout():Void
	{
		var pool = new ThreadPool(0, 1, MULTI_THREADED);
		pool.idleTimeout = 0.3;
		var completedAt = -1.0;
		pool.onComplete.add(function(message) completedAt = Timer.stamp());

		pool.run(echoIndex, {index: 0});
		pumpUntil(pool, function() return completedAt >= 0 && pool.currentThreads == 0);
		var idle = Timer.stamp() - completedAt;

		Assert.equals(0, pool.currentThreads, "the idle thread never exited");
		Assert.isTrue(idle >= 0.25, "the idle thread exited after " + Math.round(idle * 1000) + " ms, with a timeout of 300 ms");
	}

	public function testSingleThreadedWorkKeepsToItsShareOfAFrame():Void
	{
		// Work that waits, as on files or a server, uses up the share of a
		// frame as much as work that computes
		var pool = new ThreadPool(0, 1, SINGLE_THREADED);
		var state = {calls: 0};
		pool.run(waitBriefly, state);

		@:privateAccess pool.__update(16);
		pool.cancel();

		// Counts calls rather than time: a stalled runner makes a call last
		// longer but never adds calls, while work with no limit makes all
		// 1000 of them in one update
		var share = ThreadPool.workLoad / 60;
		var room = Math.ceil(share * 1000);
		Assert.isTrue(state.calls <= room * 2, "one update made " + state.calls + " calls of at least 1 ms, with a share of "
			+ Math.round(share * 1000) + " ms");
	}

	public function testManyShortJobsAllComplete():Void
	{
		// Many short jobs make threads wait on the job queue again and again
		var pool = new ThreadPool(0, 4, MULTI_THREADED);
		var completed = 0;
		pool.onComplete.add(function(message) completed++);

		for (i in 0...2000)
		{
			pool.run(echoIndex, {index: i});
		}

		pumpUntil(pool, function() return completed == 2000);
		Assert.equals(2000, completed);
	}

	// Work functions

	private static function countToThree(state:Dynamic, output:WorkOutput):Void
	{
		state.count++;

		if (state.count < 3)
		{
			output.sendProgress(state.count);
		}
		else
		{
			output.sendComplete(ThreadPool.isMainThread() ? "main" : "worker");
		}
	}

	private static function countJobsOnThread(state:Dynamic, output:WorkOutput):Void
	{
		var count:Null<Int> = jobsOnThread.value;
		jobsOnThread.value = count = (count == null ? 0 : count) + 1;
		output.sendComplete(count);
	}

	private static function echoIndex(state:Dynamic, output:WorkOutput):Void
	{
		output.sendComplete(state.index);
	}

	private static function failWithError(state:Dynamic, output:WorkOutput):Void
	{
		output.sendError("failed");
	}

	private static function progressForever(state:Dynamic, output:WorkOutput):Void
	{
		Sys.sleep(0.005);
		output.sendProgress(0);
	}

	private static function reportThread(state:Dynamic, output:WorkOutput):Void
	{
		output.sendComplete(ThreadPool.isMainThread());
	}

	private static function sleepBriefly(state:Dynamic, output:WorkOutput):Void
	{
		concurrencyMutex.acquire();
		running++;
		if (running > mostRunning) mostRunning = running;
		concurrencyMutex.release();

		Sys.sleep(state.seconds);

		concurrencyMutex.acquire();
		running--;
		concurrencyMutex.release();

		output.sendComplete();
	}

	private static function throwError(state:Dynamic, output:WorkOutput):Void
	{
		throw "thrown";
	}

	private static function waitBriefly(state:Dynamic, output:WorkOutput):Void
	{
		// Waits a millisecond at a time, and stops after a second in all
		Sys.sleep(0.001);
		state.calls++;
		if (state.calls >= 1000) output.sendComplete();
	}

	// Helpers

	private static function pumpFor(pool:ThreadPool, seconds:Float):Void
	{
		var end = Timer.stamp() + seconds;

		while (Timer.stamp() < end)
		{
			@:privateAccess pool.__update(16);
			Sys.sleep(0.002);
		}
	}

	private static function pumpUntil(pool:ThreadPool, done:Void->Bool):Void
	{
		var end = Timer.stamp() + TIMEOUT;

		while (!done() && Timer.stamp() < end)
		{
			@:privateAccess pool.__update(16);
			Sys.sleep(0.002);
		}
	}

	private static function resetConcurrency():Void
	{
		concurrencyMutex.acquire();
		running = 0;
		mostRunning = 0;
		concurrencyMutex.release();
	}
	#end
}
