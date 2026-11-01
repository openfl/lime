package media;

#if (lime_cffi && !macro)
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import lime.media.AudioBuffer;
import lime.media.AudioSource;
#end
#if (lime_cffi && !macro && sys)
import lime.system.System;
import sys.FileSystem;
import sys.io.File;
#end
import utest.Assert;
import utest.Test;

class AudioBufferTest extends Test
{
	#if (lime_cffi && !macro)
	private static inline var SAMPLE_RATE = 22050;
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	public function testWAVBytesDecodeToTheirSamples():Void
	{
		var samples = tone(2205);

		assertDecodedAs(AudioBuffer.fromBytes(createWAV(samples)), samples);
	}

	public function testWAVBytesThatEndQuietlyDecodeAsWAV():Void
	{
		// Bytes carry no file extension, so unless SDL_sound is told the format, it tries its MP3 decoder
		// before its WAV decoder, and that decoder takes the quiet tail for 44.1 kHz stereo frames
		var samples = tone(2205).concat(quietTail());

		assertDecodedAs(AudioBuffer.fromBytes(createWAV(samples)), samples);
	}

	public function testWAVBytesWithAPaddedChunkDecodeAsWAV():Void
	{
		var samples = tone(2205).concat(quietTail());

		assertDecodedAs(AudioBuffer.fromBytes(createWAV(samples, true)), samples);
	}

	#if sys
	public function testWAVFileWithAPaddedChunkDecodesAsWAV():Void
	{
		var samples = tone(2205).concat(quietTail());
		var path = scratchDirectory() + "/padded.wav";
		File.saveBytes(path, createWAV(samples, true));

		assertDecodedAs(AudioBuffer.fromFile(path), samples);
		FileSystem.deleteFile(path);
	}

	public function testWAVFileWithoutAnExtensionDecodesAsWAV():Void
	{
		// With no extension to go by, the file's signature names its format
		var samples = tone(2205).concat(quietTail());
		var path = scratchDirectory() + "/quiet";
		File.saveBytes(path, createWAV(samples));

		assertDecodedAs(AudioBuffer.fromFile(path), samples);
		FileSystem.deleteFile(path);
	}
	#end

	#if lime_sdl_sound
	public function testWAVBytesThatEndQuietlyStreamAsWAV():Void
	{
		var buffer = AudioBuffer.fromBytesStream(createWAV(tone(2205).concat(quietTail())));

		Assert.notNull(buffer);
		if (buffer == null) return;

		Assert.equals(1, buffer.channels);
		Assert.equals(SAMPLE_RATE, buffer.sampleRate);
		Assert.equals(16, buffer.bitsPerSample);
	}

	public function testAStreamReadsOnAfterItsBufferIsDisposed():Void
	{
		var samples = tone(SAMPLE_RATE);
		var buffer = AudioBuffer.fromBytesStream(createWAV(samples));
		var source = new AudioSource(buffer);
		buffer.dispose();
		buffer = null;

		// The stream reads the file's bytes where they are, so once the buffer lets go of them they are
		// collected, and the memory goes to new bytes, unless the source keeps them
		collectAndReuse(samples.length * 2 + 44);

		var backend = @:privateAccess source.__backend;
		var read = @:privateAccess backend.readSDLSoundBuffer(samples.length * 2);
		var data = @:privateAccess backend.readBuffer;

		Assert.equals(samples.length * 2, read);
		var firstDifference = -1;

		for (i in 0...Std.int(Math.min(read, samples.length * 2) / 2))
		{
			if (((data.getUInt16(i * 2) << 16) >> 16) != samples[i])
			{
				firstDifference = i;
				break;
			}
		}

		Assert.equals(-1, firstDifference);
		source.dispose();
	}

	private static function collectAndReuse(length:Int):Void
	{
		var garbage = [];

		for (i in 0...4)
		{
			collect();

			for (j in 0...16)
			{
				var bytes = Bytes.alloc(length);
				bytes.fill(0, length, 0x55);
				garbage.push(bytes);
			}
		}
	}

	private static function collect():Void
	{
		#if cpp
		cpp.vm.Gc.run(true);
		#elseif neko
		neko.vm.Gc.run(true);
		#elseif hl
		hl.Gc.major();
		#end
	}
	#end

	private function assertDecodedAs(buffer:AudioBuffer, samples:Array<Int>):Void
	{
		Assert.notNull(buffer);
		if (buffer == null) return;

		Assert.equals(1, buffer.channels);
		Assert.equals(SAMPLE_RATE, buffer.sampleRate);
		Assert.equals(16, buffer.bitsPerSample);
		Assert.equals(samples.length * 2, buffer.data.length);
		if (buffer.data.length != samples.length * 2) return;

		var firstDifference = -1;

		for (i in 0...samples.length)
		{
			var value:Int = buffer.data[i * 2] | (buffer.data[i * 2 + 1] << 8);

			if (((value << 16) >> 16) != samples[i])
			{
				firstDifference = i;
				break;
			}
		}

		Assert.equals(-1, firstDifference);
	}

	#if sys
	private static function scratchDirectory():String
	{
		var directory = System.applicationStorageDirectory + "audio-test";
		if (!FileSystem.exists(directory)) FileSystem.createDirectory(directory);
		return directory;
	}
	#end

	// When padded, the format chunk has an empty extension, making it 18 bytes long, and an odd-sized
	// LIST chunk before the data is padded to an even length, as RIFF requires
	public static function createWAV(samples:Array<Int>, padded:Bool = false):Bytes
	{
		var output = new BytesOutput();
		output.writeString("RIFF");
		output.writeInt32((padded ? 52 : 36) + samples.length * 2);
		output.writeString("WAVE");
		output.writeString("fmt ");
		output.writeInt32(padded ? 18 : 16);
		output.writeUInt16(1);
		output.writeUInt16(1);
		output.writeInt32(SAMPLE_RATE);
		output.writeInt32(SAMPLE_RATE * 2);
		output.writeUInt16(2);
		output.writeUInt16(16);

		if (padded)
		{
			output.writeUInt16(0);
			output.writeString("LIST");
			output.writeInt32(5);
			output.writeString("INFOx");
			output.writeByte(0);
		}

		output.writeString("data");
		output.writeInt32(samples.length * 2);

		for (sample in samples)
		{
			output.writeInt16(sample);
		}

		return output.getBytes();
	}

	// A fade out that ends in an occasional -1, as many recordings do. As bytes, -1 then 0 is FF FF 00 00,
	// which is also the header of an MPEG-1 Layer I frame, so evenly spaced they look like MP3 frames.
	private static function quietTail():Array<Int>
	{
		return [for (i in 0...4660) i % 233 == 0 ? -1 : 0];
	}

	public static function tone(length:Int):Array<Int>
	{
		return [for (i in 0...length) Std.int(Math.sin(i * 2 * Math.PI * 440 / SAMPLE_RATE) * 16384)];
	}
	#end
}
