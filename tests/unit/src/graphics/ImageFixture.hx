package graphics;

import haxe.PosInfos;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.PixelFormat;
import lime.utils.UInt8Array;
import utest.Assert;

/**
	Builds images for the image tests, and reads and writes their buffers
	directly, so that a test of one pixel operation does not lean on another.

	Colors here are always ARGB and unmultiplied, as Flash's `BitmapData`
	takes them. A premultiplied buffer is multiplied on the way in and
	unmultiplied on the way out, rounding to the nearest value.
**/
class ImageFixture
{
	public static function create(width:Int, height:Int, color:Int = 0, format:PixelFormat = null, premultiplied:Bool = false,
			transparent:Bool = true):Image
	{
		var buffer = new ImageBuffer(new UInt8Array(width * height * 4), width, height, 32, format == null ? RGBA32 : format);
		buffer.premultiplied = premultiplied;
		buffer.transparent = transparent;

		var image = new Image(buffer, 0, 0, width, height, null, DATA);
		fill(image, color);
		return image;
	}

	/**
		Creates an image from rows of ARGB colors.
	**/
	public static function fromRows(rows:Array<Array<Int>>, format:PixelFormat = null, premultiplied:Bool = false):Image
	{
		var image = create(rows[0].length, rows.length, 0, format, premultiplied);

		for (y in 0...rows.length)
		{
			for (x in 0...rows[y].length)
			{
				poke(image, x, y, rows[y][x]);
			}
		}

		return image;
	}

	/**
		An opaque image in which each pixel's color names its place.
	**/
	public static function numbered(width:Int, height:Int, format:PixelFormat = null):Image
	{
		var image = create(width, height, 0, format);

		for (y in 0...height)
		{
			for (x in 0...width)
			{
				poke(image, x, y, number(x, y));
			}
		}

		return image;
	}

	public static inline function number(x:Int, y:Int):Int
	{
		return 0xFF000000 | ((x + 1) << 16) | ((y + 1) << 8) | 0x40;
	}

	public static function fill(image:Image, color:Int):Void
	{
		for (y in 0...image.height)
		{
			for (x in 0...image.width)
			{
				poke(image, x, y, color);
			}
		}
	}

	/**
		Writes an ARGB color straight into the buffer, in the buffer's format.
	**/
	public static function poke(image:Image, x:Int, y:Int, color:Int):Void
	{
		var buffer = image.buffer;
		var a = (color >>> 24) & 0xFF;
		var r = (color >>> 16) & 0xFF;
		var g = (color >>> 8) & 0xFF;
		var b = color & 0xFF;

		if (buffer.premultiplied)
		{
			r = premultiply(r, a);
			g = premultiply(g, a);
			b = premultiply(b, a);
		}

		var data = buffer.data;
		var offset = byteOffset(image, x, y);

		switch (buffer.format)
		{
			case ARGB32:
				data[offset] = a;
				data[offset + 1] = r;
				data[offset + 2] = g;
				data[offset + 3] = b;

			case BGRA32:
				data[offset] = b;
				data[offset + 1] = g;
				data[offset + 2] = r;
				data[offset + 3] = a;

			default:
				data[offset] = r;
				data[offset + 1] = g;
				data[offset + 2] = b;
				data[offset + 3] = a;
		}
	}

	/**
		Reads the ARGB color stored in the buffer, premultiplied if the buffer is.
	**/
	public static function peek(image:Image, x:Int, y:Int):Int
	{
		var data = image.buffer.data;
		var offset = byteOffset(image, x, y);
		var first = data[offset];
		var second = data[offset + 1];
		var third = data[offset + 2];
		var fourth = data[offset + 3];

		return switch (image.buffer.format)
		{
			case ARGB32: argb(first, second, third, fourth);
			case BGRA32: argb(fourth, third, second, first);
			default: argb(fourth, first, second, third);
		}
	}

	/**
		Reads the unmultiplied ARGB color of a pixel from the buffer.
	**/
	public static function read(image:Image, x:Int, y:Int):Int
	{
		var color = peek(image, x, y);
		if (!image.buffer.premultiplied) return color;

		var a = (color >>> 24) & 0xFF;
		return argb(a, unmultiply((color >>> 16) & 0xFF, a), unmultiply((color >>> 8) & 0xFF, a), unmultiply(color & 0xFF, a));
	}

	/**
		Reads every pixel, unmultiplied, row by row.
	**/
	public static function pixels(image:Image):Array<Int>
	{
		var result = [];

		for (y in 0...image.height)
		{
			for (x in 0...image.width)
			{
				result.push(read(image, x, y));
			}
		}

		return result;
	}

	public static function bytesAt(image:Image, x:Int, y:Int):Array<Int>
	{
		var data = image.buffer.data;
		var offset = byteOffset(image, x, y);
		return [data[offset], data[offset + 1], data[offset + 2], data[offset + 3]];
	}

	public static inline function argb(a:Int, r:Int, g:Int, b:Int):Int
	{
		return ((a & 0xFF) << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF);
	}

	/**
		Re-encodes an ARGB color as the 32-bit value for another `PixelFormat`.
	**/
	public static function toFormat(color:Int, format:PixelFormat):Int
	{
		var a = (color >>> 24) & 0xFF;
		var r = (color >>> 16) & 0xFF;
		var g = (color >>> 8) & 0xFF;
		var b = color & 0xFF;

		return switch (format)
		{
			case ARGB32: color;
			case BGRA32: (b << 24) | (g << 16) | (r << 8) | a;
			default: (r << 24) | (g << 16) | (b << 8) | a;
		}
	}

	public static function premultiply(channel:Int, alpha:Int):Int
	{
		return Math.round(channel * alpha / 255);
	}

	public static function unmultiply(channel:Int, alpha:Int):Int
	{
		if (alpha == 0) return 0;
		var value = Math.round(channel * 255 / alpha);
		return value > 255 ? 255 : value;
	}

	public static function hex(value:Int):String
	{
		return "0x" + StringTools.hex(value, 8);
	}

	public static function formatName(format:PixelFormat):String
	{
		return switch (format)
		{
			case ARGB32: "ARGB32";
			case BGRA32: "BGRA32";
			default: "RGBA32";
		}
	}

	public static function sameColor(expected:Int, actual:Int, tolerance:Int = 0):Bool
	{
		var shift = 0;

		while (shift < 32)
		{
			var difference = ((expected >>> shift) & 0xFF) - ((actual >>> shift) & 0xFF);
			if (difference > tolerance || difference < -tolerance) return false;
			shift += 8;
		}

		return true;
	}

	/**
		Compares two 32-bit colors channel by channel, each within `tolerance`.
	**/
	public static function assertColor(expected:Int, actual:Int, tolerance:Int = 0, ?label:String, ?pos:PosInfos):Void
	{
		Assert.isTrue(sameColor(expected, actual, tolerance),
			(label != null ? label + ": " : "") + "expected " + hex(expected) + " but was " + hex(actual) + (tolerance > 0 ? " (within " + tolerance + ")" : ""),
			pos);
	}

	public static function assertPixel(expected:Int, image:Image, x:Int, y:Int, tolerance:Int = 0, ?label:String, ?pos:PosInfos):Void
	{
		assertColor(expected, read(image, x, y), tolerance, (label != null ? label + ", " : "") + "pixel " + x + "," + y, pos);
	}

	/**
		Compares every pixel of an image, row by row, and reports all those that
		differ in one assertion.
	**/
	public static function assertPixels(expected:Array<Int>, image:Image, tolerance:Int = 0, ?label:String, ?pos:PosInfos):Void
	{
		var actual = pixels(image);
		var differences = [];

		if (expected.length != actual.length)
		{
			Assert.fail((label != null ? label + ": " : "") + "expected " + expected.length + " pixels but the image has " + actual.length, pos);
			return;
		}

		for (i in 0...expected.length)
		{
			if (!sameColor(expected[i], actual[i], tolerance))
			{
				differences.push((i % image.width) + "," + Std.int(i / image.width) + " expected " + hex(expected[i]) + " was " + hex(actual[i]));
			}
		}

		Assert.isTrue(differences.length == 0, (label != null ? label + ": " : "") + differences.join("; ") + (tolerance > 0 ? " (within " + tolerance + ")" : ""), pos);
	}

	public static function assertBytes(expected:Array<Int>, actual:Array<Int>, ?label:String, ?pos:PosInfos):Void
	{
		if (actual == null)
		{
			Assert.fail((label != null ? label + ": " : "") + "expected [" + hexBytes(expected) + "] but was null", pos);
			return;
		}

		Assert.isTrue(expected.join(",") == actual.join(","), (label != null ? label + ": " : "") + "expected [" + hexBytes(expected) + "] but was [" + hexBytes(actual) + "]", pos);
	}

	public static function hexBytes(bytes:Array<Int>):String
	{
		return [for (byte in bytes) StringTools.hex(byte, 2)].join(" ");
	}

	private static inline function byteOffset(image:Image, x:Int, y:Int):Int
	{
		return ((image.offsetY + y) * image.buffer.width + image.offsetX + x) * 4;
	}
}
