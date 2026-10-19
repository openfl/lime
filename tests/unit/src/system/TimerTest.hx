package system;

import haxe.Int64;
import haxe.Timer;
import lime.app.Application;
import lime.system.System;
import utest.Assert;
import utest.Test;
#if (lime_cffi && !macro)
import haxe.MainLoop;
#end
#if (lime_threads && !html5)
import lime.app.Future;
#end

// Applications can run for longer than an Int millisecond count holds, which is
// 2^31 ms, or 24.8 days. Building with -Dsimulate_uptime=<ms> starts the timer
// that far in, and CI also runs the tests with it starting just short of 2^31 ms,
// so they run where getTimer wraps around.
class TimerTest extends Test
{
	public function new()
	{
		super();
	}

	public function testGetTimerWrapsAround():Void
	{
		// getTimer is the low 32 bits of the timer, as a signed Int, so past
		// 2^31 ms it goes negative. The timer is read until it stays on one
		// millisecond throughout.
		var time:Float;
		var timer:Int;

		do
		{
			time = Math.ffloor(@:privateAccess System.__getTimer());
			timer = System.getTimer();
		}
		while (Math.ffloor(@:privateAccess System.__getTimer()) != time);

		Assert.equals(Int64.fromFloat(time).low, timer, "getTimer gave " + timer + " with the timer at " + time + " ms");
	}

	#if (lime_cffi && !macro)
	public function testStampKeepsCounting():Void
	{
		// Lime's Timer.stamp is the same timer in seconds, past where getTimer wraps
		var time = @:privateAccess System.__getTimer() / 1000;
		var stamp = Timer.stamp();

		Assert.isTrue(stamp >= time && stamp - time < 0.05, "Timer.stamp gave " + stamp + " s with the timer at " + time + " s");
	}

	public function testTimersFire():Void
	{
		var repeats = 0;
		var repeating = new Timer(10);
		repeating.run = function() repeats++;

		var delayed = false;
		Timer.delay(function() delayed = true, 30);

		var ran = false;
		var event:MainEvent = null;
		event = MainLoop.add(function()
		{
			ran = true;
			event.stop();
		});
		event.delay(0.03);

		runTimers(0.25);
		repeating.stop();

		Assert.isTrue(repeats >= 5, "a 10 ms Timer fired " + repeats + " times in 0.25 s");
		Assert.isTrue(delayed, "Timer.delay did not call back after 30 ms");
		Assert.isTrue(ran, "a MainLoop event delayed by 30 ms did not run");
	}

	public function testTimersFireAcrossTheWrap():Void
	{
		// getTimer goes negative 2^31 ms past each multiple of 2^32 ms. This waits
		// for that when it is near, as with the simulated uptime of the CI run.
		var time = @:privateAccess System.__getTimer();
		var wrap = time - (time + 2147483648.0) % 4294967296.0 + 4294967296.0;

		if (wrap - time > 15000)
		{
			Assert.pass();
			return;
		}

		var repeats = 0;
		var repeating = new Timer(10);
		repeating.run = function()
		{
			if (@:privateAccess System.__getTimer() >= wrap) repeats++;
		};

		runTimers((wrap - time) / 1000 + 0.5);
		repeating.stop();

		Assert.isTrue(repeats >= 10, "a 10 ms Timer fired " + repeats + " times in the 0.5 s after getTimer wrapped");
		Assert.isTrue(Timer.stamp() * 1000 >= wrap, "Timer.stamp stopped at " + Timer.stamp() + " s");
	}

	private static function runTimers(seconds:Float):Void
	{
		// Timers fire as each frame begins, which the tests stand in for here. The
		// wall clock times the wait, since the timer is what is being tested.
		var end = Sys.time() + seconds;

		while (Sys.time() < end)
		{
			@:privateAccess Application.current.__backend.updateTimer();
			Sys.sleep(0.001);
		}
	}
	#end

	#if (lime_threads && !html5)
	public function testFutureReadyStopsWaitingAtItsTimeout():Void
	{
		var future = new Future(function()
		{
			Sys.sleep(0.5);
			return true;
		}, true);

		// ready() only waits for a job the main loop has seen start, which it
		// learns of in its updates
		var end = Sys.time() + 5;

		while (FutureWork.activeJobs == 0 && Sys.time() < end)
		{
			Application.current.onUpdate.dispatch(0);
			Sys.sleep(0.001);
		}

		var start = Sys.time();
		future.ready(100);
		var waited = Math.round((Sys.time() - start) * 1000);

		// isComplete is null until set on Neko
		Assert.isTrue(!future.isComplete, "the job finished within ready(100)");
		Assert.isTrue(waited >= 90 && waited < 400, "ready(100) waited " + waited + " ms");
	}
	#end
}
