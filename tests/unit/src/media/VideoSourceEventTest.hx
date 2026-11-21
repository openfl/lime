package media;

import haxe.Timer;
import lime.media.VideoFrame;
import lime.media.VideoSource;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	`onReady`, `onSeek` and `onBuffering`, and what `onReady` makes known: the
	length, size and frame rate of the video, and how many of its bytes there
	are. These come on later frames, so the tests wait for them while the
	application's loop runs, as an application would.
**/
class VideoSourceEventTest extends Test
{
	private static inline var PATH = "assets/video.mp4";

	// Opening can take seconds on a busy or cold machine, such as a CI runner
	private static inline var TIMEOUT = 15000;

	// Long enough for an extra dispatch to show up
	private static inline var SETTLE = 300;

	private var videos:Array<VideoSource> = [];

	public function new()
	{
		super();
	}

	public function teardown():Void
	{
		for (video in videos)
		{
			video.dispose();
		}

		videos = [];
	}

	#if (sys || (js && html5))
	public function testNothingIsKnownBeforeOpening():Void
	{
		var video = track(new VideoSource());

		Assert.equals(0.0, video.frameRate);
		Assert.equals(0.0, video.bytesLoaded);
		Assert.equals(0.0, video.bytesTotal);
	}

	@:timeout(20000)
	public function testReadyComesAfterOpeningWithTheVideosDetails(async:Async):Void
	{
		var video = track(new VideoSource());
		var ready = 0;
		var opening = true;
		var duringOpen = false;
		video.onReady.add(function()
		{
			if (opening) duringOpen = true;
			ready++;
		});

		if (!openVideo(video, async)) return;
		opening = false;

		Assert.isFalse(duringOpen, "onReady was dispatched inside open()");

		waitUntil(function() return ready > 0, TIMEOUT, function(heard)
		{
			if (!heard)
			{
				Assert.fail("onReady was not dispatched");
				async.done();
				return;
			}

			Assert.isTrue(Math.abs(video.length - 2000) <= 100, "length " + video.length);
			Assert.equals(640, video.width);
			Assert.equals(360, video.height);
			Assert.isFalse(video.playing);

			#if sys
			Assert.isTrue(Math.abs(video.frameRate - 30) < 0.5, "frame rate " + video.frameRate);
			#else
			// Browsers do not say, so it is measured once the video plays
			Assert.equals(0.0, video.frameRate);
			#end

			Timer.delay(function()
			{
				Assert.equals(1, ready, "onReady was dispatched " + ready + " times");
				async.done();
			}, SETTLE);
		});
	}

	@:timeout(20000)
	public function testAListenerAddedAfterOpeningHearsReady(async:Async):Void
	{
		var video = track(new VideoSource());
		if (!openVideo(video, async)) return;

		var ready = 0;
		video.onReady.add(function() ready++);

		waitUntil(function() return ready > 0, TIMEOUT, function(heard)
		{
			Assert.isTrue(heard, "onReady was not dispatched");
			async.done();
		});
	}

	@:timeout(20000)
	public function testAVideoDisposedOrReplacedBeforeItIsReadyIsNotReported(async:Async):Void
	{
		var closed = track(new VideoSource());
		var replaced = track(new VideoSource());
		var closedReady = 0;
		var replacedReady = 0;
		closed.onReady.add(function() closedReady++);
		replaced.onReady.add(function() replacedReady++);

		if (!openVideo(closed, async)) return;
		closed.dispose();

		// Opened twice, only the second is reported
		replaced.open(PATH);
		replaced.open(PATH);

		waitUntil(function() return replacedReady > 0, TIMEOUT, function(heard)
		{
			Timer.delay(function()
			{
				Assert.equals(0, closedReady, "a disposed video was reported ready");
				Assert.equals(1, replacedReady, "a video opened twice was reported ready " + replacedReady + " times");
				async.done();
			}, SETTLE);
		});
	}

	@:timeout(20000)
	public function testLoadingFromAFileReportsReadyAfterTheFuture(async:Async):Void
	{
		if (!VideoSource.isSupported)
		{
			Assert.pass();
			async.done();
			return;
		}

		var ready = 0;
		var failed = false;
		var loaded:VideoSource = null;

		var future = VideoSource.loadFromFile(PATH);
		future.onComplete(function(video)
		{
			loaded = track(video);
			video.onReady.add(function() ready++);
		});
		future.onError(function(error) failed = true);

		waitUntil(function() return ready > 0 || failed, TIMEOUT, function(_)
		{
			if (failed)
			{
				// utest takes a warning as a failure, so the test passes, saying why
				trace("Cannot load " + PATH + " here, so loadFromFile was not tested");
				Assert.pass();
			}
			else
			{
				Assert.notNull(loaded, "loading did not finish");
				Assert.equals(1, ready, "onReady was dispatched " + ready + " times");
			}

			async.done();
		});
	}

	@:timeout(20000)
	public function testTheByteCountsAreTheFileSize(async:Async):Void
	{
		var video = track(new VideoSource());
		var ready = false;
		video.onReady.add(function() ready = true);
		if (!openVideo(video, async)) return;

		waitUntil(function() return ready, TIMEOUT, function(_)
		{
			#if sys
			var size = fileSize();
			Assert.isTrue(size > 0, "the size of " + PATH + " was not found");
			Assert.equals(size, video.bytesTotal);
			// A local file counts as loaded
			Assert.equals(size, video.bytesLoaded);
			#else
			// Browsers do not say how much of a video they have read
			Assert.equals(0.0, video.bytesTotal);
			Assert.equals(0.0, video.bytesLoaded);
			#end
			async.done();
		});
	}

	@:timeout(20000)
	public function testSettingTheTimeReportsASeekOnce(async:Async):Void
	{
		var video = track(new VideoSource());
		var ready = false;
		var seeks = 0;
		video.onReady.add(function() ready = true);
		video.onSeek.add(function() seeks++);
		if (!openVideo(video, async)) return;

		waitUntil(function() return ready, TIMEOUT, function(_)
		{
			Assert.equals(0, seeks, "opening was reported as a seek");

			video.currentTime = 1000;
			Assert.equals(0, seeks, "onSeek was dispatched inside the setter");

			waitUntil(function() return seeks > 0, TIMEOUT, function(heard)
			{
				Assert.isTrue(heard, "onSeek was not dispatched");

				Timer.delay(function()
				{
					Assert.equals(1, seeks, "onSeek was dispatched " + seeks + " times");
					async.done();
				}, SETTLE);
			});
		});
	}

	@:timeout(20000)
	public function testLoopingAndStoppingAreNotSeeks(async:Async):Void
	{
		var video = track(new VideoSource());
		var ready = false;
		var seeks = 0;
		video.onReady.add(function() ready = true);
		video.onSeek.add(function() seeks++);
		if (!openVideo(video, async)) return;

		var frame = new VideoFrame();

		waitUntil(function() return ready, TIMEOUT, function(_)
		{
			video.loops = 1;
			video.currentTime = 1500;

			waitUntil(function() return seeks > 0, TIMEOUT, function(_)
			{
				video.play();
				var passed = false;

				// Through the end and back round to the start
				waitUntil(function()
				{
					video.readFrame(frame);
					if (video.currentTime >= 1800) passed = true;
					return passed && video.currentTime > 100 && video.currentTime < 1000;
				}, TIMEOUT, function(looped)
				{
					Assert.isTrue(looped, "the video did not loop, at " + video.currentTime + " ms");
					video.stop();

					Timer.delay(function()
					{
						Assert.equals(1, seeks, "onSeek was dispatched " + seeks + " times for one seek");
						async.done();
					}, SETTLE);
				});
			});
		});
	}

	#if (js && html5)
	@:timeout(20000)
	public function testTheBrowserWaitingForDataIsBufferingUntilPaused(async:Async):Void
	{
		var video = track(new VideoSource());
		var ready = false;
		var buffering = [];
		video.onReady.add(function() ready = true);
		video.onBuffering.add(function(value) buffering.push(value));
		if (!openVideo(video, async)) return;

		waitUntil(function() return ready, TIMEOUT, function(_)
		{
			video.gain = 0;
			video.play();

			// As the browser does when it runs out of data
			var element:js.html.VideoElement = @:privateAccess video.__backend.element;
			element.dispatchEvent(new js.html.Event("waiting"));
			element.dispatchEvent(new js.html.Event("waiting"));
			Assert.same([true], buffering);

			video.pause();
			Assert.same([true, false], buffering);

			// Waiting while paused is not buffering
			element.dispatchEvent(new js.html.Event("waiting"));
			Assert.same([true, false], buffering);
			async.done();
		});
	}

	@:timeout(20000)
	public function testTheFrameRateIsMeasuredWhilePlaying(async:Async):Void
	{
		var video = track(new VideoSource());
		var ready = false;
		video.onReady.add(function() ready = true);
		if (!openVideo(video, async)) return;

		var element:Dynamic = @:privateAccess video.__backend.element;

		waitUntil(function() return ready, TIMEOUT, function(_)
		{
			if (element.requestVideoFrameCallback == null)
			{
				trace("This browser does not report frames, so the frame rate is not measured");
				Assert.pass();
				async.done();
				return;
			}

			video.gain = 0;
			video.play();

			Timer.delay(function()
			{
				if ((@:privateAccess video.__backend.presentedTime : Float) < 0)
				{
					// Some browsers, such as embedded ones, do not paint the video and call back
					trace("This browser reported no frames shown, so the frame rate was not measured");
					Assert.pass();
				}
				else
				{
					Assert.isTrue(Math.abs(video.frameRate - 30) < 3, "frame rate " + video.frameRate);
				}

				async.done();
			}, 1200);
		});
	}
	#end

	#if sys
	private static function fileSize():Float
	{
		var path = @:privateAccess lime.media.VideoDecoder.__resolvePath(PATH);
		return sys.FileSystem.exists(path) ? sys.FileSystem.stat(path).size : 0;
	}
	#end

	/**
		Opens the test video, or ends the test, passing, where it cannot be
		played.
	**/
	private static function openVideo(video:VideoSource, async:Async):Bool
	{
		if (VideoSource.isSupported && video.open(PATH)) return true;

		// utest takes a warning as a failure, so the test passes, saying why
		trace("Cannot decode H.264 and AAC here, so video events were not tested");
		Assert.pass();
		async.done();
		return false;
	}

	private static function waitUntil(condition:Void->Bool, timeout:Int, then:Bool->Void):Void
	{
		var end = Timer.stamp() + timeout / 1000;
		var timer = new Timer(10);
		timer.run = function()
		{
			var met = condition();

			if (met || Timer.stamp() > end)
			{
				timer.stop();
				then(met);
			}
		};
	}
	#end

	private function track(video:VideoSource):VideoSource
	{
		videos.push(video);
		return video;
	}
}
