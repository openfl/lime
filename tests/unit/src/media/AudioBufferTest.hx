package media;

#if (lime_cffi && !macro)
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import lime.media.AudioBuffer;
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

	private static function createWAV(samples:Array<Int>):Bytes
	{
		var output = new BytesOutput();
		output.writeString("RIFF");
		output.writeInt32(36 + samples.length * 2);
		output.writeString("WAVE");
		output.writeString("fmt ");
		output.writeInt32(16);
		output.writeUInt16(1);
		output.writeUInt16(1);
		output.writeInt32(SAMPLE_RATE);
		output.writeInt32(SAMPLE_RATE * 2);
		output.writeUInt16(2);
		output.writeUInt16(16);
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

	private static function tone(length:Int):Array<Int>
	{
		return [for (i in 0...length) Std.int(Math.sin(i * 2 * Math.PI * 440 / SAMPLE_RATE) * 16384)];
	}
	#end
}
