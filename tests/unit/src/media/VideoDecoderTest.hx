package media;

import haxe.io.Bytes;
import haxe.Timer;
import lime.media.VideoColorMatrix;
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import utest.Assert;
import utest.Test;

/**
	Decodes assets/video.mp4: 640x360 H.264 at 30 fps with two seconds of
	AAC stereo. Each frame has a block at the top left whose luma encodes the
	frame number, a pure red block at the top right and a pure blue block at
	the bottom left, written with BT.709 values. The left channel is a 440 Hz
	tone.

	Decoding needs the platform's H.264 and AAC decoders, so those tests pass
	with a warning where there are none, such as on servers without media
	components.
**/
class VideoDecoderTest extends Test
{
	private static inline var MISSING = "assets/missing.mp4";
	private static inline var PATH = "assets/video.mp4";

	// Opening can take seconds on a busy or cold machine, such as a CI runner
	private static inline var TIMEOUT = 15;

	public function new()
	{
		super();
	}

	public function testOnlyNativeTargetsDecode():Void
	{
		#if (flash || js)
		Assert.isFalse(VideoDecoder.isSupported);
		#else
		Assert.pass();
		#end
	}

	public function testOpenMissingFile():Void
	{
		var decoder = new VideoDecoder();

		Assert.isFalse(decoder.open(MISSING));
		Assert.isNull(decoder.source);
		Assert.isFalse(decoder.hasVideo);
		Assert.isFalse(decoder.hasAudio);
		Assert.isTrue(decoder.videoComplete);
		Assert.isTrue(decoder.audioComplete);
		Assert.isFalse(decoder.readFrame(new VideoFrame()));
		Assert.equals(0, decoder.readAudio(Bytes.alloc(16), 0, 16));
		Assert.isNull(VideoDecoder.fromFile(MISSING));
	}

	#if sys
	public function testStreamInfo():Void
	{
		var decoder = open(NV12);
		if (decoder == null) return;

		Assert.equals(640, decoder.width);
		Assert.equals(360, decoder.height);
		Assert.floatEquals(30, decoder.frameRate, 0.1);
		Assert.floatEquals(2, decoder.duration, 0.1);
		Assert.isTrue(decoder.hasVideo);
		Assert.isTrue(decoder.hasAudio);
		Assert.equals(2, decoder.audioChannels);
		Assert.equals(48000, decoder.audioSampleRate);
		Assert.equals(PATH, decoder.source);

		decoder.close();
		Assert.isNull(decoder.source);
		Assert.isFalse(decoder.hasVideo);
	}

	public function testReadEveryFrame():Void
	{
		var decoder = open(NV12);
		if (decoder == null) return;

		var frame = new VideoFrame();
		var count = 0;
		var firstTime = 0.0;
		var lastTime = -1.0;
		var mismatches = 0;

		while (nextFrame(decoder, frame))
		{
			if (count == 0) firstTime = frame.time;

			Assert.equals(VideoFrameFormat.NV12, frame.format);
			Assert.equals(640, frame.width);
			Assert.equals(360, frame.height);
			Assert.equals(640 * 360 * 3 >> 1, frame.length);
			Assert.isTrue(frame.time > lastTime);

			if (Math.abs(lumaBlock(frame) - expectedLuma(frameIndex(frame, firstTime))) > 6) mismatches++;

			lastTime = frame.time;
			count++;
		}

		Assert.isTrue(decoder.videoComplete);
		Assert.isTrue(Math.abs(count - 60) <= 1, "read " + count + " frames");
		Assert.equals(0, mismatches, "frames whose content does not match their time");
		decoder.close();
	}

	public function testReadRGBA():Void
	{
		checkChannels(RGBA, 0, 1, 2, 3);
	}

	public function testReadBGRA():Void
	{
		checkChannels(BGRA, 2, 1, 0, 3);
	}

	public function testReadARGB():Void
	{
		checkChannels(ARGB, 1, 2, 3, 0);
	}

	public function testLateFramesAreSkipped():Void
	{
		var decoder = open(RGBA);
		if (decoder == null) return;

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(decoder, frame));

		// A player whose clock is ahead of the decoder, as when decoding falls
		// behind, is not given each late frame in turn, which would play them in
		// slow motion. The decoder skips them, keeping one a quarter of a second
		// at most while it catches up, besides the queued frame and the one being
		// converted when the later time is first asked for.
		var start = Timer.stamp();
		var late = 0;
		var reached = false;

		while (Timer.stamp() - start < TIMEOUT)
		{
			if (decoder.readFrame(frame, 1.5))
			{
				if (frame.time + frame.duration > 1.5)
				{
					reached = true;
					break;
				}

				late++;
			}

			Sys.sleep(0.001);
		}

		var elapsed = Timer.stamp() - start;
		var dropped = decoder.droppedFrames;
		decoder.close();

		Assert.isTrue(reached, "never reached the frame at 1.5 s");
		Assert.isTrue(late <= 2 + Std.int(elapsed / 0.25), "showed " + late + " late frames in " + elapsed + " s");
		Assert.isTrue(dropped >= 30, "counted " + dropped + " dropped frames");
	}

	public function testLateFramesAreKeptWhenAsked():Void
	{
		var decoder = new VideoDecoder();
		decoder.dropLateFrames = false;

		if (!decoder.open(PATH, RGBA))
		{
			Assert.pass();
			return;
		}

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(decoder, frame));

		// Without dropping, every frame comes in order, however late
		var count = 1;
		var lastTime = frame.time;

		while (nextFrame(decoder, frame, 1.5) && frame.time + frame.duration <= 1.5)
		{
			Assert.isTrue(frame.time > lastTime, "frame at " + frame.time + " after " + lastTime);
			lastTime = frame.time;
			count++;
		}

		var dropped = decoder.droppedFrames;
		decoder.close();

		Assert.isTrue(count >= 43, "read " + count + " frames before 1.5 s");
		Assert.equals(0, dropped);
	}

	public function testReadFrameAtTimeSkipsOlderFrames():Void
	{
		var decoder = open(NV12);
		if (decoder == null) return;

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(decoder, frame));
		var firstTime = frame.time;

		// Once a few frames are queued ahead, a later time skips straight past the older ones
		Sys.sleep(0.25);
		var target = firstTime + 0.1;
		Assert.isTrue(nextFrame(decoder, frame, target));
		Assert.isTrue(frame.time <= target + 0.001 && frame.time + frame.duration > target, "frame at " + frame.time);

		// A frame that is not due yet is not returned
		Assert.isFalse(decoder.readFrame(frame, firstTime));
		decoder.close();
	}

	public function testAccurateSeek():Void
	{
		var decoder = open(NV12);
		if (decoder == null) return;

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(decoder, frame));
		var firstTime = frame.time;

		for (target in [1.0, 0.5 + 1 / 60, 1.5])
		{
			decoder.seek(target);

			Assert.isFalse(decoder.videoComplete);
			Assert.isTrue(nextFrame(decoder, frame));
			Assert.isTrue(frame.time <= target + 0.001 && frame.time + frame.duration > target, "seek to " + target + " gave " + frame.time);
			Assert.isTrue(Math.abs(lumaBlock(frame) - expectedLuma(frameIndex(frame, firstTime))) <= 6);

			var audio = Bytes.alloc(64);
			var length = readAudio(decoder, audio);
			Assert.isTrue(length > 0);
			Assert.floatEquals(target, decoder.audioTime - length / (decoder.audioSampleRate * decoder.audioChannels * 2), 0.002);
		}

		decoder.close();
	}

	public function testRapidSeeks():Void
	{
		var decoder = open(NV12);
		if (decoder == null) return;

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(decoder, frame));
		var firstTime = frame.time;

		var audio = Bytes.alloc(64);
		var bytesPerSecond = decoder.audioSampleRate * decoder.audioChannels * 2;
		var mismatches:Array<String> = [];

		// Seeks follow each other while frames are still decoding, as they do
		// while a seek bar is dragged. Whatever is read in between has to start
		// at the time sought.
		for (i in 0...40)
		{
			// Seeking before the first frame gives the first frame
			var target = ((i * 7) % 19) / 10;
			decoder.seek(target);
			Sys.sleep(0.01 * (i % 4));

			if (i % 2 == 0)
			{
				if (!nextFrame(decoder, frame))
				{
					mismatches.push("no frame after seeking to " + target);
				}
				else if (frame.time > Math.max(target, firstTime) + 0.001 || frame.time + frame.duration <= target
					|| Math.abs(lumaBlock(frame) - expectedLuma(frameIndex(frame, firstTime))) > 6)
				{
					mismatches.push("seeking to " + target + " gave the frame at " + frame.time);
				}
			}
			else
			{
				var length = readAudio(decoder, audio);
				var audioStart = decoder.audioTime - length / bytesPerSecond;

				if (length <= 0 || Math.abs(audioStart - target) > 0.002)
				{
					mismatches.push("seeking to " + target + " gave audio at " + audioStart);
				}
			}
		}

		// The rest of the video then plays in order from the last seek
		decoder.seek(1);
		var count = 0;
		var lastTime = -1.0;

		while (nextFrame(decoder, frame))
		{
			if (frame.time <= lastTime || Math.abs(lumaBlock(frame) - expectedLuma(frameIndex(frame, firstTime))) > 6)
			{
				mismatches.push("after the last seek, a frame at " + frame.time + " was out of order or wrong");
			}

			lastTime = frame.time;
			count++;
		}

		Assert.equals(0, mismatches.length, mismatches.join("; "));
		Assert.isTrue(Math.abs(count - 30) <= 1, "read " + count + " frames after the last seek");
		decoder.close();
	}

	public function testReadAllAudio():Void
	{
		var decoder = open(NV12);
		if (decoder == null) return;

		var buffer = Bytes.alloc(4096);
		var left:Array<Int> = [];
		var length;

		while ((length = readAudio(decoder, buffer)) > 0)
		{
			var i = 0;

			while (i < length)
			{
				left.push(buffer.getUInt16(i) > 32767 ? buffer.getUInt16(i) - 65536 : buffer.getUInt16(i));
				i += 4;
			}
		}

		Assert.isTrue(decoder.audioComplete);
		Assert.floatEquals(decoder.duration, left.length / decoder.audioSampleRate, 0.1);

		// 440 Hz crosses zero 880 times a second
		var crossings = 0;
		var start = Std.int(decoder.audioSampleRate / 2);

		for (i in start + 1...start + decoder.audioSampleRate)
		{
			if ((left[i - 1] < 0) != (left[i] < 0)) crossings++;
		}

		Assert.isTrue(Math.abs(crossings - 880) < 20, crossings + " zero crossings");
		decoder.close();
	}

	public function testReopen():Void
	{
		var decoder = open(NV12);
		if (decoder == null) return;

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(decoder, frame));

		Assert.isTrue(decoder.open(PATH, RGBA));
		Assert.equals(VideoFrameFormat.RGBA, decoder.format);
		Assert.isTrue(nextFrame(decoder, frame));
		Assert.equals(VideoFrameFormat.RGBA, frame.format);
		decoder.close();
	}

	private static function checkChannels(format:VideoFrameFormat, red:Int, green:Int, blue:Int, alpha:Int):Void
	{
		var decoder = open(format);
		if (decoder == null) return;

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(decoder, frame));
		Assert.equals(format, frame.format);
		Assert.equals(640 * 360 * 4, frame.length);

		// The blocks are BT.709, which is only assumed for HD video, so allow for BT.601
		var tolerance = frame.colorMatrix == VideoColorMatrix.BT709 ? 16 : 40;
		var redBlock = pixel(frame, 640 - 64, 64);
		var blueBlock = pixel(frame, 64, 360 - 64);

		Assert.isTrue(redBlock[red] > 255 - tolerance && redBlock[green] < tolerance && redBlock[blue] < tolerance, "red block " + redBlock);
		Assert.isTrue(blueBlock[red] < tolerance && blueBlock[green] < tolerance && blueBlock[blue] > 255 - tolerance, "blue block " + blueBlock);
		Assert.equals(255, redBlock[alpha]);
		decoder.close();
	}

	private static function expectedLuma(index:Int):Int
	{
		return 16 + (index * 37) % 200;
	}

	private static function frameIndex(frame:VideoFrame, firstTime:Float):Int
	{
		return Math.round((frame.time - firstTime) * 30);
	}

	private static function lumaBlock(frame:VideoFrame):Float
	{
		var sum = 0;

		for (y in 32...96)
		{
			for (x in 32...96)
			{
				sum += frame.data[y * frame.width + x];
			}
		}

		return sum / (64 * 64);
	}

	private static function nextFrame(decoder:VideoDecoder, frame:VideoFrame, time:Float = -1):Bool
	{
		// Frames are decoded in the background, so wait for one
		var start = Timer.stamp();

		while (!decoder.readFrame(frame, time))
		{
			if (decoder.videoComplete || Timer.stamp() - start > TIMEOUT) return false;
			Sys.sleep(0.001);
		}

		return true;
	}

	private static function open(format:VideoFrameFormat):VideoDecoder
	{
		if (!VideoDecoder.isSupported)
		{
			Assert.pass();
			return null;
		}

		var decoder = VideoDecoder.fromFile(PATH, format);

		if (decoder == null)
		{
			Assert.warn("Cannot decode H.264 and AAC here, so video decoding was not tested");
		}

		return decoder;
	}

	private static function pixel(frame:VideoFrame, x:Int, y:Int):Array<Int>
	{
		var offset = (y * frame.width + x) * 4;
		return [frame.data[offset], frame.data[offset + 1], frame.data[offset + 2], frame.data[offset + 3]];
	}

	private static function readAudio(decoder:VideoDecoder, buffer:Bytes):Int
	{
		var start = Timer.stamp();

		while (true)
		{
			var length = decoder.readAudio(buffer, 0, buffer.length);
			if (length > 0 || decoder.audioComplete || Timer.stamp() - start > TIMEOUT) return length;
			Sys.sleep(0.001);
		}
	}
	#end
}
