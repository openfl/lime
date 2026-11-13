package utils;

import haxe.crypto.Adler32;
import haxe.crypto.Base64;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.zip.InflateImpl;
import lime.utils.Bytes as LimeBytes;
import lime.utils.CompressionAlgorithm;
import utest.Assert;
import utest.Test;

/**
	`lime.utils.Bytes.compress()` and `decompress()` against the formats they're named for: raw DEFLATE
	(RFC 1951), ZLIB (RFC 1950), GZIP (RFC 1952) and LZMA in the LZMA SDK's .lzma layout (a properties byte,
	a 4-byte dictionary size and an 8-byte uncompressed size that is all ones when unknown, then the data).
	Streams from other tools were written by Python's zlib, gzip and lzma modules.
**/
class CompressionTest extends Test
{
	private static var ALGORITHMS = [DEFLATE, GZIP, LZMA, ZLIB];
	private static inline var FOX = "The quick brown fox jumps over the lazy dog";

	private static inline var ZLIB_EMPTY = "eJwDAAAAAAE=";
	private static inline var ZLIB_ONE = "eJxLBAAAYgBi";
	private static inline var ZLIB_FOX = "eJwLyUhVKCzNTM5WSCrKL89TSMuvUMgqzS0oVsgvSy1SKMlIVchJrKpUSMlPBwBb3A/a";
	// zlib level 0: one stored block
	private static inline var ZLIB_FOX_STORED = "eAEBKwDU/1RoZSBxdWljayBicm93biBmb3gganVtcHMgb3ZlciB0aGUgbGF6eSBkb2db3A/a";
	private static inline var DEFLATE_EMPTY = "AwA=";
	private static inline var DEFLATE_FOX = "C8lIVSgszUzOVkgqyi/PU0jLr1DIKs0tKFbIL0stUigBSuckVlUqpOSnAwA=";
	private static inline var GZIP_EMPTY = "H4sIAAAAAAAC/wMAAAAAAAAAAAA=";
	// FNAME "fox.txt"
	private static inline var GZIP_FOX = "H4sICAAAAAAA/2ZveC50eHQAC8lIVSgszUzOVkgqyi/PU0jLr1DIKs0tKFbIL0stUigBSuckVlUqpOSnAwA5o09BKwAAAA==";
	// FEXTRA, FNAME, FCOMMENT and FHCRC
	private static inline var GZIP_FOX_ALL_FIELDS = "H4sIHgAAAAAA/wYAQVACAGhpZm94LnR4dABhIGNvbW1lbnQAQo4LyUhVKCzNTM5WSCrKL89TSMuvUMgqzS0oVsgvSy1SKAFK5yRWVSqk5KcDADmjT0ErAAAA";
	// "The quick brown " and "fox jumps over the lazy dog" as two members
	private static inline var GZIP_FOX_TWO_MEMBERS = "H4sIAAAAAAAA/wvJSFUoLM1MzlZIKsovz1MAAHwqG8gQAAAAH4sIAAAAAAAA/0vLr1DIKs0tKFbIL0stUijJSFXISayqVEjJTwcAla+dlRsAAAA=";
	// .lzma with an unknown size, so ending with an end marker
	private static inline var LZMA_EMPTY = "XQAAgAD//////////wCD//v//8AAAAA=";
	private static inline var LZMA_FOX = "XQAAgAD//////////wAqGgiiAyVm8Ut4xaIF/y7m2dIgGq00+OId6EE2+twGabs85BA0Jwnrs2bsGhcv//zOkAA=";
	// 2 MiB of zeros
	private static inline var LZMA_ZEROS = "XQAAgAD//////////wAAb/3//6O3/0c+SBVyOWFRuJIo5qOGB/nu5B6C0y/FOjwBS7F+yYqKTS+jDdl/puOMIxFT4FkYxXWK4nf4tpR/DGrA3nRJZOLpXFOyBNj3RAyrXw1tRunlw3aIt5ZXrLZN4Wkdb/tLiBBsQsuIP1wAj9BOryYolHEfPY8k4XCepyNf7CjLhdGVmIp+KpHyJ3X3GcAGmE2Y/div1ZAPxCVT+PWRNjEFpbDub8FwTUcM0ZERqq1gHbrOsScYXFmG6WZSWL7pdqxZ5OVbBQj5x9qt/PtSK3TNHlsgQvndUz34KWQJO4DLKmzftTvwxL0uX6oPPktmQpATDv8Qk/hxeFn4C83/lShGD6n8fN77mjAuVsCPhfODgcBlxCVT+PWRNjEFpbDub8FwTUcM0ZERqq1gHbrOsScYXFmG6WZSWL7pdqxZ5OVbBQj5x9qt/PtSK3TNHlsgQvndUz34KWQJO4DLKmzftTvwxLxkDSXSWP//mggAAA==";

	private static inline var ZEROS_LENGTH = 2 * 1024 * 1024;

	public function new()
	{
		super();
	}

	// Round trips

	@Ignored("Waiting on #2178")
	public function testEmptyBytesRoundTrip():Void
	{
		assertRoundTrips(Bytes.alloc(0));
	}

	public function testOneByteRoundTrips():Void
	{
		assertRoundTrips(Bytes.ofString("a"));
		var zero = Bytes.alloc(1);
		zero.set(0, 0);
		assertRoundTrips(zero);
	}

	public function testEveryByteValueRoundTrips():Void
	{
		assertRoundTrips(everyByte());
	}

	public function testHighlyCompressibleDataRoundTripsSmaller():Void
	{
		var data = repeated("abc", 1024 * 1024);

		for (algorithm in ALGORITHMS)
		{
			var compressed = compressQuietly(data, algorithm);
			Assert.isTrue(compressed != null && compressed.length < data.length / 50,
				algorithm + " compressed 1 MiB of \"abcabc...\" to " + (compressed == null ? "null" : compressed.length + " bytes"));
		}

		assertRoundTrips(data);
	}

	public function testRandomDataRoundTrips():Void
	{
		assertRoundTrips(random(65536, 1));
	}

	public function testLargeDataRoundTrips():Void
	{
		// Over a megabyte each of random bytes, zeros and text
		var data = Bytes.alloc(3 * 1024 * 1024 + 7);
		data.blit(0, random(1024 * 1024, 2), 0, 1024 * 1024);
		data.fill(1024 * 1024, 1024 * 1024, 0);
		data.blit(2 * 1024 * 1024, repeated(FOX, 1024 * 1024 + 7), 0, 1024 * 1024 + 7);

		assertRoundTrips(data);
	}

	public function testCompressingLeavesItsInputUnchanged():Void
	{
		var data = random(4096, 3);
		var copy = data.sub(0, data.length);

		for (algorithm in ALGORITHMS)
		{
			var compressed = compressQuietly(data, algorithm);
			Assert.equals(-1, firstDifference(copy, data), algorithm + " changed what it compressed");

			if (compressed != null)
			{
				var compressedCopy = compressed.sub(0, compressed.length);
				decompressQuietly(compressed, algorithm);
				Assert.equals(-1, firstDifference(compressedCopy, compressed), algorithm + " changed what it decompressed");
			}
		}
	}

	#if neko
	@Ignored("Waiting on #2179")
	#end
	public function testCompressedBytesCompareEqualToACopy():Void
	{
		// Bytes.compare() gives 0 when the bytes are identical, and getData() holds the bytes
		var data = random(1000, 12);

		for (algorithm in ALGORITHMS)
		{
			var compressed = compressQuietly(data, algorithm);
			Assert.notNull(compressed, Std.string(algorithm));
			if (compressed == null) continue;

			var decompressed = decompressQuietly(compressed, algorithm);
			var copy = compressed.sub(0, compressed.length);
			Assert.equals(0, compressed.compare(copy), algorithm + ": compressed bytes compare " + compressed.compare(copy) + " to their copy");
			var comparison = (decompressed == null ? -2 : data.compare(decompressed));
			Assert.equals(0, comparison, algorithm + ": decompressed bytes compare " + comparison + " to the original");
			var dataLength = Bytes.ofData(compressed.getData()).length;
			Assert.equals(compressed.length, dataLength, algorithm + ": getData() holds " + dataLength + " bytes for a length of " + compressed.length);
		}
	}

	// Framing

	public function testZlibStreamsStartWithAValidHeader():Void
	{
		// CMF holds CM 8 (deflate) and CINFO 7 or less; FLG has no preset dictionary, and CMF * 256 + FLG is a multiple of 31 (RFC 1950 §2.2)
		for (data in [Bytes.alloc(0), Bytes.ofString(FOX), random(70000, 4)])
		{
			var compressed = compressQuietly(data, ZLIB);
			Assert.notNull(compressed);
			if (compressed == null || compressed.length < 6) continue;

			var cmf = compressed.get(0);
			var flg = compressed.get(1);
			Assert.equals(8, cmf & 0x0F, "CM");
			Assert.isTrue(cmf >> 4 <= 7, "CINFO is " + (cmf >> 4));
			Assert.equals(0, flg & 0x20, "FDICT");
			Assert.equals(0, (cmf * 256 + flg) % 31, "FCHECK");
		}
	}

	public function testZlibStreamsEndWithTheirAdler32():Void
	{
		// The last four bytes are the Adler-32 of the uncompressed data, most significant byte first (RFC 1950 §2.2)
		for (data in [Bytes.alloc(0), Bytes.ofString("a"), Bytes.ofString(FOX), random(70000, 5)])
		{
			var compressed = compressQuietly(data, ZLIB);
			Assert.notNull(compressed);
			if (compressed == null || compressed.length < 6) continue;

			Assert.equals(hex(Adler32.make(data)), hexBigEndian(compressed, compressed.length - 4), data.length + " bytes");
		}
	}

	public function testZlibStreamsInflateWithAnotherDecoder():Void
	{
		// Haxe's own inflater checks the header and the Adler-32 too
		for (data in [Bytes.alloc(0), Bytes.ofString(FOX), random(70000, 6), repeated("abc", 100000)])
		{
			var compressed = compressQuietly(data, ZLIB);
			Assert.notNull(compressed);
			if (compressed == null) continue;

			var input = new BytesInput(compressed);
			var inflated = inflate(input, true);
			Assert.equals(0, data.compare(inflated), data.length + " bytes inflated to " + (inflated == null ? "nothing" : inflated.length + " bytes"));
			Assert.equals(compressed.length, input.position, "the stream doesn't end where its trailer does");
		}
	}

	public function testRawDeflateHasNoHeaderOrTrailer():Void
	{
		// A raw deflate stream is just its blocks (RFC 1951), so it inflates without a zlib header and ends with its last block
		for (data in [Bytes.alloc(0), Bytes.ofString(FOX), random(70000, 7), repeated("abc", 100000)])
		{
			var compressed = compressQuietly(data, DEFLATE);
			Assert.notNull(compressed);
			if (compressed == null) continue;

			var input = new BytesInput(compressed);
			var inflated = inflate(input, false);
			Assert.equals(0, data.compare(inflated), data.length + " bytes inflated to " + (inflated == null ? "nothing" : inflated.length + " bytes"));
			Assert.equals(compressed.length, input.position, data.length + " bytes: " + (compressed.length - input.position) + " bytes follow the last block");
		}
	}

	public function testGZipStreamsHaveTheirMagicHeader():Void
	{
		// ID1 0x1f, ID2 0x8b, CM 8, and FLG's reserved bits clear (RFC 1952 §2.3.1)
		for (data in [Bytes.alloc(0), Bytes.ofString(FOX)])
		{
			var compressed = compressQuietly(data, GZIP);
			Assert.notNull(compressed);
			if (compressed == null || compressed.length < 18) continue;

			Assert.equals("1F8B08", hex(compressed.get(0), 2) + hex(compressed.get(1), 2) + hex(compressed.get(2), 2));
			Assert.equals(0, compressed.get(3) & 0xE0, "FLG's reserved bits");
		}
	}

	public function testGZipStreamsEndWithTheirCRC32AndSize():Void
	{
		// The member ends with the CRC-32 and the size of the uncompressed data, least significant byte first (RFC 1952 §2.3.1)
		for (data in [Bytes.alloc(0), Bytes.ofString("a"), Bytes.ofString(FOX), random(70000, 8)])
		{
			var compressed = compressQuietly(data, GZIP);
			Assert.notNull(compressed);
			if (compressed == null || compressed.length < 18) continue;

			Assert.equals(hex(Crc32.make(data)), hexLittleEndian(compressed, compressed.length - 8), data.length + " bytes: CRC32");
			Assert.equals(hex(data.length), hexLittleEndian(compressed, compressed.length - 4), data.length + " bytes: ISIZE");

			// What lies between the header and the trailer is a raw deflate stream
			var input = new BytesInput(compressed, gzipHeaderLength(compressed));
			var inflated = inflate(input, false);
			Assert.equals(0, data.compare(inflated), data.length + " bytes: the deflate stream");
			Assert.equals(compressed.length - 8, input.position, data.length + " bytes: the trailer doesn't follow the deflate stream");
		}
	}

	public function testLZMAStreamsStartWithTheirProperties():Void
	{
		// The properties byte is (pb * 5 + lp) * 9 + lc, below 225, and the size is the data's or unknown
		for (data in [Bytes.alloc(0), Bytes.ofString(FOX), random(70000, 9)])
		{
			var compressed = compressQuietly(data, LZMA);
			Assert.notNull(compressed);
			if (compressed == null || compressed.length < 13) continue;

			Assert.isTrue(compressed.get(0) < 225, "the properties byte is " + compressed.get(0));
			var size = hexLittleEndian(compressed, 9) + hexLittleEndian(compressed, 5);
			Assert.isTrue(size == "FFFFFFFFFFFFFFFF" || size == "00000000" + hex(data.length), data.length + " bytes gave the size " + size);
		}
	}

	// Streams written by other tools

	@Ignored("Waiting on #2178")
	public function testZlibStreamsFromOtherToolsDecompress():Void
	{
		assertDecompresses(Bytes.alloc(0), ZLIB_EMPTY, ZLIB, "empty");
		assertDecompresses(Bytes.ofString("a"), ZLIB_ONE, ZLIB, "one byte");
		assertDecompresses(Bytes.ofString(FOX), ZLIB_FOX, ZLIB, "the fox");
		assertDecompresses(Bytes.ofString(FOX), ZLIB_FOX_STORED, ZLIB, "the fox, stored");
	}

	@Ignored("Waiting on #2178")
	public function testRawDeflateStreamsFromOtherToolsDecompress():Void
	{
		assertDecompresses(Bytes.alloc(0), DEFLATE_EMPTY, DEFLATE, "empty");
		assertDecompresses(Bytes.ofString(FOX), DEFLATE_FOX, DEFLATE, "the fox");
	}

	@Ignored("Waiting on #2178")
	public function testGZipStreamsFromOtherToolsDecompress():Void
	{
		assertDecompresses(Bytes.alloc(0), GZIP_EMPTY, GZIP, "empty");
		assertDecompresses(Bytes.ofString(FOX), GZIP_FOX, GZIP, "the fox");
	}

	public function testGZipOptionalHeaderFieldsAreSkipped():Void
	{
		// A decompressor must skip FEXTRA, FNAME, FCOMMENT and FHCRC when they're there (RFC 1952 §2.3.1.2)
		assertDecompresses(Bytes.ofString(FOX), GZIP_FOX_ALL_FIELDS, GZIP);
	}

	@Ignored("Waiting on #2178")
	public function testConcatenatedGZipMembersDecompressToTheirConcatenation():Void
	{
		// A gzip file is a series of members (RFC 1952 §2.2)
		assertDecompresses(Bytes.ofString(FOX), GZIP_FOX_TWO_MEMBERS, GZIP);
	}

	@Ignored("Waiting on #2177")
	public function testLZMAStreamsFromOtherToolsDecompress():Void
	{
		assertDecompresses(Bytes.alloc(0), LZMA_EMPTY, LZMA, "empty");
		assertDecompresses(Bytes.ofString(FOX), LZMA_FOX, LZMA, "the fox");
	}

	@Ignored("Waiting on #2177")
	public function testStreamsThatExpandPastAMegabyteDecompress():Void
	{
		var zeros = Bytes.alloc(ZEROS_LENGTH);
		zeros.fill(0, zeros.length, 0);

		// About 2 KB each, expanding a thousand times over
		assertDecompresses(zeros, zeroRun("78daedc13101000000c2a0f54f6d0c1fa0", 2032, "be0601e00001"), ZLIB, "zlib");
		assertDecompresses(zeros, zeroRun("edc13101000000c2a0f54f6d0c1fa0", 2032, "be06"), DEFLATE, "deflate");
		assertDecompresses(zeros, zeroRun("1f8b08000000000002ffedc13101000000c2a0f54f6d0c1fa0", 2032, "be067e87898d00002000"), GZIP, "gzip");
		assertDecompresses(zeros, Base64.decode(LZMA_ZEROS), LZMA, "lzma");
	}

	// Input that isn't a stream

	#if !neko
	@Ignored("Waiting on #2177")
	#end
	public function testGarbageFailsToDecompress():Void
	{
		var garbage = random(1024, 10);
		// Not a valid block type, a zlib header or a gzip header
		garbage.set(0, 0xFF);

		for (algorithm in ALGORITHMS)
		{
			assertFails(garbage, algorithm, algorithm + ": random bytes");
			assertFails(Bytes.ofString(FOX), algorithm, algorithm + ": text");
		}
	}

	@Ignored("Waiting on #2177")
	public function testEmptyInputFailsToDecompress():Void
	{
		// Every format has at least a header or a final block, so no bytes at all is not a stream
		for (algorithm in ALGORITHMS)
		{
			assertFails(Bytes.alloc(0), algorithm, Std.string(algorithm));
		}
	}

	@Ignored("Waiting on #2177, #2178")
	public function testTruncatedStreamsFailToDecompress():Void
	{
		var data = random(20000, 11);

		for (algorithm in ALGORITHMS)
		{
			var compressed = compressQuietly(data, algorithm);
			Assert.notNull(compressed, Std.string(algorithm));
			if (compressed == null) continue;

			for (length in [1, Std.int(compressed.length / 2), compressed.length - 9])
			{
				assertFails(compressed.sub(0, length), algorithm, algorithm + ": the first " + length + " of " + compressed.length + " bytes");
			}
		}
	}

	@Ignored("Waiting on #2178")
	public function testStreamsMissingTheirTrailerFailToDecompress():Void
	{
		// Without the Adler-32 (RFC 1950) or the CRC-32 and size (RFC 1952), the data can't be checked
		var zlib = Base64.decode(ZLIB_FOX);
		assertFails(zlib.sub(0, zlib.length - 4), ZLIB, "zlib without its Adler-32");

		var gzip = Base64.decode(GZIP_FOX);
		assertFails(gzip.sub(0, gzip.length - 8), GZIP, "gzip without its CRC-32 and size");
	}

	public function testZlibStreamWithAWrongAdler32FailsToDecompress():Void
	{
		var zlib = Base64.decode(ZLIB_FOX);
		zlib.set(zlib.length - 1, zlib.get(zlib.length - 1) ^ 0x01);

		assertFails(zlib, ZLIB, "a wrong Adler-32");
	}

	public function testZlibStreamWithABadHeaderFailsToDecompress():Void
	{
		// FCHECK no longer makes the header a multiple of 31
		var zlib = Base64.decode(ZLIB_FOX);
		zlib.set(1, zlib.get(1) ^ 0x01);
		assertFails(zlib, ZLIB, "FCHECK");

		// CM 7 is reserved
		zlib = Base64.decode(ZLIB_FOX);
		zlib.set(0, 0x77);
		zlib.set(1, 0x01 + (31 - (0x7701 % 31)) % 31);
		assertFails(zlib, ZLIB, "CM");
	}

	public function testGZipStreamWithAWrongCRC32OrSizeFailsToDecompress():Void
	{
		var gzip = Base64.decode(GZIP_FOX);
		gzip.set(gzip.length - 8, gzip.get(gzip.length - 8) ^ 0x01);
		assertFails(gzip, GZIP, "CRC-32");

		gzip = Base64.decode(GZIP_FOX);
		gzip.set(gzip.length - 4, gzip.get(gzip.length - 4) ^ 0x01);
		assertFails(gzip, GZIP, "ISIZE");
	}

	public function testGZipStreamWithoutItsMagicFailsToDecompress():Void
	{
		var gzip = Base64.decode(GZIP_FOX);
		gzip.set(1, 0x8c);

		assertFails(gzip, GZIP, "ID2 0x8c");
	}

	@Ignored("Waiting on #2177")
	public function testLZMAStreamClaimingMoreThanItHoldsFailsToDecompress():Void
	{
		// The size field says how much the stream decodes to, so a stream that ends sooner is corrupt
		var lzma = compressQuietly(Bytes.ofString(FOX), LZMA);
		Assert.notNull(lzma);
		if (lzma == null || lzma.length < 13) return;

		lzma.set(5 + 2, lzma.get(5 + 2) + 1);
		assertFails(lzma, LZMA, "a size 64 KiB larger than the data");
	}

	public function testStreamsDecompressOnlyAsTheirOwnFormat():Void
	{
		// A zlib stream is not a gzip stream, and neither is a raw deflate stream
		assertFails(Base64.decode(ZLIB_FOX), GZIP, "zlib as gzip");
		assertFails(Base64.decode(GZIP_FOX), ZLIB, "gzip as zlib");
		assertFails(Base64.decode(DEFLATE_FOX), ZLIB, "deflate as zlib");
		assertFails(Base64.decode(ZLIB_FOX), LZMA, "zlib as lzma");
	}

	// Helpers

	private static function compress(data:Bytes, algorithm:CompressionAlgorithm):Bytes
	{
		return (data : LimeBytes).compress(algorithm);
	}

	private static function decompress(data:Bytes, algorithm:CompressionAlgorithm):Bytes
	{
		return (data : LimeBytes).decompress(algorithm);
	}

	private static function compressQuietly(data:Bytes, algorithm:CompressionAlgorithm):Bytes
	{
		try
		{
			return compress(data, algorithm);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	private static function decompressQuietly(data:Bytes, algorithm:CompressionAlgorithm):Bytes
	{
		try
		{
			return decompress(data, algorithm);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	private static function assertFails(data:Bytes, algorithm:CompressionAlgorithm, name:String, ?pos:haxe.PosInfos):Void
	{
		var result = unexpectedResult(data, algorithm);
		Assert.isNull(result, name + ": " + result, pos);
	}

	/** What decompressing gave when it should have failed, or null when it failed cleanly (null or an exception) **/
	private static function unexpectedResult(data:Bytes, algorithm:CompressionAlgorithm):String
	{
		try
		{
			var result = decompress(data, algorithm);
			return (result == null ? null : "decompressed to " + result.length + " bytes");
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	private static function assertRoundTrips(data:Bytes, ?pos:haxe.PosInfos):Void
	{
		for (algorithm in ALGORITHMS)
		{
			var name = algorithm + " of " + data.length + " bytes";
			var compressed:Bytes = null;
			var result:Bytes = null;

			try
			{
				compressed = compress(data, algorithm);
				if (compressed != null) result = decompress(compressed, algorithm);
			}
			catch (e:Dynamic)
			{
				Assert.fail(name + " threw " + e, pos);
				continue;
			}

			Assert.notNull(compressed, name + ": compressing gave null", pos);
			Assert.notNull(result, name + ": decompressing gave null", pos);
			if (result == null) continue;

			Assert.equals(data.length, result.length, name + ": decompressed to " + result.length + " bytes", pos);
			var difference = firstDifference(data, result);
			Assert.equals(-1, difference, name + ": byte " + difference + " differs", pos);
		}
	}

	private static function assertDecompresses(expected:Bytes, stream:Dynamic, algorithm:CompressionAlgorithm, name:String = "", ?pos:haxe.PosInfos):Void
	{
		var bytes:Bytes = (Std.isOfType(stream, String) ? Base64.decode(stream) : stream);
		name = algorithm + (name == "" ? "" : " (" + name + ")");
		var result:Bytes = null;

		try
		{
			result = decompress(bytes, algorithm);
		}
		catch (e:Dynamic)
		{
			Assert.fail(name + " threw " + e, pos);
			return;
		}

		Assert.notNull(result, name + ": decompressing gave null", pos);
		if (result == null) return;

		Assert.equals(expected.length, result.length, name + ": decompressed to " + result.length + " bytes, not " + expected.length, pos);
		var difference = firstDifference(expected, result);
		Assert.equals(-1, difference, name + ": byte " + difference + " differs", pos);
	}

	/** Inflates with Haxe's own decoder, as a zlib stream when `zlibHeader`, or null if it can't **/
	private static function inflate(input:BytesInput, zlibHeader:Bool):Bytes
	{
		try
		{
			var inflater = new InflateImpl(input, zlibHeader, zlibHeader);
			var out = new haxe.io.BytesBuffer();
			var buffer = Bytes.alloc(65536);

			while (true)
			{
				var length = inflater.readBytes(buffer, 0, buffer.length);
				out.addBytes(buffer, 0, length);
				if (length < buffer.length) break;
			}

			return out.getBytes();
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	/** The length of a gzip member's header, with its optional fields (RFC 1952 §2.3) **/
	private static function gzipHeaderLength(bytes:Bytes):Int
	{
		var flags = bytes.get(3);
		var position = 10;

		if (flags & 0x04 != 0) position += 2 + bytes.getUInt16(position);
		if (flags & 0x08 != 0)
		{
			while (bytes.get(position) != 0)
				position++;
			position++;
		}
		if (flags & 0x10 != 0)
		{
			while (bytes.get(position) != 0)
				position++;
			position++;
		}
		if (flags & 0x02 != 0) position += 2;

		return position;
	}

	private static function firstDifference(expected:Bytes, actual:Bytes):Int
	{
		for (i in 0...Std.int(Math.min(expected.length, actual.length)))
		{
			if (expected.get(i) != actual.get(i)) return i;
		}

		return (expected.length == actual.length ? -1 : Std.int(Math.min(expected.length, actual.length)));
	}

	private static function hex(value:Int, digits:Int = 8):String
	{
		return StringTools.hex(value, digits);
	}

	private static function hexBigEndian(bytes:Bytes, position:Int):String
	{
		return [for (i in 0...4) hex(bytes.get(position + i), 2)].join("");
	}

	private static function hexLittleEndian(bytes:Bytes, position:Int):String
	{
		return [for (i in 0...4) hex(bytes.get(position + 3 - i), 2)].join("");
	}

	private static function everyByte():Bytes
	{
		var bytes = Bytes.alloc(512);
		for (i in 0...bytes.length)
		{
			bytes.set(i, i & 0xFF);
		}
		return bytes;
	}

	private static function repeated(text:String, length:Int):Bytes
	{
		var bytes = Bytes.alloc(length);
		for (i in 0...length)
		{
			bytes.set(i, text.charCodeAt(i % text.length));
		}
		return bytes;
	}

	/** Bytes from a 32-bit xorshift generator, the same for each seed on every target **/
	private static function random(length:Int, seed:Int):Bytes
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

	/** A stream of `prefix`, `count` zero bytes, then `suffix`, as hex **/
	private static function zeroRun(prefix:String, count:Int, suffix:String):Bytes
	{
		var bytes = Bytes.alloc(Std.int(prefix.length / 2) + count + Std.int(suffix.length / 2));
		bytes.fill(0, bytes.length, 0);

		for (i in 0...Std.int(prefix.length / 2))
		{
			bytes.set(i, Std.parseInt("0x" + prefix.substr(i * 2, 2)));
		}

		var start = bytes.length - Std.int(suffix.length / 2);
		for (i in 0...Std.int(suffix.length / 2))
		{
			bytes.set(start + i, Std.parseInt("0x" + suffix.substr(i * 2, 2)));
		}

		return bytes;
	}
}
