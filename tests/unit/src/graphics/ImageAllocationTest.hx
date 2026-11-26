package graphics;

import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.PixelFormat;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.utils.UInt8Array;
import utest.Assert;
import utest.Test;

/**
	Counts what the pixel operations allocate on HashLink, where each allocation is a call into the
	collector. On the other targets the count isn't available, so these tests are for HashLink only.

	The operations give the same pixels either way, which `ImageOperationOutputTest` pins. What changes
	is the work done for them: `setPixel` reading only the alpha it keeps, `getColorBoundsRect` reading
	the buffer rather than calling `getPixel32` for each pixel, and copying within one image copying
	only the rect it reads.
**/
class ImageAllocationTest extends Test
{
	public function new()
	{
		super();
	}

	#if hl
	public function testSetPixelAllocatesNoMoreThanSetPixel32():Void
	{
		// setPixel only has to read the alpha it keeps, where setPixel32 reads nothing. Today it reads all four
		// bytes, and each read through UInt8Array is boxed on HashLink (#2129), so one boxed read a call is allowed.
		for (format in [RGBA32, BGRA32, ARGB32])
		{
			for (premultiplied in [false, true])
			{
				var name = formatName(format) + (premultiplied ? " premultiplied" : "");
				var setPixel = pixelAllocations(format, premultiplied, false);
				var setPixel32 = pixelAllocations(format, premultiplied, true);

				Assert.isTrue(setPixel <= setPixel32 + 256,
					name + ": 256 calls to setPixel allocated " + setPixel + " times, and as many to setPixel32 " + setPixel32);
			}
		}
	}

	@Ignored("Waiting on #2128")
	public function testGetColorBoundsRectAllocatesTheSameForAnyImageSize():Void
	{
		for (format in [RGBA32, BGRA32, ARGB32])
		{
			var small = colorBoundsAllocations(8, format);
			var large = colorBoundsAllocations(64, format);

			// The large image has 64 times the pixels to scan. Each getPixel32 call boxes its format today; reading
			// the buffer through UInt8Array would box each byte instead until #2129, so the buffer is read otherwise.
			Assert.isTrue(large <= small + 16,
				formatName(format) + ": getColorBoundsRect allocated " + small + " times over 8x8 pixels and " + large + " over 64x64");
		}
	}

	public function testCopyPixelsWithinOneImageAllocatesForTheRectItCopies():Void
	{
		var image = new Image(null, 0, 0, 512, 512, 0x336699FF);
		image.setPixel32(10, 10, 0xFF0000FF);

		// Overlapping, so the rect has to be read before it is written
		var bytes = allocatedBytes(function()
		{
			image.copyPixels(image, new Rectangle(8, 8, 8, 8), new Vector2(12, 12));
		});

		Assert.equals(0xFF0000FF, image.getPixel32(14, 14));
		// The whole image is 1 MB and the rect 256 bytes
		Assert.isTrue(bytes < 64 * 1024, "copying 8x8 pixels within a 512x512 image allocated " + bytes + " bytes");
	}

	// Helpers

	private static function pixelAllocations(format:PixelFormat, premultiplied:Bool, set32:Bool):Float
	{
		var image = randomImage(32, 32, format, premultiplied);
		var colors = [for (i in 0...256) (i * 0x01030507) | 0xFF000000];

		// Once first, so nothing that is made once is counted
		image.setPixel(0, 0, 0x123456);
		image.setPixel32(0, 0, 0xFF123456);

		return allocations(function()
		{
			for (i in 0...256)
			{
				if (set32) image.setPixel32(i & 31, i >> 3, colors[i]);
				else image.setPixel(i & 31, i >> 3, colors[i]);
			}
		});
	}

	/** Searched from each edge for its one matching pixel, in the middle, so each search covers half the image **/
	private static function colorBoundsAllocations(size:Int, format:PixelFormat):Float
	{
		var image = new Image(null, 0, 0, size, size, 0x000000FF);
		image.format = format;
		image.setPixel32(size >> 1, size >> 1, 0x123456FF);
		var bounds = image.getColorBoundsRect(0xFFFFFFFF, 0x123456FF, true);
		Assert.equals(1, bounds.width * bounds.height);

		return allocations(function()
		{
			image.getColorBoundsRect(0xFFFFFFFF, 0x123456FF, true);
		});
	}

	private static function randomImage(width:Int, height:Int, format:PixelFormat, premultiplied:Bool):Image
	{
		var data = new UInt8Array(width * height * 4);
		var state = 0x2545F491;

		for (i in 0...data.length)
		{
			state ^= state << 13;
			state ^= state >>> 17;
			state ^= state << 5;
			data[i] = state & 0xFF;
		}

		// Alpha in every format's place is above zero, so premultiplied colors survive unmultiplying
		for (i in 0...width * height)
		{
			var alpha = (format == ARGB32 ? i * 4 : i * 4 + 3);
			data[alpha] = data[alpha] | 0x10;
		}

		var buffer = new ImageBuffer(data, width, height, 32, format);
		buffer.premultiplied = premultiplied;
		buffer.transparent = true;
		return new Image(buffer, 0, 0, width, height, null, DATA);
	}

	private static function allocations(f:Void->Void):Float
	{
		var before = allocationCount();
		f();
		return allocationCount() - before;
	}

	private static function allocatedBytes(f:Void->Void):Float
	{
		var total = 0.0, count = 0.0, memory = 0.0;
		@:privateAccess hl.Gc._stats(total, count, memory);
		var before = total;
		f();
		@:privateAccess hl.Gc._stats(total, count, memory);
		return total - before;
	}

	// Through the native call, as Gc.stats() makes an object of its own
	private static function allocationCount():Float
	{
		var total = 0.0, count = 0.0, memory = 0.0;
		@:privateAccess hl.Gc._stats(total, count, memory);
		return count;
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
	#end
}
