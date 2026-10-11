package media;

import haxe.Timer;
#if (lime_cffi && lime_openal)
import lime.media.AudioManager;
import lime.media.openal.AL;
import lime.media.openal.ALC;
#end
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import lime.media.VideoSource;
import lime.system.System;
#if (lime_cffi && lime_openal)
import lime.utils.Int16Array;
#end
import utest.Assert;
import utest.Test;

class VideoSourceTest extends Test
{
	private static inline var PATH = "assets/video.mp4";

	// Opening can take seconds on a busy or cold machine, such as a CI runner
	private static inline var TIMEOUT = 15;

	public function new()
	{
		super();
	}

	public function testIsSupported():Void
	{
		#if flash
		Assert.isFalse(VideoSource.isSupported);
		#elseif js
		Assert.isTrue(VideoSource.isSupported);
		#else
		Assert.equals(VideoDecoder.isSupported, VideoSource.isSupported);
		#end
	}

	#if sys
	public function testOpenMissingFile():Void
	{
		var video = new VideoSource();

		Assert.isFalse(video.open("assets/missing.mp4"));
		Assert.isNull(video.source);
		Assert.isFalse(video.playing);
		Assert.equals(0, video.length);
		Assert.isFalse(video.readFrame(new VideoFrame()));
	}

	public function testPlaybackState():Void
	{
		var video = open();
		if (video == null) return;

		Assert.equals(PATH, video.source);
		Assert.equals(640, video.width);
		Assert.equals(360, video.height);
		Assert.isTrue(Math.abs(video.length - 2000) <= 100, "length " + video.length);
		Assert.isTrue(video.hasAudio);
		Assert.isFalse(video.playing);
		Assert.equals(0, video.currentTime);

		video.play();
		Assert.isTrue(video.playing);

		video.pause();
		Assert.isFalse(video.playing);

		video.currentTime = 1000;
		Assert.equals(1000, video.currentTime);

		video.stop();
		Assert.isFalse(video.playing);
		Assert.equals(0, video.currentTime);

		video.dispose();
		Assert.isNull(video.source);
	}

	public function testPausedVideoShowsItsFirstFrame():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(video, frame));
		Assert.isTrue(frame.time < 0.05, "first frame at " + frame.time);

		// While paused, no later frame becomes due
		Assert.isFalse(video.readFrame(frame));
		video.dispose();
	}

	public function testSeekShowsTheFrameAtTheNewTime():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		video.currentTime = 1500;

		Assert.isTrue(nextFrame(video, frame));
		Assert.isTrue(frame.time <= 1.501 && frame.time + frame.duration > 1.5, "frame at " + frame.time);
		video.dispose();
	}

	public function testSeekingAgainWhilePausedPlaysFromTheNewTime():Void
	{
		var video = open();
		if (video == null) return;

		// Each seek buffers the audio at its time while paused, so the second
		// has to replace what the first queued
		var frame = new VideoFrame();
		video.currentTime = 1500;
		run(video, frame, 0.3);
		video.currentTime = 200;
		run(video, frame, 0.3);

		// Audio left from the first seek would put the clock near 1500 ms
		video.play();
		var latest = 0;
		var end = Timer.stamp() + 0.5;

		while (Timer.stamp() < end)
		{
			video.readFrame(frame);
			if (video.currentTime > latest) latest = video.currentTime;
			Sys.sleep(0.005);
		}

		var time = video.currentTime;
		video.dispose();

		Assert.isTrue(latest <= 1000, "playing from 200 ms, the clock reached " + latest + " ms");
		Assert.isTrue(time >= 200, "playing from 200 ms, the clock read " + time + " ms");
	}

	public function testClockRunsInRealTime():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		startPlaying(video, frame);

		var rate = measureRate(video, frame, 1);
		Assert.floatEquals(1, rate, 0.1, "the clock ran at " + rate + " times real time");
		video.dispose();
	}

	public function testClockRunsInRealTimeAfterSeekingWhilePlaying():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		startPlaying(video, frame);

		video.currentTime = 1000;
		waitForTime(video, frame, 1050);

		var rate = measureRate(video, frame, 0.6);
		Assert.floatEquals(1, rate, 0.1, "after seeking, the clock ran at " + rate + " times real time");
		video.dispose();
	}

	public function testFramesKeepUpWithTheClock():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		startPlaying(video, frame);

		var frames = 0;
		var worstLag = 0.0;
		var end = Timer.stamp() + 1;

		while (Timer.stamp() < end)
		{
			if (video.readFrame(frame))
			{
				frames++;

				// A frame is shown while the clock is within it. One that arrives
				// later shows the decoder falling behind.
				var lag = video.currentTime / 1000 - (frame.time + frame.duration);
				if (lag > worstLag) worstLag = lag;
			}

			Sys.sleep(0.002);
		}

		video.dispose();

		// A slow loop skips the frames it missed, so fewer than 30 a second is
		// fine as long as each one is current
		Assert.isTrue(frames >= 10, frames + " frames in a second");
		Assert.isTrue(worstLag < 0.1, "a frame was shown " + Math.round(worstLag * 1000) + " ms after it ended");
	}

	public function testGainAndLoops():Void
	{
		var video = open();
		if (video == null) return;

		video.gain = 0.5;
		video.loops = 2;

		Assert.equals(0.5, video.gain);
		Assert.equals(2, video.loops);
		video.dispose();
	}

	public function testPanStaysInRange():Void
	{
		var video = open();
		if (video == null) return;

		Assert.equals(0.0, video.pan);

		video.pan = -0.5;
		Assert.equals(-0.5, video.pan);

		video.pan = 2;
		Assert.equals(1.0, video.pan);
		video.dispose();
	}

	#if (lime_cffi && lime_openal)
	public function testClockCarriesOnWhenTheAudioOutputStalls():Void
	{
		var video = open();
		if (video == null) return;

		var context = ALC.getCurrentContext();
		var device = context != null ? ALC.getContextsDevice(context) : null;

		if (device == null)
		{
			Assert.warn("There is no audio output here, so a stalled output was not tested");
			video.dispose();
			return;
		}

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// A paused device stops taking audio, as a sound server that hangs does
		var before = video.currentTime;
		ALC.pauseDevice(device);
		run(video, frame, 1.6);
		ALC.resumeDevice(device);

		var moved = video.currentTime - before;
		video.dispose();

		Assert.isTrue(moved >= 500, "the clock moved " + moved + " ms in 1.6 s while the output was stalled");
	}

	public function testBadAudioPositionsDoNotMoveTheClock():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// A source whose device went away can report any position, here an hour
		// past the audio that is queued
		var before = video.currentTime;
		var bufferTimes:Array<Float> = @:privateAccess video.__backend.bufferTimes;

		for (i in 0...bufferTimes.length)
		{
			bufferTimes[i] += 3600;
		}

		var latest = 0;
		var end = Timer.stamp() + 0.4;

		while (Timer.stamp() < end)
		{
			video.readFrame(frame);
			if (video.currentTime > latest) latest = video.currentTime;
			Sys.sleep(0.005);
		}

		video.dispose();

		Assert.isTrue(latest < before + 1000, "after a bad audio position at " + before + " ms, the clock reached " + latest + " ms");
		Assert.isTrue(latest > before, "the clock stopped at " + before + " ms");
	}

	public function testSuspendedAudioHoldsTheVideo():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// Lime suspends audio while the window is hidden, which is not a stall,
		// so the video waits for it
		var before = video.currentTime;
		AudioManager.suspend();
		run(video, frame, 1.6);
		var held = video.currentTime - before;
		AudioManager.resume();
		run(video, frame, 0.4);
		var resumed = video.currentTime - before - held;

		video.dispose();

		Assert.isTrue(held < 150, "the clock moved " + held + " ms while audio was suspended");
		Assert.isTrue(resumed >= 200, "the clock moved " + resumed + " ms in 0.4 s after audio resumed");
	}

	public function testPanTurnsDownTheOppositeChannel():Void
	{
		for (pan in [-1.0, 1.0])
		{
			var video = open();
			if (video == null) return;

			if (!hasAudioOutput())
			{
				video.dispose();
				return;
			}

			// Both channels of the test video carry a loud tone
			var frame = new VideoFrame();
			video.pan = pan;
			startPlaying(video, frame);

			var peaks = bufferedPeaks(video);
			video.dispose();

			var opposite = pan < 0 ? peaks[1] : peaks[0];
			var kept = pan < 0 ? peaks[0] : peaks[1];
			Assert.equals(0, opposite, "with pan " + pan + ", the opposite channel peaked at " + opposite);
			Assert.isTrue(kept > 1000, "with pan " + pan + ", the panned channel peaked at " + kept);
		}
	}

	public function testVideoPlaysOnWhenTheAudioDeviceIsReplaced():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// Lime replaces the OpenAL context when the output device is unplugged or
		// changes, and the sources move to the new one
		var before = video.currentTime;
		@:privateAccess AudioManager.recoverOutputDevice();
		run(video, frame, 0.8);

		var moved = video.currentTime - before;
		var error = AL.getError();
		video.dispose();

		Assert.isTrue(moved >= 500, "the clock moved " + moved + " ms in 0.8 s after the device was replaced");
		Assert.equals(AL.NO_ERROR, error);
	}
	#end

	#if (lime_cffi && lime_openal)
	private static function bufferedPeaks(video:VideoSource):Array<Int>
	{
		// The left and right peaks of the audio last given to OpenAL
		var samples:Int16Array = @:privateAccess video.__backend.audioSamples;
		var peaks = [0, 0];

		for (i in 0...samples.length)
		{
			var value = Std.int(Math.abs(samples[i]));
			if (value > peaks[i & 1]) peaks[i & 1] = value;
		}

		return peaks;
	}

	private static function hasAudioOutput():Bool
	{
		if (ALC.getCurrentContext() != null) return true;

		Assert.warn("There is no audio output here, so it was not tested");
		return false;
	}
	#end

	private static function startPlaying(video:VideoSource, frame:VideoFrame):Void
	{
		// The clock holds until the first frame and the audio arrive, which can
		// take a moment after opening
		video.play();
		waitForTime(video, frame, 50);
	}

	private static function waitForTime(video:VideoSource, frame:VideoFrame, time:Int):Void
	{
		var end = Timer.stamp() + TIMEOUT;

		while (video.currentTime < time && Timer.stamp() < end)
		{
			video.readFrame(frame);
			Sys.sleep(0.005);
		}

		Assert.isTrue(video.currentTime >= time, "the clock did not reach " + time + " ms");
	}

	private static function measureRate(video:VideoSource, frame:VideoFrame, seconds:Float):Float
	{
		// The monotonic clock the video keeps time with
		var startTime = video.currentTime;
		var start = System.getTimer();
		run(video, frame, seconds);

		return (video.currentTime - startTime) / (System.getTimer() - start);
	}

	private static function nextFrame(video:VideoSource, frame:VideoFrame):Bool
	{
		var start = Timer.stamp();

		while (!video.readFrame(frame))
		{
			if (Timer.stamp() - start > TIMEOUT) return false;
			Sys.sleep(0.001);
		}

		return true;
	}

	private static function run(video:VideoSource, frame:VideoFrame, seconds:Float):Void
	{
		// Keeps the video updating, as a render loop would
		var end = Timer.stamp() + seconds;

		while (Timer.stamp() < end)
		{
			video.readFrame(frame);
			Sys.sleep(0.005);
		}
	}

	private static function open():VideoSource
	{
		if (!VideoSource.isSupported)
		{
			Assert.pass();
			return null;
		}

		var video = new VideoSource();

		if (!video.open(PATH))
		{
			Assert.warn("Cannot decode H.264 and AAC here, so video playback was not tested");
			return null;
		}

		return video;
	}
	#end
}
