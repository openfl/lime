package system;

#if (sys && lime_cffi && !macro && target.threaded)
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import lime.graphics.Image;
import lime.utils.Bytes as LimeBytes;
import lime.utils.CompressionAlgorithm;
import sys.thread.Deque;
import sys.thread.Thread;
#end
import utest.Assert;
import utest.Test;

/**
	Native calls that take `Bytes`, made on several threads at once.

	Each native call that takes `Bytes` notes them in shared state while it runs, under one lock, so that
	the bytes can be handed back as the same object. However that is kept, calls on different threads
	have to see only their own bytes and give their own results, and a call has to hand back the bytes it
	was given.
**/
class NativeBytesThreadTest extends Test
{
	public function new()
	{
		super();
	}

	#if (sys && lime_cffi && !macro && target.threaded)
	public function testCompressionOnSeveralThreadsAtOnceGivesEachItsOwnResult():Void
	{
		var errors = runOnThreads(4, 25, function(thread, round)
		{
			var data = noise(20000 + thread * 977 + round * 31, thread * 1000 + round);

			var algorithms:Array<CompressionAlgorithm> = [ZLIB, DEFLATE, GZIP, LZMA];
			for (algorithm in algorithms)
			{
				var compressed = (data : LimeBytes).compress(algorithm);
				var decompressed = compressed == null ? null : (compressed : LimeBytes).decompress(algorithm);

				if (decompressed == null || decompressed.compare(data) != 0)
				{
					return algorithm + " on thread " + thread + ", round " + round + " gave other bytes back";
				}
			}

			return null;
		});

		Assert.equals(0, errors.length, errors.join("; "));
	}

	public function testDecodingImagesOnSeveralThreadsAtOnceGivesEachItsOwnPixels():Void
	{
		var files = ["assets/image-rgba.png", "assets/image-palette.png", "assets/image-420.jpg", "assets/image-grey.jpg"];
		var bytes = [for (file in files) LimeBytes.fromFile(file)];
		var expected = [for (each in bytes) checksum(Image.fromBytes(each))];

		var errors = runOnThreads(4, 25, function(thread, round)
		{
			var i = (thread + round) % files.length;
			var actual = checksum(Image.fromBytes(bytes[i]));
			return actual == expected[i] ? null : files[i] + " on thread " + thread + " gave " + actual + " for " + expected[i];
		});

		Assert.equals(0, errors.length, errors.join("; "));
	}

	public function testBytesHandedToANativeCallComeBackAsThemselves():Void
	{
		// An image decoded from bytes keeps its own buffer, and the bytes it was decoded from are left alone
		var bytes = LimeBytes.fromFile("assets/image-rgba.png");
		var copy = bytes.sub(0, bytes.length);
		var errors = runOnThreads(4, 25, function(thread, round)
		{
			var image = Image.fromBytes(bytes);
			var encoded = image.encode(PNG);
			var again = Image.fromBytes(encoded);
			if (checksum(image) != checksum(again)) return "thread " + thread + ", round " + round + ": the image did not survive encoding";
			return null;
		});

		Assert.equals(0, errors.length, errors.join("; "));
		Assert.equals(0, bytes.compare(copy), "the bytes decoded from changed");
	}

	// Helpers

	private static function runOnThreads(threads:Int, rounds:Int, work:Int->Int->String):Array<String>
	{
		var results = new Deque<Array<String>>();

		for (thread in 0...threads)
		{
			Thread.create(function()
			{
				var errors = [];

				for (round in 0...rounds)
				{
					try
					{
						var error = work(thread, round);
						if (error != null) errors.push(error);
					}
					catch (e:Dynamic)
					{
						errors.push("thread " + thread + ", round " + round + " threw " + e);
					}
				}

				results.add(errors);
			});
		}

		var all = [];
		for (i in 0...threads)
		{
			all = all.concat(results.pop(true));
		}
		return all;
	}

	private static function noise(length:Int, seed:Int):Bytes
	{
		var bytes = Bytes.alloc(length);
		var state = seed * 0x9E3779B1 + 1;

		for (i in 0...length)
		{
			state ^= state << 13;
			state ^= state >>> 17;
			state ^= state << 5;
			// Half text-like, so it compresses with matches as well as codes
			bytes.set(i, i % 512 < 256 ? state & 0xFF : 97 + (state & 7));
		}

		return bytes;
	}

	private static function checksum(image:Image):String
	{
		if (image == null) return "null";

		var data = image.buffer.data;
		return StringTools.hex(Crc32.make(data.toBytes().sub(data.byteOffset, data.byteLength)), 8);
	}
	#end
}
