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
import utest.Assert;
import utest.Test;

class VideoSourceTest extends Test
{
	private static inline var PATH = "assets/video.mp4";

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
		video.play();
		run(video, frame, 0.2);

		Assert.floatEquals(1, measureRate(video, frame, 1), 0.1, "playback rate");
		video.dispose();
	}

	public function testClockRunsInRealTimeAfterSeekingWhilePlaying():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		video.play();
		run(video, frame, 0.3);

		video.currentTime = 1000;
		run(video, frame, 0.15);

		Assert.isTrue(video.currentTime >= 1000, "playing on from 1000 ms, the clock read " + video.currentTime + " ms");
		Assert.floatEquals(1, measureRate(video, frame, 0.6), 0.1, "playback rate after seeking");
		video.dispose();
	}

	public function testFramesArriveAtTheFrameRate():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		video.play();
		run(video, frame, 0.2);

		var frames = 0;
		var end = Timer.stamp() + 1;

		while (Timer.stamp() < end)
		{
			if (video.readFrame(frame)) frames++;
			Sys.sleep(0.002);
		}

		video.dispose();

		// The video is 30 fps, and each frame is shown once
		Assert.isTrue(Math.abs(frames - 30) <= 4, frames + " frames in a second");
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
		video.play();
		run(video, frame, 0.3);

		// A paused device stops taking audio, as a sound server that hangs does
		var before = video.currentTime;
		ALC.pauseDevice(device);
		run(video, frame, 1.6);
		ALC.resumeDevice(device);

		var moved = video.currentTime - before;
		video.dispose();

		Assert.isTrue(moved >= 500, "the clock moved " + moved + " ms in 1.6 s while the output was stalled");
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
		video.play();
		run(video, frame, 0.3);

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
		video.play();
		run(video, frame, 0.3);

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
	private static function hasAudioOutput():Bool
	{
		if (ALC.getCurrentContext() != null) return true;

		Assert.warn("There is no audio output here, so it was not tested");
		return false;
	}
	#end

	private static function measureRate(video:VideoSource, frame:VideoFrame, seconds:Float):Float
	{
		var startTime = video.currentTime;
		var start = Timer.stamp();
		run(video, frame, seconds);

		return (video.currentTime - startTime) / 1000 / (Timer.stamp() - start);
	}

	private static function nextFrame(video:VideoSource, frame:VideoFrame):Bool
	{
		var start = Timer.stamp();

		while (!video.readFrame(frame))
		{
			if (Timer.stamp() - start > 5) return false;
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
