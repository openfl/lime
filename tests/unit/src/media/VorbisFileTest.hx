package media;

import haxe.io.Bytes;
import utest.Assert;
import utest.Test;
#if (lime_cffi && lime_vorbis)
import lime.media.vorbis.VorbisFile;
#end

/**
	`VorbisFile.readFloat()` decodes the same sound `read()` does, as floats: each
	16-bit sample `read()` gives is the float `readFloat()` gives for it, scaled to
	16 bits and rounded.
**/
class VorbisFileTest extends Test
{
	private static inline var PATH = "assets/tone.ogg";

	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_vorbis)
	public function testReadFloatGivesTheSamplesReadGives():Void
	{
		var shorts = VorbisFile.fromFile(PATH);
		var floats = VorbisFile.fromFile(PATH);
		if (shorts == null || floats == null)
		{
			Assert.fail("could not open " + PATH);
			return;
		}

		var channels = floats.info().channels;
		var expected = readAllShorts(shorts);
		var actual = readAllFloats(floats, channels, 300);

		Assert.isTrue(expected.length > 0, "read() gave no samples");
		Assert.equals(expected.length, actual.length, "read() and readFloat() gave different numbers of samples");

		var largest = 0.0;
		for (i in 0...Std.int(Math.min(expected.length, actual.length)))
		{
			var difference = Math.abs(actual[i] * 32768 - expected[i]);
			if (difference > largest) largest = difference;
		}

		Assert.isTrue(largest <= 1, "a float sample differs from read()'s by " + largest + " in 16-bit steps");

		shorts.clear();
		floats.clear();
	}

	public function testReadFloatReadsNoMoreThanFits():Void
	{
		var file = VorbisFile.fromFile(PATH);
		if (file == null)
		{
			Assert.fail("could not open " + PATH);
			return;
		}

		var channels = file.info().channels;
		// Room for 10 frames, and a few bytes that are not a whole frame, which stay as they were
		var buffer = Bytes.alloc(10 * 4 * channels + 3);
		buffer.fill(0, buffer.length, 0x7F);

		var frames = file.readFloat(buffer, 1000);
		Assert.isTrue(frames > 0 && frames <= 10, "read " + frames + " frames into room for 10");
		for (i in 10 * 4 * channels...buffer.length) Assert.equals(0x7F, buffer.get(i));

		Assert.equals(0, file.readFloat(Bytes.alloc(4 * channels - 1), 10), "read into room for less than a frame");
		Assert.equals(0, file.readFloat(null, 10));

		file.clear();
	}

	public function testReadFloatGivesZeroAtTheEnd():Void
	{
		var file = VorbisFile.fromFile(PATH);
		if (file == null)
		{
			Assert.fail("could not open " + PATH);
			return;
		}

		readAllFloats(file, file.info().channels, 4096);
		Assert.equals(0, file.readFloat(Bytes.alloc(4096), 256));
		file.clear();
	}

	private static function readAllShorts(file:VorbisFile):Array<Int>
	{
		var samples = [];
		var buffer = Bytes.alloc(4096);

		while (true)
		{
			var read = file.read(buffer, 0, buffer.length, false, 2, true);
			if (read <= 0) break;

			for (i in 0...(read >> 1))
			{
				var value = buffer.get(i * 2) | (buffer.get(i * 2 + 1) << 8);
				samples.push(value >= 0x8000 ? value - 0x10000 : value);
			}
		}

		return samples;
	}

	// Reads a few frames at a time, so reads end partway through the decoder's blocks
	private static function readAllFloats(file:VorbisFile, channels:Int, frames:Int):Array<Float>
	{
		var samples = [];
		var buffer = Bytes.alloc(frames * 4 * channels);

		while (true)
		{
			var read = file.readFloat(buffer, frames);
			if (read <= 0) break;

			for (i in 0...read * channels)
			{
				samples.push(buffer.getFloat(i * 4));
			}
		}

		return samples;
	}
	#end
}
