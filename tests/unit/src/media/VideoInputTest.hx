package media;

import haxe.io.Bytes;
import haxe.Timer;
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import lime.media.VideoSource;
import utest.Assert;
import utest.Test;
#if sys
import lime.system.System;
import sys.FileSystem;
import sys.io.File;
#end

/**
	Decodes files that are damaged, unusual, or at unusual paths, which
	players meet in production. The clips in assets were written by Media
	Foundation's sink writer:

	- video-noaudio.mp4: 320x180 H.264 at 15 fps for a second, without sound.
	  Baseline profile, so with no B-frames its 15 frames fill exactly its
	  length, which the loop tests count on every platform.
	- audio-only.m4a: a second of AAC stereo, without video
	- video-odd.mp4: 330x186, so its size is not a multiple of 16
	- video-51.mp4: 320x180 with six channel AAC, which is mixed down to stereo
	- video-anamorphic.mp4: 320x180 with pixels 4:3 as wide as tall, which the
	  encoder wrote into the stream, given a matching pasp box by hand
	- video-hdr-pq.mp4 and video-hdr-hlg.mp4: 320x180 BT.2020 patches on black,
	  gray along the top and red and green below, given the PQ or HLG transfer
	  in the stream and in a colr box by hand. The PQ grays are 10, 100, 203
	  and 1000 nits and the colors 203, and the HLG grays a quarter, half,
	  three quarters and all of the signal and the colors three quarters.

	These were then edited box by box:

	- video-rotated.mp4: video-noaudio.mp4 with its track turned a quarter
	  clockwise, as phones store video recorded upright
	- video-unsupported.mp4: video.mp4 with its picture marked as a codec that
	  nothing decodes, as for a codec the platform lacks
**/
class VideoInputTest extends Test
{
	private static inline var PATH = "assets/video.mp4";
	private static inline var TIMEOUT = 15;

	public function new()
	{
		super();
	}

	#if sys
	public function testWhatIsNotAVideoIsNotOpened():Void
	{
		if (!canDecode()) return;

		var directory = scratchDirectory();
		var video = readAsset(PATH);
		var noise = Bytes.alloc(4096);
		var seed = 1;

		for (i in 0...noise.length)
		{
			seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
			noise.set(i, seed >> 16);
		}

		// The index of the test video is at its end, so the first half has none
		var files = [
			"empty.mp4" => Bytes.alloc(0),
			"text.mp4" => Bytes.ofString("This is not a video."),
			"noise.mp4" => noise,
			"cut.mp4" => video.sub(0, Std.int(video.length / 2))
		];

		for (name in files.keys())
		{
			var path = directory + "/" + name;
			File.saveBytes(path, files.get(name));

			var decoder = new VideoDecoder();
			Assert.isFalse(decoder.open(path), name + " opened");
			Assert.isFalse(decoder.readFrame(new VideoFrame()), name + " gave a frame");
			decoder.close();
		}

		Assert.isFalse(new VideoDecoder().open(directory), "a directory opened");
		Assert.isFalse(new VideoDecoder().open(directory + "/missing.mp4"), "a missing file opened");
	}

	public function testDamagedVideoPlaysToTheEnd():Void
	{
		if (!canDecode()) return;

		// Noise over the middle of the frames and sound, with the index intact
		var bytes = readAsset(PATH);
		var seed = 7;

		for (i in Std.int(bytes.length * 0.3)...Std.int(bytes.length * 0.6))
		{
			seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
			bytes.set(i, seed >> 16);
		}

		var path = scratchDirectory() + "/damaged.mp4";
		File.saveBytes(path, bytes);

		var decoder = new VideoDecoder();

		if (!decoder.open(path))
		{
			// Refusing a damaged file is fine too
			Assert.pass();
			return;
		}

		var frames = readToTheEnd(decoder);
		decoder.close();

		Assert.isTrue(frames.ended, "decoding did not finish, after " + frames.count + " frames");
	}

	public function testPathsWithAnyCharacters():Void
	{
		if (!canDecode()) return;

		#if (windows && !cpp)
		// Only hxcpp writes Unicode file names on Windows, which the test needs
		Assert.pass();
		#else
		var directory = scratchDirectory() + "/files & folders";
		if (!FileSystem.exists(directory)) FileSystem.createDirectory(directory);

		for (name in ["with spaces.mp4", "#1 100% done.mp4", "vidéo ünïcødé 日本語.mp4"])
		{
			var path = directory + "/" + name;
			File.saveBytes(path, readAsset(PATH));

			var decoder = new VideoDecoder();
			Assert.isTrue(decoder.open(path), "could not open " + name);
			Assert.isTrue(nextFrame(decoder, new VideoFrame()), "no frame from " + name);
			decoder.close();
		}
		#end
	}

	public function testSeekingOutsideTheVideo():Void
	{
		var decoder = open(PATH);
		if (decoder == null) return;

		var frame = new VideoFrame();

		// Past the end, and to the end, it finishes rather than waiting
		for (time in [10.0, decoder.duration])
		{
			decoder.seek(time);
			var frames = readToTheEnd(decoder);
			Assert.isTrue(frames.ended, "after seeking to " + time + " s, decoding did not finish");
			Assert.isTrue(frames.count <= 1, "after seeking to " + time + " s, " + frames.count + " frames came");
		}

		// Before the start is the start
		decoder.seek(-5);
		Assert.isTrue(nextFrame(decoder, frame), "no frame after seeking before the start");
		Assert.isTrue(frame.time < 0.1, "after seeking before the start, the first frame was at " + frame.time + " s");
		decoder.close();
	}

	public function testOpeningAndClosingAgainAndAgain():Void
	{
		if (!canDecode()) return;

		var frame = new VideoFrame();
		var audio = Bytes.alloc(4096);
		var formats:Array<VideoFrameFormat> = [NV12, RGBA, BGRA];

		for (i in 0...20)
		{
			var decoder = VideoDecoder.fromFile(PATH, formats[i % formats.length]);
			Assert.notNull(decoder, "opening failed on try " + i);
			if (decoder == null) return;

			// Some are closed straight away, while they are still decoding
			if (i % 3 != 0)
			{
				Assert.isTrue(nextFrame(decoder, frame), "no frame on try " + i);
				decoder.readAudio(audio, 0, audio.length);
			}

			decoder.close();
		}
	}

	public function testTwoVideosAtOnce():Void
	{
		var first = open(PATH, NV12);
		var second = open(PATH, RGBA);

		if (first == null || second == null)
		{
			if (first != null) first.close();
			if (second != null) second.close();
			return;
		}

		var frameA = new VideoFrame();
		var frameB = new VideoFrame();
		var lastA = -1.0;
		var lastB = -1.0;

		for (i in 0...20)
		{
			Assert.isTrue(nextFrame(first, frameA) && nextFrame(second, frameB), "frame " + i + " did not come from both");
			Assert.isTrue(frameA.time > lastA && frameB.time > lastB, "frames came out of order");
			lastA = frameA.time;
			lastB = frameB.time;
		}

		first.close();
		second.close();
	}

	public function testVideoWithoutSound():Void
	{
		var decoder = open("assets/video-noaudio.mp4");
		if (decoder == null) return;

		Assert.isTrue(decoder.hasVideo);
		Assert.isFalse(decoder.hasAudio);
		Assert.isTrue(decoder.audioComplete);
		Assert.equals(0, decoder.readAudio(Bytes.alloc(64), 0, 64));

		var frames = readToTheEnd(decoder);
		decoder.close();

		Assert.isTrue(frames.ended, "decoding did not finish");
		Assert.isTrue(Math.abs(frames.count - 15) <= 1, "read " + frames.count + " frames");
	}

	public function testSoundWithoutVideo():Void
	{
		var decoder = open("assets/audio-only.m4a");
		if (decoder == null) return;

		Assert.isFalse(decoder.hasVideo);
		Assert.isTrue(decoder.hasAudio);
		Assert.isTrue(decoder.videoComplete);
		Assert.equals(0, decoder.width);
		Assert.isFalse(decoder.readFrame(new VideoFrame()));

		var buffer = Bytes.alloc(16384);
		var total = 0;
		var start = Timer.stamp();

		while (!decoder.audioComplete && Timer.stamp() - start < TIMEOUT)
		{
			var length = decoder.readAudio(buffer, 0, buffer.length);
			if (length > 0) total += length else Sys.sleep(0.001);
		}

		var seconds = total / (decoder.audioSampleRate * decoder.audioChannels * 2);
		decoder.close();

		Assert.isTrue(Math.abs(seconds - 1) < 0.1, "read " + seconds + " s of sound");
	}

	public function testUnusualSize():Void
	{
		var decoder = open("assets/video-odd.mp4", RGBA);
		if (decoder == null) return;

		Assert.equals(330, decoder.width);
		Assert.equals(186, decoder.height);

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(decoder, frame));
		Assert.equals(330 * 186 * 4, frame.length);

		// The red block is at the top right, so rows and columns line up
		var offset = (64 * 330 + 330 - 64) * 4;
		var red = [frame.data[offset], frame.data[offset + 1], frame.data[offset + 2]];
		Assert.isTrue(red[0] > 200 && red[1] < 50 && red[2] < 50, "the red block reads " + red);

		var frames = readToTheEnd(decoder);
		decoder.close();

		Assert.isTrue(frames.ended, "decoding did not finish");
	}

	public function testSurroundSoundIsMixedToStereo():Void
	{
		var decoder = open("assets/video-51.mp4");
		if (decoder == null) return;

		Assert.equals(2, decoder.audioChannels);

		// The tone is on every channel, so both sides of the mix carry it
		var buffer = Bytes.alloc(48000);
		var peaks = [0, 0];
		var read = 0;
		var start = Timer.stamp();

		while (read < buffer.length && !decoder.audioComplete && Timer.stamp() - start < TIMEOUT)
		{
			var length = decoder.readAudio(buffer, read, buffer.length - read);
			if (length > 0) read += length else Sys.sleep(0.001);
		}

		var i = 0;

		while (i + 3 < read)
		{
			for (channel in 0...2)
			{
				var sample = buffer.getUInt16(i + channel * 2);
				if (sample >= 32768) sample -= 65536;
				if (Std.int(Math.abs(sample)) > peaks[channel]) peaks[channel] = Std.int(Math.abs(sample));
			}

			i += 4;
		}

		decoder.close();

		Assert.isTrue(read > 0, "no sound was read");
		Assert.isTrue(peaks[0] > 500 && peaks[1] > 500, "the stereo mix peaks at " + peaks);
	}

	public function testRotatedVideoReportsItsRotation():Void
	{
		// Stored sideways, to be shown turned a quarter clockwise. Some platforms
		// turn the frames as they decode them, and then report no rotation.
		for (hardware in [true, false])
		{
			var decoder = openWith("assets/video-rotated.mp4", hardware);
			if (decoder == null) return;

			var described = (hardware ? "hardware" : "software") + " decoding gave rotation " + decoder.rotation + " for " + decoder.width + "x"
				+ decoder.height + " frames";
			Assert.equals(180, decoder.displayWidth, described);
			Assert.equals(320, decoder.displayHeight, described);
			Assert.isTrue(decoder.rotation == 90 && decoder.width == 320 || decoder.rotation == 0 && decoder.width == 180, described);

			// Frames have the size reported
			var frame = new VideoFrame();
			Assert.isTrue(nextFrame(decoder, frame), "no frame");
			Assert.equals(decoder.width, frame.width, described);
			Assert.equals(decoder.height, frame.height, described);
			decoder.close();
		}

		var decoder = open("assets/video-noaudio.mp4");
		if (decoder == null) return;

		Assert.equals(0, decoder.rotation);
		Assert.equals(320, decoder.displayWidth);
		Assert.equals(180, decoder.displayHeight);
		decoder.close();
	}

	public function testAnamorphicVideoReportsItsPixelShape():Void
	{
		// 320 pixels that are each 4:3 as wide as tall are shown 427 wide. Some
		// platforms stretch the frames as they decode them, and then report
		// square pixels.
		for (hardware in [true, false])
		{
			var decoder = openWith("assets/video-anamorphic.mp4", hardware);
			if (decoder == null) return;

			var described = (hardware ? "hardware" : "software") + " decoding gave pixels " + decoder.pixelAspectRatio + " wide for "
				+ decoder.width + "x" + decoder.height + " frames";
			Assert.isTrue(Math.abs(decoder.displayWidth - 427) <= 2, described + ", shown " + decoder.displayWidth + " wide");
			Assert.equals(180, decoder.displayHeight, described);
			Assert.isTrue(Math.abs(decoder.pixelAspectRatio - 4 / 3) < 0.01 && decoder.width == 320
				|| decoder.pixelAspectRatio == 1 && Math.abs(decoder.width - 427) <= 2, described);
			decoder.close();
		}

		var decoder = open("assets/video-noaudio.mp4");
		if (decoder == null) return;

		Assert.floatEquals(1, decoder.pixelAspectRatio);
		decoder.close();
	}

	public function testHDRVideoIsShownInStandardRange():Void
	{
		// The reference white, 203 nits or three quarters of HLG, is shown near
		// white, and brighter grays no darker, rather than the frames being
		// shown as they are stored, which leaves them dim and gray
		for (transfer in ["pq", "hlg"])
		{
			for (hardware in [true, false])
			{
				var decoder = openWith("assets/video-hdr-" + transfer + ".mp4", hardware);
				if (decoder == null) return;

				decoder.close();
				Assert.isTrue(decoder.open("assets/video-hdr-" + transfer + ".mp4", RGBA));

				var frame = new VideoFrame();
				var described = transfer + " with " + (hardware ? "hardware" : "software") + " decoding";

				if (!nextFrame(decoder, frame))
				{
					Assert.fail("no frame from " + described);
					decoder.close();
					continue;
				}

				var grays = [for (i in 0...4) patch(frame, 48 + i * 76, 48)];
				var red = patch(frame, 48, 132);
				var green = patch(frame, 124, 132);
				var shown = described + " showed grays " + [for (gray in grays) gray[1]] + ", red " + red + " and green " + green;
				decoder.close();

				for (i in 1...4)
				{
					Assert.isTrue(grays[i][1] >= grays[i - 1][1], shown);
				}

				Assert.isTrue(grays[0][1] < 128, shown);
				Assert.isTrue(grays[2][1] >= 200, shown);
				Assert.isTrue(grays[3][1] >= 225, shown);
				Assert.isTrue(red[0] >= 180 && red[1] < 90 && red[2] < 90, shown);
				Assert.isTrue(green[1] >= 180 && green[0] < 90 && green[2] < 90, shown);
			}
		}
	}

	public function testVideoInAMissingCodecPlaysItsSound():Void
	{
		var decoder = open("assets/video-unsupported.mp4");
		if (decoder == null) return;

		Assert.isFalse(decoder.hasVideo, "the picture was decoded");
		Assert.isTrue(decoder.hasAudio, "the sound was left out");

		// Android's extractor gives a track in a codec it does not know no type,
		// so only a known codec that the device cannot decode is reported there
		#if android
		Assert.pass();
		#else
		Assert.isTrue(decoder.videoUnsupported, "the picture that cannot be decoded was not reported");
		#end
		Assert.isFalse(decoder.audioUnsupported);

		var frames = readToTheEnd(decoder);
		decoder.close();

		Assert.isTrue(frames.ended, "decoding did not finish");
		Assert.equals(0, frames.count);

		decoder = open(PATH);
		if (decoder == null) return;

		Assert.isFalse(decoder.videoUnsupported);
		Assert.isFalse(decoder.audioUnsupported);
		decoder.close();
	}

	public function testSeekingReportsWhetherItMoved():Void
	{
		var decoder = open(PATH);
		if (decoder == null) return;

		var frame = new VideoFrame();
		Assert.isTrue(decoder.seek(1), "seeking a file failed");
		Assert.isTrue(nextFrame(decoder, frame), "no frame after seeking");
		Assert.isTrue(frame.time > 0.9 && frame.time < 1.1, "after seeking to 1 s, the first frame was at " + frame.time + " s");
		Assert.isFalse(decoder.error);
		decoder.close();

		Assert.isFalse(decoder.seek(1), "a closed decoder seeked");
	}

	public function testVideoWithoutSoundLoopsWithoutAPause():Void
	{
		if (!canDecode()) return;

		var video = new VideoSource("assets/video-noaudio.mp4");
		var completed = false;
		video.onComplete.add(function() completed = true);
		video.loops = 2;
		video.play();

		// Frames come at 15 per second through both loop points
		var frame = new VideoFrame();
		var frames = 0;
		var lastFrame = -1.0;
		var longestGap = 0.0;
		var decoder = @:privateAccess video.__backend.decoder;
		var handovers = 0;
		var start = Timer.stamp();

		while (!completed && Timer.stamp() - start < TIMEOUT)
		{
			if (@:privateAccess video.__backend.decoder != decoder && @:privateAccess video.__backend.decoder != null)
			{
				decoder = @:privateAccess video.__backend.decoder;
				handovers++;
			}

			if (video.readFrame(frame))
			{
				var now = Timer.stamp();
				if (lastFrame >= 0 && now - lastFrame > longestGap) longestGap = now - lastFrame;
				lastFrame = now;
				frames++;
			}

			var end = Timer.stamp() + 0.005;
			while (Timer.stamp() < end) {}
		}

		var elapsed = Timer.stamp() - start;
		video.dispose();

		Assert.isTrue(completed, "playback did not complete");
		Assert.equals(2, handovers, "the next loops did not take over");
		Assert.isTrue(Math.abs(frames - 45) <= 3, "showed " + frames + " frames of three loops of 15");
		Assert.isTrue(elapsed > 2.7 && elapsed < 3.6, "three loops of a second played in " + elapsed + " s");
		Assert.isTrue(longestGap < 0.2, "frames stopped for " + Math.round(longestGap * 1000) + " ms");
	}

	public function testVideoSourceWithoutSoundPlaysToTheEnd():Void
	{
		if (!canDecode()) return;

		var video = new VideoSource("assets/video-noaudio.mp4");
		var completed = false;
		video.onComplete.add(function() completed = true);
		video.play();

		var frame = new VideoFrame();
		var start = Timer.stamp();

		while (!completed && Timer.stamp() - start < TIMEOUT)
		{
			video.readFrame(frame);
			Sys.sleep(0.005);
		}

		var elapsed = Timer.stamp() - start;
		video.dispose();

		Assert.isTrue(completed, "playback did not complete");
		Assert.isTrue(elapsed > 0.8 && elapsed < 3, "a second of video played in " + elapsed + " s");
	}

	public function testVideoSourceWithoutVideoPlaysToTheEnd():Void
	{
		if (!canDecode()) return;

		var video = new VideoSource("assets/audio-only.m4a");
		var completed = false;
		video.onComplete.add(function() completed = true);
		video.play();

		var frame = new VideoFrame();
		var frames = 0;
		var start = Timer.stamp();

		while (!completed && Timer.stamp() - start < TIMEOUT)
		{
			if (video.readFrame(frame)) frames++;
			Sys.sleep(0.005);
		}

		var elapsed = Timer.stamp() - start;
		video.dispose();

		Assert.isTrue(completed, "playback did not complete");
		Assert.equals(0, frames);
		Assert.isTrue(elapsed > 0.8 && elapsed < 3, "a second of sound played in " + elapsed + " s");
	}

	private static function canDecode():Bool
	{
		var decoder = open(PATH);
		if (decoder == null) return false;
		decoder.close();
		return true;
	}

	private static function nextFrame(decoder:VideoDecoder, frame:VideoFrame):Bool
	{
		var start = Timer.stamp();

		while (!decoder.readFrame(frame))
		{
			if (decoder.videoComplete || Timer.stamp() - start > TIMEOUT) return false;
			Sys.sleep(0.001);
		}

		return true;
	}

	private static function open(path:String, format:VideoFrameFormat = NV12):VideoDecoder
	{
		if (!VideoDecoder.isSupported)
		{
			Assert.pass();
			return null;
		}

		var decoder = VideoDecoder.fromFile(path, format);

		if (decoder == null)
		{
			Assert.warn("Cannot decode " + path + " here, so it was not tested");
		}

		return decoder;
	}

	private static function openWith(path:String, hardwareDecoding:Bool):VideoDecoder
	{
		if (!VideoDecoder.isSupported)
		{
			Assert.pass();
			return null;
		}

		var decoder = new VideoDecoder();
		decoder.hardwareDecoding = hardwareDecoding;

		if (!decoder.open(path))
		{
			Assert.warn("Cannot decode " + path + " here, so it was not tested");
			return null;
		}

		return decoder;
	}

	private static function patch(frame:VideoFrame, centerX:Int, centerY:Int):Array<Int>
	{
		// The average color of an RGBA frame around a point, away from the
		// blurring at the patch's edges
		var sum = [0, 0, 0];
		var count = 0;

		for (y in centerY - 8...centerY + 8)
		{
			for (x in centerX - 8...centerX + 8)
			{
				var offset = (y * frame.width + x) * 4;
				for (i in 0...3) sum[i] += frame.data[offset + i];
				count++;
			}
		}

		return [for (i in 0...3) Math.round(sum[i] / count)];
	}

	private static function readToTheEnd(decoder:VideoDecoder):{count:Int, ended:Bool}
	{
		// Reads every frame and all of the sound, until both finish or time runs out
		var frame = new VideoFrame();
		var audio = Bytes.alloc(16384);
		var count = 0;
		var start = Timer.stamp();

		while (!(decoder.videoComplete && decoder.audioComplete) && Timer.stamp() - start < TIMEOUT)
		{
			var progressed = false;

			if (decoder.readFrame(frame))
			{
				count++;
				progressed = true;
			}

			if (decoder.readAudio(audio, 0, audio.length) > 0) progressed = true;
			if (!progressed) Sys.sleep(0.001);
		}

		return {count: count, ended: decoder.videoComplete && decoder.audioComplete};
	}

	private static function readAsset(path:String):Bytes
	{
		// Where the decoder finds it, which tests can read before assets load,
		// including from inside an Android package
		var resolved = @:privateAccess VideoDecoder.__resolvePath(path);
		var bytes:Bytes = lime.utils.Bytes.fromFile(resolved);
		return bytes != null ? bytes : File.getBytes(resolved);
	}

	private static function scratchDirectory():String
	{
		var directory = System.applicationStorageDirectory + "video-test";
		if (!FileSystem.exists(directory)) FileSystem.createDirectory(directory);
		return directory;
	}
	#end
}
