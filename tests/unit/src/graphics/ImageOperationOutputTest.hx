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
		assertPins(["89AC17FD", "A2152FC5", "E8D2800C", "75BE82E4", "FEBFB3B3", "F3DD1909"], function(format, premultiplied)
		{
			var dest = destImage(format, premultiplied);
			var source = sourceImage(nextFormat(format), premultiplied);

			dest.copyPixels(source, new Rectangle(2, 3, 11, 7), new Vector2(5, 4));
			return checksum(dest);
		});
	}

	public function testCopyPixelsWithMergeAlphaKeepsItsOutput():Void
	{
		assertPins(["8F883026", "001B2E0C", "61E43874", "554447F9", "E3953711", "1515E2CD"], function(format, premultiplied)
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
		assertPins(["97127D99", "7D760413", "611B5D25", "9EE461E2", "023E91D4", "B3002250"], function(format, premultiplied)
		{
			var dest = destImage(format, premultiplied);

			dest.copyPixels(sourceImage(format, premultiplied), new Rectangle(0, 0, 12, 7), new Vector2(4, 5), alphaImage(format, premultiplied),
				new Vector2(3, 2), false);
			return checksum(dest);
		});
	}

	public function testCopyPixelsMergingThroughAnAlphaImageKeepsItsOutput():Void
	{
		assertPins(["7237A527", "C2DB7250", "B3AF00B5", "CC7DEA5D", "99C5BC60", "A58AE91A"], function(format, premultiplied)
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
		assertPins(["57E21118", "45220F55", "C98ED565", "809CDD95", "DA09C8CD", "ADFED594"], function(format, premultiplied)
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
		assertPins(["53066D77", "80309A3F", "72AFBA69", "4E49AC85", "F2FBF6BD", "B7EED321"], function(format, premultiplied)
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
		assertPins(["9B7EBFC3", "F8A86016", "F62109AE", "54B64620", "CA92C4D9", "0457B131"], function(format, premultiplied)
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
		assertPins(["BFE3C16D", "EF0283DF", "D9F735D4", "B2F19F61", "EA479809", "0E741679"], function(format, premultiplied)
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
			"79267036 54,36,72,11",
			"96D8168C 49,39,72,0",
			"96AF64B7 54,36,72,11",
			"A22D7AE7 49,39,72,0",
			"F8552476 54,36,72,11"
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
		assertPins(["5C6A25F4", "064ACA8C", "9344FC09", "E5A2F323", "3B5CD70F", "1E6CB4F1"], function(format, premultiplied)
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
		assertPins(["91430E6E", "C3B6B017", "DDEA54CE", "BBD03DFD", "35C81434", "A8945B87"], function(format, premultiplied)
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
		assertPins(["65AC53AD", "A386B46A", "65AC53AD", "A386B46A", "65AC53AD", "A386B46A"], function(format, premultiplied)
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
			"F70FF5C6 97D62EA7 DDAD09B2 3356FF03 7E1AA39C 2142F513",
			"3CBBF522 BAA566F1 37B2F70B 513848F6 ABA9CB2C 50E52EEC",
			"F70FF5C6 97D62EA7 DDAD09B2 3356FF03 7E1AA39C 2142F513",
			"3CBBF522 BAA566F1 37B2F70B 513848F6 ABA9CB2C 50E52EEC",
			"F70FF5C6 97D62EA7 DDAD09B2 3356FF03 7E1AA39C 2142F513"
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
		assertPins(["2A8F8B09", "CBE87CC0", "1D7DFD6D", "3D3EB89C", "79C8539F", "10A782D4"], function(format, premultiplied)
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
			"C03D8750 FB868291",
			"FB868291 C03D8750",
			"4419C9E6 4A27EA4F",
			"4A27EA4F 4419C9E6",
			"65F8DACB B0DDD3EB",
			"B0DDD3EB 65F8DACB"
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
			"FAC80438 DB583775",
			"2B4FE98B B723A8FF",
			"23FFC24B DB583775",
			"CA7A56B4 B723A8FF",
			"F43BF602 DB583775"
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

	public function testCopyPixelsBetweenStraightAndPremultipliedImagesKeepsItsOutput():Void
	{
		// The source has the other premultiplied setting from the destination, in the same format and the next
		assertPins([
			"2B3142A9 D88E1015 2B3142A9 D88E1015",
			"A2152FC5 DEE63B0B A2152FC5 DEE63B0B",
			"884424D0 62DA3A9F 884424D0 62DA3A9F",
			"75BE82E4 2F07D6AE 75BE82E4 2F07D6AE",
			"049B9590 9B93DDBF 049B9590 9B93DDBF",
			"F3DD1909 450DDCFA F3DD1909 450DDCFA"
		], function(format, premultiplied)
		{
			var results = [];

			for (sourceFormat in [format, nextFormat(format)])
			{
				for (mergeAlpha in [false, true])
				{
					var dest = destImage(format, premultiplied);
					dest.copyPixels(sourceImage(sourceFormat, !premultiplied), new Rectangle(2, 3, 11, 7), new Vector2(5, 4), null, null, mergeAlpha);
					results.push(checksum(dest));
				}
			}

			return results.join(" ");
		});
	}

	public function testCopyPixelsThroughTheHaxeLoopKeepsItsOutput():Void
	{
		// What HTML5 runs, and native targets without the native library
		assertPins([
			"89AC17FD 97591F27 E5D3DDF0 5FF3A9BF",
			"A2152FC5 970A2AF8 4901F08C D7F200CB",
			"E8D2800C 38D4BFE9 86E2DF48 F053D06B",
			"75BE82E4 9E86C2AF 0BD3007A D5DB1716",
			"FEBFB3B3 658921CA EDAB3194 1911E464",
			"F3DD1909 36BCFECA 837F0DBF 10E276BC"
		], function(format, premultiplied)
		{
			return withoutNative(function()
			{
				var results = [];
				var dest = destImage(format, premultiplied);
				var source = sourceImage(format, premultiplied);

				dest.copyPixels(source, new Rectangle(2, 3, 11, 7), new Vector2(5, 4));
				results.push(checksum(dest));
				dest.copyPixels(source, new Rectangle(6, 0, 12, 10), new Vector2(9, 5), null, null, true);
				results.push(checksum(dest));
				dest.copyPixels(sourceImage(nextFormat(format), !premultiplied), new Rectangle(1, 2, 13, 8), new Vector2(2, 6), null, null, true);
				results.push(checksum(dest));
				dest.copyPixels(source, new Rectangle(0, 0, 12, 7), new Vector2(4, 5), alphaImage(format, premultiplied), new Vector2(3, 2), true);
				results.push(checksum(dest));
				return results.join(" ");
			});
		});
	}

	public function testCopyPixelsWithinOneImageThroughTheHaxeLoopKeepsItsOutput():Void
	{
		assertPins([
			"33C6479E C9A32759 02834365",
			"874F3BBE 5E563BDE B1B6324A",
			"452550D3 67334680 28FCE47F",
			"B1797B16 AF5EDA16 63ACF4B6",
			"417F208D CE5DD449 C04729DA",
			"C3BD3771 E998DB42 934C2822"
		], function(format, premultiplied)
		{
			return withoutNative(function()
			{
				var image = destImage(format, premultiplied);
				var results = [];

				image.copyPixels(image, new Rectangle(3, 2, 12, 9), new Vector2(6, 5));
				results.push(checksum(image));
				image.copyPixels(image, new Rectangle(8, 7, 10, 8), new Vector2(4, 3), null, null, true);
				results.push(checksum(image));
				image.scroll(-3, 2);
				results.push(checksum(image));
				return results.join(" ");
			});
		});
	}

	public function testCopyPixelsWithinOneImageThroughAnAlphaImageKeepsItsOutput():Void
	{
		// The source is the destination, overlapping, so it has to be read before it is written
		assertPins(["25345246 6B0FB2ED", "AEEB14C3 3BF3D252", "F786649F 30A8C88F", "8A180ABD A601783A", "7D82708E 0C14FDF9", "1C7C1FD4 F5057E89"], function(format, premultiplied)
		{
			var image = destImage(format, premultiplied);
			var results = [];

			image.copyPixels(image, new Rectangle(2, 1, 12, 9), new Vector2(5, 4), alphaImage(format, premultiplied), new Vector2(0, 0), false);
			results.push(checksum(image));
			image.copyPixels(image, new Rectangle(7, 6, 11, 8), new Vector2(3, 2), alphaImage(format, premultiplied), new Vector2(0, 0), true);
			results.push(checksum(image));
			return results.join(" ");
		});
	}

	public function testChangingTheFormatKeepsItsOutput():Void
	{
		// To each other format and back
		assertPins([
			"2DA2675B 2B22285C 7461E90E 2B22285C",
			"4419C9E6 C03D8750 65F8DACB C03D8750",
			"2B22285C 2DA2675B 7461E90E 2DA2675B",
			"C03D8750 4419C9E6 65F8DACB 4419C9E6",
			"2B22285C 7461E90E 2DA2675B 7461E90E",
			"C03D8750 65F8DACB 4419C9E6 65F8DACB"
		], function(format, premultiplied)
		{
			var results = [];

			for (other in FORMATS)
			{
				if (other == format) continue;

				var image = destImage(format, premultiplied);
				image.format = other;
				results.push(checksum(image));
				image.format = format;
				results.push(checksum(image));
			}

			return results.join(" ");
		});
	}

	public function testConvertingToPremultipliedBGRAKeepsItsOutput():Void
	{
		// As OpenFL does with every image it loads on native targets: the format first, then alpha. The
		// opaque image is as a decoded JPEG is, every alpha 255 but marked transparent.
		assertPins(["4419C9E6 6B7B356A", "4419C9E6 6B7B356A", "4419C9E6 6B7B356A", "4419C9E6 6B7B356A", "4419C9E6 6B7B356A", "4419C9E6 6B7B356A"], function(format, premultiplied)
		{
			var image = destImage(format, false);
			var opaque = destImage(format, false);
			opaque.fillRect(new Rectangle(0, 0, WIDTH, HEIGHT), 0xFF336699, ARGB32);
			opaque.setPixel32(3, 4, 0xFF000000, ARGB32);
			opaque.setPixel32(5, 6, 0xFFFFFFFF, ARGB32);
			opaque.setPixel32(7, 8, 0xFF010203, ARGB32);

			for (each in [image, opaque])
			{
				if (premultiplied)
				{
					// The other order
					each.premultiplied = true;
					each.format = BGRA32;
				}
				else
				{
					each.format = BGRA32;
					each.premultiplied = true;
				}
			}

			return checksum(image) + " " + checksum(opaque);
		});
	}

	public function testPixelAccessOnAnImageWithinALargerBufferKeepsItsOutput():Void
	{
		// setPixel, getPixel and getColorBoundsRect add the image's offsets in Haxe
		assertPins([
			"B38986DA 11978A80 4,3,8,7 0,0,19,14",
			"FD62DC2A B9A72046 4,3,8,7 0,0,19,14",
			"F2C86F47 11978A80 4,3,8,7 0,0,19,14",
			"57436DDD B9A72046 4,3,8,7 0,0,19,14",
			"88B29506 11978A80 4,3,8,7 0,0,19,14",
			"676B31E4 B9A72046 4,3,8,7 0,0,19,14"
		], function(format, premultiplied)
		{
			var whole = randomImage(31, 25, DEST, format, premultiplied);
			var part = new Image(whole.buffer, 5, 4, 19, 14, null, DATA);
			var values = Bytes.alloc(19 * 14 * 8);
			var state = 0x51ED270B;

			for (i in 0...40)
			{
				state = xorshift(state);
				var x = ((state >>> 16) & 0xFFFF) % 19;
				var y = (state & 0xFFFF) % 14;
				state = xorshift(state);
				if (i % 2 == 0) part.setPixel(x, y, state, FORMATS[i % 3]);
				else part.setPixel32(x, y, state, FORMATS[i % 3]);
			}

			for (y in 0...14)
			{
				for (x in 0...19)
				{
					values.setInt32((y * 19 + x) * 8, part.getPixel32(x, y, ARGB32));
					values.setInt32((y * 19 + x) * 8 + 4, part.getPixel(x, y, BGRA32));
				}
			}

			// A color nothing else has, at two places, and everything that isn't it
			part.setPixel32(4, 3, 0xFF123456, ARGB32);
			part.setPixel32(11, 9, 0xFF123456, ARGB32);
			var bounds = part.getColorBoundsRect(0xFFFFFFFF, 0xFF123456, true, ARGB32);
			var rare = part.getColorBoundsRect(0xFFFFFFFF, 0xFF123456, false, ARGB32);

			return checksum(whole) + " " + crc(values) + " " + rectString(bounds) + " " + rectString(rare);
		});
	}

	public function testOperationsOnABufferThatStartsPartwayIntoItsBytesKeepTheirOutput():Void
	{
		// The buffer's data is a view that starts 64 bytes into a larger array
		assertPins(["ED901F7B 4A83BD38", "39AE37D4 56741E47", "238F5E9F 4A83BD38", "80A9B148 56741E47", "A64A1DBB 4A83BD38", "235250D8 56741E47"], function(format, premultiplied)
		{
			var plain = destImage(format, premultiplied);
			var bytes = Bytes.alloc(64 + WIDTH * HEIGHT * 4 + 64);
			bytes.fill(0, bytes.length, 0x5A);
			bytes.blit(64, plain.buffer.data.toBytes(), 0, WIDTH * HEIGHT * 4);

			var buffer = new ImageBuffer(new UInt8Array(bytes, 64, WIDTH * HEIGHT * 4), WIDTH, HEIGHT, 32, format);
			buffer.premultiplied = premultiplied;
			buffer.transparent = true;
			var image = new Image(buffer, 0, 0, WIDTH, HEIGHT, null, DATA);
			var source = sourceImage(format, premultiplied);
			var matrix = new ColorMatrix();
			matrix.blueMultiplier = 0.5;
			matrix.redOffset = 16;

			image.fillRect(new Rectangle(2, 3, 8, 5), 0xC0336699, ARGB32);
			image.copyPixels(source, new Rectangle(1, 1, 9, 6), new Vector2(8, 6));
			image.copyPixels(source, new Rectangle(2, 1, 8, 6), new Vector2(12, 9), null, null, true);
			image.colorTransform(new Rectangle(4, 5, 10, 6), matrix);
			image.merge(source, new Rectangle(2, 2, 6, 5), new Vector2(1, 8), 128, 96, 160, 200);
			image.copyChannel(source, new Rectangle(0, 0, 7, 5), new Vector2(11, 1), ImageChannel.RED, ImageChannel.BLUE);
			var read = image.getPixels(new Rectangle(3, 3, 9, 7), ARGB32);

			var guards = 0;
			for (i in 0...64)
			{
				if (bytes.get(i) != 0x5A) guards++;
				if (bytes.get(bytes.length - 1 - i) != 0x5A) guards++;
			}

			return checksum(image) + " " + crc(read) + (guards == 0 ? "" : " " + guards + " bytes outside the view changed");
		});
	}

	public function testCopyPixelsWithinAnImageWithinALargerBufferInEveryDirectionKeepsItsOutput():Void
	{
		// Overlapping copies each way within an image that is part of a larger buffer, through the native
		// copy and the Haxe loop. Each must move the bytes as they were before it, and leave the rest of
		// the buffer alone.
		assertPins(["1BF8B996 1BF8B996", "66850A27 66850A27", "E996D36D E996D36D", "B3F9EFDF B3F9EFDF", "6DE660C8 6DE660C8", "17CB6047 17CB6047"], function(format, premultiplied)
		{
			var native = copiesInEveryDirection(format, premultiplied);
			var haxe = withoutNative(function() return copiesInEveryDirection(format, premultiplied));
			return native + " " + haxe;
		});
	}

	public function testGetColorBoundsRectOnAnImageWithinALargerBufferKeepsItsBounds():Void
	{
		// The image is part of a larger buffer of the same noise, so pixels just outside it match too
		assertPins([
			"0,0,19,14 2,0,14,14 3,0,16,11 15,3,1,1 11,3,5,3 3,3,15,10",
			"0,0,19,14 2,0,14,14 5,0,14,11 4,0,15,10 11,3,6,3 15,3,3,10",
			"0,0,19,14 2,0,14,14 3,0,16,11 15,3,1,1 11,3,5,3 3,3,15,10",
			"0,0,19,14 2,0,14,14 5,0,14,11 4,0,15,10 11,3,6,3 15,3,3,10",
			"0,0,19,14 2,0,14,14 3,0,16,11 15,3,1,1 11,3,5,3 3,3,15,10",
			"0,0,19,14 2,0,14,14 5,0,14,11 4,0,15,10 11,3,6,3 15,3,3,10"
		], function(format, premultiplied)
		{
			var whole = randomImage(31, 25, DEST, format, premultiplied);
			var part = new Image(whole.buffer, 5, 4, 19, 14, null, DATA);
			var bounds = [
				part.getColorBoundsRect(0x000000FF, 0x00000000, false, RGBA32),
				part.getColorBoundsRect(0xF8000000, 0x08000000, true, RGBA32),
				part.getColorBoundsRect(0x0000F800, 0x0000F800, true, ARGB32),
				part.getColorBoundsRect(0x0000FF00, 0x0000FF00, true, BGRA32),
				part.getColorBoundsRect(0xE0E00000, 0xE0E00000, true, RGBA32),
				part.getColorBoundsRect(0x00E000E0, 0x00E000E0, true, ARGB32)
			];

			// A color only outside the image is not found in it, and one inside is found where it is
			var outside = [[0, 0], [30, 24], [4, 10], [24, 10], [12, 3], [12, 18]];
			for (point in outside)
			{
				whole.setPixel32(point[0], point[1], 0xFF123456, ARGB32);
			}
			var none = part.getColorBoundsRect(0xFFFFFFFF, 0xFF123456, true, ARGB32);
			part.setPixel32(3, 2, 0xFF123456, ARGB32);
			part.setPixel32(15, 11, 0xFF123456, ARGB32);
			var two = part.getColorBoundsRect(0xFFFFFFFF, 0xFF123456, true, ARGB32);

			var checks = (rectString(none) == "0,0,0,0" ? "" : " found outside " + rectString(none))
				+ (rectString(two) == "3,2,13,10" ? "" : " found inside " + rectString(two));
			return [for (rect in bounds) rectString(rect)].join(" ") + checks;
		});
	}

	public function testSmallOperationsKeepTheirOutput():Void
	{
		// The sizes whose cost is mostly getting the arguments to native code: 1x1 copies with mergeAlpha,
		// 16x11 copies with and without it, and 4x4 fills, at many places, each inside both images
		assertPins([
			"B30B61F0 D272D99F 8FC6EEE1 6D60B90B",
			"3E084523 32665A1F 08D6F939 6C9FC2C0",
			"2E45B17F 5F31581E 772BD94C ECC9D2EF",
			"FDD71171 500E87AB 23B95DB7 B70F1FD6",
			"E5092078 8CA88E62 B64ABDF8 7651B96A",
			"EE200667 4DC21068 AEFEB769 525B742B"
		], function(format, premultiplied)
		{
			var dest = destImage(format, premultiplied);
			var source = sourceImage(format, premultiplied);
			var state = 0x3243F6A8;
			var results = [];

			for (i in 0...40)
			{
				state = xorshift(state);
				var a = (state >>> 8) & 0xFF;
				var b = state & 0xFF;
				var c = (state >>> 16) & 0xFF;
				var d = (state >>> 24) & 0xFF;

				switch (i % 4)
				{
					case 0:
						dest.copyPixels(source, new Rectangle(c % 19, d % 13, 1, 1), new Vector2(a % WIDTH, b % HEIGHT), null, null, true);
					case 1:
						dest.fillRect(new Rectangle(a % (WIDTH - 4), b % (HEIGHT - 4), 4, 4), state, FORMATS[i % 3]);
					case 2:
						dest.copyPixels(source, new Rectangle(c % 3, d % 2, 16, 11), new Vector2(a % (WIDTH - 16), b % (HEIGHT - 11)));
					default:
						dest.copyPixels(source, new Rectangle(c % 3, d % 2, 16, 11), new Vector2(a % (WIDTH - 16), b % (HEIGHT - 11)), null, null, true);
				}

				if (i % 10 == 9) results.push(checksum(dest));
			}

			return results.join(" ");
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

	/**
		Copies within a 19x14 image at 5, 4 in a 31x25 buffer, overlapping, in each of eight directions,
		each checked against the bytes moved by hand. Gives a checksum of the buffer after each copy, with
		what went wrong when anything did.
	**/
	private static function copiesInEveryDirection(format:PixelFormat, premultiplied:Bool):String
	{
		var whole = randomImage(31, 25, SOURCE, format, premultiplied);
		var part = new Image(whole.buffer, 5, 4, 19, 14, null, DATA);
		var moves = [[3, 2], [-3, -2], [3, -2], [-3, 2], [4, 0], [-4, 0], [0, 3], [0, -3]];
		var states = Bytes.alloc(moves.length * 4);
		var problems = [];

		for (i in 0...moves.length)
		{
			var dx = moves[i][0];
			var dy = moves[i][1];
			var source = new Rectangle(4, 3, 11, 8);
			var before = whole.buffer.data.toBytes().sub(0, 31 * 25 * 4);
			var expected = before.sub(0, before.length);

			// Every source pixel is read before any is written
			for (y in 0...8)
			{
				for (x in 0...11)
				{
					var from = ((4 + y + 3) * 31 + (5 + x + 4)) * 4;
					var to = ((4 + y + 3 + dy) * 31 + (5 + x + 4 + dx)) * 4;
					expected.blit(to, before, from, 4);
				}
			}

			part.copyPixels(part, source, new Vector2(source.x + dx, source.y + dy));

			var after = whole.buffer.data.toBytes().sub(0, 31 * 25 * 4);
			if (after.compare(expected) != 0) problems.push("moving by " + dx + "," + dy + " gave other bytes");
			states.setInt32(i * 4, Crc32.make(after));
		}

		return crc(states) + (problems.length == 0 ? "" : " (" + problems.join(", ") + ")");
	}

	/** Runs `operation` through the Haxe code, with the native library turned off **/
	private static function withoutNative(operation:Void->String):String
	{
		var enabled = lime.system.CFFI.enabled;
		lime.system.CFFI.enabled = false;
		var result = try operation() catch (e:Dynamic) "threw " + e;
		lime.system.CFFI.enabled = enabled;
		return result;
	}

	private static function rectString(rect:Rectangle):String
	{
		return rect == null ? "null" : Std.int(rect.x) + "," + Std.int(rect.y) + "," + Std.int(rect.width) + "," + Std.int(rect.height);
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
