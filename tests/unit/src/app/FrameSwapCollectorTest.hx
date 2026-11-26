package app;

#if ((cpp || hl) && lime_cffi && !macro)
import haxe.Timer;
import lime.app.Application;
import lime.app.VSyncMode;
import sys.thread.Thread;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	Collections started on another thread while the main thread waits for the display, on C++ and
	HashLink.

	With vsync on and little to draw, the main thread spends most of each frame in the buffer swap. A
	collection stops every thread at a safe point first, and the main thread can't reach one while it is
	inside the swap unless the swap is marked as blocking, so a collection started by a loader, a thread
	pool job or the audio thread would wait up to a refresh interval for it.
**/
class FrameSwapCollectorTest extends Test
{
	public function new()
	{
		super();
	}

	#if ((cpp || hl) && lime_cffi && !macro)
	@Ignored("Waiting on #2237")
	@:timeout(20000)
	public function testCollectionsOnAnotherThreadDoNotWaitForTheSwap(async:Async):Void
	{
		var application = Application.current;

		if (application.window == null || application.window.context == null)
		{
			trace("There is no window to draw to here, so the swap was not tested");
			Assert.pass();
			async.done();
			return;
		}

		var previous = application.vsyncMode;
		var off = collectionTimes(VSyncMode.OFF);

		off.onComplete(function(withoutVSync:Array<Float>)
		{
			collectionTimes(VSyncMode.ON).onComplete(function(withVSync:Array<Float>)
			{
				application.vsyncMode = previous;

				var usual = median(withoutVSync);
				var during = median(withVSync);
				Assert.isTrue(during < usual * 2 + 0.002,
					"a collection on another thread took " + ms(during) + " with vsync on, and " + ms(usual) + " with it off (medians)");
				async.done();
			});
		});
	}

	// Helpers

	/** Collections run on another thread for a second, while frames are drawn here with vsync as given **/
	private static function collectionTimes(mode:VSyncMode):lime.app.Future<Array<Float>>
	{
		var promise = new lime.app.Promise<Array<Float>>();
		Application.current.vsyncMode = mode;
		var times:Array<Float> = [];
		var done = false;

		Thread.create(function()
		{
			// The new setting takes a frame or two
			Sys.sleep(0.3);
			var end = Timer.stamp() + 1;

			while (Timer.stamp() < end)
			{
				var start = Timer.stamp();
				#if cpp
				cpp.vm.Gc.run(true);
				#else
				hl.Gc.major();
				#end
				times.push(Timer.stamp() - start);
				// At a time of its own in each frame
				Sys.sleep(0.003 + (times.length % 7) * 0.001);
			}

			done = true;
		});

		var check:Void->Void = null;
		check = function()
		{
			if (done) promise.complete(times);
			else Timer.delay(check, 50);
		};
		Timer.delay(check, 50);

		return promise.future;
	}

	private static function median(values:Array<Float>):Float
	{
		if (values.length == 0) return 0;
		var sorted = values.copy();
		sorted.sort(Reflect.compare);
		return sorted[sorted.length >> 1];
	}

	private static function ms(seconds:Float):String
	{
		return Math.round(seconds * 10000) / 10 + " ms";
	}
	#end
}
