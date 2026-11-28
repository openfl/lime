package graphics;

import graphics.ImageFixture.*;
import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.PixelFormat;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.system.Endian;
import lime.utils.BytePointer;
import lime.utils.UInt8Array;
import utest.Assert;
import utest.Test;

/**
	Reading and writing single pixels and blocks of pixels, in each
	`PixelFormat`, with and without premultiplied alpha.

	Expectations follow Flash's `BitmapData`, which OpenFL builds on these
	methods: colors go in and come out unmultiplied, however the buffer holds
	them. Where the buffer is premultiplied a channel may be off by one, as
	multiplying by alpha and dividing again cannot always round back exactly.
**/
class ImagePixelTest extends Test
{
	private static var FORMATS:Array<PixelFormat> = [RGBA32, ARGB32, BGRA32];

	// ARGB colors with every kind of alpha, and channels that differ from each other
	private static var VARIED_ROWS:Array<Array<Int>> = [
		[0x11223344, 0x80FF8040, 0x00000000, 0xFF000000],
		[0x01FFFFFF, 0xFE123456, 0xC0A0B0C0, 0x40804020],
		[0xFFFFFFFF, 0x7F7F7F7F, 0x2050A0F0, 0xE0010203]
	];

	public function new()
	{
		super();
	}

	public function testANewImageIsFilledWithItsColorAsRGBA():Void
	{
		var image = new Image(null, 0, 0, 3, 2, 0x11223344, DATA);

		Assert.equals(3, image.width);
		Assert.equals(2, image.height);
		Assert.equals(3 * 2 * 4, image.buffer.data.length);
		assertPixels([for (i in 0...6) 0x44112233], image);
	}

	public function testANewImageWithoutAColorIsTransparentBlack():Void
	{
		var image = new Image(null, 0, 0, 2, 2, null, DATA);

		Assert.isTrue(image.transparent);
		assertPixels([0, 0, 0, 0], image);
	}

	public function testANewImageOverABufferTakesTheBufferSize():Void
	{
		var buffer = new ImageBuffer(new UInt8Array(5 * 3 * 4), 5, 3);
		var image = new Image(buffer, 0, 0, -1, -1, null, DATA);

		Assert.equals(5, image.width);
		Assert.equals(3, image.height);
	}

	public function testGetPixel32ReturnsWhatSetPixel32SetInEachFormat():Void
	{
		for (format in FORMATS)
		{
			var image = create(2, 1);
			image.setPixel32(1, 0, toFormat(0x80402010, format), format);

			assertPixel(0x80402010, image, 1, 0, formatName(format));
			assertColor(toFormat(0x80402010, format), image.getPixel32(1, 0, format), 0, formatName(format));
			assertPixel(0, image, 0, 0, formatName(format));
		}
	}

	public function testPixelColorsDefaultToRGBA():Void
	{
		var image = create(1, 1);
		image.setPixel32(0, 0, 0x11223344);

		assertPixel(0x44112233, image, 0, 0);
		assertColor(0x11223344, image.getPixel32(0, 0));
	}

	public function testGetPixel32ConvertsBetweenColorFormats():Void
	{
		var image = create(1, 1);
		image.setPixel32(0, 0, 0x11223344, RGBA32);

		assertColor(0x44112233, image.getPixel32(0, 0, ARGB32), 0, "ARGB32");
		assertColor(0x33221144, image.getPixel32(0, 0, BGRA32), 0, "BGRA32");
	}

	public function testSetPixel32StoresThePixelInTheBufferFormat():Void
	{
		// In the order of FORMATS
		var expected = [[0x22, 0x33, 0x44, 0x11], [0x11, 0x22, 0x33, 0x44], [0x44, 0x33, 0x22, 0x11]];

		for (i in 0...FORMATS.length)
		{
			var image = create(1, 1, 0, FORMATS[i]);
			image.setPixel32(0, 0, 0x11223344, ARGB32);

			assertBytes(expected[i], bytesAt(image, 0, 0), formatName(FORMATS[i]));
		}
	}

	public function testGetPixel32ReadsEachBufferFormat():Void
	{
		for (format in FORMATS)
		{
			var image = create(1, 1, 0x11223344, format);

			assertColor(0x11223344, image.getPixel32(0, 0, ARGB32), 0, formatName(format));
			assertColor(0x22334411, image.getPixel32(0, 0, RGBA32), 0, formatName(format));
		}
	}

	public function testSetPixelKeepsTheAlphaOfThePixel():Void
	{
		// Flash: "The current alpha channel value of the image pixel is preserved"
		for (format in FORMATS)
		{
			var image = create(1, 1, 0x80FFFFFF);
			image.setPixel(0, 0, toFormat(0x00112233, format), format);

			assertPixel(0x80112233, image, 0, 0, formatName(format));
		}
	}

	public function testSetPixelIgnoresTheAlphaOfTheColor():Void
	{
		var image = create(1, 1, 0x80FFFFFF);
		image.setPixel(0, 0, 0xFF112233, ARGB32);

		assertPixel(0x80112233, image, 0, 0);
	}

	public function testGetPixelLeavesOutAlpha():Void
	{
		var image = create(1, 1, 0x80112233);

		assertColor(0x00112233, image.getPixel(0, 0, ARGB32), 0, "ARGB32");
		assertColor(0x11223300, image.getPixel(0, 0, RGBA32), 0, "RGBA32");
		assertColor(0x33221100, image.getPixel(0, 0, BGRA32), 0, "BGRA32");
	}

	public function testReadingOutsideTheImageReturnsZero():Void
	{
		var image = create(2, 2, 0xFF112233);

		for (point in [[-1, 0], [0, -1], [2, 0], [0, 2], [2, 1]])
		{
			var label = point[0] + "," + point[1];
			Assert.equals(0, image.getPixel(point[0], point[1], ARGB32), label);
			Assert.equals(0, image.getPixel32(point[0], point[1], ARGB32), label);
		}
	}

	public function testWritingOutsideTheImageChangesNothing():Void
	{
		var image = create(2, 2, 0xFF112233);

		for (point in [[-1, 0], [0, -1], [2, 0], [0, 2], [2, 1], [-1, 1]])
		{
			image.setPixel32(point[0], point[1], 0xFFFF0000, ARGB32);
			image.setPixel(point[0], point[1], 0x00FF0000, ARGB32);
		}

		assertPixels([for (i in 0...4) 0xFF112233], image);
	}

	public function testAPremultipliedImageStoresPremultipliedColors():Void
	{
		var image = create(1, 1, 0, null, true);
		image.setPixel32(0, 0, 0x80FF8000, ARGB32);

		// 0xFF * 0x80 / 0xFF and 0x80 * 0x80 / 0xFF
		assertColor(0x80804000, peek(image, 0, 0), 1);
	}

	public function testGetPixel32UnmultipliesAPremultipliedImage():Void
	{
		for (format in FORMATS)
		{
			var image = create(1, 1, 0x80FF8040, format, true);

			assertColor(0x80FF8040, image.getPixel32(0, 0, ARGB32), 1, formatName(format));
		}
	}

	public function testGetPixelUnmultipliesAPremultipliedImage():Void
	{
		var image = create(1, 1, 0x80FF8040, null, true);

		assertColor(0x00FF8040, image.getPixel(0, 0, ARGB32), 1);
	}

	public function testSetPixelOnAPremultipliedImageKeepsItsAlpha():Void
	{
		var image = create(1, 1, 0x80FFFFFF, null, true);
		image.setPixel(0, 0, 0x00FF0000, ARGB32);

		assertPixel(0x80FF0000, image, 0, 0, 1);
		assertColor(0x80800000, peek(image, 0, 0), 1, "stored");
	}

	public function testTurningPremultipliedOnMultipliesTheData():Void
	{
		var image = create(2, 1, 0xFF336699);
		poke(image, 1, 0, 0x80FF8040);

		image.premultiplied = true;

		Assert.isTrue(image.premultiplied);
		Assert.isTrue(image.buffer.premultiplied);
		assertColor(0xFF336699, peek(image, 0, 0), 0, "opaque pixel stored");
		assertColor(0x80804020, peek(image, 1, 0), 1, "translucent pixel stored");
		assertColor(0x80FF8040, image.getPixel32(1, 0, ARGB32), 1, "read back");
	}

	public function testTurningPremultipliedOffUnmultipliesTheData():Void
	{
		var image = create(2, 1, 0xFF336699, null, true);
		poke(image, 1, 0, 0x80FF8040);

		image.premultiplied = false;

		Assert.isFalse(image.premultiplied);
		Assert.isFalse(image.buffer.premultiplied);
		assertColor(0xFF336699, peek(image, 0, 0), 0, "opaque pixel stored");
		assertColor(0x80FF8040, peek(image, 1, 0), 1, "translucent pixel stored");
		assertColor(0x80FF8040, image.getPixel32(1, 0, ARGB32), 1, "read back");
	}

	public function testSettingPremultipliedToItsValueLeavesTheDataAlone():Void
	{
		var plain = create(1, 1, 0x80FF8040);
		plain.premultiplied = false;
		assertColor(0x80FF8040, peek(plain, 0, 0), 0, "not premultiplied");

		var premultiplied = create(1, 1, 0x80FF8040, null, true);
		var stored = peek(premultiplied, 0, 0);
		premultiplied.premultiplied = true;
		assertColor(stored, peek(premultiplied, 0, 0), 0, "premultiplied");
	}

	public function testChangingTheFormatReordersTheData():Void
	{
		var image = create(2, 1, 0x11223344);

		image.format = BGRA32;
		Assert.equals(BGRA32, image.format);
		Assert.equals(BGRA32, image.buffer.format);
		assertBytes([0x44, 0x33, 0x22, 0x11], bytesAt(image, 1, 0), "BGRA32");
		assertColor(0x11223344, image.getPixel32(1, 0, ARGB32), 0, "BGRA32 read back");

		image.format = ARGB32;
		Assert.equals(ARGB32, image.buffer.format);
		assertBytes([0x11, 0x22, 0x33, 0x44], bytesAt(image, 1, 0), "ARGB32");

		image.format = RGBA32;
		Assert.equals(RGBA32, image.buffer.format);
		assertBytes([0x22, 0x33, 0x44, 0x11], bytesAt(image, 1, 0), "RGBA32");
	}

	public function testChangingTheFormatOfAPremultipliedImageOnlyReordersTheData():Void
	{
		var image = create(1, 1, 0x80FF8040, null, true);
		var stored = peek(image, 0, 0);

		image.format = ARGB32;

		Assert.isTrue(image.premultiplied);
		assertColor(stored, peek(image, 0, 0), 0, "stored");
		assertColor(0x80FF8040, image.getPixel32(0, 0, ARGB32), 1, "read back");
	}

	public function testAnOpaqueImageIgnoresAlphaInSetPixel32():Void
	{
		// Flash: "If the BitmapData object is opaque (not transparent), the alpha portion of this color value is ignored"
		var image = create(1, 1, 0xFF000000, null, false, false);
		image.setPixel32(0, 0, 0x80FF0000, ARGB32);

		Assert.isFalse(image.transparent);
		assertPixel(0xFFFF0000, image, 0, 0);
		assertColor(0xFFFF0000, image.getPixel32(0, 0, ARGB32));
	}

	public function testAnOpaqueImageIgnoresAlphaInFillRect():Void
	{
		var image = create(2, 2, 0xFF000000, null, false, false);
		image.fillRect(new Rectangle(0, 0, 2, 2), 0x00FF0000, ARGB32);

		assertPixels([for (i in 0...4) 0xFFFF0000], image);
	}

	public function testCloneCopiesThePixelsAndSettings():Void
	{
		var image = create(3, 2, 0x80FF8040, BGRA32, true, true);
		poke(image, 2, 1, 0xFF112233);

		var clone = image.clone();

		Assert.equals(3, clone.width);
		Assert.equals(2, clone.height);
		Assert.equals(BGRA32, clone.format);
		Assert.isTrue(clone.premultiplied);
		Assert.isTrue(clone.transparent);
		for (y in 0...2)
		{
			for (x in 0...3)
			{
				assertColor(peek(image, x, y), peek(clone, x, y), 0, "pixel " + x + "," + y);
			}
		}

		var opaque = create(1, 1, 0xFF000000, ARGB32, false, false).clone();
		Assert.isFalse(opaque.transparent);
		Assert.isFalse(opaque.premultiplied);
		Assert.equals(ARGB32, opaque.format);
	}

	#if flash
	#end
	public function testACloneHasItsOwnPixels():Void
	{
		var image = create(2, 1, 0xFF112233);
		var clone = image.clone();

		poke(clone, 0, 0, 0xFFFF0000);
		poke(image, 1, 0, 0xFF00FF00);

		assertPixels([0xFF112233, 0xFF00FF00], image, 0, "original");
		assertPixels([0xFFFF0000, 0xFF112233], clone, 0, "clone");
	}

	#if neko
	#end
	public function testGetPixelsWritesEachFormatInItsByteOrder():Void
	{
		var image = fromRows([[0x11223344, 0x55667788]]);
		var rect = new Rectangle(0, 0, 2, 1);

		assertBytes([0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88], bytesOf(image.getPixels(rect, ARGB32)), "ARGB32");
		assertBytes([0x22, 0x33, 0x44, 0x11, 0x66, 0x77, 0x88, 0x55], bytesOf(image.getPixels(rect, RGBA32)), "RGBA32");
		assertBytes([0x44, 0x33, 0x22, 0x11, 0x88, 0x77, 0x66, 0x55], bytesOf(image.getPixels(rect, BGRA32)), "BGRA32");
		assertBytes([0x22, 0x33, 0x44, 0x11, 0x66, 0x77, 0x88, 0x55], bytesOf(image.getPixels(rect)), "default");
	}

	public function testGetPixelsReadsEachBufferFormat():Void
	{
		for (format in FORMATS)
		{
			var image = fromRows([[0x11223344, 0x55667788]], format);

			assertBytes([0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88], bytesOf(image.getPixels(new Rectangle(0, 0, 2, 1), ARGB32)), formatName(format));
		}
	}

	public function testGetPixelsUnmultipliesAPremultipliedImage():Void
	{
		var image = create(1, 1, 0x80FF8040, null, true);
		var bytes = bytesOf(image.getPixels(new Rectangle(0, 0, 1, 1), ARGB32));

		assertColor(0x80FF8040, argb(bytes[0], bytes[1], bytes[2], bytes[3]), 1);
	}

	public function testGetPixelsReadsTheRectRowByRow():Void
	{
		var image = numbered(3, 3);
		var bytes = bytesOf(image.getPixels(new Rectangle(1, 0, 2, 3), ARGB32));

		assertBytes(argbBytes([number(1, 0), number(2, 0), number(1, 1), number(2, 1), number(1, 2), number(2, 2)]), bytes);
	}

	public function testGetPixelsReadsOnlyThePartOfTheRectInsideTheImage():Void
	{
		// Flash returns the pixels of the rect's intersection with the bitmap
		var image = numbered(3, 3);

		assertBytes(argbBytes([number(1, 1), number(2, 1), number(1, 2), number(2, 2)]), bytesOf(image.getPixels(new Rectangle(1, 1, 5, 5), ARGB32)),
			"past the right and bottom");
		assertBytes(argbBytes([number(0, 0), number(1, 0)]), bytesOf(image.getPixels(new Rectangle(-1, -1, 3, 2), ARGB32)), "before the left and top");
	}

	public function testSetPixelsReadsEachFormatInItsByteOrder():Void
	{
		// In the order of FORMATS
		var bytes = [[0x22, 0x33, 0x44, 0x11], [0x11, 0x22, 0x33, 0x44], [0x44, 0x33, 0x22, 0x11]];

		for (i in 0...FORMATS.length)
		{
			var image = create(1, 1);
			image.setPixels(new Rectangle(0, 0, 1, 1), pointer(bytes[i]), FORMATS[i], BIG_ENDIAN);

			assertPixel(0x11223344, image, 0, 0, formatName(FORMATS[i]));
		}
	}

	#if neko
	#end
	public function testSetPixelsTakesRGBAByDefault():Void
	{
		var image = create(1, 1);
		image.setPixels(new Rectangle(0, 0, 1, 1), pointer([0x22, 0x33, 0x44, 0x11]), null, BIG_ENDIAN);

		assertPixel(0x11223344, image, 0, 0);
	}

	public function testSetPixelsReadsLittleEndianValues():Void
	{
		// OpenFL passes its ByteArray's endian; an ARGB value written little endian is stored B, G, R, A
		var image = create(1, 1);
		image.setPixels(new Rectangle(0, 0, 1, 1), pointer([0x44, 0x33, 0x22, 0x11]), ARGB32, LITTLE_ENDIAN);

		assertPixel(0x11223344, image, 0, 0);
	}

	public function testSetPixelsWritesEachBufferFormat():Void
	{
		for (format in FORMATS)
		{
			var image = create(1, 1, 0, format);
			image.setPixels(new Rectangle(0, 0, 1, 1), pointer([0x11, 0x22, 0x33, 0x44]), ARGB32, BIG_ENDIAN);

			assertPixel(0x11223344, image, 0, 0, formatName(format));
		}
	}

	public function testSetPixelsPremultipliesForAPremultipliedImage():Void
	{
		var image = create(1, 1, 0, null, true);
		image.setPixels(new Rectangle(0, 0, 1, 1), pointer([0x80, 0xFF, 0x80, 0x40]), ARGB32, BIG_ENDIAN);

		assertColor(0x80804020, peek(image, 0, 0), 1, "stored");
		assertPixel(0x80FF8040, image, 0, 0, 1);
	}

	public function testSetPixelsFillsTheRectRowByRow():Void
	{
		var image = create(3, 3);
		image.setPixels(new Rectangle(1, 1, 2, 2), pointer(argbBytes([0xFF000001, 0xFF000002, 0xFF000003, 0xFF000004])), ARGB32, BIG_ENDIAN);

		assertPixels([0, 0, 0, 0, 0xFF000001, 0xFF000002, 0, 0xFF000003, 0xFF000004], image);
	}

	public function testSetPixelsStartsAtThePointerOffset():Void
	{
		var image = create(1, 1);
		image.setPixels(new Rectangle(0, 0, 1, 1), new BytePointer(Bytes.ofHex("aabbccdd11223344"), 4), ARGB32, BIG_ENDIAN);

		assertPixel(0x11223344, image, 0, 0);
	}

	public function testSetPixelsStopsAtTheBottomOfTheImage():Void
	{
		var image = create(2, 2);
		image.setPixels(new Rectangle(0, 1, 2, 2), pointer(argbBytes([0xFF000001, 0xFF000002, 0xFF000003, 0xFF000004])), ARGB32, BIG_ENDIAN);

		assertPixels([0, 0, 0xFF000001, 0xFF000002], image);
	}

	public function testGetPixelsThenSetPixelsCopiesARegion():Void
	{
		for (format in FORMATS)
		{
			var source = numbered(3, 3);
			var dest = create(3, 3);
			dest.setPixels(new Rectangle(0, 0, 2, 2), new BytePointer(source.getPixels(new Rectangle(1, 1, 2, 2), format)), format, BIG_ENDIAN);

			assertPixels([number(1, 1), number(2, 1), 0, number(1, 2), number(2, 2), 0, 0, 0, 0], dest, 0, formatName(format));
		}
	}

	// getPixels() takes an endian as setPixels() does, BIG_ENDIAN unless given (#1071)

	public function testGetPixelsWritesEachFormatBigEndian():Void
	{
		var image = fromRows([[0x11223344, 0x55667788]]);
		var rect = new Rectangle(0, 0, 2, 1);

		assertBytes([0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88], bytesOf(image.getPixels(rect, ARGB32, BIG_ENDIAN)), "ARGB32");
		assertBytes([0x22, 0x33, 0x44, 0x11, 0x66, 0x77, 0x88, 0x55], bytesOf(image.getPixels(rect, RGBA32, BIG_ENDIAN)), "RGBA32");
		assertBytes([0x44, 0x33, 0x22, 0x11, 0x88, 0x77, 0x66, 0x55], bytesOf(image.getPixels(rect, BGRA32, BIG_ENDIAN)), "BGRA32");
	}

	public function testGetPixelsWritesEachFormatLittleEndian():Void
	{
		// A 32-bit value written little endian starts with its least significant byte, as a ByteArray
		// with Endian.LITTLE_ENDIAN writes it and as setPixels() reads it with LITTLE_ENDIAN
		var image = fromRows([[0x11223344, 0x55667788]]);
		var rect = new Rectangle(0, 0, 2, 1);

		assertBytes([0x44, 0x33, 0x22, 0x11, 0x88, 0x77, 0x66, 0x55], bytesOf(image.getPixels(rect, ARGB32, LITTLE_ENDIAN)), "ARGB32");
		assertBytes([0x11, 0x44, 0x33, 0x22, 0x55, 0x88, 0x77, 0x66], bytesOf(image.getPixels(rect, RGBA32, LITTLE_ENDIAN)), "RGBA32");
		assertBytes([0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88], bytesOf(image.getPixels(rect, BGRA32, LITTLE_ENDIAN)), "BGRA32");
		assertBytes([0x11, 0x44, 0x33, 0x22, 0x55, 0x88, 0x77, 0x66], bytesOf(image.getPixels(rect, null, LITTLE_ENDIAN)), "the default format");
	}

	public function testGetPixelsIsBigEndianUnlessToldOtherwise():Void
	{
		var image = fromRows(VARIED_ROWS);
		var rect = new Rectangle(0, 0, image.width, image.height);

		for (format in FORMATS)
		{
			var big = bytesOf(image.getPixels(rect, format, BIG_ENDIAN));
			assertBytes(big, bytesOf(image.getPixels(rect, format)), formatName(format) + " without an endian");
			assertBytes(big, bytesOf(image.getPixels(rect, format, null)), formatName(format) + " with a null endian");
		}
	}

	public function testLittleEndianPixelsAreTheBigEndianOnesReversed():Void
	{
		for (bufferFormat in FORMATS)
		{
			for (premultiplied in [false, true])
			{
				var image = fromRows(VARIED_ROWS, bufferFormat, premultiplied);

				// The whole image, and a rect that starts and ends inside its rows
				for (rect in [new Rectangle(0, 0, image.width, image.height), new Rectangle(1, 1, 2, 2)])
				{
					for (format in FORMATS)
					{
						var label = formatName(format) + " of a " + rect.width + "x" + rect.height + " rect of " + (premultiplied ? "premultiplied " : "")
							+ formatName(bufferFormat);
						var big = bytesOf(image.getPixels(rect, format, BIG_ENDIAN));
						var little = bytesOf(image.getPixels(rect, format, LITTLE_ENDIAN));

						if (big == null || little == null)
						{
							Assert.fail(label + ": getPixels() gave null");
							continue;
						}

						assertBytes(reversedPixels(big), little, label);
					}
				}
			}
		}
	}

	public function testGetPixelsThenSetPixelsWithTheSameEndianLeavesTheImageUnchanged():Void
	{
		// Written into a new image of the same kind, which then holds what the first one does. Where the
		// buffer is premultiplied, unmultiplying and multiplying again may leave a channel off by one.
		for (bufferFormat in FORMATS)
		{
			for (premultiplied in [false, true])
			{
				var image = fromRows(VARIED_ROWS, bufferFormat, premultiplied);
				var rect = new Rectangle(0, 0, image.width, image.height);

				for (format in FORMATS)
				{
					for (endian in [BIG_ENDIAN, LITTLE_ENDIAN])
					{
						var label = formatName(format) + " " + (endian == BIG_ENDIAN ? "big" : "little") + " endian through "
							+ (premultiplied ? "premultiplied " : "") + formatName(bufferFormat);
						var bytes = image.getPixels(rect, format, endian);

						if (bytes == null)
						{
							Assert.fail(label + ": getPixels() gave null");
							continue;
						}

						var copy = create(image.width, image.height, 0, bufferFormat, premultiplied);
						copy.setPixels(rect, new BytePointer(bytes, 0), format, endian);

						assertSameBuffer(image, copy, premultiplied ? 1 : 0, label);
					}
				}
			}
		}
	}

	#if (js && html5)
	public function testACanvasImageGivesLittleEndianPixelsToo():Void
	{
		// Opaque, as a canvas keeps colors premultiplied and could not give a translucent one back exactly
		var image = fromRows([[0xFF223344, 0xFF667788]]);
		lime._internal.graphics.ImageCanvasUtil.convertToCanvas(image);
		Assert.equals(lime.graphics.ImageType.CANVAS, image.type);

		var rect = new Rectangle(0, 0, 2, 1);
		assertBytes([0x44, 0x33, 0x22, 0xFF, 0x88, 0x77, 0x66, 0xFF], bytesOf(image.getPixels(rect, ARGB32, LITTLE_ENDIAN)), "ARGB32");
		assertBytes([0xFF, 0x22, 0x33, 0x44, 0xFF, 0x66, 0x77, 0x88], bytesOf(image.getPixels(rect, ARGB32, BIG_ENDIAN)), "ARGB32 big endian");
	}
	#end

	public function testAnImageWithAnOffsetReadsItsOwnPartOfTheBuffer():Void
	{
		var whole = numbered(4, 4);
		var part = new Image(whole.buffer, 1, 2, 2, 2, null, DATA);

		assertColor(number(1, 2), part.getPixel32(0, 0, ARGB32), 0, "0,0");
		assertColor(number(2, 3), part.getPixel32(1, 1, ARGB32), 0, "1,1");
		Assert.equals(0, part.getPixel32(2, 0, ARGB32), "past its own width");
	}

	public function testAnImageWithAnOffsetWritesOnlyItsOwnPartOfTheBuffer():Void
	{
		var whole = create(4, 4);
		var part = new Image(whole.buffer, 1, 1, 2, 2, null, DATA);

		part.fillRect(new Rectangle(0, 0, 10, 10), 0xFFFF0000, ARGB32);
		part.setPixel32(2, 0, 0xFF00FF00, ARGB32);

		assertPixels([
			0,          0,          0,          0,
			0, 0xFFFF0000, 0xFFFF0000,          0,
			0, 0xFFFF0000, 0xFFFF0000,          0,
			0,          0,          0,          0
		], whole);
	}

	public function testPixelOperationsMakeTheImageDirtyAndNewer():Void
	{
		var operations = new Map<String, Image->Void>();
		operations.set("setPixel", function(image) image.setPixel(0, 0, 0xFF0000, ARGB32));
		operations.set("setPixel32", function(image) image.setPixel32(0, 0, 0xFFFF0000, ARGB32));
		operations.set("setPixels", function(image) image.setPixels(new Rectangle(0, 0, 1, 1), pointer([0xFF, 0xFF, 0, 0]), ARGB32, BIG_ENDIAN));
		operations.set("fillRect", function(image) image.fillRect(new Rectangle(0, 0, 1, 1), 0xFFFF0000, ARGB32));
		operations.set("floodFill", function(image) image.floodFill(0, 0, 0xFFFF0000, ARGB32));
		operations.set("copyPixels", function(image) image.copyPixels(create(1, 1, 0xFFFF0000), new Rectangle(0, 0, 1, 1), new Vector2(0, 0)));
		operations.set("copyChannel", function(image) image.copyChannel(create(1, 1, 0xFFFF0000), new Rectangle(0, 0, 1, 1), new Vector2(0, 0), RED, BLUE));
		operations.set("colorTransform", function(image) image.colorTransform(new Rectangle(0, 0, 1, 1), offsetMatrix()));
		operations.set("merge", function(image) image.merge(create(1, 1, 0xFFFF0000), new Rectangle(0, 0, 1, 1), new Vector2(0, 0), 128, 128, 128, 128));
		operations.set("threshold", function(image)
		{
			image.threshold(image, new Rectangle(0, 0, 1, 1), new Vector2(0, 0), "==", 0x80112233, 0xFFFF0000, 0xFFFFFFFF, false, ARGB32);
		});
		operations.set("scroll", function(image) image.scroll(1, 0));
		operations.set("resize", function(image) image.resize(3, 3));
		operations.set("format", function(image)
		{
			image.format = BGRA32;
		});
		operations.set("premultiplied", function(image)
		{
			image.premultiplied = true;
		});

		for (name in operations.keys())
		{
			var image = fromRows([[0x80112233, 0xFF445566], [0xFF778899, 0xFFAABBCC]]);
			image.dirty = false;
			var version = image.version;

			operations.get(name)(image);

			Assert.isTrue(image.dirty, name + " makes the image dirty");
			Assert.isTrue(image.version > version, name + " moves the version on from " + version + " (now " + image.version + ")");
		}
	}

	public function testReadingPixelsLeavesTheImageAlone():Void
	{
		var operations = new Map<String, Image->Void>();
		operations.set("getPixel", function(image)
		{
			image.getPixel(0, 0);
		});
		operations.set("getPixel32", function(image)
		{
			image.getPixel32(0, 0);
		});
		operations.set("getPixels", function(image)
		{
			image.getPixels(new Rectangle(0, 0, 2, 2));
		});
		operations.set("getColorBoundsRect", function(image)
		{
			image.getColorBoundsRect(0xFFFFFFFF, 0x112233FF);
		});
		operations.set("clone", function(image)
		{
			image.clone();
		});

		for (name in operations.keys())
		{
			var image = fromRows([[0x80112233, 0xFF445566], [0xFF778899, 0xFFAABBCC]], null, true);
			var stored = [for (y in 0...2) for (x in 0...2) peek(image, x, y)];
			image.dirty = false;
			var version = image.version;

			operations.get(name)(image);

			Assert.isFalse(image.dirty, name + " leaves the image clean");
			Assert.equals(version, image.version, name + " leaves the version");
			Assert.equals(stored.join(","), [for (y in 0...2) for (x in 0...2) peek(image, x, y)].join(","), name + " leaves the data");
		}
	}

	public function testOperationsLeaveTheRectAndPointTheyAreGivenAlone():Void
	{
		// As in Flash, a caller may use one rectangle or point for many calls
		var operations = new Map<String, Rectangle->Vector2->Void>();
		operations.set("copyPixels", function(rect, point) create(3, 3).copyPixels(numbered(3, 3), rect, point));
		operations.set("copyChannel", function(rect, point) create(3, 3).copyChannel(numbered(3, 3), rect, point, RED, BLUE));
		operations.set("merge", function(rect, point) create(3, 3).merge(numbered(3, 3), rect, point, 128, 128, 128, 128));
		operations.set("threshold", function(rect, point)
		{
			create(3, 3).threshold(numbered(3, 3), rect, point, "!=", 0, 0xFFFF0000, 0xFFFFFFFF, false, ARGB32);
		});
		operations.set("fillRect", function(rect, point) create(3, 3).fillRect(rect, 0xFFFF0000, ARGB32));
		operations.set("colorTransform", function(rect, point) create(3, 3).colorTransform(rect, offsetMatrix()));
		operations.set("setPixels", function(rect, point) create(3, 3).setPixels(rect, pointer([for (i in 0...100) 0xFF]), ARGB32, BIG_ENDIAN));
		operations.set("getPixels", function(rect, point)
		{
			numbered(3, 3).getPixels(rect, ARGB32);
		});

		for (name in operations.keys())
		{
			var rect = new Rectangle(-1, -1, 5, 5);
			var point = new Vector2(-1, -1);

			operations.get(name)(rect, point);

			Assert.equals("-1,-1 5x5", rect.x + "," + rect.y + " " + rect.width + "x" + rect.height, name + " rect");
			Assert.equals("-1,-1", point.x + "," + point.y, name + " point");
		}
	}

	private static function offsetMatrix():ColorMatrix
	{
		var matrix = new ColorMatrix();
		matrix.redOffset = 16;
		return matrix;
	}

	private static function pointer(bytes:Array<Int>):BytePointer
	{
		var data = Bytes.alloc(bytes.length);
		for (i in 0...bytes.length)
		{
			data.set(i, bytes[i]);
		}
		return new BytePointer(data, 0);
	}

	private static function argbBytes(colors:Array<Int>):Array<Int>
	{
		var bytes = [];
		for (color in colors)
		{
			bytes.push((color >>> 24) & 0xFF);
			bytes.push((color >>> 16) & 0xFF);
			bytes.push((color >>> 8) & 0xFF);
			bytes.push(color & 0xFF);
		}
		return bytes;
	}

	private static function bytesOf(bytes:Bytes):Array<Int>
	{
		if (bytes == null) return null;
		return [for (i in 0...bytes.length) bytes.get(i)];
	}

	/** The bytes of each 32-bit pixel in the opposite order **/
	private static function reversedPixels(bytes:Array<Int>):Array<Int>
	{
		var result = [];
		var i = 0;

		while (i + 3 < bytes.length)
		{
			result.push(bytes[i + 3]);
			result.push(bytes[i + 2]);
			result.push(bytes[i + 1]);
			result.push(bytes[i]);
			i += 4;
		}

		return result;
	}

	/** Compares what two images of the same size and kind hold, as stored, each channel within `tolerance` **/
	private static function assertSameBuffer(expected:Image, actual:Image, tolerance:Int, label:String, ?pos:haxe.PosInfos):Void
	{
		var differences = [];

		for (y in 0...expected.height)
		{
			for (x in 0...expected.width)
			{
				if (!sameColor(peek(expected, x, y), peek(actual, x, y), tolerance))
				{
					differences.push(x + "," + y + " was " + hex(peek(expected, x, y)) + " and is " + hex(peek(actual, x, y)));
				}
			}
		}

		Assert.isTrue(differences.length == 0, label + ": " + differences.join("; "), pos);
	}
}
