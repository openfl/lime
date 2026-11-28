package utils;

#if (sys && lime_cffi && !macro && !neko)
import haxe.Timer;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.zip.Compress;
import lime.utils.Bytes as LimeBytes;
import lime.utils.CompressionAlgorithm;
#end
#if ((cpp || hl) && lime_cffi && !macro)
import system.CollectorWait;
#end
import utest.Assert;
import utest.Test;

/**
	Native decompression of large streams that another zlib wrote, byte for byte, and the work native
	compression does.

	The streams come from the Haxe target's own zlib, through `haxe.zip.Compress`, at its fastest, default
	and smallest settings, so they don't depend on the zlib Lime builds. Decompressing them must give
	exactly the data they were made from whatever Lime builds zlib from. What Lime's own compressors write
	may change with the zlib they are built from, so that is checked here only by its round trip and its
	size, with the size allowed some room.

	Decompressing grows its output as it goes, and shouldn't copy everything it has so far for each new
	piece. A collection on the main thread shouldn't wait for a worker's compression either.

	Not on Neko, where making the 6 MB of data in Haxe takes too long. The native code is the same.
**/
class CompressionOutputTest extends Test
{
	#if (sys && lime_cffi && !macro && !neko)
	private static var data:Bytes;
	#end

	public function new()
	{
		super();
	}

	#if (sys && lime_cffi && !macro && !neko)
	public function testTheDataKeepsItsBytes():Void
	{
		// The input to every other test here
		Assert.equals("6291469 bytes, crc " + DATA_CRC, describe(mixedData()));
	}

	public function testLargeZlibStreamsFromAnotherZlibDecompressToTheirData():Void
	{
		for (level in [1, 6, 9])
		{
			assertDecompresses(mixedData(), Compress.run(mixedData(), level), ZLIB, "zlib, level " + level);
		}
	}

	public function testLargeDeflateStreamsFromAnotherZlibDecompressToTheirData():Void
	{
		for (level in [1, 6, 9])
		{
			assertDecompresses(mixedData(), deflate(mixedData(), level), DEFLATE, "deflate, level " + level);
		}
	}

	public function testLargeGZipStreamsFromAnotherZlibDecompressToTheirData():Void
	{
		for (level in [1, 6, 9])
		{
			assertDecompresses(mixedData(), gzip([mixedData()], level), GZIP, "gzip, level " + level);
		}
	}

	public function testGZipStreamsOfManyMembersDecompressToTheirData():Void
	{
		// Members of uneven sizes, one of them empty, one of them a single byte
		var all = mixedData();
		var cuts = [0, 1, 1, 65537, 2000000, 2000001, 4500000, all.length];
		var members = [for (i in 0...cuts.length - 1) all.sub(cuts[i], cuts[i + 1] - cuts[i])];

		assertDecompresses(all, gzip(members, 6), GZIP, members.length + " members");
	}

	public function testStreamsOfEachBlockTypeDecompressToTheirData():Void
	{
		// Level 0 stores, and short runs at level 9 take fixed codes
		var text = mixedData().sub(0, 300000);
		assertDecompresses(text, Compress.run(text, 0), ZLIB, "stored blocks");
		assertDecompresses(Bytes.ofString("abcabcabd"), Compress.run(Bytes.ofString("abcabcabd"), 9), ZLIB, "fixed codes");
		assertDecompresses(Bytes.alloc(0), Compress.run(Bytes.alloc(0), 6), ZLIB, "nothing");
	}

	public function testCompressedDataRoundTripsAtAboutTodaysSize():Void
	{
		// Today's sizes, with a tenth either way for a zlib that compresses a little differently
		var sizes:Map<CompressionAlgorithm, Int> = [DEFLATE => DEFLATE_SIZE, GZIP => GZIP_SIZE, ZLIB => ZLIB_SIZE];
		var algorithms:Array<CompressionAlgorithm> = [DEFLATE, GZIP, ZLIB];
		var all = mixedData();

		for (algorithm in algorithms)
		{
			var compressed = (all : LimeBytes).compress(algorithm);
			Assert.notNull(compressed);
			if (compressed == null) continue;

			var size = sizes.get(algorithm);
			Assert.isTrue(compressed.length > size * 0.9 && compressed.length < size * 1.1,
				algorithm + " compressed " + all.length + " bytes to " + compressed.length + ", where today it gives " + size);
			assertDecompresses(all, compressed, algorithm, algorithm + " from Lime's own compressor");
		}
	}

	@Ignored("Waiting on #2233")
	public function testDecompressingTakesTimeInProportionToTheOutput():Void
	{
		// Zeros inflate quickly, so the time is the decompressor's own work on its output. Copying all of the
		// output for each new piece would take sixteen times as long for four times the output.
		var small = timeToDecompress(8 * 1024 * 1024);
		var large = timeToDecompress(32 * 1024 * 1024);

		Assert.isTrue(large < small * 8, "decompressing 8 MB took " + ms(small) + " and 32 MB " + ms(large));
	}

	#if (cpp || hl)
	@Ignored("Waiting on #2245")
	public function testTheCollectorRunsWhileAWorkerCompressesWithZlib():Void
	{
		var all = mixedData();
		var result = CollectorWait.collectDuring(function() (all : LimeBytes).compress(ZLIB));
		Assert.isFalse(result.waited, "Compressing with zlib on a worker: " + result);
	}

	@Ignored("Waiting on #2245")
	public function testTheCollectorRunsWhileAWorkerDecompressesWithZlib():Void
	{
		var stream = Compress.run(mixedData(), 6);
		var result = CollectorWait.collectDuring(function() (stream : LimeBytes).decompress(ZLIB));
		Assert.isFalse(result.waited, "Decompressing with zlib on a worker: " + result);
	}

	@Ignored("Waiting on #2245")
	public function testTheCollectorRunsWhileAWorkerCompressesWithLZMA():Void
	{
		var part = mixedData().sub(0, 1024 * 1024);
		var result = CollectorWait.collectDuring(function() (part : LimeBytes).compress(LZMA));
		Assert.isFalse(result.waited, "Compressing with LZMA on a worker: " + result);
	}

	@Ignored("Waiting on #2245")
	public function testTheCollectorRunsWhileAWorkerDecompressesWithLZMA():Void
	{
		var stream = (mixedData() : LimeBytes).compress(LZMA);
		var result = CollectorWait.collectDuring(function() (stream : LimeBytes).decompress(LZMA));
		Assert.isFalse(result.waited, "Decompressing with LZMA on a worker: " + result);
	}
	#end

	// Helpers

	private static inline var DATA_CRC = "5014556C";
	private static inline var DEFLATE_SIZE = 2859270;
	private static inline var GZIP_SIZE = 2859288;
	private static inline var ZLIB_SIZE = 2859276;

	private static function assertDecompresses(expected:Bytes, stream:Bytes, algorithm:CompressionAlgorithm, name:String, ?pos:haxe.PosInfos):Void
	{
		var actual:Bytes = null;

		try
		{
			actual = (stream : LimeBytes).decompress(algorithm);
		}
		catch (e:Dynamic)
		{
			Assert.fail(name + ": decompressing threw " + e, pos);
			return;
		}

		if (actual == null)
		{
			Assert.fail(name + " did not decompress", pos);
			return;
		}

		Assert.equals(describe(expected), describe(actual), name, pos);
		if (actual.length == expected.length) Assert.equals(-1, firstDifference(expected, actual), name + ": the first byte that differs", pos);
	}

	private static function describe(bytes:Bytes):String
	{
		return bytes.length + " bytes, crc " + StringTools.hex(Crc32.make(bytes), 8);
	}

	private static function firstDifference(a:Bytes, b:Bytes):Int
	{
		for (i in 0...a.length)
		{
			if (a.get(i) != b.get(i)) return i;
		}
		return -1;
	}

	/**
		6 MB of words made up from a 32-bit xorshift, as text that compresses with matches and codes, then
		random bytes that don't compress, zeros, and a short pattern repeated, ending at an odd length.
	**/
	private static function mixedData():Bytes
	{
		if (data != null) return data;

		var out = Bytes.alloc(6 * 1024 * 1024 + 13);
		var position = 0;
		var state = 0x2545F491;
		var syllables = ["ka", "lo", "mi", "ne", "su", "ta", "ri", "po", "ve", "do", "an", "el", "is", "or", "um", "th", "qu", "x"];

		while (position < 2 * 1024 * 1024)
		{
			state ^= state << 13;
			state ^= state >>> 17;
			state ^= state << 5;
			var length = 1 + ((state >>> 8) & 3);

			for (i in 0...length)
			{
				var syllable = syllables[((state >>> (i * 5)) & 0x1F) % syllables.length];
				for (c in 0...syllable.length)
				{
					if (position < 2 * 1024 * 1024) out.set(position++, StringTools.fastCodeAt(syllable, c));
				}
			}

			if (position < 2 * 1024 * 1024) out.set(position++, (state & 0x3F) == 0 ? 10 : 32);
		}

		while (position < 4 * 1024 * 1024)
		{
			state ^= state << 13;
			state ^= state >>> 17;
			state ^= state << 5;
			out.set(position++, state & 0xFF);
		}

		out.fill(position, 1024 * 1024, 0);
		position += 1024 * 1024;

		while (position < out.length)
		{
			out.set(position, (position * 7 + (position >> 9)) & 0xFF);
			position++;
		}

		data = out;
		return data;
	}

	/** The zlib stream without its two-byte header and its Adler-32 **/
	private static function deflate(bytes:Bytes, level:Int):Bytes
	{
		var stream = Compress.run(bytes, level);
		return stream.sub(2, stream.length - 6);
	}

	private static function gzip(members:Array<Bytes>, level:Int):Bytes
	{
		var out = new BytesBuffer();

		for (member in members)
		{
			// ID1, ID2, CM, FLG, MTIME, XFL, OS
			for (byte in [0x1F, 0x8B, 8, 0, 0, 0, 0, 0, 0, 255])
			{
				out.addByte(byte);
			}

			out.add(deflate(member, level));
			out.addInt32(Crc32.make(member));
			out.addInt32(member.length);
		}

		return out.getBytes();
	}

	private static function timeToDecompress(length:Int):Float
	{
		var zeros = Bytes.alloc(length);
		zeros.fill(0, length, 0);
		var stream = Compress.run(zeros, 6);
		var best = 1e9;

		for (i in 0...3)
		{
			var start = Timer.stamp();
			var result = (stream : LimeBytes).decompress(ZLIB);
			var time = Timer.stamp() - start;
			if (result == null || result.length != length) return 1e9;
			if (time < best) best = time;
		}

		return best;
	}

	private static function ms(seconds:Float):String
	{
		return Math.round(seconds * 1000) + " ms";
	}
	#end
}
