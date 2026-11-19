package utils;

import haxe.io.Bytes;
import lime.utils.Bytes as LimeBytes;
#if sys
import sys.FileSystem;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	`lime.utils.Bytes` apart from compression, which CompressionTest covers. A file read from disk has
	exactly the bytes that were written to it, whatever its size or name, a file that can't be read gives
	null or a failed Future rather than a crash or empty Bytes, and text is stored as UTF-8, as
	`haxe.io.Bytes.ofString()` documents.
**/
class BytesTest extends Test
{
	// "a", "é" (2 bytes), "€" (3 bytes) and U+1F600 (4 bytes)
	private static inline var TEXT = "aé€\u{1F600}";
	private static inline var TEXT_UTF8 = "61c3a9e282acf09f9880";

	#if (sys && lime_cffi && !macro)
	private var files:AssetTestFiles;
	#end

	public function new()
	{
		super();
	}

	public function testAllocGivesBytesOfThatLength():Void
	{
		var bytes:Bytes = LimeBytes.alloc(16);
		Assert.equals(16, bytes.length);

		bytes.set(0, 0x12);
		bytes.set(15, 0xFE);
		Assert.equals(0x12, bytes.get(0));
		Assert.equals(0xFE, bytes.get(15));
	}

	public function testAllocOfNothingGivesEmptyBytes():Void
	{
		var bytes:Bytes = LimeBytes.alloc(0);
		Assert.equals(0, bytes.length);
		Assert.equals("", bytes.toString());
		Assert.equals(0, bytes.sub(0, 0).length);
	}

	public function testOfStringStoresTextAsUTF8():Void
	{
		var bytes:Bytes = LimeBytes.ofString(TEXT);
		Assert.equals(TEXT_UTF8, bytes.toHex());
		Assert.equals(TEXT, bytes.getString(0, bytes.length));
	}

	public function testOfStringOfAnEmptyStringIsEmpty():Void
	{
		var bytes:Bytes = LimeBytes.ofString("");
		Assert.equals(0, bytes.length);
	}

	public function testFromBytesGivesTheSameBytes():Void
	{
		var source = Bytes.ofHex("00017f80ff");
		var bytes:Bytes = LimeBytes.fromBytes(source);
		Assert.equals("00017f80ff", bytes.toHex());

		var none:Bytes = LimeBytes.fromBytes(null);
		Assert.isNull(none);
	}

	public function testOfDataWrapsBytesData():Void
	{
		var source = Bytes.ofHex("00017f80ff");
		var bytes:Bytes = LimeBytes.ofData(source.getData());
		Assert.equals("00017f80ff", bytes.toHex());
	}

	public function testNewBytesHaveTheLengthGiven():Void
	{
		// The data may be longer than the bytes that use it
		var source = Bytes.ofHex("00017f80ff");
		var bytes:Bytes = new LimeBytes(3, source.getData());
		Assert.equals(3, bytes.length);
		Assert.equals("00017f", bytes.toHex());
	}

	public function testFastGetReadsBytesAtBothEnds():Void
	{
		var data = Bytes.ofHex("fe017f8000ff").getData();
		var first:Int = LimeBytes.fastGet(data, 0);
		var middle:Int = LimeBytes.fastGet(data, 3);
		var last:Int = LimeBytes.fastGet(data, 5);

		Assert.equals(0xFE, first);
		Assert.equals(0x80, middle);
		Assert.equals(0xFF, last);
	}

	public function testLoadFromBytesCompletesWithTheBytes():Void
	{
		var future = LimeBytes.loadFromBytes(Bytes.ofHex("00017f80ff"));
		Assert.isTrue(future.isComplete);
		Assert.isTrue(!future.isError);

		var value:Bytes = future.value;
		Assert.notNull(value);
		if (value != null) Assert.equals("00017f80ff", value.toHex());
	}

	#if (sys && lime_cffi && !macro)
	public function setupClass():Void
	{
		files = new AssetTestFiles("bytes");
	}

	public function teardownClass():Void
	{
		files.remove();
	}

	public function testFromFileReadsExactlyTheBytesWritten():Void
	{
		// Every byte value, with the line endings and Ctrl-Z that reading as text would change
		var written = Bytes.alloc(1024);
		for (i in 0...written.length)
		{
			written.set(i, i & 0xFF);
		}

		var path = files.write("every-byte.bin", written);
		assertSameBytes(written, LimeBytes.fromFile(path));
	}

	public function testFromFileReadsAFileLargerThanOneReadBuffer():Void
	{
		var written = pattern(1024 * 1024 + 3);
		var path = files.write("large.bin", written);
		assertSameBytes(written, LimeBytes.fromFile(path));
	}

	public function testFromFileReadsAFileOfOneByte():Void
	{
		var written = Bytes.ofHex("00");
		var path = files.write("one-byte.bin", written);
		assertSameBytes(written, LimeBytes.fromFile(path));
	}

	public function testFromFileOfAnEmptyFileGivesEmptyBytes():Void
	{
		var path = files.write("empty.bin", Bytes.alloc(0));
		var read:Bytes = LimeBytes.fromFile(path);

		Assert.notNull(read, "an empty file read as null, as a missing file does");
		if (read != null) Assert.equals(0, read.length);
	}

	public function testFromFileOfAMissingFileGivesNull():Void
	{
		var missing:Bytes = LimeBytes.fromFile(files.path("missing.bin"));
		Assert.isNull(missing);

		var missingDirectory:Bytes = LimeBytes.fromFile(files.path("missing/file.bin"));
		Assert.isNull(missingDirectory);
	}

	public function testFromFileOfADirectoryGivesNull():Void
	{
		var directory:Bytes = LimeBytes.fromFile(files.directory);
		Assert.isNull(directory);
	}

	public function testFromFileOfNoPathGivesNull():Void
	{
		var none:Bytes = LimeBytes.fromFile(null);
		Assert.isNull(none);
	}

	public function testFromFileClosesTheFile():Void
	{
		var path = files.write("closed.bin", pattern(100));
		Assert.notNull(LimeBytes.fromFile(path));

		// Windows doesn't delete a file that is still open
		try
		{
			FileSystem.deleteFile(path);
		}
		catch (e:Dynamic) {}

		Assert.isFalse(FileSystem.exists(path), "the file is still open after fromFile()");
	}

	// Neko's own file functions take names in the ANSI code page on Windows, so it can't write these files there
	#if !(neko && windows)
	public function testFromFileReadsAFileWithANonASCIIName():Void
	{
		var written = pattern(300);
		assertSameBytes(written, LimeBytes.fromFile(files.write("café-日本語.bin", written)), "the file's name");
		assertSameBytes(written, LimeBytes.fromFile(files.write("été/日本語/data.bin", written)), "its directories' names");
	}

	@:timeout(5000)
	public function testLoadFromFileReadsAFileWithANonASCIIName(async:Async):Void
	{
		var written = pattern(300);
		var path = files.write("chargé-読み込み.bin", written);

		LimeBytes.loadFromFile(path).onComplete(function(bytes)
		{
			assertSameBytes(written, bytes);
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadFromFile() failed: " + error);
			async.done();
		});
	}
	#end

	@:timeout(5000)
	public function testLoadFromFileCompletesWithTheFilesBytes(async:Async):Void
	{
		var written = pattern(70000);
		var path = files.write("loaded.bin", written);
		var progress = [];

		LimeBytes.loadFromFile(path).onProgress(function(loaded, total)
		{
			progress.push(loaded + " of " + total);
		}).onComplete(function(bytes)
		{
			assertSameBytes(written, bytes);
			// The whole file is reported as loaded before the load completes
			Assert.equals("70000 of 70000", progress.length > 0 ? progress[progress.length - 1] : "no progress");
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadFromFile() failed: " + error);
			async.done();
		});
	}

	@:timeout(5000)
	public function testLoadFromFileFailsForAMissingFile(async:Async):Void
	{
		LimeBytes.loadFromFile(files.path("missing.bin")).onComplete(function(bytes)
		{
			Assert.fail("loadFromFile() completed for a missing file, with " + (bytes == null ? "null" : bytes.length + " bytes"));
			async.done();
		}).onError(function(error)
		{
			Assert.notNull(error);
			async.done();
		});
	}

	@:timeout(5000)
	public function testLoadFromFileOfAnEmptyFileCompletesWithEmptyBytes(async:Async):Void
	{
		var path = files.write("empty-loaded.bin", Bytes.alloc(0));

		LimeBytes.loadFromFile(path).onComplete(function(bytes)
		{
			Assert.notNull(bytes);
			if (bytes != null) Assert.equals(0, bytes.length);
			async.done();
		}).onError(function(error)
		{
			Assert.fail("loadFromFile() failed for an empty file: " + error);
			async.done();
		});
	}

	// Helpers

	private static function assertSameBytes(expected:Bytes, actual:Bytes, name:String = "", ?pos:haxe.PosInfos):Void
	{
		if (name != "") name += ": ";

		Assert.notNull(actual, name + "the file read as null", pos);
		if (actual == null) return;

		Assert.equals(expected.length, actual.length, name + "read " + actual.length + " bytes of " + expected.length, pos);
		if (expected.length != actual.length) return;

		var difference = -1;

		for (i in 0...expected.length)
		{
			if (expected.get(i) != actual.get(i))
			{
				difference = i;
				break;
			}
		}

		Assert.equals(-1, difference, name + "byte " + difference + " differs", pos);
	}

	/** Bytes that don't repeat from one block of a file to the next **/
	private static function pattern(length:Int):Bytes
	{
		var bytes = Bytes.alloc(length);

		for (i in 0...length)
		{
			bytes.set(i, (i * 31 + (i >> 8) * 7 + (i >> 16)) & 0xFF);
		}

		return bytes;
	}
	#end
}
