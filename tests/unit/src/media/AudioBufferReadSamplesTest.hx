package media;

import haxe.io.Bytes;
import lime.media.AudioBuffer;
import lime.utils.UInt8Array;
import utest.Assert;
import utest.Test;
#if (lime_cffi && !macro && lime_vorbis)
import lime.media.vorbis.VorbisFile;
#end

/**
	`AudioBuffer.readSamples()` copies frames from a decoded buffer, and on
	native targets decodes streamed buffers again from any position, which
	must give the same samples as the decoded buffer.
**/
class AudioBufferReadSamplesTest extends Test
{
	private static inline var COUNT = 512;

	public function new()
	{
		super();
	}

	public function testADecodedBufferCopiesFramesWithinItsBounds():Void
	{
		// Ten stereo 16-bit frames, each byte its index
		var buffer = new AudioBuffer();
		buffer.channels = 2;
		buffer.bitsPerSample = 16;
		buffer.sampleRate = 44100;
		buffer.data = new UInt8Array(40);
		for (i in 0...40)
		{
			buffer.data[i] = i;
		}

		var output = Bytes.alloc(40);
		Assert.equals(3, buffer.readSamples(2, 3, output));
		Assert.equals("8,9,10,11,12,13,14,15,16,17,18,19", bytes(output, 0, 12));

		// At an offset, and fewer near the end
		output.fill(0, output.length, 0xFF);
		Assert.equals(2, buffer.readSamples(8, 5, output, 4));
		Assert.equals("255,255,255,255,32,33,34,35,36,37,38,39,255", bytes(output, 0, 13));

		// No more than the output holds from its offset
		var small = Bytes.alloc(10);
		Assert.equals(2, buffer.readSamples(0, 10, small, 1));
		Assert.equals("0,1,2,3,4,5,6,7", bytes(small, 1, 8));

		// Nothing to read
		Assert.equals(0, buffer.readSamples(10, 1, output));
		Assert.equals(0, buffer.readSamples(100, 1, output));
		Assert.equals(0, buffer.readSamples(-1, 1, output));
		Assert.equals(0, buffer.readSamples(0, 0, output));
		Assert.equals(0, buffer.readSamples(0, 1, null));
		Assert.equals(0, buffer.readSamples(0, 1, output, -1));
		Assert.equals(0, buffer.readSamples(0, 1, output, 40));

		// HTML5's dispose() unloads a Howl, which a buffer made here has not
		#if !(js && html5)
		buffer.dispose();
		Assert.equals(0, buffer.readSamples(0, 1, output));
		#end
	}

	public function testAnEmptyBufferHasNothingToRead():Void
	{
		Assert.equals(0, new AudioBuffer().readSamples(0, 1, Bytes.alloc(16)));
	}

	#if (lime_cffi && !macro && sys)
	public function testAStreamedWAVReadsTheSamplesOfItsDecodedBuffer():Void
	{
		assertStreamMatchesDecoded("assets/tone.wav");
	}

	public function testAStreamedVorbisFileReadsTheSamplesOfItsDecodedBuffer():Void
	{
		assertStreamMatchesDecoded("assets/tone.ogg");
	}

	public function testReadingAStreamInPiecesIsOneRead():Void
	{
		for (path in ["assets/tone.wav", "assets/tone.ogg"])
		{
			var stream = AudioBuffer.fromFileStream(path);

			if (stream == null)
			{
				cannotStream(path);
				continue;
			}

			var frameSize = Std.int(stream.channels * stream.bitsPerSample / 8);
			var whole = Bytes.alloc(3000 * frameSize);
			var read = stream.readSamples(100, 3000, whole);

			// Read again from the start, then on in pieces, each going on from the last
			var pieces = Bytes.alloc(whole.length);
			var total = 0;
			stream.readSamples(0, 10, Bytes.alloc(10 * frameSize));

			while (total < read)
			{
				var got = stream.readSamples(100 + total, 700, pieces, total * frameSize);
				if (got == 0) break;
				total += got;
			}

			Assert.isTrue(read > 0, path + " read nothing");
			Assert.equals(read, total, path);
			Assert.equals(0, whole.sub(0, read * frameSize).compare(pieces.sub(0, total * frameSize)), path + " read differently in pieces");
			stream.dispose();
		}
	}

	#if lime_vorbis
	public function testAVorbisFileBufferReadsWhatLibvorbisDecodes():Void
	{
		// The two Vorbis decoders round differently, so libvorbis is compared with itself
		var expected = Bytes.alloc(0);
		var reference = VorbisFile.fromFile("assets/tone.ogg");

		if (reference == null)
		{
			Assert.fail("cannot open assets/tone.ogg");
			return;
		}

		var all = new haxe.io.BytesBuffer();
		var chunk = Bytes.alloc(4096);

		while (true)
		{
			var read = reference.read(chunk, 0, chunk.length);
			if (read <= 0) break;
			all.addBytes(chunk, 0, read);
		}

		reference.clear();
		expected = all.getBytes();

		var vorbisFile = VorbisFile.fromFile("assets/tone.ogg");
		var buffer = AudioBuffer.fromVorbisFile(vorbisFile);
		var frameSize = Std.int(buffer.channels * buffer.bitsPerSample / 8);
		var frames = Std.int(expected.length / frameSize);

		// Where a player reading the file has got to
		var playing = Bytes.alloc(1000);
		vorbisFile.read(playing, 0, playing.length);
		var playedTo = haxe.Int64.toStr(vorbisFile.pcmTell());

		for (position in positions(frames))
		{
			var output = Bytes.alloc(COUNT * frameSize);
			var read = buffer.readSamples(position, COUNT, output);
			var wanted = Std.int(Math.max(0, Math.min(COUNT, frames - position)));

			Assert.equals(wanted, read, "frames read at " + position);
			if (read > 0)
			{
				Assert.equals(0, expected.sub(position * frameSize, read * frameSize).compare(output.sub(0, read * frameSize)), "the frames at " + position + " differ");
			}
		}

		Assert.equals(playedTo, haxe.Int64.toStr(vorbisFile.pcmTell()), "reading moved the player's place in the file");

		buffer.dispose();
		vorbisFile.clear();
	}
	#end

	private static function assertStreamMatchesDecoded(path:String):Void
	{
		var decoded = AudioBuffer.fromFile(path);
		var stream = AudioBuffer.fromFileStream(path);

		Assert.notNull(decoded, "cannot decode " + path);

		if (decoded == null || stream == null)
		{
			if (decoded != null) cannotStream(path);
			return;
		}

		Assert.isNull(stream.data, path + " is not streamed");
		Assert.equals(decoded.channels, stream.channels);
		Assert.equals(decoded.bitsPerSample, stream.bitsPerSample);

		var frameSize = Std.int(decoded.channels * decoded.bitsPerSample / 8);
		var frames = Std.int(decoded.data.byteLength / frameSize);

		for (position in positions(frames))
		{
			var expected = Bytes.alloc(COUNT * frameSize);
			var actual = Bytes.alloc(COUNT * frameSize);
			var wanted = decoded.readSamples(position, COUNT, expected);
			var read = stream.readSamples(position, COUNT, actual);

			Assert.equals(Std.int(Math.max(0, Math.min(COUNT, frames - position))), wanted, path + ": frames in the decoded buffer at " + position);
			Assert.equals(wanted, read, path + ": frames read at " + position);
			if (read > 0 && read == wanted)
			{
				Assert.equals(0, expected.sub(0, read * frameSize).compare(actual.sub(0, read * frameSize)), path + ": the frames at " + position + " differ");
			}
		}

		decoded.dispose();
		stream.dispose();
	}

	private static function cannotStream(path:String):Void
	{
		// utest takes a warning as a failure, so the test passes, saying why
		trace("Cannot stream " + path + " here, so reading it was not tested");
		Assert.pass();
	}

	private static function positions(frames:Int):Array<Int>
	{
		// Forward, back to the start, on from where a read ended, near the end and past it
		return [0, 1, 1000, 1102, 2000, 0, COUNT, frames - 10, 1102, frames, frames + 100, 3];
	}
	#end

	private static function bytes(data:Bytes, offset:Int, length:Int):String
	{
		return [for (i in offset...offset + length) data.get(i)].join(",");
	}
}
