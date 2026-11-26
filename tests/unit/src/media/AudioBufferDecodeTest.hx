package media;

#if (lime_cffi && !macro && sys)
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesOutput;
import lime.media.AudioBuffer;
import sys.io.File;
#end
#if ((cpp || hl) && lime_cffi && !macro)
import system.CollectorWait;
#end
import utest.Assert;
import utest.Test;

/**
	Whole sounds decoded through SDL_sound, which Lime tries first.

	The decoder sizes its output from the sound's duration, which SDL_sound gives in whole milliseconds,
	so a sound that isn't a whole number of milliseconds long makes it grow and trim the output. The
	samples have to come out exactly as they went in, whatever the length, rate, channels and sample
	size.

	A long decode on a worker thread shouldn't hold up collections on the main thread either. Lime
	has no Vorbis encoder, so the long sound is made from `assets/tone.ogg`, its audio page repeated
	with its page number and granule position moved on each time.
**/
class AudioBufferDecodeTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && sys)
	public function testWAVsOfEveryLengthDecodeToExactlyTheirSamples():Void
	{
		// Lengths of a whole millisecond, a frame either side of one, and of less than a millisecond. SDL_sound
		// is asked for 16-bit samples, so 8-bit ones come out as 16-bit, through SDL's float conversion: the
		// unsigned byte less 128, times 256, with SDL's x86 converters, and times 32767 / 128, cut toward zero,
		// with its NEON ones on ARM. Either is the same sound; each must be exactly one of them.
		var failures = [];

		for (format in [[22050, 1, 16], [44100, 2, 16], [48000, 2, 16], [44100, 1, 8], [11025, 2, 8], [8000, 1, 16]])
		{
			var rate = format[0];
			var frames = [1, 3, Std.int(rate / 10), Std.int(rate / 10) + 1, Std.int(rate / 10) - 1, rate * 3 + 17, rate + rate - 1];

			for (count in frames)
			{
				var pcm = samples(count, format[1], format[2]);
				var buffer = AudioBuffer.fromBytes(wav(pcm, rate, format[1], format[2]));
				var name = rate + " Hz, " + format[1] + " channels, " + format[2] + "-bit, " + count + " frames";

				if (buffer == null || buffer.data == null)
				{
					failures.push(name + " did not decode");
					continue;
				}

				var data = buffer.data.toBytes().sub(buffer.data.byteOffset, buffer.data.byteLength);
				var neon = format[2] == 8 ? widen(pcm, true) : null;
				if (format[2] == 8) pcm = widen(pcm, false);

				if (buffer.sampleRate != rate || buffer.channels != format[1] || buffer.bitsPerSample != 16)
				{
					failures.push(name + " decoded as " + buffer.sampleRate + " Hz, " + buffer.channels + " channels, " + buffer.bitsPerSample + "-bit");
				}
				else if (data.length != pcm.length)
				{
					failures.push(name + " decoded to " + data.length + " bytes of " + pcm.length);
				}
				else if (data.compare(pcm) != 0 && (neon == null || data.compare(neon) != 0))
				{
					failures.push(name + " decoded to other samples");
				}
			}
		}

		Assert.equals(0, failures.length, failures.join("; "));
	}

	#if (cpp || hl)
	public function testALongVorbisStreamDecodesToItsWholeLength():Void
	{
		var buffer = AudioBuffer.fromBytes(longVorbis(600));

		Assert.notNull(buffer);
		if (buffer == null) return;

		// tone.ogg is 2205 frames a page. Vorbis decodes in floating point, so only the format and length are pinned
		Assert.equals("1 channels, 22050 Hz, 16-bit, 2646000 bytes",
			buffer.channels + " channels, " + buffer.sampleRate + " Hz, " + buffer.bitsPerSample + "-bit, " + buffer.data.byteLength + " bytes");
	}

	public function testALongVorbisStreamDecodesTheSameEachTime():Void
	{
		var bytes = longVorbis(100);
		Assert.equals(describe(AudioBuffer.fromBytes(bytes)), describe(AudioBuffer.fromBytes(bytes)));
	}

	@Ignored("Waiting on #2126")
	public function testTheCollectorRunsWhileAWorkerDecodesASound():Void
	{
		var bytes = longVorbis(4800);
		var buffer:AudioBuffer = null;
		var result = CollectorWait.collectDuring(function()
		{
			buffer = AudioBuffer.fromBytes(bytes);
		});

		Assert.isFalse(result.waited, "Decoding Vorbis on a worker: " + result);
		Assert.notNull(buffer);
	}

	#if lime_sdl_sound
	@Ignored("Waiting on #2126")
	public function testTheCollectorRunsWhileAStreamReadsAhead():Void
	{
		// A stream's refill reads what it asks for in one decode. The feeding thread asks for about a second
		// at a time; this asks for the whole sound, so that the decode outlasts a collection by far.
		var source = new lime.media.AudioSource(AudioBuffer.fromBytesStream(longVorbis(4800)));
		var backend = @:privateAccess source.__backend;
		var read = 0;
		// Its buffer made beforehand, so the worker is in the decode when the collection starts
		@:privateAccess backend.ensureReadBuffer(4800 * 2205 * 2);
		var result = CollectorWait.collectDuring(function()
		{
			read = @:privateAccess backend.readSDLSoundBuffer(4800 * 2205 * 2);
		});

		Assert.isFalse(result.waited, "Reading a stream ahead on a worker: " + result);
		Assert.isTrue(read > 0, "the stream read " + read + " bytes");
		source.dispose();
	}

	public function testAStreamReadsTheSameSamplesAsTheWholeSound():Void
	{
		// However each refill is decoded, a stream read in pieces gives what decoding the sound whole does
		var bytes = longVorbis(50);
		var whole = AudioBuffer.fromBytes(bytes);
		var source = new lime.media.AudioSource(AudioBuffer.fromBytesStream(bytes));
		var backend = @:privateAccess source.__backend;
		var out = new BytesOutput();

		while (true)
		{
			var read = @:privateAccess backend.readSDLSoundBuffer(48000);
			if (read <= 0) break;
			var data:Bytes = @:privateAccess backend.readBuffer;
			out.writeFullBytes(data, 0, read);
		}

		source.dispose();
		var streamed = out.getBytes();
		Assert.equals(describe(whole), streamed.length + " bytes, crc " + StringTools.hex(Crc32.make(streamed), 8));
	}
	#end
	#end

	// Helpers

	private static function describe(buffer:AudioBuffer):String
	{
		if (buffer == null || buffer.data == null) return "null";

		var data = buffer.data.toBytes().sub(buffer.data.byteOffset, buffer.data.byteLength);
		return data.length + " bytes, crc " + StringTools.hex(Crc32.make(data), 8);
	}

	/** 8-bit samples as SDL gives them as 16-bit, by its x86 converters or by its NEON ones **/
	private static function widen(pcm:Bytes, neon:Bool):Bytes
	{
		var wide = Bytes.alloc(pcm.length * 2);
		for (i in 0...pcm.length)
		{
			var centered = pcm.get(i) - 128;
			// Exact in a 32-bit float, and Std.int cuts toward zero as NEON's conversion does
			var sample = neon ? Std.int(centered / 128 * 32767) : centered * 256;
			wide.set(i * 2, sample & 0xFF);
			wide.set(i * 2 + 1, (sample >> 8) & 0xFF);
		}
		return wide;
	}

	/** Interleaved samples from a pair of tones, a different one on each channel **/
	private static function samples(frames:Int, channels:Int, bits:Int):Bytes
	{
		var bytes = Bytes.alloc(frames * channels * (bits >> 3));
		var position = 0;

		for (i in 0...frames)
		{
			for (channel in 0...channels)
			{
				var value = Math.sin(i * 2 * Math.PI * (440 + channel * 110) / 22050) * 0.6 + ((i * 7 + channel) % 13 - 6) / 100;

				if (bits == 8)
				{
					bytes.set(position++, Std.int(128 + value * 127));
				}
				else
				{
					var sample = Std.int(value * 32767);
					bytes.set(position++, sample & 0xFF);
					bytes.set(position++, (sample >> 8) & 0xFF);
				}
			}
		}

		return bytes;
	}

	private static function wav(pcm:Bytes, rate:Int, channels:Int, bits:Int):Bytes
	{
		var output = new BytesOutput();
		output.writeString("RIFF");
		output.writeInt32(36 + pcm.length + (pcm.length & 1));
		output.writeString("WAVE");
		output.writeString("fmt ");
		output.writeInt32(16);
		output.writeUInt16(1);
		output.writeUInt16(channels);
		output.writeInt32(rate);
		output.writeInt32(rate * channels * (bits >> 3));
		output.writeUInt16(channels * (bits >> 3));
		output.writeUInt16(bits);
		output.writeString("data");
		output.writeInt32(pcm.length);
		output.write(pcm);
		if (pcm.length & 1 == 1) output.writeByte(0);
		return output.getBytes();
	}

	/**
		tone.ogg as one logical stream of `repeats` audio pages. Its first page holds the identification
		header, its second the comment and setup headers, and its third all of its audio, 2205 frames.
	**/
	private static function longVorbis(repeats:Int):Bytes
	{
		var source = File.getBytes("assets/tone.ogg");
		var pages = [];
		var position = 0;

		while (position < source.length)
		{
			var segments = source.get(position + 26);
			var length = 27 + segments;
			for (i in 0...segments)
			{
				length += source.get(position + 27 + i);
			}
			pages.push(source.sub(position, length));
			position += length;
		}

		var out = new BytesBuffer();
		out.add(pages[0]);
		out.add(pages[1]);

		for (i in 0...repeats)
		{
			var page = pages[2].sub(0, pages[2].length);
			// Continued from nothing, and the last of the stream only at the end
			page.set(5, i == repeats - 1 ? 4 : 0);
			var granule = haxe.Int64.ofInt(2205 * (i + 1));
			page.setInt32(6, granule.low);
			page.setInt32(10, granule.high);
			page.setInt32(18, 2 + i);
			page.setInt32(22, 0);
			page.setInt32(22, oggCRC(page));
			out.add(page);
		}

		return out.getBytes();
	}

	private static var crcTable:Array<Int>;

	/** Ogg's CRC-32: polynomial 0x04C11DB7, not reflected, starting from zero **/
	private static function oggCRC(bytes:Bytes):Int
	{
		if (crcTable == null)
		{
			crcTable = [];
			for (i in 0...256)
			{
				var r = i << 24;
				for (j in 0...8)
				{
					r = (r & 0x80000000) != 0 ? ((r << 1) ^ 0x04C11DB7) : (r << 1);
				}
				crcTable.push(r);
			}
		}

		var crc = 0;
		for (i in 0...bytes.length)
		{
			crc = (crc << 8) ^ crcTable[((crc >>> 24) ^ bytes.get(i)) & 0xFF];
		}
		return crc;
	}
	#end
}
