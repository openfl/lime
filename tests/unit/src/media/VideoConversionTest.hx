package media;

#if sys
import haxe.Timer;
import lime.media.VideoColorMatrix;
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
#end
import utest.Assert;
import utest.Test;

/**
	Frames read as RGBA, BGRA and ARGB, byte for byte, as the same frames read as NV12 and converted here.

	Lime converts each frame from YUV in its own code, on the video thread, with 16.16 fixed-point
	coefficients worked out from the frame's color matrix and range, rounding as `convert` does below.
	The conversion is due to be made faster, and has to give the same bytes for each channel order.
	Reading NV12 copies the luma plane and interleaves the chroma planes where the decoder gives them
	apart, so the NV12 frame is checked as well, through what it converts to.

	The decoders are software ones, and don't drop late frames, so the frames read in each format are
	the same frames.
**/
class VideoConversionTest extends Test
{
	#if sys
	private static inline var TIMEOUT = 15;
	private static inline var FRAMES = 8;
	#end

	public function new()
	{
		super();
	}

	#if sys
	public function testColorFramesAreTheNV12FramesConverted():Void
	{
		assertConverted("assets/video.mp4", RGBA);
		assertConverted("assets/video.mp4", BGRA);
		assertConverted("assets/video.mp4", ARGB);
	}

	public function testColorFramesOfOddSizeAreTheNV12FramesConverted():Void
	{
		// The last column and row share chroma with nothing to their right and below
		assertConverted("assets/video-odd.mp4", RGBA);
		assertConverted("assets/video-odd.mp4", BGRA);
		assertConverted("assets/video-odd.mp4", ARGB);
	}

	#if target.threaded
	public function testClosingWhileAnotherThreadReadsIsSafe():Void
	{
		// Frames and audio are read on threads of their own while the decoder is closed under them, at a
		// different moment each time, as a copy outside the decoder's lock could still be running
		var closed = 0;

		for (round in 0...6)
		{
			if (!VideoDecoder.isSupported) break;

			var decoder = new VideoDecoder();
			decoder.dropLateFrames = false;
			if (!decoder.open("assets/video.mp4", round % 2 == 0 ? RGBA : NV12))
			{
				trace("Cannot decode assets/video.mp4 here, so closing while reading was not tested");
				Assert.pass();
				return;
			}

			var running = true;
			var done = new sys.thread.Deque<Bool>();

			sys.thread.Thread.create(function()
			{
				var frame = new VideoFrame();
				while (running)
				{
					decoder.readFrame(frame);
					// A safe point for the collector, which a loop of native calls alone never reaches on C++
					Sys.sleep(0.0005);
				}
				done.add(true);
			});
			sys.thread.Thread.create(function()
			{
				var audio = haxe.io.Bytes.alloc(4096);
				while (running)
				{
					decoder.readAudio(audio, 0, audio.length);
					Sys.sleep(0.0005);
				}
				done.add(true);
			});

			Sys.sleep(0.02 + round * 0.015);
			decoder.close();
			Sys.sleep(0.02);
			running = false;
			done.pop(true);
			done.pop(true);

			// A closed decoder reads nothing
			Assert.isFalse(decoder.readFrame(new VideoFrame()));
			closed++;
		}

		Assert.isTrue(closed > 0 || !VideoDecoder.isSupported);
	}
	#end

	// Helpers

	private static function assertConverted(path:String, format:VideoFrameFormat, ?pos:haxe.PosInfos):Void
	{
		var yuv = frames(path, NV12);
		var color = frames(path, format);

		if (yuv == null || color == null)
		{
			// utest takes a warning as a failure where it counts, so the test passes, saying why
			trace("Cannot decode " + path + " here, so its conversion was not tested");
			Assert.pass();
			return;
		}

		Assert.equals(yuv.length, color.length, path + ": frames read as NV12 and " + name(format), pos);

		for (i in 0...Std.int(Math.min(yuv.length, color.length)))
		{
			var source = yuv[i];
			var frame = color[i];
			var label = path + " as " + name(format) + ", frame at " + source.time;

			Assert.equals(source.time, frame.time, label + ": the frames are not the same", pos);
			Assert.equals(source.width + "x" + source.height + " " + source.colorMatrix + (source.fullRange ? " full" : " limited"),
				frame.width + "x" + frame.height + " " + frame.colorMatrix + (frame.fullRange ? " full" : " limited"), label, pos);

			var difference = firstDifference(convert(source, format), frame);
			Assert.equals("none", difference, label + ": " + difference, pos);
		}
	}

	private static function frames(path:String, format:VideoFrameFormat):Array<VideoFrame>
	{
		if (!VideoDecoder.isSupported) return null;

		var decoder = new VideoDecoder();
		decoder.dropLateFrames = false;
		decoder.hardwareDecoding = false;
		if (!decoder.open(path, format)) return null;

		var result = [];
		var start = Timer.stamp();

		while (result.length < FRAMES && !decoder.videoComplete && Timer.stamp() - start < TIMEOUT)
		{
			var frame = new VideoFrame();
			if (decoder.readFrame(frame))
			{
				// The frame's own copy, in case the buffer it was read into is used again
				var copy = new lime.utils.UInt8Array(frame.data.length);
				copy.set(frame.data);
				frame.data = copy;
				result.push(frame);
			}
			else
			{
				Sys.sleep(0.001);
			}
		}

		decoder.close();
		return result.length > 0 ? result : null;
	}

	/** The NV12 frame as Lime converts it, in the channel order of `format` **/
	private static function convert(frame:VideoFrame, format:VideoFrameFormat):Array<Int>
	{
		var kr = 0.2126, kb = 0.0722;
		if (frame.colorMatrix == VideoColorMatrix.BT601)
		{
			kr = 0.299;
			kb = 0.114;
		}
		else if (frame.colorMatrix == VideoColorMatrix.BT2020)
		{
			kr = 0.2627;
			kb = 0.0593;
		}

		var kg = 1.0 - kr - kb;
		var yScale = frame.fullRange ? 1.0 : 255.0 / 219.0;
		var cScale = frame.fullRange ? 1.0 : 255.0 / 224.0;
		var yOffset = frame.fullRange ? 0 : 16;

		var yFactor = Std.int(yScale * 65536.0 + 0.5);
		var rv = Std.int(2.0 * (1.0 - kr) * cScale * 65536.0 + 0.5);
		var gu = Std.int(2.0 * kb * (1.0 - kb) / kg * cScale * 65536.0 + 0.5);
		var gv = Std.int(2.0 * kr * (1.0 - kr) / kg * cScale * 65536.0 + 0.5);
		var bu = Std.int(2.0 * (1.0 - kb) * cScale * 65536.0 + 0.5);

		var red = 0, green = 1, blue = 2, alpha = 3;
		if (format == BGRA)
		{
			red = 2;
			blue = 0;
		}
		else if (format == ARGB)
		{
			alpha = 0;
			red = 1;
			green = 2;
			blue = 3;
		}

		var width = frame.width;
		var data = frame.data;
		var chroma = frame.chromaOffset;
		var chromaWidth = frame.chromaWidth;
		var out = [];
		out.resize(width * frame.height * 4);

		for (row in 0...frame.height)
		{
			for (x in 0...width)
			{
				var uv = chroma + ((row >> 1) * chromaWidth + (x >> 1)) * 2;
				// As Int, since elements read as UInt, which wraps below zero
				var u:Int = data[uv];
				var v:Int = data[uv + 1];
				var y:Int = data[row * width + x];
				var cu = u - 128;
				var cv = v - 128;
				var luma = (y - yOffset) * yFactor + 32768;
				var o = (row * width + x) * 4;

				out[o + red] = clamp((luma + rv * cv) >> 16);
				out[o + green] = clamp((luma - gu * cu - gv * cv) >> 16);
				out[o + blue] = clamp((luma + bu * cu) >> 16);
				out[o + alpha] = 255;
			}
		}

		return out;
	}

	private static inline function clamp(value:Int):Int
	{
		return value < 0 ? 0 : (value > 255 ? 255 : value);
	}

	private static function firstDifference(expected:Array<Int>, frame:VideoFrame):String
	{
		if (frame.length != expected.length) return "the frame is " + frame.length + " bytes, not " + expected.length;

		for (i in 0...expected.length)
		{
			if (frame.data[i] != expected[i])
			{
				var pixel = i >> 2;
				return "byte " + i + " (" + (pixel % frame.width) + ", " + Std.int(pixel / frame.width) + ") is " + frame.data[i] + ", not " + expected[i];
			}
		}

		return "none";
	}

	private static function name(format:VideoFrameFormat):String
	{
		return switch (format)
		{
			case RGBA: "RGBA";
			case BGRA: "BGRA";
			case ARGB: "ARGB";
			default: "NV12";
		}
	}
	#end
}
