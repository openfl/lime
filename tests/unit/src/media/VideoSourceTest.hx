package media;

import haxe.Timer;
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
