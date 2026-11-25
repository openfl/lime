package utils;

import haxe.io.Bytes;
import lime._internal.format.Base64;
import utest.Assert;
import utest.Test;

/**
	Lime's Base64, which `Image.fromBase64()` and `AudioBuffer.fromBase64()` decode with, against RFC 4648.
**/
class Base64Test extends Test
{
	private static inline var ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	private static inline var EVERY_BYTE = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+AgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6ChoqOkpaanqKmqq6ytrq+wsbKztLW2t7i5uru8vb6/wMHCw8TFxsfIycrLzM3Oz9DR0tPU1dbX2Nna29zd3t/g4eLj5OXm5+jp6uvs7e7v8PHy8/T19vf4+fr7/P3+/w==";

	public function new()
	{
		super();
	}

	public function testEncodingMatchesTheRFCTestVectors():Void
	{
		// RFC 4648 §10
		Assert.equals("", Base64.encode(Bytes.ofString("")));
		Assert.equals("Zg==", Base64.encode(Bytes.ofString("f")));
		Assert.equals("Zm8=", Base64.encode(Bytes.ofString("fo")));
		Assert.equals("Zm9v", Base64.encode(Bytes.ofString("foo")));
		Assert.equals("Zm9vYg==", Base64.encode(Bytes.ofString("foob")));
		Assert.equals("Zm9vYmE=", Base64.encode(Bytes.ofString("fooba")));
		Assert.equals("Zm9vYmFy", Base64.encode(Bytes.ofString("foobar")));
	}

	public function testDecodingMatchesTheRFCTestVectors():Void
	{
		Assert.equals("", decodeToString(""));
		Assert.equals("f", decodeToString("Zg=="));
		Assert.equals("fo", decodeToString("Zm8="));
		Assert.equals("foo", decodeToString("Zm9v"));
		Assert.equals("foob", decodeToString("Zm9vYg=="));
		Assert.equals("fooba", decodeToString("Zm9vYmE="));
		Assert.equals("foobar", decodeToString("Zm9vYmFy"));
	}

	public function testEveryByteValueEncodesAndDecodes():Void
	{
		var bytes = Bytes.alloc(256);
		for (i in 0...256)
		{
			bytes.set(i, i);
		}

		Assert.equals(EVERY_BYTE, Base64.encode(bytes));

		var decoded = Base64.decode(EVERY_BYTE);
		Assert.equals(256, decoded.length);
		Assert.equals(0, bytes.compare(decoded));
	}

	public function testEncodingAlwaysPadsToWholeQuanta():Void
	{
		// Output is a whole number of 4-character quanta, padded with one "=" for 2 trailing bytes and two for 1 (RFC 4648 §4)
		for (length in 0...20)
		{
			var encoded = Base64.encode(randomBytes(length, length + 1));
			var padding = [0, 2, 1][length % 3];

			Assert.equals(Math.ceil(length / 3) * 4, encoded.length, length + " bytes");
			Assert.equals(padding, trailingPadding(encoded), length + " bytes: the padding");
		}
	}

	public function testEncodingMatchesTheAlphabet():Void
	{
		for (length in 0...100)
		{
			var bytes = randomBytes(length, length + 100);
			Assert.equals(reference(bytes), Base64.encode(bytes), length + " bytes");
		}
	}

	public function testDecodingInvertsEncoding():Void
	{
		for (length in 0...100)
		{
			var bytes = randomBytes(length, length + 200);
			var decoded = Base64.decode(Base64.encode(bytes));

			Assert.equals(length, decoded.length, length + " bytes");
			Assert.equals(0, bytes.compare(decoded), length + " bytes");
		}
	}

	public function testLargeInputRoundTrips():Void
	{
		var bytes = randomBytes(1024 * 1024 + 1, 7);
		var encoded = Base64.encode(bytes);

		Assert.equals(reference(bytes), encoded);
		Assert.equals(0, bytes.compare(Base64.decode(encoded)));
	}

	public function testDecodingRejectsCharactersOutsideTheAlphabet():Void
	{
		// Implementations must reject data with characters outside the alphabet (RFC 4648 §3.3)
		for (encoded in ["Zm9v*mFy", "Zm9vYméy", "Zm9v.mFy", "Zm9vYm-y"])
		{
			var decoded = unexpectedDecoding(encoded);
			Assert.isNull(decoded, encoded + ": " + decoded);
		}
	}

	public function testUnpaddedInputDecodesToItsBytesOrIsRejected():Void
	{
		// Padding may only be left out where a specification says so (RFC 4648 §3.2): either way, the bytes mustn't be wrong
		for (pair in [["Zg", "f"], ["Zm8", "fo"], ["Zm9vYg", "foob"], ["Zm9vYmE", "fooba"]])
		{
			var decoded:Bytes = null;
			try
			{
				decoded = Base64.decode(pair[0]);
			}
			catch (e:Dynamic) {}

			if (decoded != null)
			{
				Assert.equals(pair[1], decoded.toString(), pair[0]);
			}
			else
			{
				Assert.pass();
			}
		}
	}

	private static function decodeToString(encoded:String):String
	{
		var decoded = Base64.decode(encoded);
		return (decoded == null ? null : decoded.toString());
	}

	private static function trailingPadding(encoded:String):Int
	{
		var count = 0;
		while (count < encoded.length && encoded.charAt(encoded.length - 1 - count) == "=")
		{
			count++;
		}
		return count;
	}

	/** What decoding gave when it should have been rejected, or null when it was rejected **/
	private static function unexpectedDecoding(encoded:String):String
	{
		try
		{
			var decoded = Base64.decode(encoded);
			return (decoded == null ? null : "decoded to " + decoded.length + " bytes");
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	/** RFC 4648 §4, a bit at a time **/
	private static function reference(bytes:Bytes):String
	{
		var buffer = new StringBuf();
		var i = 0;

		while (i < bytes.length)
		{
			var remaining = bytes.length - i;
			var group = (bytes.get(i) << 16) | ((remaining > 1 ? bytes.get(i + 1) : 0) << 8) | (remaining > 2 ? bytes.get(i + 2) : 0);

			buffer.add(ALPHABET.charAt((group >> 18) & 63));
			buffer.add(ALPHABET.charAt((group >> 12) & 63));
			buffer.add(remaining > 1 ? ALPHABET.charAt((group >> 6) & 63) : "=");
			buffer.add(remaining > 2 ? ALPHABET.charAt(group & 63) : "=");
			i += 3;
		}

		return buffer.toString();
	}

	private static function randomBytes(length:Int, seed:Int):Bytes
	{
		var bytes = Bytes.alloc(length);
		var state = 0x2545F491 ^ (seed << 8);

		for (i in 0...length)
		{
			state ^= state << 13;
			state ^= state >>> 17;
			state ^= state << 5;
			bytes.set(i, (state >>> 24) & 0xFF);
		}

		return bytes;
	}
}
