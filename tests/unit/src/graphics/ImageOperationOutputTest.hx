package graphics;

#if (lime_cffi && !macro)
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.ImageChannel;
import lime.graphics.PixelFormat;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.system.Endian;
import lime.utils.BytePointer;
import lime.utils.UInt8Array;
#end
import utest.Assert;
import utest.Test;

/**
	Pins what each image operation gives today, mostly as a CRC-32 of the buffer it leaves, for each
	`PixelFormat` with straight and premultiplied alpha. The images are filled from a 32-bit xorshift,
	so every channel value turns up, with a quarter of the pixels opaque and some clear.

	These pin current native output for the performance work on image operations: passing their
	arguments to the native prims more cheaply, reading only the alpha byte in `setPixel`, reading the
	buffer directly in `getColorBoundsRect` and copying less within one image. Each operation must give
	the same bytes afterwards, so a change that is meant to change the output updates the constants here
	in the same commit.

	Rects and points stay inside the images and short of the whole image, since clipping at the edges,
	the whole-image shortcuts and the threshold mask have problems that other tests show, and will change.
	Each array of pins follows `assertPins`: RGBA32, BGRA32 and ARGB32, each straight and then premultiplied.
**/
class ImageOperationOutputTest extends Test
{
	#if (lime_cffi && !macro)
	private static var FORMATS:Array<PixelFormat> = [RGBA32, BGRA32, ARGB32];

	private static inline var WIDTH = 23;
	private static inline var HEIGHT = 17;

	// Seeds for the destination, source and alpha images
	private static inline var DEST = 0x2545F491;
	private static inline var SOURCE = 0x6A09E667;
	private static inline var ALPHA = 0x3C6EF372;
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	public function testGeneratedImagesKeepTheirBytes():Void
	{
		// The input to every other test here
		assertPins([
			"2B22285C 06D1CC49 ED1789AA",
			"C03D8750 39FD6FB5 94F399B2",
			"2DA2675B FFB397B0 16F3D280",
			"4419C9E6 D725DA99 C3BF483C",
			"7461E90E 7AB5B3B9 C9D380BB",
			"65F8DACB E310921F F17B3CB2"
		], function(format, premultiplied)
		{
			return checksum(destImage(format, premultiplied)) + " " + checksum(sourceImage(format, premultiplied)) + " "
				+ checksum(alphaImage(format, premultiplied));
		});
	}

	public function testCopyPixelsKeepsItsOutput():Void
	{
		assertPins(["F317EC25", "EEFFA082", "B887EBE7", "8FEAC8D0", "2432BB38", "7B6E7828"], function(format, premultiplied)
		{
			var dest = destImage(format, premultiplied);
			var source = sourceImage(format, premultiplied);

			dest.copyPixels(source, new Rectangle(2, 3, 11, 7), new Vector2(5, 4));
			dest.copyPixels(source, new Rectangle(7, 1, 5, 9), new Vector2(16, 6));
			return checksum(dest);
		});
	}

	public function testCopyPixelsFromAnotherFormatKeepsItsOutput():Void
	{
		assertPins(["89AC17FD", "CBC7A27B", "E8D2800C", "4F24F691", "FEBFB3B3", "2792599A"], function(format, premultiplied)
		{
			var dest = destImage(format, premultiplied);
			var source = sourceImage(nextFormat(format), premultiplied);

			dest.copyPixels(source, new Rectangle(2, 3, 11, 7), new Vector2(5, 4));
			return checksum(dest);
		});
	}

	public function testCopyPixelsWithMergeAlphaKeepsItsOutput():Void
	{
		assertPins(["23DA9497", "531AF663", "85000672", "40E8DD09", "0DC8C63A", "A75EBD3F"], function(format, premultiplied)
		{
			var dest = destImage(format, premultiplied);
			var source = sourceImage(format, premultiplied);

			dest.copyPixels(source, new Rectangle(2, 3, 11, 7), new Vector2(5, 4), null, null, true);
			dest.copyPixels(source, new Rectangle(6, 0, 12, 10), new Vector2(9, 5), null, null, true);
			return checksum(dest);
		});
	}

	public function testCopyPixelsThroughAnAlphaImageKeepsItsOutput():Void
	{
		// The source rect starts at 0, 0, where the alpha point means the same whichever way it is read
		assertPins(["97127D99", "708C71AF", "611B5D25", "35FE7754", "023E91D4", "241FA0DA"], function(format, premultiplied)
		{
			var dest = destImage(format, premultiplied);

			dest.copyPixels(sourceImage(format, premultiplied), new Rectangle(0, 0, 12, 7), new Vector2(4, 5), alphaImage(format, premultiplied),
				new Vector2(3, 2), false);
			return checksum(dest);
		});
	}

	public function testCopyPixelsMergingThroughAnAlphaImageKeepsItsOutput():Void
	{
		assertPins(["7237A527", "89416C18", "B3AF00B5", "799D47AC", "99C5BC60", "3B40E63F"], function(format, premultiplied)
		{
			var dest = destImage(format, premultiplied);

			dest.copyPixels(sourceImage(format, premultiplied), new Rectangle(0, 0, 12, 7), new Vector2(4, 5), alphaImage(format, premultiplied),
				new Vector2(3, 2), true);
			return checksum(dest);
		});
	}

	public function testCopyPixelsWithinOneImageKeepsItsOutput():Void
	{
		assertPins([
			"33C6479E DA184AAC 858294C2",
			"874F3BBE F1477A71 B11F8AB7",
			"452550D3 5BFE171F D3634F9F",
			"B1797B16 EF116FFC B9E5A57F",
			"417F208D 21C1F81E 2F23825B",
			"C3BD3771 CAABB7A4 DCE40B32"
		], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);
			var results = [];

			// Overlapping down and right, then up and left, then apart
			image.copyPixels(image, new Rectangle(3, 2, 12, 9), new Vector2(6, 5));
			results.push(checksum(image));
			image.copyPixels(image, new Rectangle(8, 7, 10, 8), new Vector2(4, 3));
			results.push(checksum(image));
			image.copyPixels(image, new Rectangle(0, 0, 7, 6), new Vector2(14, 10));
			results.push(checksum(image));
			return results.join(" ");
		});
	}

	public function testScrollKeepsItsOutput():Void
	{
		assertPins([
			"C5450360 58D0CEEE AD135DF8",
			"B77D0295 EA17BA85 4C48093A",
			"729107BB 3F8BF396 BC3EBC89",
			"293C00DD 0672FFFA 0ABBABA8",
			"BAE746B2 E4C95C59 DBFFAEBD",
			"85813674 9EB61FE0 8E3374F6"
		], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);
			var results = [];

			image.scroll(3, -2);
			results.push(checksum(image));
			image.scroll(-5, 4);
			results.push(checksum(image));
			image.scroll(0, 3);
			results.push(checksum(image));
			return results.join(" ");
		});
	}

	public function testFillRectKeepsItsOutput():Void
	{
		assertPins(["57E21118", "CD1CD1C5", "C98ED565", "07A0F33F", "DA09C8CD", "9B7AA34C"], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);

			image.fillRect(new Rectangle(4, 3, 9, 6), 0x80C04020, ARGB32);
			image.fillRect(new Rectangle(10, 8, 7, 5), 0x406080FF, RGBA32);
			// Every channel the same, as the whole-image shortcut looks for, but over part of the image
			image.fillRect(new Rectangle(1, 11, 12, 4), 0x99999999, BGRA32);
			image.fillRect(new Rectangle(15, 1, 6, 6), 0x00000000, ARGB32);
			return checksum(image);
		});
	}

	public function testColorTransformKeepsItsOutput():Void
	{
		// Multipliers that a Float32Array holds exactly, and offsets that come back from it as the same whole
		// numbers. Alpha is left alone in premultiplied images, where changing it loses color to rounding
		// that other tests show.
		assertPins(["53066D77", "250AC7B1", "72AFBA69", "4C2CBB5A", "F2FBF6BD", "87063606"], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);
			var matrix = new ColorMatrix();
			matrix.redMultiplier = 0.75;
			matrix.redOffset = 20;
			matrix.greenMultiplier = 1.25;
			matrix.blueMultiplier = 0.5;
			matrix.blueOffset = 64;

			if (!premultiplied)
			{
				matrix.alphaMultiplier = 0.875;
				matrix.alphaOffset = 16;
			}

			image.colorTransform(new Rectangle(3, 2, 15, 11), matrix);
			return checksum(image);
		});
	}

	public function testCopyChannelKeepsItsOutput():Void
	{
		assertPins(["9B7EBFC3", "87710C75", "F62109AE", "7DE2B01F", "CA92C4D9", "39B92792"], function(format, premultiplied)
		{
			var dest = destImage(format, premultiplied);
			var source = sourceImage(format, premultiplied);

			dest.copyChannel(source, new Rectangle(1, 2, 10, 8), new Vector2(3, 4), ImageChannel.RED, ImageChannel.GREEN);
			dest.copyChannel(source, new Rectangle(6, 0, 9, 11), new Vector2(12, 2), ImageChannel.ALPHA, ImageChannel.BLUE);
			dest.copyChannel(source, new Rectangle(2, 5, 12, 6), new Vector2(8, 10), ImageChannel.BLUE, ImageChannel.ALPHA);
			dest.copyChannel(source, new Rectangle(0, 1, 7, 7), new Vector2(1, 9), ImageChannel.GREEN, ImageChannel.RED);
			return checksum(dest);
		});
	}

	public function testMergeKeepsItsOutput():Void
	{
		assertPins(["BFE3C16D", "E76B5FEA", "D9F735D4", "DD271858", "EA479809", "0A950E34"], function(format, premultiplied)
		{
			var dest = destImage(format, premultiplied);
			var source = sourceImage(format, premultiplied);

			dest.merge(source, new Rectangle(2, 1, 13, 10), new Vector2(6, 5), 64, 128, 200, 100);
			dest.merge(source, new Rectangle(9, 4, 8, 8), new Vector2(1, 2), 256, 0, 32, 256);
			return checksum(dest);
		});
	}

	public function testThresholdKeepsItsOutputAndCounts():Void
	{
		// Each mask covers green alone, and each threshold has no bits outside its mask
		assertPins([
			"38C64C1A 49,39,72,0",
			"D8021B62 54,36,72,11",
			"96D8168C 49,39,72,0",
			"AF73E254 54,36,72,11",
			"A22D7AE7 49,39,72,0",
			"0DAD0ED7 54,36,72,11"
		], function(format, premultiplied)
		{
			var dest = destImage(format, premultiplied);
			var source = sourceImage(format, premultiplied);
			var hits = [];

			hits.push(dest.threshold(source, new Rectangle(1, 1, 12, 9), new Vector2(4, 3), "<", 0x00007000, 0xFF20C040, 0x0000FF00, false, ARGB32));
			hits.push(dest.threshold(source, new Rectangle(5, 2, 10, 10), new Vector2(11, 6), ">=", 0x00A00000, 0x8040A0C0, 0x00FF0000, true, RGBA32));
			hits.push(dest.threshold(source, new Rectangle(0, 4, 9, 8), new Vector2(2, 8), "!=", 0x00400000, 0x00000000, 0x00FF0000, true, BGRA32));
			hits.push(dest.threshold(source, new Rectangle(7, 0, 11, 13), new Vector2(0, 0), "==", 0x00000000, 0xFFFFFFFF, 0x0000FF00, false, ARGB32));
			return checksum(dest) + " " + hits.join(",");
		});
	}

	public function testSetPixelKeepsItsOutput():Void
	{
		assertPins(["5C6A25F4", "E516D4C5", "9344FC09", "AE97B76A", "3B5CD70F", "2179EF79"], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);
			var state = 0x51ED270B;

			for (i in 0...60)
			{
				state = xorshift(state);
				var x = ((state >>> 16) & 0xFFFF) % WIDTH;
				var y = (state & 0xFFFF) % HEIGHT;
				state = xorshift(state);
				image.setPixel(x, y, state, FORMATS[i % 3]);
			}

			return checksum(image);
		});
	}

	public function testSetPixel32KeepsItsOutput():Void
	{
		assertPins(["91430E6E", "CF097BA9", "DDEA54CE", "D8EE6490", "35C81434", "A144DD4C"], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);
			var state = 0x1B873593;

			for (i in 0...60)
			{
				state = xorshift(state);
				var x = ((state >>> 16) & 0xFFFF) % WIDTH;
				var y = (state & 0xFFFF) % HEIGHT;
				state = xorshift(state);
				image.setPixel32(x, y, state, FORMATS[i % 3]);
			}

			return checksum(image);
		});
	}

	public function testGetPixelAndGetPixel32KeepTheirValues():Void
	{
		assertPins(["65AC53AD", "5E2DF114", "65AC53AD", "5E2DF114", "65AC53AD", "5E2DF114"], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);
			var values = Bytes.alloc(WIDTH * HEIGHT * 8 * FORMATS.length);
			var position = 0;

			for (colorFormat in FORMATS)
			{
				for (y in 0...HEIGHT)
				{
					for (x in 0...WIDTH)
					{
						values.setInt32(position, image.getPixel32(x, y, colorFormat));
						values.setInt32(position + 4, image.getPixel(x, y, colorFormat));
						position += 8;
					}
				}
			}

			return crc(values);
		});
	}

	public function testGetPixelsKeepsItsOutput():Void
	{
		assertPins([
			"3CBBF522 BAA566F1 37B2F70B 513848F6 ABA9CB2C 50E52EEC",
			"98B275C5 11002894 4DEC2CB7 20B8A940 73ED414A 249612C3",
			"3CBBF522 BAA566F1 37B2F70B 513848F6 ABA9CB2C 50E52EEC",
			"98B275C5 11002894 4DEC2CB7 20B8A940 73ED414A 249612C3",
			"3CBBF522 BAA566F1 37B2F70B 513848F6 ABA9CB2C 50E52EEC",
			"98B275C5 11002894 4DEC2CB7 20B8A940 73ED414A 249612C3"
		], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);
			var results = [];

			for (colorFormat in FORMATS)
			{
				results.push(crc(image.getPixels(new Rectangle(3, 2, 14, 11), colorFormat)));
				results.push(crc(image.getPixels(new Rectangle(9, 6, 5, 9), colorFormat)));
			}

			return results.join(" ");
		});
	}

	public function testSetPixelsKeepsItsOutput():Void
	{
		assertPins(["2A8F8B09", "E5FB439A", "1D7DFD6D", "749FF510", "79C8539F", "B79559A9"], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);
			var bytes = Bytes.alloc(1024);
			var state = 0x7F4A7C15;

			for (i in 0...bytes.length >> 2)
			{
				state = xorshift(state);
				bytes.setInt32(i * 4, state);
			}

			var rects = [
				new Rectangle(2, 1, 10, 6),
				new Rectangle(13, 3, 8, 7),
				new Rectangle(1, 9, 9, 6),
				new Rectangle(11, 10, 7, 5),
				new Rectangle(5, 5, 6, 8),
				new Rectangle(16, 12, 5, 4)
			];

			for (i in 0...rects.length)
			{
				// Each starts partway into the bytes, which hold at least the 240 a rect needs after it
				image.setPixels(rects[i], new BytePointer(bytes, 4 + i * 124), FORMATS[i % 3], i < 3 ? BIG_ENDIAN : LITTLE_ENDIAN);
			}

			return checksum(image);
		});
	}

	public function testGetColorBoundsRectKeepsItsBounds():Void
	{
		// Pixels outside 4, 3 to 17, 12 are all zero, so the bounds stay inside the image
		assertPins([
			"4,3,14,10 12,4,3,8 4,3,10,6 7,10,1,1 7,3,9,8 7,5,6,6 0,0,0,0",
			"4,3,14,10 12,4,3,8 4,3,10,6 7,6,3,5 7,3,9,8 7,5,6,6 0,0,0,0",
			"4,3,14,10 12,4,3,8 4,3,10,6 7,10,1,1 7,3,9,8 7,5,6,6 0,0,0,0",
			"4,3,14,10 12,4,3,8 4,3,10,6 7,6,3,5 7,3,9,8 7,5,6,6 0,0,0,0",
			"4,3,14,10 12,4,3,8 4,3,10,6 7,10,1,1 7,3,9,8 7,5,6,6 0,0,0,0",
			"4,3,14,10 12,4,3,8 4,3,10,6 7,6,3,5 7,3,9,8 7,5,6,6 0,0,0,0"
		], function(format, premultiplied)
		{
			var image = randomImage(WIDTH, HEIGHT, DEST, format, premultiplied, new Rectangle(4, 3, 14, 10));
			// Rarer colors have bounds that are smaller, down to a single pixel, and none at all
			var bounds = [
				image.getColorBoundsRect(0x000000FF, 0x00000000, false, RGBA32),
				image.getColorBoundsRect(0xF8000000, 0x08000000, true, RGBA32),
				image.getColorBoundsRect(0x0000F800, 0x0000F800, true, ARGB32),
				image.getColorBoundsRect(0x0000FF00, 0x0000FF00, true, BGRA32),
				image.getColorBoundsRect(0xE0E00000, 0xE0E00000, true, RGBA32),
				image.getColorBoundsRect(0x00E000E0, 0x00E000E0, true, ARGB32),
				image.getColorBoundsRect(0xFFFFFFFF, 0x12345678, true, RGBA32)
			];

			return [for (rect in bounds) rect == null ? "null" : Std.int(rect.x) + "," + Std.int(rect.y) + "," + Std.int(rect.width) + "," + Std.int(rect.height)].join(" ");
		});
	}

	public function testCloneKeepsItsPixelsAndSettings():Void
	{
		assertPins(["2B22285C", "C03D8750", "2DA2675B", "4419C9E6", "7461E90E", "65F8DACB"], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);
			var copy = image.clone();
			var settings = (copy.buffer.format == format ? "" : " format changed") + (copy.buffer.premultiplied == premultiplied ? "" : " premultiplied changed");

			return checksum(copy) + settings;
		});
	}

	public function testTurningPremultipliedOnAndOffKeepsItsOutput():Void
	{
		assertPins([
			"FEAF4E13 B90AA519",
			"9178850D E42CD5AB",
			"3D9A22D7 E11C3362",
			"62AAE205 C131CDD5",
			"9946422C 8E6237C2",
			"FEFABDFA C0098738"
		], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);
			var results = [];

			image.premultiplied = !premultiplied;
			results.push(checksum(image));
			image.premultiplied = premultiplied;
			results.push(checksum(image));
			return results.join(" ");
		});
	}

	public function testOperationsOnAnImageWithinALargerBufferKeepTheirOutput():Void
	{
		// Each image here is part of a larger buffer, so the native prims get offsets to add
		assertPins([
			"DF000235 B723A8FF",
			"443C4C9B 8122CB36",
			"2B4FE98B B723A8FF",
			"984ED3C8 8122CB36",
			"CA7A56B4 B723A8FF",
			"EC0270F6 8122CB36"
		], function(format, premultiplied)
		{
			var whole = randomImage(31, 25, DEST, format, premultiplied);
			var part = new Image(whole.buffer, 5, 4, 19, 14, null, DATA);
			var sourceWhole = randomImage(20, 15, SOURCE, format, premultiplied);
			var source = new Image(sourceWhole.buffer, 3, 2, 12, 9, null, DATA);
			var before = whole.buffer.data.toBytes().sub(0, whole.buffer.data.byteLength);
			var matrix = new ColorMatrix();
			matrix.redMultiplier = 0.5;
			matrix.greenOffset = 32;

			part.fillRect(new Rectangle(2, 3, 8, 5), 0xC0336699, ARGB32);
			part.copyPixels(source, new Rectangle(1, 1, 9, 6), new Vector2(8, 6));
			part.colorTransform(new Rectangle(4, 5, 10, 6), matrix);
			part.copyPixels(source, new Rectangle(1, 1, 8, 6), new Vector2(10, 7), null, null, true);
			part.merge(source, new Rectangle(2, 2, 6, 5), new Vector2(1, 8), 128, 96, 160, 200);
			part.copyChannel(source, new Rectangle(0, 0, 7, 5), new Vector2(11, 1), ImageChannel.RED, ImageChannel.BLUE);
			part.setPixels(new Rectangle(12, 9, 5, 4), new BytePointer(before, 40), RGBA32, BIG_ENDIAN);
			var read = part.getPixels(new Rectangle(3, 3, 9, 7), ARGB32);

			// Everything outside the part is as it was
			var after = whole.buffer.data.toBytes();
			var outside = 0;
			for (y in 0...25)
			{
				for (x in 0...31)
				{
					if (x >= 5 && x < 24 && y >= 4 && y < 18) continue;
					if (after.getInt32((y * 31 + x) * 4) != before.getInt32((y * 31 + x) * 4)) outside++;
				}
			}

			return checksum(whole) + " " + crc(read) + (outside == 0 ? "" : " " + outside + " pixels outside changed");
		});
	}

	// Helpers

	private static function assertPins(expected:Array<String>, operation:PixelFormat->Bool->String, ?pos:haxe.PosInfos):Void
	{
		var i = 0;

		for (format in FORMATS)
		{
			for (premultiplied in [false, true])
			{
				var name = formatName(format) + (premultiplied ? " premultiplied" : "");
				var actual = operation(format, premultiplied);
				Assert.equals(expected[i], actual, name + " gave " + actual + ", pinned " + expected[i], pos);
				i++;
			}
		}
	}

	private static function destImage(format:PixelFormat, premultiplied:Bool):Image
	{
		return randomImage(WIDTH, HEIGHT, DEST, format, premultiplied);
	}

	private static function sourceImage(format:PixelFormat, premultiplied:Bool):Image
	{
		return randomImage(19, 13, SOURCE, format, premultiplied);
	}

	private static function alphaImage(format:PixelFormat, premultiplied:Bool):Image
	{
		return randomImage(17, 11, ALPHA, format, premultiplied);
	}

	/**
		An image of pseudo-random pixels, a quarter of them opaque and one in sixteen clear. Premultiplied
		images hold the same colors multiplied by alpha, so no channel is above its alpha. Outside `inside`,
		when it is given, every byte is zero.
	**/
	private static function randomImage(width:Int, height:Int, seed:Int, format:PixelFormat, premultiplied:Bool, ?inside:Rectangle):Image
	{
		var data = new UInt8Array(width * height * 4);
		var state = seed;

		for (y in 0...height)
		{
			for (x in 0...width)
			{
				state = xorshift(state);
				var r = (state >>> 24) & 0xFF;
				var g = (state >>> 16) & 0xFF;
				var b = (state >>> 8) & 0xFF;
				state = xorshift(state);
				var kind = (state >>> 28) & 0xF;
				var a = (kind < 4 ? 0xFF : (kind == 4 ? 0 : (state >>> 16) & 0xFF));

				if (inside != null && (x < inside.x || y < inside.y || x >= inside.right || y >= inside.bottom))
				{
					r = g = b = a = 0;
				}

				if (premultiplied)
				{
					r = premultiply(r, a);
					g = premultiply(g, a);
					b = premultiply(b, a);
				}

				var offset = (y * width + x) * 4;

				switch (format)
				{
					case BGRA32:
						data[offset] = b;
						data[offset + 1] = g;
						data[offset + 2] = r;
						data[offset + 3] = a;

					case ARGB32:
						data[offset] = a;
						data[offset + 1] = r;
						data[offset + 2] = g;
						data[offset + 3] = b;

					default:
						data[offset] = r;
						data[offset + 1] = g;
						data[offset + 2] = b;
						data[offset + 3] = a;
				}
			}
		}

		var buffer = new ImageBuffer(data, width, height, 32, format);
		buffer.premultiplied = premultiplied;
		buffer.transparent = true;
		return new Image(buffer, 0, 0, width, height, null, DATA);
	}

	private static inline function xorshift(state:Int):Int
	{
		state ^= state << 13;
		state ^= state >>> 17;
		state ^= state << 5;
		return state;
	}

	private static inline function premultiply(channel:Int, alpha:Int):Int
	{
		// Rounded, in whole numbers
		return Std.int((channel * alpha + 127) / 255);
	}

	private static function nextFormat(format:PixelFormat):PixelFormat
	{
		return FORMATS[(FORMATS.indexOf(format) + 1) % FORMATS.length];
	}

	private static function checksum(image:Image):String
	{
		var data = image.buffer.data;
		return crc(data.toBytes().sub(data.byteOffset, data.byteLength));
	}

	private static function crc(bytes:Bytes):String
	{
		return bytes == null ? "null" : StringTools.hex(Crc32.make(bytes), 8);
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
