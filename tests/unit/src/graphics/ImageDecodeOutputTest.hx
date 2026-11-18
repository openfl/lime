package graphics;

#if (lime_cffi && !macro)
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import lime.app.Application;
import lime.app.Future;
import lime.graphics.Image;
import lime.graphics.PixelFormat;
import lime.utils.Bytes as LimeBytes;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	Pins the pixels today's native PNG and JPEG decoders give for the image files in assets/, as each
	image's size, buffer settings and a CRC-32 of its pixel bytes.

	These pin current native output for the performance work on decoding: releasing the collector while
	an image decodes, decoding straight into the image's buffer, and libjpeg-turbo's RGBA output and SIMD.
	Decoding must give the same bytes afterwards, so a change that is meant to change the output updates
	the constants here in the same commit.

	The files were written once with Pillow 13 (libjpeg-turbo 3.2, zlib-ng), from the same 45x37 drawing:
	- image-420.jpg: baseline, quality 85, chroma halved both ways (4:2:0)
	- image-444.jpg: baseline, quality 90, full resolution chroma (4:4:4)
	- image-422.jpg: baseline, quality 85, chroma halved across (4:2:2)
	- image-progressive.jpg: as image-420.jpg, progressive, so it holds the same coefficients
	- image-grey.jpg: one greyscale component, quality 85
	- image-cmyk.jpg: four components with an Adobe marker, stored inverted as Adobe applications do
	- image-rgba.png: 40x30 truecolour with alpha, deflated with dynamic Huffman codes
	- image-palette.png: 40x30, 4-bit indexed, with a transparency chunk shorter than the palette

	Each checksum is also that of Pillow's own decoding of the file, taking the CMYK file's samples to RGB
	as Lime does, so these pin the files' pixels and not only what Lime made of them.
**/
class ImageDecodeOutputTest extends Test
{
	#if (lime_cffi && !macro)
	private static var FIXTURES:Array<{path:String, pixels:String}> = [
		{path: "assets/image-420.jpg", pixels: "45x37 32bpp RGBA32 transparent 6660 bytes, crc 03F2157D"},
		{path: "assets/image-444.jpg", pixels: "45x37 32bpp RGBA32 transparent 6660 bytes, crc 48CDF84D"},
		{path: "assets/image-422.jpg", pixels: "45x37 32bpp RGBA32 transparent 6660 bytes, crc 6D375F3C"},
		{path: "assets/image-progressive.jpg", pixels: "45x37 32bpp RGBA32 transparent 6660 bytes, crc 03F2157D"},
		{path: "assets/image-grey.jpg", pixels: "45x37 32bpp RGBA32 transparent 6660 bytes, crc 4F5859F0"},
		{path: "assets/image-cmyk.jpg", pixels: "45x37 32bpp RGBA32 transparent 6660 bytes, crc FF1EBB1B"},
		{path: "assets/image-rgba.png", pixels: "40x30 32bpp RGBA32 transparent 4800 bytes, crc 47550931"},
		{path: "assets/image-palette.png", pixels: "40x30 32bpp RGBA32 transparent 4800 bytes, crc 87065BC5"}
	];
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	public function testJPEGWithHalvedChromaKeepsItsPixels():Void
	{
		assertDecodes("assets/image-420.jpg");
	}

	public function testJPEGWithFullChromaKeepsItsPixels():Void
	{
		assertDecodes("assets/image-444.jpg");
	}

	public function testJPEGWithChromaHalvedAcrossKeepsItsPixels():Void
	{
		assertDecodes("assets/image-422.jpg");
	}

	public function testProgressiveJPEGKeepsItsPixels():Void
	{
		assertDecodes("assets/image-progressive.jpg");

		// Progressive scans carry the same coefficients as the baseline file
		Assert.equals(expectedFor("assets/image-420.jpg"), expectedFor("assets/image-progressive.jpg"));
	}

	public function testGreyscaleJPEGKeepsItsPixels():Void
	{
		assertDecodes("assets/image-grey.jpg");
	}

	public function testCMYKJPEGKeepsItsPixels():Void
	{
		assertDecodes("assets/image-cmyk.jpg");
	}

	public function testDeflatedRGBAPNGKeepsItsPixels():Void
	{
		assertDecodes("assets/image-rgba.png");
	}

	public function testFourBitIndexedPNGKeepsItsPixels():Void
	{
		assertDecodes("assets/image-palette.png");
	}

	public function testRepeatedDecodesWhileTheCollectorRunsKeepThePixels():Void
	{
		for (round in 0...4)
		{
			for (fixture in FIXTURES)
			{
				// Bytes that nothing else holds, collected under the decode if anything lets go of them early
				var image = Image.fromBytes(LimeBytes.fromFile(fixture.path));
				collect();
				churn();

				var actual = describe(image);
				if (actual != fixture.pixels)
				{
					assertPin(fixture.pixels, actual, fixture.path + ", round " + round);
					return;
				}
			}
		}

		Assert.pass();
	}

	public function testLoadFromBytesGivesTheSamePixelsWhileTheMainThreadCollects():Void
	{
		// Image.loadFromBytes decodes on a worker thread, so collections here run alongside the decodes
		var futures:Array<Future<Image>> = [];
		var paths = [];

		for (round in 0...4)
		{
			for (fixture in FIXTURES)
			{
				futures.push(Image.loadFromBytes(LimeBytes.fromFile(fixture.path)));
				paths.push(fixture.path);
			}
		}

		var deadline = haxe.Timer.stamp() + 10;
		var waiting = firstUnfinished(futures);

		while (waiting != null && haxe.Timer.stamp() < deadline)
		{
			churn();
			collect();
			// Takes in what the worker has finished, as the application's loop would
			waiting.ready(0);
			waiting = firstUnfinished(futures);
		}

		for (i in 0...futures.length)
		{
			var future = futures[i];
			Assert.isTrue(future.isComplete, paths[i] + " did not finish decoding");
			if (future.isComplete) assertPin(expectedFor(paths[i]), describe(future.value), paths[i] + ", load " + i);
		}
	}

	public function testLoadFromFileGivesTheSamePixelsWhileTheMainThreadCollects(async:Async):Void
	{
		async.setTimeout(10000);

		var pending = FIXTURES.length;
		var collecting = function(_:Int)
		{
			churn();
			collect();
		};

		Application.current.onUpdate.add(collecting);

		for (fixture in FIXTURES)
		{
			var path = fixture.path;
			var expected = fixture.pixels;
			Image.loadFromFile(path).onComplete(function(image)
			{
				assertPin(expected, describe(image), path);
				if (--pending == 0)
				{
					Application.current.onUpdate.remove(collecting);
					async.done();
				}
			}).onError(function(error)
			{
				Assert.fail(path + " did not load: " + error);
				if (--pending == 0)
				{
					Application.current.onUpdate.remove(collecting);
					async.done();
				}
			});
		}
	}

	// Helpers

	private static function assertDecodes(path:String, ?pos:haxe.PosInfos):Void
	{
		var bytes = LimeBytes.fromFile(path);

		Assert.notNull(bytes, path + " is missing", pos);
		if (bytes == null) return;

		assertPin(expectedFor(path), describe(Image.fromBytes(bytes)), path + " through Image.fromBytes", pos);
		assertPin(expectedFor(path), describe(Image.fromFile(path)), path + " through Image.fromFile", pos);
	}

	private static function assertPin(expected:String, actual:String, name:String, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(expected, actual, name + " gave " + actual + ", pinned " + expected, pos);
	}

	/** The image's size and buffer settings, and a CRC-32 of its pixel bytes **/
	private static function describe(image:Image):String
	{
		if (image == null) return "null";

		var buffer = image.buffer;
		var data = buffer.data;
		var pixels = data.toBytes().sub(data.byteOffset, data.byteLength);

		return image.width + "x" + image.height + " " + buffer.bitsPerPixel + "bpp " + formatName(buffer.format)
			+ (buffer.premultiplied ? " premultiplied" : "") + (buffer.transparent ? " transparent" : " opaque") + " " + pixels.length + " bytes, crc "
			+ StringTools.hex(Crc32.make(pixels), 8);
	}

	private static function expectedFor(path:String):String
	{
		for (fixture in FIXTURES)
		{
			if (fixture.path == path) return fixture.pixels;
		}

		return null;
	}

	private static function firstUnfinished(futures:Array<Future<Image>>):Future<Image>
	{
		for (future in futures)
		{
			if (!future.isComplete && !future.isError) return future;
		}

		return null;
	}

	private static function formatName(format:PixelFormat):String
	{
		return switch (format)
		{
			case ARGB32: "ARGB32";
			case BGRA32: "BGRA32";
			default: "RGBA32";
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

	/** Allocations the size of the decoded images, which take memory a collection just freed **/
	private static function churn():Void
	{
		var keep:Array<Dynamic> = [];

		for (i in 0...32)
		{
			var bytes = Bytes.alloc(45 * 37 * 4);
			bytes.fill(0, bytes.length, 0xA5);
			keep.push(bytes);
			keep.push([for (j in 0...64) Std.string(j)]);
		}
	}
	#end
}
