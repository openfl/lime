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
