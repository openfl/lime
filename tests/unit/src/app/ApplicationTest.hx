package app;

import haxe.Timer;
import lime.app.Application;
import utest.Assert;
import utest.Async;
import utest.Test;

class ApplicationTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	private var idleTimeChanged:Bool = false;
	private var previousIdleCallback:Void->Void;

	public function teardown():Void
	{
		restoreIdleTime();
	}

	@:timeout(5000)
	public function testTheTimeBeforeAFrameIsReported(async:Async):Void
	{
		var application = Application.current;
		var backend = @:privateAccess application.__backend;
		previousIdleCallback = @:privateAccess backend.__idleCallback;
		idleTimeChanged = true;

		// Frames this far apart leave idle time however long a frame takes here
		backend.configureFrameTiming(application.frameProfile, 10, application.frameOptions);

		@:privateAccess backend.__setIdleCallback(function()
		{
			var remaining = @:privateAccess backend.applicationEventInfo.deltaTime;
			restoreIdleTime();

			// The tests go on from here, so they leave the wait for a frame first
			Timer.delay(function()
			{
				Assert.isTrue(remaining >= 1, "an idle event left " + remaining + " ms before the frame");
				async.done();
			}, 1);
		});
	}

	// While every window is minimised, frames come at backgroundFrameRate, 30 by default,
	// however fast the application asks for them. The counts are per second of time
	// measured, as a timer's second may run long on a busy machine.
	@:timeout(15000)
	public function testAMinimisedApplicationUpdatesAtItsBackgroundFrameRate(async:Async):Void
	{
		countMinimisedUpdates(null, function(count)
		{
			if (count < 0)
			{
				async.done();
				return;
			}

			Assert.isTrue(count >= 10 && count <= 40, "a minimised application asking for 120 frames a second updated " + count + " times in a second");
			async.done();
		});
	}

	@:timeout(15000)
	public function testABackgroundFrameRateOfItsOwnIsKept(async:Async):Void
	{
		countMinimisedUpdates(withBackgroundFrameRate(10), function(count)
		{
			if (count >= 0) Assert.isTrue(count >= 4 && count <= 14, "with a background frame rate of 10, a minimised application updated " + count + " times in a second");
			async.done();
		});
	}

	@:timeout(15000)
	public function testABackgroundFrameRateOf0KeepsTheFullRate(async:Async):Void
	{
		countMinimisedUpdates(withBackgroundFrameRate(0), function(count)
		{
			// Well above the default cap of 30, but below 120: macOS slows the timers of
			// a minimised application, and a minimised Intel runner gave 79
			if (count >= 0) Assert.isTrue(count >= 50, "with a background frame rate of 0, a minimised application asking for 120 frames a second updated " + count + " times in a second");
			async.done();
		});
	}

	private static function withBackgroundFrameRate(rate:Float):lime.app.FrameOptions
	{
		var options = Application.current.frameOptions;
		options.backgroundFrameRate = rate;
		return options;
	}

	// Minimises every window, asks for 120 frames a second with options, and gives
	// how many updates a second came after, or -1 where windows can't be
	// minimised here. Everything is put back before done is called. A window is
	// minimised once its onMinimize comes: the minimized property says so as
	// soon as it is set, even where nothing minimises it, as on X11 without a
	// window manager.
	private function countMinimisedUpdates(options:lime.app.FrameOptions, done:Int->Void):Void
	{
		var application = Application.current;
		var backend = @:privateAccess application.__backend;
		var windows = [for (window in application.windows) if (!window.hidden && !window.minimized) window];

		if (windows.length == 0)
		{
			trace("There is no window to minimise here, so the background frame rate was not tested");
			Assert.pass();
			done(-1);
			return;
		}

		var minimisedWindows = 0;
		var onMinimize = function() minimisedWindows++;
		for (window in windows) window.onMinimize.add(onMinimize);

		var restore = function()
		{
			for (window in windows) window.onMinimize.remove(onMinimize);
			for (window in windows) window.minimized = false;
			backend.configureFrameTiming(application.frameProfile, @:privateAccess application.__frameRate, application.frameOptions);
		};

		backend.configureFrameTiming(application.frameProfile, 120, options != null ? options : application.frameOptions);
		for (window in windows) window.minimized = true;

		var start = Timer.stamp();
		var wait:Void->Void = null;

		wait = function()
		{
			if (minimisedWindows < windows.length)
			{
				if (Timer.stamp() - start > 3)
				{
					restore();
					trace("Windows could not be minimised here, so the background frame rate was not tested");
					Assert.pass();
					done(-1);
				}
				else
				{
					Timer.delay(wait, 50);
				}

				return;
			}

			// Counted once the change has settled
			Timer.delay(function()
			{
				var count = 0;
				var listener = function(_:Int) count++;
				var countStart = Timer.stamp();
				application.onUpdate.add(listener);

				Timer.delay(function()
				{
					application.onUpdate.remove(listener);
					var rate = Math.round(count / (Timer.stamp() - countStart));
					restore();

					// The tests go on once the windows are back
					Timer.delay(function() done(rate), 200);
				}, 1000);
			}, 300);
		};

		Timer.delay(wait, 50);
	}

	private function restoreIdleTime():Void
	{
		if (!idleTimeChanged) return;
		idleTimeChanged = false;

		var application = Application.current;
		var backend = @:privateAccess application.__backend;
		@:privateAccess backend.__setIdleCallback(previousIdleCallback);
		backend.configureFrameTiming(application.frameProfile, @:privateAccess application.__frameRate, application.frameOptions);
	}
	#end

	#if (cpp && libhxcpp && HXCPP_GC_INCREMENTAL && !no_idle_gc)
	public function testTheTimeBeforeAFrameAdvancesACollection():Void
	{
		finishCollection();

		// Too short to finish, so that a cycle is left to advance
		hxcpp.gc.Incremental.step(0.001);

		if (!hxcpp.gc.Incremental.isActive())
		{
			trace("A step finished the whole collection, so advancing one was not tested");
			Assert.pass();
			return;
		}

		var pauses:Float = hxcpp.gc.Incremental.getStats().pauses;
		idle();
		var advanced:Float = hxcpp.gc.Incremental.getStats().pauses;

		finishCollection();
		Assert.isTrue(advanced > pauses, "the collection was not advanced");
	}

	public function testTheTimeBeforeAFrameStartsNoCollection():Void
	{
		finishCollection();
		idle();

		var active = hxcpp.gc.Incremental.isActive();
		finishCollection();
		Assert.isFalse(active, "a collection started with nothing asking for one");
	}

	private static function finishCollection():Void
	{
		while (hxcpp.gc.Incremental.isActive())
		{
			hxcpp.gc.Incremental.step(1);
		}
	}

	private static function idle():Void
	{
		var backend = @:privateAccess Application.current.__backend;
		@:privateAccess backend.applicationEventInfo.type = IDLE;
		@:privateAccess backend.handleApplicationEvent();
	}
	#end
}
