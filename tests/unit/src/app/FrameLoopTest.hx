package app;

#if (lime_cffi && !macro && (windows || mac || linux) && !rpi)
import haxe.Timer;
import lime.app.Application;
import lime.app.FrameOptions;
import lime.app.FrameProfile;
import lime.app.Future;
import lime.app.UncapMode;
import lime.app.VSyncMode;
import lime.graphics.RenderContextType;
import lime.net.WebSocket;
import lime.net.WebSocketServer;
import lime.system.BackgroundWorker;
import lime.system.FileWatcher;
import lime.system.ThreadPool;
import lime.system.WorkOutput;
import lime.ui.WebView;
import lime.ui.Window;
import sys.thread.Thread;
#if windows
import haxe.Int64;
import haxe.crypto.Base64;
import haxe.io.Bytes;
#end
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	The frame loop of native desktop applications, by what an application sees of it.

	Order. A turn of the loop handles every event that has arrived, then runs a frame if one is
	due: an update, then a render. So a frame never starts with an event that came before it left
	to handle, however long frames or listeners take, and events reach their listeners in the
	order they arrived.

	Timing. `Window.frameRate` is a cap: updates come that often and no more often, whichever
	profile waits for them. An update's `deltaTime` is the whole milliseconds since the one
	before, with what rounding leaves carried over, and `Application.frameDeltaTime` is that time
	with its fractions. A frame that ran long is not made up for, and the frame after it is a whole
	period away.

	Cost. Between frames the application sleeps, unless it asked to busy wait. Input wakes it no
	more often than its profile allows, and an idle listener with nothing to do isn't called
	through the wait.

	Say. `FrameOptions.idleFrameRate` holds frames to a low rate until `Application.requestFrame()`
	asks for one, from any thread, and a frame that is asked for comes as soon as the frame rate
	allows.

	Vertical sync holds frames to the display where the display makes each swap wait.
**/
class FrameLoopTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && (windows || mac || linux) && !rpi)
	private static var isRunning:Bool = false;

	private var paced:Bool = false;
	private var cleanups:Array<Void->Void> = [];
	private var hiddenWindow:Window;
	private var reported:Bool = false;

	// The first test of a run starts as the application is made, before it has a window, and before
	// it sets the frame rate of its window, which would replace a pace set here. In a run of every
	// class it follows whatever the class before left to finish, windows closing among it, so it
	// waits for frames to come evenly, or for five seconds.
	public function setup(async:Async):Void
	{
		if (isRunning)
		{
			async.done();
			return;
		}

		async.setTimeout(20000);

		var application = Application.current;
		var started = 0.0;
		var last = 0.0;
		var even = 0;
		var first:Int->Void = null;

		first = function(_:Int)
		{
			var now = Timer.stamp();
			if (started == 0) started = now;

			// The application asks for 30 frames a second
			even = (last > 0 && now - last < 0.05) ? even + 1 : 0;
			last = now;
			if (even < 20 && now - started < 5) return;

			application.onUpdate.remove(first);
			isRunning = true;
			Timer.delay(function() async.done(), 1);
		};

		application.onUpdate.add(first);
	}

	public function teardown():Void
	{
		for (cleanup in cleanups) cleanup();
		cleanups = [];
		restorePace();
	}

	// Order

	public function testAnUpdateIsFollowedByItsRender(async:Async):Void
	{
		var application = Application.current;
		var window = application.window;

		if (window == null || window.context == null)
		{
			trace("There is no window to draw here, so the order of update and render was not tested");
			Assert.pass();
			async.done();
			return;
		}

		async.setTimeout(10000);
		pace(FrameProfile.BALANCED, 60);

		var order = "";
		var onRender = function(_) order += "r";
		var onUpdate:Int->Void = null;

		onUpdate = function(_:Int)
		{
			order += "u";
			if (order.length < 40) return;

			application.onUpdate.remove(onUpdate);
			window.onRender.remove(onRender);
			restorePace();

			Timer.delay(function()
			{
				Assert.isTrue(order.indexOf("uu") == -1 && order.indexOf("rr") == -1, "updates and renders came in the order " + order);
				async.done();
			}, 1);
		};

		window.onRender.add(onRender);
		application.onUpdate.add(onUpdate);
		cleanups.push(function()
		{
			application.onUpdate.remove(onUpdate);
			window.onRender.remove(onRender);
		});
	}

	#if windows
	/**
		Mouse messages are posted to a window while its application is busy, so they are all
		waiting when its loop next looks. Every update takes longer than the frame rate allows, so
		a frame is always due. Each frame must still come after all the input before it: handling
		one event for each frame would leave the application acting on input from seconds before,
		and further behind for as long as input kept coming.
	**/
	@:timeout(30000)
	public function testEventsThatCameBeforeAFrameAreAllHandledBeforeItWhenFramesRunLate(async:Async):Void
	{
		// Each update takes 30 ms of a frame of under 17
		inputBehindFrames(0.03, 0, async, function(heard:Array<Int>, frames:Array<Int>)
		{
			var spread = frames[frames.length - 1] - frames[0] + 1;
			Assert.isTrue(spread <= 2, "with updates of 30 ms at 60 frames a second, " + frames.length + " mouse moves posted together were spread over "
				+ spread + " frames");
		});
	}

	/**
		Here the frames are on time, with a few milliseconds to spare, and it is the listeners that
		are slow: the moves take more time to handle than one frame has to spare. A frame that
		comes due part way through them waits for the rest. Were it to go first, with what is left
		over handled in the time the next frame has to spare, the input would again fall behind.
	**/
	@:timeout(30000)
	public function testEventsThatTakeLongToHandleAreAllHandledBeforeTheNextFrame(async:Async):Void
	{
		// Each update takes 10 ms of a frame of under 17, and each of the 40 moves a millisecond or two
		inputBehindFrames(0.01, 0.002, async, function(heard:Array<Int>, frames:Array<Int>)
		{
			var spread = frames[frames.length - 1] - frames[0] + 1;
			Assert.isTrue(spread <= 2, "with updates of 10 ms at 60 frames a second, and listeners of 1 to 2 ms, " + frames.length
				+ " mouse moves posted together were spread over " + spread + " frames");
		});
	}

	@:timeout(30000)
	public function testEventsReachTheirListenersInTheOrderTheyArrived(async:Async):Void
	{
		inputBehindFrames(0.02, 0, async, function(heard:Array<Int>, frames:Array<Int>)
		{
			var inOrder = true;
			for (i in 1...heard.length) if (heard[i] != heard[i - 1] + 1) inOrder = false;
			Assert.isTrue(inOrder, "mouse moves posted at 1 to " + MOVES + " were heard as " + heard.join(" "));
		});
	}

	/**
		Input wakes a waiting application at once, and input that follows within the interval its
		profile sets waits for the interval to pass, so a mouse that reports thousands of times a
		second wakes the application as often as one that reports hundreds. The low energy
		profile's interval is 8 ms. Every move is still heard.
	**/
	@:timeout(40000)
	public function testInputWakesTheLowEnergyProfileNoMoreThanEvery8Milliseconds(async:Async):Void
	{
		inputStream(FrameProfile.LOW_ENERGY, async, function(posted:Int, heard:Int, wakes:Int, seconds:Float)
		{
			Assert.equals(posted, heard);

			// 125 a second by the interval, and a turn for each of the 10 frames a second besides
			var limit = Math.ceil(seconds * (125 + 10) * 1.3);
			Assert.isTrue(wakes <= limit, heard + " mouse moves posted over " + round(seconds) + " seconds woke the low energy profile " + wakes
				+ " times, where its interval allows " + limit);
		});
	}

	/** The precision profile hears each event as it comes **/
	@:timeout(40000)
	public function testInputWakesThePrecisionProfileAsItComes(async:Async):Void
	{
		inputStream(FrameProfile.PRECISION, async, function(posted:Int, heard:Int, wakes:Int, seconds:Float)
		{
			Assert.equals(posted, heard);

			// Posted about 2 ms apart, where an interval of 8 ms would allow 125 wakes a second
			Assert.isTrue(wakes >= seconds * 200 || wakes >= posted * 0.6, heard + " mouse moves posted over " + round(seconds)
				+ " seconds woke the precision profile " + wakes + " times");
		});
	}

	/**
		What is held for the interval is a stream of input. A message that another process sent
		and is waiting on the answer to, as a screen reader or the shell does, is answered at
		once, also while mouse moves are coming faster than the interval.
	**/
	@:timeout(40000)
	public function testAMessageSentDuringAStreamOfInputIsAnsweredAtOnce(async:Async):Void
	{
		var application = Application.current;
		var window = openHiddenWindow();

		if (window == null)
		{
			async.done();
			return;
		}

		// The profile whose interval is the longest, 8 ms
		pace(FrameProfile.LOW_ENERGY, 10);

		var waits:Array<Float> = null;
		var finished = false;

		Thread.create(function()
		{
			waits = sendDuringMoves(window, 400, 2, 10);
		});

		var onUpdate:Int->Void = null;
		onUpdate = function(_:Int)
		{
			if (finished || waits == null) return;

			finished = true;
			application.onUpdate.remove(onUpdate);
			restorePace();

			Timer.delay(function()
			{
				if (waits.length == 0)
				{
					Assert.fail("the messages could not be sent");
				}
				else
				{
					waits.sort(Reflect.compare);
					var median = waits[waits.length >> 1];

					// Held for the interval with the moves, one waits 4 ms on average
					Assert.isTrue(median < 2, "a message sent while mouse moves came 2 ms apart waited " + round3(median)
						+ " ms for its answer, the median of " + waits.length);
				}

				async.done();
			}, 1);
		};

		application.onUpdate.add(onUpdate);
		cleanups.push(function() application.onUpdate.remove(onUpdate));
	}
	#end

	// Timing

	@:timeout(10000)
	public function testUpdatesComeAtTheFrameRate(async:Async):Void
	{
		pace(FrameProfile.BALANCED, 40);

		frames(1, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			var rate = rateOf(times);
			Assert.isTrue(rate >= 28 && rate <= 41, "at 40 frames a second there were " + round(rate) + " updates a second");

			// And evenly, a frame apart, not in twos with a gap between
			var interval = median(intervals(times));
			Assert.isTrue(interval >= 20 && interval <= 36, "at 40 frames a second the usual time between updates was " + round(interval) + " ms");
			async.done();
		});
	}

	@:timeout(10000)
	public function testTheLowEnergyProfileKeepsTheFrameRate(async:Async):Void
	{
		pace(FrameProfile.LOW_ENERGY, 30);

		frames(1, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			var rate = rateOf(times);
			Assert.isTrue(rate >= 20 && rate <= 31, "at 30 frames a second the low energy profile gave " + round(rate) + " updates a second");
			async.done();
		});
	}

	@:timeout(10000)
	public function testThePrecisionProfileKeepsTheFrameRate(async:Async):Void
	{
		pace(FrameProfile.PRECISION, 75);

		frames(1, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			var rate = rateOf(times);
			Assert.isTrue(rate >= 50 && rate <= 76.5, "at 75 frames a second the precision profile gave " + round(rate) + " updates a second");
			async.done();
		});
	}

	// An update's deltaTime is whole milliseconds, and what rounding leaves over is carried to the
	// next one, so they neither gain nor lose time. A frame rate whose frames aren't whole
	// milliseconds apart would drift by a third of a millisecond a frame otherwise.
	@:timeout(10000)
	public function testTheTimesBetweenUpdatesAddUpToTheTimeThatPassed(async:Async):Void
	{
		pace(FrameProfile.BALANCED, 60);

		frames(1, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			Assert.isTrue(Math.abs(sum(deltas) - elapsed(times)) <= 4,
				"the times between " + times.length + " updates added up to " + sum(deltas) + " ms over " + round(elapsed(times)) + " ms");

			pace(FrameProfile.PRECISION, 90);

			frames(1, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
			{
				Assert.isTrue(Math.abs(sum(deltas) - elapsed(times)) <= 4,
					"with the precision profile the times between " + times.length + " updates added up to " + sum(deltas) + " ms over "
					+ round(elapsed(times)) + " ms");
				async.done();
			});
		});
	}

	/**
		`frameDeltaTime` is the time `deltaTime` rounds: never more than a millisecond from it, with
		the fractions that 60 frames a second leave, and adding up to the time that passed.
	**/
	@:timeout(10000)
	public function testTheFrameDeltaTimeIsTheTimeBetweenUpdatesWithItsFractions(async:Async):Void
	{
		var application = Application.current;
		pace(FrameProfile.BALANCED, 60);

		var precise:Array<Float> = [];
		var whole:Array<Int> = [];
		var stamps:Array<Float> = [];
		var settle = 5;
		var listener:Int->Void = null;

		listener = function(deltaTime:Int)
		{
			if (settle-- > 0) return;

			precise.push(application.frameDeltaTime);
			whole.push(deltaTime);
			stamps.push(Timer.stamp());
			if (precise.length < 60) return;

			application.onUpdate.remove(listener);
			restorePace();

			Timer.delay(function()
			{
				var total = 0.0;
				var fractions = 0;
				var apart = 0.0;

				for (i in 1...precise.length)
				{
					total += precise[i];
					if (Math.abs(precise[i] - Math.round(precise[i])) > 0.001) fractions++;
					apart = Math.max(apart, Math.abs(precise[i] - whole[i]));
				}

				var passed = (stamps[stamps.length - 1] - stamps[0]) * 1000;
				Assert.isTrue(Math.abs(total - passed) <= 3, "the frame delta times of " + precise.length + " updates added up to " + round(total) + " ms over "
					+ round(passed) + " ms");
				Assert.isTrue(apart <= 1.001, "a frame delta time was " + round(apart) + " ms from the deltaTime of its update");
				Assert.isTrue(fractions > precise.length / 2, "of " + precise.length + " frame delta times at 60 frames a second, " + fractions
					+ " had a fraction: " + [for (i in 1...8) round3(precise[i])].join(" "));
				async.done();
			}, 1);
		};

		application.onUpdate.add(listener);
		cleanups.push(function() application.onUpdate.remove(listener));
	}

	@:timeout(10000)
	public function testAFrameThatRanLongIsNotMadeUpForWithABurst(async:Async):Void
	{
		var application = Application.current;
		pace(FrameProfile.BALANCED, 50);

		var settle = 5;
		var stalled = false;
		var after:Array<Float> = [];
		var end = 0.0;
		var listener:Int->Void = null;

		listener = function(_:Int)
		{
			if (settle-- > 0) return;

			if (!stalled)
			{
				// Ten and a half frames' worth
				stalled = true;
				spin(0.21);
				end = Timer.stamp() + 0.2;
				return;
			}

			if (Timer.stamp() <= end)
			{
				after.push(Timer.stamp());
				return;
			}

			application.onUpdate.remove(listener);
			restorePace();

			Timer.delay(function()
			{
				// Ten more at this rate, and the one that was due while the long frame ran
				Assert.isTrue(after.length >= 4 && after.length <= 12,
					"in the 200 ms after a frame of 210 ms, at 50 frames a second, there were " + after.length + " updates");

				// The late frame starts the count afresh: the next is a whole period after it, not
				// at what is left of the period it came in
				var gap = after.length > 1 ? (after[1] - after[0]) * 1000 : 0;
				Assert.isTrue(gap >= 15, "the update after a frame that came late, at 50 frames a second, followed it by " + round(gap) + " ms");
				async.done();
			}, 1);
		};

		application.onUpdate.add(listener);
		cleanups.push(function() application.onUpdate.remove(listener));
	}

	// Applications that set the frame rate as they run, some of them every frame, get the rate
	// they set, not a frame for each time they set it
	@:timeout(10000)
	public function testSettingTheFrameRateOftenAddsNoFrames(async:Async):Void
	{
		var application = Application.current;
		var backend = @:privateAccess application.__backend;
		pace(FrameProfile.BALANCED, 40);

		var toggle = false;
		var setter = function(_:Int)
		{
			toggle = !toggle;
			backend.configureFrameTiming(FrameProfile.BALANCED, toggle ? 41 : 40, application.frameOptions);
		};

		application.onUpdate.add(setter);
		cleanups.push(function() application.onUpdate.remove(setter));

		frames(1, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			application.onUpdate.remove(setter);

			var rate = rateOf(times);
			Assert.isTrue(rate >= 28 && rate <= 42, "setting the frame rate to 40 or 41 on every update gave " + round(rate) + " updates a second");
			async.done();
		});
	}

	// Uncapped loops

	@:timeout(10000)
	public function testTheUncappedProfileIgnoresTheFrameRate(async:Async):Void
	{
		pace(FrameProfile.UNCAPPED, 10);

		frames(0.5, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			var rate = rateOf(times);
			Assert.isTrue(rate > 30, "the uncapped profile, asked for 10 frames a second, gave " + round(rate) + " updates a second");
			async.done();
		});
	}

	@:timeout(10000)
	public function testTheUncapModesIgnoreTheFrameRate(async:Async):Void
	{
		var application = Application.current;
		var soft = application.frameOptions;
		soft.uncapMode = UncapMode.SOFT;
		pace(FrameProfile.BALANCED, 10, soft);

		frames(0.5, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			var rate = rateOf(times);
			Assert.isTrue(rate > 30, "with the soft uncap mode, asked for 10 frames a second, there were " + round(rate) + " updates a second");

			var hard = application.frameOptions;
			hard.uncapMode = UncapMode.HARD;
			pace(FrameProfile.BALANCED, 10, hard);

			frames(0.5, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
			{
				var rate = rateOf(times);
				Assert.isTrue(rate > 30, "with the hard uncap mode, asked for 10 frames a second, there were " + round(rate) + " updates a second");
				async.done();
			});
		});
	}

	// The wait for a frame

	// Five frames a second, so that what the frames themselves cost is little beside the waits
	// between them. A loop that spun until each frame was due would use a whole processor.
	@:timeout(15000)
	public function testTheWaitForAFrameUsesNoProcessor(async:Async):Void
	{
		pace(FrameProfile.BALANCED, 5);

		frames(1.2, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			var balanced = cpu / (elapsed(times) / 1000);
			pace(FrameProfile.LOW_ENERGY, 5);

			frames(1.2, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
			{
				var lowEnergy = cpu / (elapsed(times) / 1000);
				Assert.isTrue(balanced < 0.6, "waiting for 5 frames a second, the balanced profile used " + percent(balanced) + " of a processor");
				Assert.isTrue(lowEnergy < 0.6, "waiting for 5 frames a second, the low energy profile used " + percent(lowEnergy) + " of a processor");
				async.done();
			}, 2);
		}, 2);
	}

	/**
		The time before a frame is offered to an idle listener as the wait for it begins. One with
		nothing to do isn't called again through that wait: calling it would wake the application
		for nothing, many times a frame.
	**/
	@:timeout(15000)
	public function testAnIdleListenerWithNothingToDoIsCalledOnceInAWait(async:Async):Void
	{
		idleCalls(false, function(calls:Int, updates:Int)
		{
			// Once for each wait, and a wait for each frame where nothing else wakes the application
			Assert.isTrue(calls >= updates - 2, "over " + updates + " frames 200 ms apart, an idle listener was called " + calls + " times");
			Assert.isTrue(calls <= updates * 3 + 2, "over " + updates + " frames 200 ms apart, an idle listener with nothing to do was called " + calls
				+ " times");
			async.done();
		});
	}

	/** One that says it has more to do, as a collector part way through a cycle does, is called again while there is time **/
	@:timeout(15000)
	public function testAnIdleListenerWithMoreToDoIsCalledAgainBeforeTheFrame(async:Async):Void
	{
		idleCalls(true, function(calls:Int, updates:Int)
		{
			// A millisecond apart, through waits of 200 ms
			Assert.isTrue(calls >= updates * 20, "over " + updates + " frames 200 ms apart, an idle listener with more to do was called " + calls + " times");
			async.done();
		});
	}

	// An uncapped loop starts each frame as the last one ends, so it has no time before a frame to report
	@:timeout(10000)
	public function testAnUncappedLoopReportsNoTimeBeforeAFrame(async:Async):Void
	{
		var application = Application.current;
		var backend = @:privateAccess application.__backend;
		var previous = @:privateAccess backend.__idleCallback;
		var idles:Array<Float> = [];

		cleanups.push(function() @:privateAccess backend.__setIdleCallback(previous));
		@:privateAccess backend.__setIdleCallback(function() idles.push(Timer.stamp()));
		pace(FrameProfile.UNCAPPED, 10);

		frames(0.3, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			@:privateAccess backend.__setIdleCallback(previous);

			// The loop is capped again once the last update has been counted
			var counted = 0;
			for (time in idles) if (time >= times[0] && time < times[times.length - 1]) counted++;

			Assert.equals(0, counted);
			async.done();
		});
	}

	// Frames that are asked for

	/** With an idle frame rate, frames come that often for as long as none is asked for **/
	@:timeout(15000)
	public function testAnIdleFrameRateHoldsFramesUntilOneIsAskedFor(async:Async):Void
	{
		pace(FrameProfile.BALANCED, 60, idleAt(5));

		frames(1.6, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			var rate = rateOf(times);
			Assert.isTrue(rate >= 3 && rate <= 7, "at 60 frames a second with an idle frame rate of 5, and no frame asked for, there were " + round(rate)
				+ " updates a second");
			async.done();
		}, 2);
	}

	/**
		A frame that is asked for doesn't wait out the idle frame. It is asked for here from another
		thread, while the application sleeps, which has to wake it.
	**/
	@:timeout(20000)
	public function testAFrameAskedForFromAnotherThreadWakesTheApplication(async:Async):Void
	{
		var application = Application.current;
		pace(FrameProfile.BALANCED, 60, idleAt(1));

		var update = 0;
		var asked = 0.0;
		var listener:Int->Void = null;

		listener = function(_:Int)
		{
			// The first update may be one that was due before the idle frame rate was set
			if (++update < 2) return;

			if (update == 2)
			{
				// 150 ms into a wait of a second
				Thread.create(function()
				{
					Sys.sleep(0.15);
					asked = Timer.stamp();
					application.requestFrame();
				});

				return;
			}

			var waited = asked > 0 ? (Timer.stamp() - asked) * 1000 : -1;
			application.onUpdate.remove(listener);
			restorePace();

			Timer.delay(function()
			{
				Assert.isTrue(waited >= 0, "an update came before the frame was asked for, with an idle frame rate of 1");
				Assert.isTrue(waited < 120, "a frame asked for from another thread, with an idle frame rate of 1, came " + round(waited) + " ms later");
				async.done();
			}, 1);
		};

		application.onUpdate.add(listener);
		cleanups.push(function() application.onUpdate.remove(listener));
	}

	/** An application that animates asks for a frame from each update, and gets its frames at the frame rate **/
	@:timeout(15000)
	public function testAskingForAFrameFromEachUpdateGivesTheFrameRate(async:Async):Void
	{
		var application = Application.current;
		pace(FrameProfile.BALANCED, 40, idleAt(2));

		var asker = function(_:Int) application.requestFrame();
		application.onUpdate.add(asker);
		cleanups.push(function() application.onUpdate.remove(asker));

		frames(1, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			application.onUpdate.remove(asker);

			var rate = rateOf(times);
			Assert.isTrue(rate >= 28 && rate <= 41, "asking for a frame from each update, at 40 frames a second with an idle frame rate of 2, gave "
				+ round(rate) + " updates a second");

			var interval = median(intervals(times));
			Assert.isTrue(interval >= 20 && interval <= 36, "and the usual time between them was " + round(interval) + " ms");
			async.done();
		});
	}

	/** Asking never brings frames closer than the frame rate allows, however often, and from whichever thread **/
	@:timeout(15000)
	public function testAskingForFramesOftenAddsNoneBeyondTheFrameRate(async:Async):Void
	{
		var application = Application.current;
		pace(FrameProfile.BALANCED, 30, idleAt(2));

		var asking = true;
		cleanups.push(function() asking = false);

		Thread.create(function()
		{
			while (asking)
			{
				application.requestFrame();
				Sys.sleep(0.0005);
			}
		});

		var asker = function(_:Int) for (i in 0...10) application.requestFrame();
		application.onUpdate.add(asker);
		cleanups.push(function() application.onUpdate.remove(asker));

		frames(1, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			asking = false;
			application.onUpdate.remove(asker);

			var rate = rateOf(times);
			Assert.isTrue(rate >= 20 && rate <= 31.5, "asking for frames all the time, at 30 frames a second, gave " + round(rate) + " updates a second");
			async.done();
		});
	}

	/** Without an idle frame rate, frames already come at the frame rate, and asking changes nothing **/
	@:timeout(15000)
	public function testAskingForAFrameWithoutAnIdleFrameRateChangesNothing(async:Async):Void
	{
		var application = Application.current;
		pace(FrameProfile.BALANCED, 20);

		var asker = function(_:Int) application.requestFrame();
		application.onUpdate.add(asker);
		cleanups.push(function() application.onUpdate.remove(asker));

		frames(1, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			application.onUpdate.remove(asker);

			var rate = rateOf(times);
			Assert.isTrue(rate >= 14 && rate <= 21, "asking for a frame from each update at 20 frames a second gave " + round(rate) + " updates a second");
			async.done();
		});
	}

	/** Several requests before the frame comes give one frame **/
	@:timeout(20000)
	public function testAskingSeveralTimesGivesOneFrame(async:Async):Void
	{
		var application = Application.current;
		pace(FrameProfile.BALANCED, 60, idleAt(1));

		var update = 0;
		var asked = 0.0;
		var after:Array<Float> = [];
		var listener:Int->Void = null;

		listener = function(_:Int)
		{
			if (++update < 2) return;

			if (update == 2)
			{
				// From a timer, which runs between frames, so all five are in before the frame
				// can come. A thread that asked could be held up part way through them.
				Timer.delay(function()
				{
					asked = Timer.stamp();
					for (i in 0...5) application.requestFrame();
				}, 100);

				return;
			}

			// The frame asked for, and then the next idle one, a second later
			after.push(Timer.stamp());
			if (after.length < 2) return;

			application.onUpdate.remove(listener);
			restorePace();

			Timer.delay(function()
			{
				var gap = (after[1] - after[0]) * 1000;
				Assert.isTrue(asked > 0 && after[0] >= asked, "an update came before the frame was asked for");
				Assert.isTrue(gap >= 600, "five requests for a frame, with an idle frame rate of 1, gave updates " + round(gap) + " ms apart");
				async.done();
			}, 1);
		};

		application.onUpdate.add(listener);
		cleanups.push(function() application.onUpdate.remove(listener));
	}

	/**
		Timers run from the application's updates. With an idle frame rate the next update may be a
		long way off, so a timer that is due before it fires on time, between the updates.
	**/
	@:timeout(20000)
	public function testATimerFiresOnTimeWithAnIdleFrameRate(async:Async):Void
	{
		var application = Application.current;
		pace(FrameProfile.BALANCED, 60, idleAt(1));

		var update = 0;
		var listener:Int->Void = null;

		listener = function(_:Int)
		{
			if (++update != 2) return;
			application.onUpdate.remove(listener);

			// Made in an update, with the next idle frame a second away
			var started = Timer.stamp();

			Timer.delay(function()
			{
				var waited = (Timer.stamp() - started) * 1000;
				restorePace();

				Timer.delay(function()
				{
					Assert.isTrue(waited >= 140 && waited < 400, "a timer of 150 ms, with an idle frame rate of 1, fired after " + round(waited) + " ms");
					async.done();
				}, 1);
			}, 150);
		};

		application.onUpdate.add(listener);
		cleanups.push(function() application.onUpdate.remove(listener));
	}

	/**
		A timer that repeats keeps its interval, and its firing is no frame: frames still come at
		the idle rate, and what a timer changes is drawn by the frame it asks for.
	**/
	@:timeout(20000)
	public function testATimerThatRepeatsKeepsItsIntervalAndAddsNoFramesToAnIdleFrameRate(async:Async):Void
	{
		var application = Application.current;
		pace(FrameProfile.BALANCED, 60, idleAt(2));

		var update = 0;
		var updates = 0;
		var timing = false;
		var listener:Int->Void = null;

		listener = function(_:Int)
		{
			if (timing) updates++;
			if (++update != 2) return;

			var fired:Array<Float> = [];
			var timer = new Timer(50);
			cleanups.push(function() timer.stop());
			timing = true;

			timer.run = function()
			{
				fired.push(Timer.stamp());
				if (fired.length < 21) return;

				timer.stop();
				timing = false;
				application.onUpdate.remove(listener);
				restorePace();

				Timer.delay(function()
				{
					var passed = (fired[20] - fired[0]) * 1000;
					Assert.isTrue(passed >= 950 && passed < 1400, "a timer of 50 ms, with an idle frame rate of 2, fired twenty times more in " + round(passed)
						+ " ms");
					Assert.isTrue(updates <= 5, "while a timer of 50 ms fired for " + round(passed) + " ms, with an idle frame rate of 2, there were " + updates
						+ " updates");
					async.done();
				}, 1);
			};
		};

		application.onUpdate.add(listener);
		cleanups.push(function() application.onUpdate.remove(listener));
	}

	/** A window that changes size is drawn at its new size without waiting out an idle frame **/
	@:timeout(20000)
	public function testAResizedWindowIsDrawnWithoutWaitingOutAnIdleFrame(async:Async):Void
	{
		var application = Application.current;
		var window = openHiddenWindow();

		if (window == null)
		{
			async.done();
			return;
		}

		pace(FrameProfile.BALANCED, 60, idleAt(1));

		var update = 0;
		var resized = 0.0;
		var heard = false;
		var onResize = function(width:Int, height:Int) heard = true;
		var listener:Int->Void = null;

		listener = function(_:Int)
		{
			if (++update < 2) return;

			if (update == 2)
			{
				// A frame asked for from another thread, part way through a wait of a second,
				// is where the window is resized, with the next idle frame a second away
				Thread.create(function()
				{
					Sys.sleep(0.15);
					application.requestFrame();
				});

				return;
			}

			if (update == 3)
			{
				resized = Timer.stamp();
				window.resize(window.width + 16, window.height + 8);
				return;
			}

			var waited = (Timer.stamp() - resized) * 1000;
			application.onUpdate.remove(listener);
			window.onResize.remove(onResize);
			restorePace();

			Timer.delay(function()
			{
				if (!heard)
				{
					trace("A hidden window gives no resize event here, so drawing a resized window was not tested");
					Assert.pass();
				}
				else
				{
					Assert.isTrue(waited < 300, "a window resized with an idle frame rate of 1 had its next frame " + round(waited) + " ms later");
				}

				async.done();
			}, 1);
		};

		window.onResize.add(onResize);
		application.onUpdate.add(listener);
		cleanups.push(function()
		{
			application.onUpdate.remove(listener);
			window.onResize.remove(onResize);
		});
	}

	// What is delivered between frames

	/**
		With an idle frame rate, what ends off the main thread or between frames is heard of when
		it ends, and not in the next idle frame, by an application that asks for no frame itself.
		It brings no frame either: a listener that changes what is drawn asks for one. A job of a
		thread pool reports on the main thread, between frames as well.
	**/
	@:timeout(15000)
	public function testAThreadPoolsJobIsHeardOfWhenItEndsWithAnIdleFrameRate(async:Async):Void
	{
		var pool = new ThreadPool(0, 1, MULTI_THREADED);

		delivery(async, "a job of a thread pool", function(heard:Void->Void)
		{
			pool.onComplete.add(function(_) heard());
			pool.run(sleepThenComplete);
		});
	}

	private static function sleepThenComplete(state:Dynamic, output:WorkOutput):Void
	{
		Sys.sleep(0.3);
		workEnded = Timer.stamp();
		output.sendComplete();
	}

	/** A future's work is done by a thread pool **/
	@:timeout(15000)
	public function testAFuturesWorkIsHeardOfWhenItEndsWithAnIdleFrameRate(async:Async):Void
	{
		delivery(async, "the work of a future", function(heard:Void->Void)
		{
			new Future<Int>(function()
			{
				Sys.sleep(0.3);
				workEnded = Timer.stamp();
				return 1;
			}, true).onComplete(function(_) heard());
		});
	}

	/** A file is loaded by a thread pool, as an asset is **/
	@:timeout(15000)
	public function testAFileThatWasLoadedIsHeardOfWhenItIsReadWithAnIdleFrameRate(async:Async):Void
	{
		var path = haxe.io.Path.join([Sys.getCwd(), "FrameLoopTestLoad.txt"]);
		sys.io.File.saveContent(path, "loaded");

		delivery(async, "a file that was loaded", function(heard:Void->Void)
		{
			// When the read ends can't be seen from here, so the time it was asked for stands for
			// it. A file that was just written may be held up as it is opened, by a virus
			// scanner for one, so what is asked is that it doesn't take until the idle frame.
			workEnded = Timer.stamp();
			lime.utils.Bytes.loadFromFile(path).onComplete(function(_) heard());
		}, function()
		{
			try sys.FileSystem.deleteFile(path) catch (error:Dynamic) {}
		}, null, 850);
	}

	/** A background worker's messages are heard on the main thread the same way **/
	@:timeout(15000)
	public function testABackgroundWorkersMessageIsHeardWhenItIsSentWithAnIdleFrameRate(async:Async):Void
	{
		var worker = new BackgroundWorker();

		delivery(async, "the completion a background worker sent", function(heard:Void->Void)
		{
			worker.doWork.add(function(_)
			{
				Sys.sleep(0.3);
				workEnded = Timer.stamp();
				worker.sendComplete();
			});

			worker.onComplete.add(function(_) heard());
			worker.run();
		});
	}

	#if (haxe_ver >= 4.2)
	/**
		The main thread's events are run with the timers, between frames as well. A timer of the
		test runner's own keeps the timers running here, so this passes without the loop being
		woken for the event. It is here so that waking it doesn't get in the event's way, and the
		frame loop bench has the time an event waits where no timer runs.
	**/
	@:timeout(15000)
	public function testAnEventAnotherThreadGivesTheMainThreadRunsWhenItIsGivenWithAnIdleFrameRate(async:Async):Void
	{
		var main = Thread.current();

		delivery(async, "an event another thread gave the main thread", function(heard:Void->Void)
		{
			Thread.create(function()
			{
				Sys.sleep(0.3);
				workEnded = Timer.stamp();
				main.events.run(heard);
			});
		});
	}
	#end

	/** WebSockets are polled, between frames as well while any is open **/
	@:timeout(20000)
	public function testAWebSocketsMessageIsHeardWhenItComesWithAnIdleFrameRate(async:Async):Void
	{
		if (!WebSocketServer.isSupported)
		{
			Assert.pass();
			async.done();
			return;
		}

		var server = new WebSocketServer();
		var client = new WebSocket();
		var accepted:WebSocket = null;
		var connected = false;

		server.onConnect.add(function(socket) accepted = socket);
		Assert.isTrue(server.listen(0, "127.0.0.1"), "the server did not listen");
		client.onConnect.add(function() connected = true);
		client.connect("ws://127.0.0.1:" + server.localPort + "/");

		delivery(async, "a message that came to a WebSocket", function(heard:Void->Void)
		{
			accepted.onText.add(function(_) heard());

			// A timer runs on its own with an idle frame rate
			Timer.delay(function()
			{
				workEnded = Timer.stamp();
				client.sendText("now");
			}, 300);
		}, function()
		{
			client.close();
			server.close();
		}, function() return connected && accepted != null);
	}

	/** What a web view reports is read between frames as well **/
	@:timeout(30000)
	public function testAWebViewsMessageIsHeardWhenItIsPostedWithAnIdleFrameRate(async:Async):Void
	{
		if (!WebView.isSupported)
		{
			trace("No web engine here, so what a web view reports was not tested");
			Assert.pass();
			async.done();
			return;
		}

		var view = new WebView();
		var loaded = false;
		view.onLoad.add(function() loaded = true);
		view.loadHTML("<!doctype html><html><body></body></html>");

		delivery(async, "a message a web view posted", function(heard:Void->Void)
		{
			view.onMessage.add(function(_) heard());

			Timer.delay(function()
			{
				workEnded = Timer.stamp();
				view.evaluateJavaScript("window.chrome.webview.postMessage('now');");
			}, 300);
		}, function() view.close(), function() return loaded);
	}

	// Not on HashLink: FileWatcher.addDirectory() ends in an access violation there, on develop
	// as on this branch, with or without an idle frame rate. That is a fault of its own, which
	// this test found and doesn't fix. Not on macOS, whose file events come a while after the change.
	#if ((windows || linux) && !hl)
	/** What a file watcher saw is heard on the main thread the same way **/
	@:timeout(15000)
	public function testAChangeAFileWatcherSawIsHeardOfWhenItHappensWithAnIdleFrameRate(async:Async):Void
	{
		var directory = haxe.io.Path.join([Sys.getCwd(), "FrameLoopTestWatched"]);
		var file = haxe.io.Path.join([directory, "added.txt"]);
		if (!sys.FileSystem.exists(directory)) sys.FileSystem.createDirectory(directory);
		if (sys.FileSystem.exists(file)) sys.FileSystem.deleteFile(file);

		var watcher = new FileWatcher();

		if (!watcher.addDirectory(directory, false))
		{
			trace("The directory could not be watched, so what a file watcher reports was not tested");
			Assert.pass();
			async.done();
			return;
		}

		delivery(async, "a file added to a watched directory", function(heard:Void->Void)
		{
			watcher.onAdd.add(function(_) heard());
			watcher.onModify.add(function(_) heard());

			Timer.delay(function()
			{
				workEnded = Timer.stamp();
				sys.io.File.saveContent(file, "now");
			}, 300);
		}, function()
		{
			watcher.removeDirectory(directory);

			try
			{
				sys.FileSystem.deleteFile(file);
				sys.FileSystem.deleteDirectory(directory);
			}
			catch (error:Dynamic) {}
		});
	}
	#end

	// When the work of a delivery test ended, by Timer.stamp(), from whichever thread it ran on
	private static var workEnded = 0.0;

	/**
		Sets an idle frame rate of 1 and, as an idle frame ends, calls `start`, which begins work
		that ends some 300 ms later, sets `workEnded` as it does, and has its listener call the
		function it is given. With nothing to bring it forward, the listener would hear in the
		next idle frame, 700 ms after the work ended. It is to hear within `within` milliseconds,
		and before any update, as nothing here asks for a frame. `ready` is waited for first, at
		the frame rate.
	**/
	private function delivery(async:Async, what:String, start:(Void->Void)->Void, ?finish:Void->Void, ?ready:Void->Bool, within:Float = 150):Void
	{
		var application = Application.current;
		var updates = 0;
		var updatesAtStart = -1;
		var updatesWhenHeard = 0;
		var heardAt = -1.0;
		var startedAt = 0.0;
		var begun = Timer.stamp();
		var idle = false;
		var finished = false;
		var listener:Int->Void = null;
		workEnded = 0.0;

		var end = function(failure:String)
		{
			if (finished) return;
			finished = true;
			application.onUpdate.remove(listener);
			restorePace();
			if (finish != null) finish();

			Timer.delay(function()
			{
				if (failure != null)
				{
					Assert.fail(failure);
				}
				else
				{
					var waited = (heardAt - workEnded) * 1000;
					var frames = updatesWhenHeard - updatesAtStart;

					Assert.isTrue(waited < within, what + ", which ended " + round((workEnded - startedAt) * 1000)
						+ " ms into a wait of a second for an idle frame, was heard of " + round(waited) + " ms after it ended");

					// It is handed over between frames, and brings none
					Assert.equals(0, frames, "there were " + frames + " updates between " + what
						+ " being begun and being heard of, where no frame was asked for");
				}

				async.done();
			}, 1);
		};

		listener = function(_:Int)
		{
			var now = Timer.stamp();

			if (!idle)
			{
				// At the frame rate still
				if (ready == null || ready())
				{
					idle = true;
					pace(FrameProfile.BALANCED, 60, idleAt(1));
				}
				else if (now - begun > 8)
				{
					end(what + " could not be set up");
				}

				return;
			}

			updates++;

			if (heardAt >= 0)
			{
				end(null);
			}
			else if (updatesAtStart >= 0 && now - startedAt > 4)
			{
				end(what + " was not heard of at all");
			}
			else if (updatesAtStart < 0 && updates == 2)
			{
				// The first update may be one that was due before the idle frame rate was set
				updatesAtStart = updates;
				startedAt = now;

				start(function()
				{
					if (heardAt >= 0) return;
					heardAt = Timer.stamp();
					updatesWhenHeard = updates;
				});

				// The test ends in an update, which this thread asks for once the listener has
				// heard. A timer that looked for that would run the main thread's events and
				// poll the sockets as it did, which is what is being tested.
				Thread.create(function()
				{
					while (!finished)
					{
						Sys.sleep(0.02);
						if (heardAt >= 0 || Timer.stamp() - startedAt > 4) application.requestFrame();
					}
				});
			}
		};

		// Ahead of every other listener, so an update that hands something over is counted first
		application.onUpdate.add(listener, false, 1000);
		cleanups.push(function()
		{
			finished = true;
			application.onUpdate.remove(listener);
		});
	}

	// Vertical sync

	/**
		With vertical sync on, each swap waits for the display, so frames come at its refresh rate,
		however many more the frame rate allows.
	**/
	@:timeout(30000)
	public function testVerticalSyncHoldsFramesToTheDisplay(async:Async):Void
	{
		swapsWait(async, function(window:Window, refresh:Float, uncapped:Float, wait:Bool)
		{
			if (!wait)
			{
				trace("Swaps do not wait for the display here (" + round(uncapped) + " frames a second uncapped, at " + refresh
					+ " Hz), so frames held to the display were not tested");
				Assert.pass();
				async.done();
				return;
			}

			pace(FrameProfile.BALANCED, refresh * 4, null, VSyncMode.ON);

			frames(1, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
			{
				var rate = rateOf(times);
				Assert.isTrue(rate >= refresh * 0.7 && rate <= refresh * 1.3,
					"with vertical sync on at " + refresh + " Hz, and a frame rate of " + (refresh * 4) + ", there were " + round(rate) + " updates a second");
				async.done();
			});
		});
	}

	/**
		Gives the application's window, its display's refresh rate, the updates a second of an uncapped
		loop with vertical sync on, and whether that shows swaps waiting for the display: nothing else
		holds an uncapped loop to it. Where no window is drawn with OpenGL, whose swap is what waits, the
		test passes saying so.
	**/
	private function swapsWait(async:Async, check:Window->Float->Float->Bool->Void):Void
	{
		var window = Application.current.window;
		var drawn = window != null && window.context != null && !window.hidden && !window.minimized
			&& (window.context.type == RenderContextType.OPENGL || window.context.type == RenderContextType.OPENGLES);

		if (!drawn)
		{
			trace("There is no window drawn with OpenGL here, so frames paced by vertical sync were not tested");
			Assert.pass();
			async.done();
			return;
		}

		var refresh:Float = window.displayMode != null ? window.displayMode.refreshRate : 0;
		if (refresh <= 0) refresh = 60;

		pace(FrameProfile.UNCAPPED, refresh, null, VSyncMode.ON);

		frames(0.5, function(times:Array<Float>, deltas:Array<Int>, cpu:Float)
		{
			var uncapped = rateOf(times);
			check(window, refresh, uncapped, uncapped <= refresh * 1.5);
		});
	}

	// Helpers

	#if windows
	private static inline var MOVES = 40;

	// Posts mouse moves to a hidden window together, with updates and mouse move listeners that take
	// as long as given, and gives the place each move heard was posted at, and the frame it came before
	private function inputBehindFrames(update:Float, listener:Float, async:Async, check:Array<Int>->Array<Int>->Void):Void
	{
		var application = Application.current;
		var window = openHiddenWindow();

		if (window == null)
		{
			async.done();
			return;
		}

		pace(FrameProfile.BALANCED, 60);

		var frame = 0;
		var heard:Array<Int> = [];
		var heardAt:Array<Int> = [];
		var start = 0.0;
		var finished = false;

		var onMove = function(x:Float, y:Float)
		{
			// The real cursor is not over the window, so SDL may add a move to its edge
			if (y != 7 || x < 1 || x > MOVES) return;
			heard.push(Std.int(x));
			heardAt.push(frame);
			spin(listener);
		};

		var onUpdate:Int->Void = null;
		onUpdate = function(_:Int)
		{
			frame++;
			spin(update);

			if (finished || start == 0 || (heardAt.length < MOVES && Timer.stamp() - start < 8)) return;

			finished = true;
			application.onUpdate.remove(onUpdate);
			window.onMouseMove.remove(onMove);
			restorePace();

			Timer.delay(function()
			{
				Assert.equals(MOVES, heardAt.length);
				if (heardAt.length > 1) check(heard, heardAt);
				async.done();
			}, 1);
		};

		window.onMouseMove.add(onMove);
		application.onUpdate.add(onUpdate);
		cleanups.push(function()
		{
			application.onUpdate.remove(onUpdate);
			window.onMouseMove.remove(onMove);
		});

		// WM_MOUSEMOVE, each at a place of its own, as SDL drops a move to where the mouse is
		var messages = [for (i in 0...MOVES) [0x0200, 0, i + 1, 7]];

		if (!postMessages(window, messages, 0))
		{
			finished = true;
			Assert.fail("the mouse messages could not be posted");
			async.done();
			return;
		}

		start = Timer.stamp();
	}

	private static inline var STREAM = 400;

	// Posts mouse moves to a hidden window 2 ms apart, at 10 frames a second, and gives how many were
	// posted and heard, how many turns of the loop they were heard in, and the seconds from the first
	// to the last. Moves handled in one turn come within microseconds of each other, and turns are a
	// wait apart.
	private function inputStream(profile:FrameProfile, async:Async, check:Int->Int->Int->Float->Void):Void
	{
		var application = Application.current;
		var window = openHiddenWindow();

		if (window == null)
		{
			async.done();
			return;
		}

		pace(profile, 10);

		var heard = 0;
		var wakes = 0;
		var first = 0.0;
		var last = 0.0;
		var posted = false;
		var postedAt = 0.0;
		var failed = false;
		var finished = false;

		var onMove = function(x:Float, y:Float)
		{
			if (y != 9 || x < 1 || x > 60) return;

			var now = Timer.stamp();
			if (heard == 0) first = now;

			// Half a millisecond or more since the last move heard is another turn
			if (heard == 0 || now - last >= 0.0005) wakes++;
			last = now;
			heard++;
		};

		var onUpdate:Int->Void = null;
		onUpdate = function(_:Int)
		{
			if (finished || !posted) return;

			// Moves that were posted and not heard within three seconds aren't coming
			var unheard = failed || (heard == 0 && Timer.stamp() - postedAt > 3);
			if (!unheard && (heard == 0 || (heard < STREAM && Timer.stamp() - last < 1.5))) return;

			finished = true;
			application.onUpdate.remove(onUpdate);
			window.onMouseMove.remove(onMove);
			restorePace();

			var seconds = last - first;
			Timer.delay(function()
			{
				if (failed) Assert.fail("the mouse messages could not be posted");
				else if (heard == 0) Assert.fail("none of the " + STREAM + " mouse moves posted was heard");
				else check(STREAM, heard, wakes, seconds);
				async.done();
			}, 1);
		};

		window.onMouseMove.add(onMove);
		application.onUpdate.add(onUpdate);
		cleanups.push(function()
		{
			application.onUpdate.remove(onUpdate);
			window.onMouseMove.remove(onMove);
		});

		// Each at another place than the one before, as SDL drops a move to where the mouse is
		var messages = [for (i in 0...STREAM) [0x0200, 0, (i % 60) + 1, 9]];

		Thread.create(function()
		{
			failed = !postMessages(window, messages, 2);
			postedAt = Timer.stamp();
			posted = true;
		});

		// Until the first move is heard
		last = Timer.stamp();
		first = last;
	}

	/**
		Posts each message, wParam and position to the window through PowerShell, the milliseconds given
		apart, and returns once they are in its queue
	**/
	private static function postMessages(window:Window, messages:Array<Array<Int>>, apart:Float):Bool
	{
		var hwnd = Int64.toStr(window.nativeHandle.window);
		var script = "$ErrorActionPreference = 'Stop'\n"
			+ "Add-Type -Namespace LimeTest -Name User32 -MemberDefinition '[DllImport(\"user32.dll\")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);'\n"
			+ "$h = [IntPtr][Int64]" + hwnd + "\n$ok = $true\n";

		if (apart > 0)
		{
			// A loop that keeps time by the clock, as a sleep lasts as long as the system's timer allows
			script += "$m = @(" + [for (message in messages) Std.string(message[2] + (message[3] << 16))].join(",") + ")\n"
				+ "$w = [Diagnostics.Stopwatch]::StartNew()\n"
				+ "for ($i = 0; $i -lt $m.Length; $i++) {\n"
				+ "  while ($w.Elapsed.TotalMilliseconds -lt $i * " + apart + ") { }\n"
				+ "  $ok = [LimeTest.User32]::PostMessage($h, " + messages[0][0] + ", [IntPtr]" + messages[0][1] + ", [IntPtr]$m[$i]) -and $ok\n"
				+ "}\n";
		}
		else
		{
			for (message in messages)
			{
				script += "$ok = [LimeTest.User32]::PostMessage($h, " + message[0] + ", [IntPtr](" + message[1] + "), [IntPtr](" + message[2] + " + ("
					+ message[3] + " -shl 16))) -and $ok\n";
			}
		}

		script += "if (-not $ok) { exit 1 }\n";

		var process = powerShell(script);
		var exitCode = process.exitCode();
		process.close();
		return exitCode == 0;
	}

	/**
		Posts mouse moves to the window through PowerShell, the milliseconds given apart, and after
		every so many sends it a message and waits for the answer. Returns how long each of those
		waited, in milliseconds.
	**/
	private static function sendDuringMoves(window:Window, moves:Int, apart:Float, every:Int):Array<Float>
	{
		var hwnd = Int64.toStr(window.nativeHandle.window);
		var script = "$ErrorActionPreference = 'Stop'\n"
			+ "Add-Type -Namespace LimeTest -Name User32 -MemberDefinition '[DllImport(\"user32.dll\")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);"
			+ " [DllImport(\"user32.dll\")] public static extern IntPtr SendMessageTimeoutW(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam, uint flags, uint timeout, out IntPtr result);'\n"
			+ "$h = [IntPtr][Int64]" + hwnd + "\n"
			+ "$r = [IntPtr]::Zero\n"
			+ "$w = [Diagnostics.Stopwatch]::StartNew()\n"
			+ "for ($i = 0; $i -lt " + moves + "; $i++) {\n"
			+ "  while ($w.Elapsed.TotalMilliseconds -lt $i * " + apart + ") { }\n"
			+ "  [void][LimeTest.User32]::PostMessage($h, 0x0200, [IntPtr]0, [IntPtr](($i % 60) + 1 + (9 -shl 16)))\n"
			+ "  if ($i % " + every + " -eq " + (every - 1) + ") {\n"
			+ "    $t = $w.Elapsed.TotalMilliseconds\n"
			// WM_NULL, which a window answers and does nothing about
			+ "    [void][LimeTest.User32]::SendMessageTimeoutW($h, 0, [IntPtr]0, [IntPtr]0, 0, 2000, [ref]$r)\n"
			+ "    [Console]::Out.WriteLine(($w.Elapsed.TotalMilliseconds - $t).ToString([Globalization.CultureInfo]::InvariantCulture))\n"
			+ "  }\n"
			+ "}\n";

		var process = powerShell(script);
		var output = process.stdout.readAll().toString();
		var exitCode = process.exitCode();
		process.close();

		var waits:Array<Float> = [];

		if (exitCode == 0)
		{
			for (line in output.split("\n"))
			{
				var wait = Std.parseFloat(StringTools.trim(line));
				if (!Math.isNaN(wait)) waits.push(wait);
			}
		}

		return waits;
	}

	private static function powerShell(script:String):sys.io.Process
	{
		// An encoded command is UTF-16, and needs no quoting
		var utf16 = Bytes.alloc(script.length * 2);
		for (i in 0...script.length)
		{
			utf16.setUInt16(i * 2, StringTools.fastCodeAt(script, i));
		}

		// HashLink starts a process by its path, without looking through PATH
		var root = Sys.getEnv("SystemRoot");
		var path = root != null ? root + "\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" : null;
		var executable = path != null && sys.FileSystem.exists(path) ? path : "powershell";

		return new sys.io.Process(executable, ["-NoProfile", "-NonInteractive", "-EncodedCommand", Base64.encode(utf16)]);
	}
	#end

	private function openHiddenWindow():Window
	{
		if (hiddenWindow == null)
		{
			// Left open, hidden, as closing the last window of the application ends it
			hiddenWindow = Application.current.createWindow({
				width: 64,
				height: 64,
				hidden: true,
				title: "FrameLoopTest"
			});
		}

		if (hiddenWindow == null)
		{
			if (!reported) trace("No window can be created here, so what needs one was not tested");
			reported = true;
			Assert.pass();
		}

		return hiddenWindow;
	}

	/** Frame options with the idle frame rate given **/
	private static function idleAt(rate:Float):FrameOptions
	{
		var options = Application.current.frameOptions;
		options.idleFrameRate = rate;
		return options;
	}

	// Counts the calls of an idle listener over six frames 200 ms apart, one that says it has more to
	// do or one that doesn't, and the frames
	private function idleCalls(more:Bool, done:Int->Int->Void):Void
	{
		var application = Application.current;
		var backend = @:privateAccess application.__backend;
		var previous = @:privateAccess backend.__idleCallback;
		var calls = 0;
		var counting = false;

		cleanups.push(function() @:privateAccess backend.__setIdleCallback(previous));

		@:privateAccess backend.__setIdleCallback(function()
		{
			if (counting) calls++;
			if (more) @:privateAccess backend.__idleAgain = true;
		});

		pace(FrameProfile.BALANCED, 5);

		var settle = 2;
		var updates = 0;
		var listener:Int->Void = null;

		listener = function(_:Int)
		{
			if (settle-- > 0) return;

			if (!counting)
			{
				counting = true;
				return;
			}

			if (++updates < 6) return;

			counting = false;
			application.onUpdate.remove(listener);
			@:privateAccess backend.__setIdleCallback(previous);
			restorePace();

			Timer.delay(function() done(calls, updates), 1);
		};

		application.onUpdate.add(listener);
		cleanups.push(function() application.onUpdate.remove(listener));
	}

	/**
		Frames come as given until `restorePace()`. Vertical sync is off unless it is asked for, so they
		are timed. They keep their rate while every window is minimised or hidden, which a desktop
		that shows no windows makes them, so the background frame rate doesn't stand in for the one set.
	**/
	private function pace(profile:FrameProfile, frameRate:Float, ?options:FrameOptions, ?vsync:VSyncMode):Void
	{
		var application = Application.current;
		var backend = @:privateAccess application.__backend;
		paced = true;
		if (options == null) options = application.frameOptions;
		options.backgroundFrameRate = 0;
		backend.configureFrameTiming(profile, frameRate, options);
		backend.setVSyncMode(vsync != null ? vsync : VSyncMode.OFF);
	}

	private function restorePace():Void
	{
		if (!paced) return;
		paced = false;

		var application = Application.current;
		var backend = @:privateAccess application.__backend;
		backend.configureFrameTiming(application.frameProfile, @:privateAccess application.__frameRate, application.frameOptions);
		backend.setVSyncMode(application.vsyncMode);
	}

	/**
		Gives the time of each update for the seconds given, in seconds, the `deltaTime` of each, and the
		processor time the application used between the first and the last, in seconds. The first
		`settle` updates after a change of pace aren't counted. The pace is restored before `done` is called.
	**/
	private function frames(seconds:Float, done:Array<Float>->Array<Int>->Float->Void, settle:Int = 5):Void
	{
		var application = Application.current;
		var times:Array<Float> = [];
		var deltas:Array<Int> = [];
		var cpuStart = 0.0;
		var listener:Int->Void = null;

		listener = function(deltaTime:Int)
		{
			if (settle-- > 0) return;

			if (times.length == 0) cpuStart = Sys.cpuTime();
			times.push(Timer.stamp());
			deltas.push(deltaTime);

			if (times[times.length - 1] - times[0] < seconds) return;

			var cpu = Sys.cpuTime() - cpuStart;
			application.onUpdate.remove(listener);
			restorePace();

			// The tests go on from here, so they leave the update first
			Timer.delay(function() done(times, deltas, cpu), 1);
		};

		application.onUpdate.add(listener);
		cleanups.push(function() application.onUpdate.remove(listener));
	}

	/**
		Uses the processor for the seconds given, as work would, where a sleep may last longer than asked.
		The clock is in milliseconds, so it may end up to one early.
	**/
	private static function spin(seconds:Float):Void
	{
		if (seconds <= 0) return;

		var until = Timer.stamp() + seconds;
		while (Timer.stamp() < until) {}
	}

	/** Updates a second, by the time from the first to the last **/
	private static function rateOf(times:Array<Float>):Float
	{
		if (times.length < 2) return 0;
		return (times.length - 1) / (times[times.length - 1] - times[0]);
	}

	/** The milliseconds from the first update to the last **/
	private static function elapsed(times:Array<Float>):Float
	{
		if (times.length < 2) return 0;
		return (times[times.length - 1] - times[0]) * 1000;
	}

	/** The milliseconds between each update and the one before **/
	private static function intervals(times:Array<Float>):Array<Float>
	{
		return [for (i in 1...times.length) (times[i] - times[i - 1]) * 1000];
	}

	/** The `deltaTime` of every update after the first, which counts from before the first **/
	private static function sum(deltas:Array<Int>):Int
	{
		var total = 0;
		for (i in 1...deltas.length) total += deltas[i];
		return total;
	}

	private static function median(values:Array<Float>):Float
	{
		if (values.length == 0) return 0;
		var sorted = values.copy();
		sorted.sort(Reflect.compare);
		return sorted[sorted.length >> 1];
	}

	private static function round(value:Float):Float
	{
		return Math.round(value * 10) / 10;
	}

	private static function round3(value:Float):Float
	{
		return Math.round(value * 1000) / 1000;
	}

	private static function percent(value:Float):String
	{
		return Math.round(value * 100) + "%";
	}
	#end
}
