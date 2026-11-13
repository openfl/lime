package graphics;

#if (lime_cffi && !macro)
import graphics.PNGFile;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import lime._internal.format.BMP as BMPFormat;
import lime._internal.format.BMP.BMPType;
import lime._internal.format.JPEG as JPEGFormat;
import lime._internal.format.PNG as PNGFormat;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.ImageFileFormat;
import lime.graphics.PixelFormat;
import lime.utils.UInt8Array;
#end
import utest.Assert;
import utest.Test;

#if (lime_cffi && !macro)
typedef BMPImage =
{
	var width:Int;
	var height:Int;
	var topDown:Bool;
	var bitCount:Int;
	var compression:Int;
	var headerSize:Int;
	var alphaMask:Int;
	var stride:Int;
	var pixelOffset:Int;
	/** Where the pixel array ends, which is where an icon's AND mask starts **/
	var pixelEnd:Int;
	/** 0xRRGGBBAA, top row first **/
	var pixels:Array<Int>;
	var problems:Array<String>;
}
#end

/**
	Image decoding and encoding through `Image.fromBytes()`, `Image.fromBase64()`, `Image.loadFromBytes()`
	and `Image.encode()`, with their expectations taken from the PNG specification (W3C, Third Edition),
	JPEG (ITU T.81) and Microsoft's BMP and ICO documentation rather than from Lime's codecs.
	Pixels are compared as 0xRRGGBBAA, row by row.
**/
class ImageCodecTest extends Test
{
	#if (lime_cffi && !macro)
	private static var ALPHAS = [0, 1, 127, 128, 254, 255, 64, 200];
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	// PNG decoding, from files built by hand

	public function testTruecolourAlphaPNGDecodesToItsPixels():Void
	{
		var rows = [
			[255, 0, 0, 255, 0, 255, 0, 128, 0, 0, 255, 0],
			[10, 20, 30, 40, 250, 240, 230, 1, 255, 255, 255, 255]
		];

		// PNG alpha is not premultiplied (PNG §12.4), so a pixel with no alpha keeps its colour
		assertPixels(["FF0000FF 00FF0080 0000FF00", "0A141E28 FAF0E601 FFFFFFFF"], Image.fromBytes(PNGFile.create(3, 2, PNGFile.TRUECOLOUR_ALPHA, 8, rows)));
	}

	public function testTruecolourPNGDecodesOpaque():Void
	{
		var rows = [[255, 0, 0, 0, 255, 0, 0, 0, 255], [1, 2, 3, 128, 64, 32, 0, 0, 0]];

		assertPixels(["FF0000FF 00FF00FF 0000FFFF", "010203FF 804020FF 000000FF"], Image.fromBytes(PNGFile.create(3, 2, PNGFile.TRUECOLOUR, 8, rows)));
	}

	public function testGreyscalePNGDecodesToGrey():Void
	{
		assertPixels(["000000FF 7F7F7FFF FFFFFFFF"], Image.fromBytes(PNGFile.create(3, 1, PNGFile.GREYSCALE, 8, [[0, 127, 255]])));
	}

	public function testLowBitDepthGreyscaleIsScaledToEightBits():Void
	{
		// Samples scale to the full range, so the largest is white (PNG §13.12); widths leave part of a byte unused
		assertPixels(["FFFFFFFF 000000FF FFFFFFFF FFFFFFFF 000000FF", "000000FF FFFFFFFF 000000FF 000000FF FFFFFFFF"],
			Image.fromBytes(PNGFile.create(5, 2, PNGFile.GREYSCALE, 1, [[1, 0, 1, 1, 0], [0, 1, 0, 0, 1]])), "1-bit");
		assertPixels(["000000FF 555555FF AAAAAAFF", "FFFFFFFF AAAAAAFF 555555FF"],
			Image.fromBytes(PNGFile.create(3, 2, PNGFile.GREYSCALE, 2, [[0, 1, 2], [3, 2, 1]])), "2-bit");
		assertPixels(["000000FF 777777FF FFFFFFFF"], Image.fromBytes(PNGFile.create(3, 1, PNGFile.GREYSCALE, 4, [[0, 7, 15]])), "4-bit");
	}

	public function testGreyscaleAlphaPNGDecodes():Void
	{
		assertPixels(["10101000 808080FF EEEEEE7F"], Image.fromBytes(PNGFile.create(3, 1, PNGFile.GREYSCALE_ALPHA, 8, [[0x10, 0, 0x80, 255, 0xEE, 0x7F]])));
	}

	public function testIndexedPNGTakesAlphaFromItsTransparencyChunk():Void
	{
		// Entries past the end of tRNS are opaque (PNG §11.3.2.1)
		var chunks = [
			PNGFile.palette([0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00]),
			PNGFile.transparency([0x00, 0x80], false)
		];

		assertPixels(["FF000000 00FF0080 0000FFFF", "FFFF00FF FF000000 00FF0080"],
			Image.fromBytes(PNGFile.create(3, 2, PNGFile.INDEXED_COLOUR, 8, [[0, 1, 2], [3, 0, 1]], chunks)));
	}

	public function testIndexedPNGWithoutTransparencyIsOpaque():Void
	{
		var chunks = [PNGFile.palette([0x102030, 0xA0B0C0])];

		assertPixels(["A0B0C0FF 102030FF"], Image.fromBytes(PNGFile.create(2, 1, PNGFile.INDEXED_COLOUR, 8, [[1, 0]], chunks)));
	}

	public function testLowBitDepthIndexedPNGsDecode():Void
	{
		// Indices are not scaled, whatever their depth
		var colours = [0x000000, 0xFF0000, 0x00FF00, 0x0000FF, 0x111111, 0x222222, 0x333333, 0x444444, 0x555555, 0x666666, 0x777777, 0x888888,
			0x999999, 0xAAAAAA, 0xBBBBBB, 0xCCCCCC];

		assertPixels(["FF0000FF 000000FF FF0000FF"],
			Image.fromBytes(PNGFile.create(3, 1, PNGFile.INDEXED_COLOUR, 1, [[1, 0, 1]], [PNGFile.palette(colours.slice(0, 2))])), "1-bit");
		assertPixels(["0000FFFF 00FF00FF FF0000FF 000000FF 0000FFFF"],
			Image.fromBytes(PNGFile.create(5, 1, PNGFile.INDEXED_COLOUR, 2, [[3, 2, 1, 0, 3]], [PNGFile.palette(colours.slice(0, 4))])), "2-bit");
		assertPixels(["CCCCCCFF 111111FF 777777FF", "000000FF FF0000FF BBBBBBFF"],
			Image.fromBytes(PNGFile.create(3, 2, PNGFile.INDEXED_COLOUR, 4, [[15, 4, 10], [0, 1, 14]], [PNGFile.palette(colours)])), "4-bit");
	}

	public function testGreyscaleTransparencyChunkMakesItsGreyTransparent():Void
	{
		// The tRNS grey is given at the image's own sample depth (PNG §11.3.2.1)
		assertPixels(["80808000 404040FF"],
			Image.fromBytes(PNGFile.create(2, 1, PNGFile.GREYSCALE, 8, [[0x80, 0x40]], [PNGFile.transparency([0x80], true)])), "8-bit");
		assertPixels(["55555500 666666FF"],
			Image.fromBytes(PNGFile.create(2, 1, PNGFile.GREYSCALE, 4, [[5, 6]], [PNGFile.transparency([5], true)])), "4-bit");
	}

	public function testTruecolourTransparencyChunkMakesItsColourTransparent():Void
	{
		assertPixels(["10203000 102031FF"],
			Image.fromBytes(PNGFile.create(2, 1, PNGFile.TRUECOLOUR, 8, [[0x10, 0x20, 0x30, 0x10, 0x20, 0x31]],
				[PNGFile.transparency([0x10, 0x20, 0x30], true)])));
	}

	public function testSixteenBitPNGsDecodeToEightBits():Void
	{
		// Each 0xXYXY sample is 0xXY whether a decoder rounds 65535 to 255 or keeps the high byte (PNG §13.12)
		assertPixels(["12345678 FF0000FF"],
			Image.fromBytes(PNGFile.create(2, 1, PNGFile.TRUECOLOUR_ALPHA, 16, [[0x1212, 0x3434, 0x5656, 0x7878, 0xFFFF, 0, 0, 0xFFFF]])), "RGBA");
		assertPixels(["ABCDEFFF"], Image.fromBytes(PNGFile.create(1, 1, PNGFile.TRUECOLOUR, 16, [[0xABAB, 0xCDCD, 0xEFEF]])), "RGB");
		assertPixels(["ABABABFF 000000FF"], Image.fromBytes(PNGFile.create(2, 1, PNGFile.GREYSCALE, 16, [[0xABAB, 0]])), "grey");
		assertPixels(["CDCDCD01"], Image.fromBytes(PNGFile.create(1, 1, PNGFile.GREYSCALE_ALPHA, 16, [[0xCDCD, 0x0101]])), "grey and alpha");
	}

	public function testEveryScanlineFilterIsUndone():Void
	{
		// Filter types 0 to 4 are None, Sub, Up, Average and Paeth (PNG §9.2)
		var pixels = pattern(4, 5);
		assertPixels(describeRows(4, pixels),
			Image.fromBytes(PNGFile.create(4, 5, PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(4, pixels), null, false, [0, 1, 2, 3, 4])), "RGBA");

		var rgb = [for (y in 0...5) [for (i in 0...9) (y * 71 + i * 29 + (i * y) % 7) & 0xFF]];
		var expected = [];
		for (y in 0...5)
		{
			expected.push([for (x in 0...3) hex(rgba(rgb[y][x * 3], rgb[y][x * 3 + 1], rgb[y][x * 3 + 2], 255))].join(" "));
		}
		assertPixels(expected, Image.fromBytes(PNGFile.create(3, 5, PNGFile.TRUECOLOUR, 8, rgb, null, false, [4, 3, 2, 1, 0])), "RGB");

		// Below 8 bits, filters work on whole bytes with the byte to the left
		var grey = [for (y in 0...5) [for (x in 0...7) (x + y) % 4]];
		expected = [for (y in 0...5) [for (x in 0...7) hex(rgba(grey[y][x] * 85, grey[y][x] * 85, grey[y][x] * 85, 255))].join(" ")];
		assertPixels(expected, Image.fromBytes(PNGFile.create(7, 5, PNGFile.GREYSCALE, 2, grey, null, false, [1, 2, 3, 4, 0])), "2-bit grey");
	}

	public function testInterlacedPNGsDecodeEveryPass():Void
	{
		// Adam7 sends the pixels in seven passes (PNG §8.2), each pass filtered on its own
		var pixels = pattern(9, 7);
		assertPixels(describeRows(9, pixels),
			Image.fromBytes(PNGFile.create(9, 7, PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(9, pixels), null, true, [0, 1, 2, 3, 4])), "RGBA");

		var indices = [for (y in 0...9) [for (x in 0...11) (x * 3 + y) % 4]];
		var colours = [0xFF0000, 0x00FF00, 0x0000FF, 0xFFFFFF];
		var expected = [for (y in 0...9) [for (x in 0...11) hex((colours[indices[y][x]] << 8) | 0xFF)].join(" ")];
		assertPixels(expected,
			Image.fromBytes(PNGFile.create(11, 9, PNGFile.INDEXED_COLOUR, 2, indices, [PNGFile.palette(colours)], true, [4, 1])), "2-bit indexed");

		var wide = [for (y in 0...6) [for (i in 0...15) (((i % 3) * 80 + Std.int(i / 3) * 40 + y * 30) & 0xFF) * 257]];
		expected = [for (y in 0...6) [for (x in 0...5) hex(rgba(wide[y][x * 3] >> 8, wide[y][x * 3 + 1] >> 8, wide[y][x * 3 + 2] >> 8, 255))].join(" ")];
		assertPixels(expected, Image.fromBytes(PNGFile.create(5, 6, PNGFile.TRUECOLOUR, 16, wide, null, true, [2])), "16-bit RGB");
	}

	public function testInterlacedPNGsSmallerThanAPassDecode():Void
	{
		// Images narrower or shorter than a pass leave that pass empty, with no scanlines at all
		for (size in [[1, 1], [2, 1], [1, 5], [3, 3], [5, 2], [4, 4]])
		{
			var pixels = pattern(size[0], size[1]);
			assertPixels(describeRows(size[0], pixels),
				Image.fromBytes(PNGFile.create(size[0], size[1], PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(size[0], pixels), null, true)),
				size[0] + "x" + size[1]);
		}
	}

	public function testOneByOnePNGsDecode():Void
	{
		assertPixels(["11223344"], Image.fromBytes(PNGFile.create(1, 1, PNGFile.TRUECOLOUR_ALPHA, 8, [[0x11, 0x22, 0x33, 0x44]])), "RGBA");
		assertPixels(["112233FF"], Image.fromBytes(PNGFile.create(1, 1, PNGFile.TRUECOLOUR, 8, [[0x11, 0x22, 0x33]])), "RGB");
		assertPixels(["999999FF"], Image.fromBytes(PNGFile.create(1, 1, PNGFile.GREYSCALE, 8, [[0x99]])), "grey");
		assertPixels(["99999955"], Image.fromBytes(PNGFile.create(1, 1, PNGFile.GREYSCALE_ALPHA, 8, [[0x99, 0x55]])), "grey and alpha");
		assertPixels(["123456FF"], Image.fromBytes(PNGFile.create(1, 1, PNGFile.INDEXED_COLOUR, 8, [[0]], [PNGFile.palette([0x123456])])), "indexed");
		assertPixels(["FFFFFFFF"], Image.fromBytes(PNGFile.create(1, 1, PNGFile.GREYSCALE, 1, [[1]])), "1-bit");
	}

	public function testOddSizedPNGsDecode():Void
	{
		for (size in [[7, 3], [1, 9], [13, 1], [31, 17]])
		{
			var pixels = pattern(size[0], size[1]);
			assertPixels(describeRows(size[0], pixels),
				Image.fromBytes(PNGFile.create(size[0], size[1], PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(size[0], pixels), null, false, [4])),
				size[0] + "x" + size[1]);
		}
	}

	public function testLargePNGsDecode():Void
	{
		// 240,200 bytes of image data, so the zlib stream holds several blocks
		var pixels = pattern(300, 200);
		var image = Image.fromBytes(PNGFile.create(300, 200, PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(300, pixels), null, false, [1, 4]));

		Assert.notNull(image);
		if (image == null) return;
		Assert.equals("300x200", image.width + "x" + image.height);
		Assert.equals("", firstPixelDifference(300, pixels, image));
	}

	public function testImageDataSplitOverManyIDATChunksDecodes():Void
	{
		// The zlib stream may be split over IDAT chunks anywhere (PNG §11.2.4)
		var pixels = pattern(6, 4);
		assertPixels(describeRows(6, pixels),
			Image.fromBytes(PNGFile.create(6, 4, PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(6, pixels), null, false, null, 1)), "1-byte IDATs");
		assertPixels(describeRows(6, pixels),
			Image.fromBytes(PNGFile.create(6, 4, PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(6, pixels), null, false, null, 7)), "7-byte IDATs");
	}

	public function testUnknownAncillaryChunksAreIgnored():Void
	{
		// A chunk whose type starts in lower case is ancillary, and a decoder that doesn't know it skips it (PNG §5.4)
		// tEXt is a keyword, a null separator and the text (PNG §11.3.3.2)
		var text = Bytes.ofString("Comment made by hand");
		text.set(7, 0);
		var chunks = [{type: "tEXt", data: text}, {type: "prVt", data: Bytes.ofString("private data")}];

		assertPixels(["01020304 05060708"], Image.fromBytes(PNGFile.create(2, 1, PNGFile.TRUECOLOUR_ALPHA, 8, [[1, 2, 3, 4, 5, 6, 7, 8]], chunks)));
	}

	public function testPNGBase64DecodesThroughFromBase64():Void
	{
		var png = PNGFile.create(2, 1, PNGFile.TRUECOLOUR_ALPHA, 8, [[0xFF, 0, 0, 0x80, 0, 0, 0xFF, 0]]);

		assertPixels(["FF000080 0000FF00"], Image.fromBase64(Base64.encode(png), "image/png"));
	}

	public function testPNGBytesLoadThroughAFuture():Void
	{
		var png = PNGFile.create(2, 1, PNGFile.TRUECOLOUR_ALPHA, 8, [[0xFF, 0, 0, 0x80, 0, 0, 0xFF, 0]]);

		assertPixels(["FF000080 0000FF00"], Image.loadFromBytes(png).result(5000), "loadFromBytes");
		assertPixels(["FF000080 0000FF00"], Image.loadFromBase64(Base64.encode(png), "image/png").result(5000), "loadFromBase64");
	}

	public function testPNGDecodeBytesGivesTheSamePixels():Void
	{
		var pixels = pattern(5, 3);
		var png = PNGFile.create(5, 3, PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(5, pixels));

		assertPixels(describeRows(5, pixels), PNGFormat.decodeBytes(png), "decoding the data");

		// Without its data, the image still knows its size
		var header = PNGFormat.decodeBytes(png, false);
		Assert.notNull(header);
		if (header != null) Assert.equals("5x3", header.width + "x" + header.height);
	}

	// PNG encoding

	public function testPNGEncodingIsAValidPNG():Void
	{
		var image = imageOf(5, pattern(5, 3));

		// PNG is the default format (Image.encode's documentation)
		for (encoded in [image.encode(), image.encode(ImageFileFormat.PNG)])
		{
			var png = PNGFile.read(encoded);
			Assert.equals("", png.problems.join("; "));
			Assert.equals("5x3", png.width + "x" + png.height);
			Assert.equals("IHDR", png.chunkTypes[0]);
			Assert.equals("IEND", png.chunkTypes[png.chunkTypes.length - 1]);
		}
	}

	public function testPNGEncodingKeepsEveryRGBAValue():Void
	{
		// Including the colour of pixels with no alpha, and every level of partial alpha
		var pixels = [for (a in 0...256) rgba((a * 7) & 0xFF, 255 - a, (a * 13 + 5) & 0xFF, a)];
		pixels = pixels.concat([0xFF000000, 0x00FF0000, 0x0000FF00, 0xFFFFFF00, 0x12345601, 0xFEDCBAFE]);
		var width = 13;
		while (pixels.length % width != 0)
		{
			pixels.push(0x80808080);
		}

		var encoded = imageOf(width, pixels).encode(ImageFileFormat.PNG);
		var png = PNGFile.read(encoded);
		Assert.equals("", png.problems.join("; "));
		Assert.equals("", firstDifference(width, pixels, png.pixels), "as read by the specification");
		Assert.equals("", firstPixelDifference(width, pixels, Image.fromBytes(encoded)), "as decoded by Image.fromBytes()");
	}

	public function testPNGEncodingKeepsOddSizes():Void
	{
		for (size in [[1, 1], [1, 7], [7, 1], [13, 5], [33, 3]])
		{
			var pixels = pattern(size[0], size[1]);
			var encoded = imageOf(size[0], pixels).encode(ImageFileFormat.PNG);
			var png = PNGFile.read(encoded);
			var name = size[0] + "x" + size[1];

			Assert.equals("", png.problems.join("; "), name);
			Assert.equals(name, png.width + "x" + png.height);
			Assert.equals("", firstDifference(size[0], pixels, png.pixels), name);
		}
	}

	public function testPremultipliedImagesEncodeTheirUnmultipliedColour():Void
	{
		// PNG stores colour without alpha multiplied in (PNG §12.4)
		var straight = [0xC86432FF, 0xC8643280, 0x0A5AF0C0, 0xFFFFFFFF, 0x80402080, 0x000000FF];
		var image = imageOf(3, straight, RGBA32, true);
		var png = PNGFile.read(image.encode(ImageFileFormat.PNG));

		Assert.equals("", png.problems.join("; "));
		if (png.problems.length > 0) return;

		for (i in 0...straight.length)
		{
			// Multiplying by alpha 128 and back can be off by one or two
			Assert.isTrue(closeTo(straight[i], png.pixels[i], 2, 0), "pixel " + i + " encoded as " + hex(png.pixels[i]) + ", not " + hex(straight[i]));
		}

		var transparent = imageOf(1, [0xFF000000, 0x00000000], RGBA32, true);
		png = PNGFile.read(transparent.encode(ImageFileFormat.PNG));
		Assert.equals("", png.problems.join("; "));
		if (png.problems.length == 0) Assert.equals(0, png.pixels[0] & 0xFF, "a pixel with no alpha encoded alpha " + (png.pixels[0] & 0xFF));
	}

	public function testBGRAAndARGBImagesEncodeTheirColours():Void
	{
		var pixels = pattern(4, 3);

		for (format in [BGRA32, ARGB32])
		{
			var png = PNGFile.read(imageOf(4, pixels, format).encode(ImageFileFormat.PNG));
			var name = (format == BGRA32 ? "BGRA32" : "ARGB32");

			Assert.equals("", png.problems.join("; "), name);
			Assert.equals("", firstDifference(4, pixels, png.pixels), name);
		}
	}

	@Ignored("Waiting on #2181")
	public function testAnImageWithinALargerBufferEncodesOnlyItself():Void
	{
		// An Image can be a region of its buffer (Image.offsetX, Image.width), and encoding it encodes that region
		var pixels = pattern(4, 3);
		var image = new Image(imageOf(4, pixels).buffer, 1, 1, 2, 2);
		var expected = [pixels[5], pixels[6], pixels[9], pixels[10]];

		var png = PNGFile.read(image.encode(ImageFileFormat.PNG));
		Assert.equals("", png.problems.join("; "));
		Assert.equals("2x2", png.width + "x" + png.height);
		Assert.equals("", firstDifference(2, expected, png.pixels));
	}

	public function testEncodingLeavesTheImageUnchanged():Void
	{
		for (format in [ImageFileFormat.PNG, ImageFileFormat.JPEG, ImageFileFormat.BMP])
		{
			for (pixelFormat in [RGBA32, BGRA32])
			{
				for (premultiplied in [false, true])
				{
					var image = imageOf(5, pattern(5, 4), pixelFormat, premultiplied);
					var before = Bytes.alloc(image.buffer.data.length);
					before.blit(0, image.buffer.data.toBytes(), 0, before.length);
					var name = format + " of " + (pixelFormat == RGBA32 ? "RGBA32" : "BGRA32") + (premultiplied ? ", premultiplied" : "");

					Assert.notNull(image.encode(format, 90), name);
					Assert.equals(pixelFormat, image.buffer.format, name + ": format changed");
					Assert.equals(premultiplied, image.buffer.premultiplied, name + ": premultiplied changed");
					Assert.equals(0, before.compare(image.buffer.data.toBytes().sub(0, before.length)), name + ": pixels changed");
				}
			}
		}
	}

	public function testEmptyImagesDoNotEncodeToInvalidFiles():Void
	{
		// A PNG can't be 0 pixels wide (PNG §11.2.2), so encode() returns null, as its documentation says it can
		var image = new Image(new ImageBuffer(new UInt8Array(0), 0, 0, 32, RGBA32));

		Assert.isNull(encodeQuietly(image, ImageFileFormat.PNG), "PNG");
		Assert.isNull(encodeQuietly(image, ImageFileFormat.JPEG), "JPEG");
	}

	// JPEG

	public function testJPEGEncodingStartsAndEndsWithItsMarkers():Void
	{
		// Start of image FFD8 and end of image FFD9 (ITU T.81 §B.2.1)
		var jpeg = imageOf(8, opaque(pattern(8, 8))).encode(ImageFileFormat.JPEG, 90);

		Assert.notNull(jpeg);
		if (jpeg == null) return;
		Assert.equals("FFD8", hex(jpeg.get(0), 2) + hex(jpeg.get(1), 2));
		Assert.equals("FFD9", hex(jpeg.get(jpeg.length - 2), 2) + hex(jpeg.get(jpeg.length - 1), 2));
	}

	public function testJPEGRoundTripKeepsSizeAndApproximateColour():Void
	{
		// Four flat 16x16 quadrants, each a whole macroblock even with chroma subsampled
		var colours = [0xC82828FF, 0x28C828FF, 0x2828C8FF, 0x808080FF];
		var pixels = [for (y in 0...32) for (x in 0...32) colours[(y < 16 ? 0 : 2) + (x < 16 ? 0 : 1)]];
		var image = Image.fromBytes(imageOf(32, pixels).encode(ImageFileFormat.JPEG, 90));

		Assert.notNull(image);
		if (image == null) return;
		Assert.equals("32x32", image.width + "x" + image.height);

		for (i in 0...4)
		{
			var x = (i % 2) * 16 + 8;
			var y = Std.int(i / 2) * 16 + 8;
			var pixel = image.getPixel32(x, y, RGBA32);
			Assert.isTrue(closeTo(colours[i], pixel, 8, 0), "quadrant " + i + " decoded as " + hex(pixel) + ", not about " + hex(colours[i]));
		}
	}

	public function testJPEGRoundTripKeepsOddSizes():Void
	{
		for (size in [[1, 1], [13, 7], [7, 13], [17, 1]])
		{
			var pixels = [for (i in 0...size[0] * size[1]) 0x3C78B4FF];
			var image = Image.fromBytes(imageOf(size[0], pixels).encode(ImageFileFormat.JPEG, 90));
			var name = size[0] + "x" + size[1];

			Assert.notNull(image, name);
			if (image == null) continue;
			Assert.equals(name, image.width + "x" + image.height);
			Assert.isTrue(closeTo(0x3C78B4FF, image.getPixel32(0, 0, RGBA32), 8, 0), name + " decoded as " + hex(image.getPixel32(0, 0, RGBA32)));
		}
	}

	public function testJPEGQualityTradesSizeForFidelity():Void
	{
		var pixels = noise(64, 64);
		var image = imageOf(64, pixels);
		var low = image.encode(ImageFileFormat.JPEG, 10);
		var high = image.encode(ImageFileFormat.JPEG, 95);

		Assert.notNull(low);
		Assert.notNull(high);
		if (low == null || high == null) return;
		Assert.isTrue(low.length < high.length, "quality 10 took " + low.length + " bytes and quality 95 took " + high.length);

		var lowError = meanError(pixels, Image.fromBytes(low));
		var highError = meanError(pixels, Image.fromBytes(high));
		Assert.isTrue(highError < lowError, "quality 95 was off by " + highError + " a channel and quality 10 by " + lowError);
	}

	public function testJPEGQualityBoundsBothEncode():Void
	{
		// Quality runs from 0 to 100 (Image.encode's documentation)
		for (quality in [0, 1, 100])
		{
			var image = Image.fromBytes(imageOf(16, opaque(pattern(16, 16))).encode(ImageFileFormat.JPEG, quality));
			Assert.notNull(image, "quality " + quality);
			if (image != null) Assert.equals("16x16", image.width + "x" + image.height, "quality " + quality);
		}
	}

	public function testJPEGDecodesOpaque():Void
	{
		// JPEG has no alpha, so whatever alpha went in, the image comes back opaque
		var image = Image.fromBytes(imageOf(8, [for (i in 0...64) rgba(200, 100, 50, ALPHAS[i % ALPHAS.length])]).encode(ImageFileFormat.JPEG, 90));

		Assert.notNull(image);
		if (image == null) return;
		var alphas = [for (y in 0...8) for (x in 0...8) image.getPixel32(x, y, RGBA32) & 0xFF];
		Assert.equals(-1, firstNot(255, alphas), "alpha " + alphas[Std.int(Math.max(0, firstNot(255, alphas)))]);
	}

	public function testJPEGDecodeBytesGivesTheSamePixels():Void
	{
		var jpeg = imageOf(16, noise(16, 16)).encode(ImageFileFormat.JPEG, 90);
		var expected = describe(Image.fromBytes(jpeg));

		Assert.equals(expected, describe(JPEGFormat.decodeBytes(jpeg)));

		var header = JPEGFormat.decodeBytes(jpeg, false);
		Assert.notNull(header);
		if (header != null) Assert.equals("16x16", header.width + "x" + header.height);
	}

	// BMP

	@Ignored("Waiting on #2180")
	public function testBMPEncodingHasAValidFileHeader():Void
	{
		var bmp = imageOf(3, opaque(pattern(3, 2))).encode(ImageFileFormat.BMP);
		var read = readBMP(bmp);

		Assert.equals("", read.problems.join("; "));
		Assert.equals("3x2", read.width + "x" + read.height);
	}

	public function testBMPEncodingKeepsEachPixelInItsRow():Void
	{
		// Rows run bottom-up for a positive height, top-down for a negative one
		var pixels = opaque(pattern(4, 3));
		var read = readBMP(imageOf(4, pixels).encode(ImageFileFormat.BMP));

		Assert.equals("", read.problems.join("; "));
		Assert.equals("", firstDifference(4, pixels, read.pixels));
	}

	@Ignored("Waiting on #2180")
	public function testBMPRowsArePaddedToFourBytes():Void
	{
		// Each row is a whole number of 4-byte words, whatever the width
		for (width in [1, 2, 3, 5, 6, 7])
		{
			var pixels = opaque(pattern(width, 3));
			var bmp = imageOf(width, pixels).encode(ImageFileFormat.BMP);
			var read = readBMP(bmp);
			var name = width + " wide, " + read.bitCount + "-bit";

			Assert.equals("", read.problems.join("; "), name + ": " + read.problems.join("; "));
			Assert.equals(read.pixelOffset + read.stride * 3, bmp.length,
				name + ": rows of " + read.stride + " bytes need a " + (read.pixelOffset + read.stride * 3) + "-byte file, but it is " + bmp.length);

			var difference = firstDifference(width, pixels, read.pixels);
			Assert.equals("", difference, name + ": " + difference);
		}
	}

	@Ignored("Waiting on #2180")
	public function testBMPTypesEncodeTheirOwnLayout():Void
	{
		var pixels = pattern(3, 2);

		// BI_RGB, so no alpha
		var read = readBMP(BMPFormat.encode(imageOf(3, pixels), BMPType.RGB));
		Assert.equals("", read.problems.join("; "), "RGB: " + read.problems.join("; "));
		Assert.equals(0, read.compression, "RGB");
		var difference = firstDifference(3, opaque(pixels), opaque(read.pixels));
		Assert.equals("", difference, "RGB: " + difference);

		// BI_BITFIELDS, whose masks say where each channel is
		read = readBMP(BMPFormat.encode(imageOf(3, pixels), BMPType.BITFIELD));
		Assert.equals("", read.problems.join("; "), "BITFIELD");
		Assert.equals(3, read.compression, "BITFIELD");
		Assert.equals(32, read.bitCount, "BITFIELD");
		if (read.alphaMask != 0)
		{
			Assert.equals("", firstDifference(3, pixels, read.pixels), "BITFIELD with alpha");
		}
		else
		{
			Assert.equals("", firstDifference(3, opaque(pixels), read.pixels), "BITFIELD");
		}
	}

	@Ignored("Waiting on #2180")
	public function testICOBitmapsHaveADoubleHeightAndAnANDMask():Void
	{
		// An icon's bitmap has no file header, gives twice its height, and follows its colours with a
		// 1-bit AND mask whose rows are padded to 32 bits (Microsoft, "Icons" and BITMAPINFOHEADER)
		var pixels = pattern(5, 3);
		var ico = BMPFormat.encode(imageOf(5, pixels), BMPType.ICO);
		var read = readDIB(ico, 0, -1, true);

		Assert.equals("", read.problems.join("; "));
		Assert.equals("5x3", read.width + "x" + read.height);
		Assert.equals(32, read.bitCount);
		Assert.isFalse(read.topDown, "icons are bottom-up");
		Assert.equals(read.pixelEnd + ((5 + 31) >> 5) * 4 * 3, ico.length,
			"the AND mask is " + (ico.length - read.pixelEnd) + " bytes, not " + (((5 + 31) >> 5) * 4 * 3) + " (3 rows of 4)");
		Assert.equals("", firstDifference(5, pixels, read.pixels));
	}

	@Ignored("Waiting on #2180")
	public function testICOANDMaskMarksTransparentPixels():Void
	{
		// A set AND bit keeps the screen, so a pixel with no alpha sets it and an opaque one clears it
		var pixels = [0xFF000000, 0x00FF00FF, 0x0000FF00, 0x123456FF];
		var ico = BMPFormat.encode(imageOf(2, pixels), BMPType.ICO);
		var read = readDIB(ico, 0, -1, true);

		Assert.equals("", read.problems.join("; "));
		if (read.problems.length > 0) return;

		// Two rows of 32 bits
		var maskStride = 4;
		Assert.isTrue(ico.length >= read.pixelEnd + 2 * maskStride, "the AND mask is " + (ico.length - read.pixelEnd) + " bytes, not 8");
		if (ico.length < read.pixelEnd + 2 * maskStride) return;

		var bits = [];
		for (y in 0...2)
		{
			var row = read.pixelEnd + (1 - y) * maskStride;
			bits.push([for (x in 0...2) (ico.get(row) >> (7 - x)) & 1].join(""));
		}

		Assert.equals("10,10", bits.join(","));
	}

	public function testBMPBytesDecodeOrAreRefusedCleanly():Void
	{
		// Image.fromBytes doesn't promise BMP, but a BMP it reads must come out right
		var pixels = [0xFF0000FF, 0x00FF00FF, 0x0000FFFF, 0x102030FF, 0x405060FF, 0x708090FF];

		for (topDown in [false, true])
		{
			var image:Image = null;
			try
			{
				image = Image.fromBytes(createBMP(3, pixels, topDown));
			}
			catch (e:Dynamic) {}

			if (image != null)
			{
				Assert.equals(describeRows(3, pixels).join("\n"), describe(image), topDown ? "top-down" : "bottom-up");
			}
			else
			{
				Assert.pass();
			}
		}
	}

	// Bytes that aren't an image

	public function testNullOrEmptyBytesDoNotDecode():Void
	{
		assertDoesNotDecode(null, "null");
		assertDoesNotDecode(Bytes.alloc(0), "no bytes");
	}

	public function testBytesThatAreNotAnImageDoNotDecode():Void
	{
		var garbage = Bytes.alloc(4096);
		var state = 0x1F2E3D4C;
		for (i in 0...garbage.length)
		{
			state ^= state << 13;
			state ^= state >>> 17;
			state ^= state << 5;
			garbage.set(i, (state >>> 24) & 0xFF);
		}

		assertDoesNotDecode(garbage, "random bytes");
		assertDoesNotDecode(Bytes.ofString("This is not an image, only some text"), "text");

		var png = Bytes.alloc(64);
		png.fill(0, 64, 0x41);
		png.blit(0, PNGFile.signature(), 0, 8);
		assertDoesNotDecode(png, "a PNG signature and nothing else");

		var jpeg = garbage.sub(0, 256);
		jpeg.set(0, 0xFF);
		jpeg.set(1, 0xD8);
		jpeg.set(2, 0xFF);
		assertDoesNotDecode(jpeg, "a JPEG start of image and nothing else");
	}

	public function testTruncatedPNGsDoNotDecode():Void
	{
		var png = PNGFile.create(16, 16, PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(16, pattern(16, 16)));
		var dataStart = 8 + 25 + 8;
		var dataLength = png.length - dataStart - 4 - 12;

		for (length in [8, 20, 33, dataStart + 2, dataStart + Std.int(dataLength / 4), dataStart + Std.int(dataLength / 2), dataStart + dataLength - 8])
		{
			assertDoesNotDecode(png.sub(0, length), "the first " + length + " of " + png.length + " bytes");
		}
	}

	public function testPNGsWithACorruptCriticalChunkDoNotDecode():Void
	{
		var rows = PNGFile.samplesOf(4, pattern(4, 4));

		// A CRC error in a critical chunk is an error (PNG §13.2)
		var png = PNGFile.create(4, 4, PNGFile.TRUECOLOUR_ALPHA, 8, rows);
		png.set(8 + 8 + 13, png.get(8 + 8 + 13) ^ 0xFF);
		assertDoesNotDecode(png, "a wrong IHDR CRC");

		// Zero is not a valid width (PNG §11.2.2)
		var stream = PNGFile.zlibStored(PNGFile.imageData(4, 4, PNGFile.TRUECOLOUR_ALPHA, 8, rows, false, null));
		assertDoesNotDecode(withChunks([PNGFile.chunk("IHDR", PNGFile.header(0, 4, 8, 6, false)), PNGFile.chunk("IDAT", stream)]),
			"a width of zero");

		// Truecolour with alpha only comes in 8 and 16 bits (PNG §11.2.2)
		assertDoesNotDecode(withChunks([PNGFile.chunk("IHDR", PNGFile.header(4, 4, 4, 6, false)), PNGFile.chunk("IDAT", stream)]),
			"truecolour with alpha at 4 bits");

		// Image data that isn't a zlib stream
		var broken = stream.sub(0, stream.length);
		for (i in 0...broken.length)
		{
			broken.set(i, (i * 89 + 17) & 0xFF);
		}
		assertDoesNotDecode(withChunks([PNGFile.chunk("IHDR", PNGFile.header(4, 4, 8, 6, false)), PNGFile.chunk("IDAT", broken)]),
			"image data that isn't zlib");

		// An indexed image needs its palette (PNG §11.2.3)
		assertDoesNotDecode(PNGFile.create(2, 1, PNGFile.INDEXED_COLOUR, 8, [[0, 1]]), "an indexed image without PLTE");
	}

	public function testTruncatedJPEGsFailOrKeepTheirSize():Void
	{
		// A decoder may fill in what's missing, but it mustn't crash or return an image of another size
		var jpeg = imageOf(32, noise(32, 32)).encode(ImageFileFormat.JPEG, 90);

		for (length in [2, 20, Std.int(jpeg.length / 2), jpeg.length - 2])
		{
			var image:Image = null;
			try
			{
				image = Image.fromBytes(jpeg.sub(0, length));
			}
			catch (e:Dynamic) {}

			if (image != null)
			{
				Assert.equals("32x32", image.width + "x" + image.height, "the first " + length + " of " + jpeg.length + " bytes");
			}
			else
			{
				Assert.pass();
			}
		}
	}

	public function testInvalidBase64DoesNotDecode():Void
	{
		var image:Image = null;
		try
		{
			image = Image.fromBase64("!!! not base64 ***", "image/png");
		}
		catch (e:Dynamic) {}

		Assert.isNull(image);
	}

	public function testFuturesForBytesThatAreNotAnImageFinish():Void
	{
		var future = Image.loadFromBytes(Bytes.ofString("This is not an image, only some text"));
		future.ready(5000);

		Assert.isTrue(future.isComplete || future.isError, "the future never finished");
		if (future.isComplete) Assert.isNull(future.value);
	}

	// Decoding and encoding while the collector runs

	public function testPNGBytesDecodeRepeatedlyWhileTheCollectorRuns():Void
	{
		var pixels = pattern(37, 23);
		var expected = describeRows(37, pixels).join("\n");
		var shared = PNGFile.create(37, 23, PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(37, pixels), null, false, [4]);

		for (i in 0...40)
		{
			// Fresh bytes each time, which nothing keeps once they're decoded, and the same bytes again and again
			var image = Image.fromBytes(i % 2 == 0 ? PNGFile.create(37, 23, PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(37, pixels), null, false, [4]) : shared);
			collect();
			churn(shared.length);

			var actual = describe(image);
			if (actual != expected)
			{
				Assert.equals(expected, actual, "decode " + i);
				return;
			}
		}

		Assert.pass();
	}

	public function testDecodedPixelsDoNotDependOnTheEncodedBytes():Void
	{
		var pixels = pattern(9, 9);
		var png = PNGFile.create(9, 9, PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(9, pixels));
		var image = Image.fromBytes(png);

		png.fill(0, png.length, 0x5A);
		png = null;
		collect();
		churn(4096);

		assertPixels(describeRows(9, pixels), image);
	}

	#if lime_threads
	public function testPNGsDecodeOnSeveralThreadsAtOnce():Void
	{
		var expected = [];
		var futures = [];

		for (i in 0...8)
		{
			var width = 20 + i * 3;
			var pixels = pattern(width, 10 + i);
			expected.push(describeRows(width, pixels).join("\n"));
			futures.push(Image.loadFromBytes(PNGFile.create(width, 10 + i, PNGFile.TRUECOLOUR_ALPHA, 8, PNGFile.samplesOf(width, pixels), null, i % 2 == 1)));
		}

		collect();
		churn(8192);

		for (i in 0...futures.length)
		{
			Assert.equals(expected[i], describe(futures[i].result(10000)), "image " + i);
		}
	}
	#end

	public function testEncodingRepeatedlyWhileTheCollectorRuns():Void
	{
		var pixels = pattern(21, 17);

		for (i in 0...20)
		{
			var image = imageOf(21, pixels);
			var png = image.encode(ImageFileFormat.PNG);
			var jpeg = image.encode(ImageFileFormat.JPEG, 80);
			image = null;
			collect();
			churn(21 * 17 * 4);

			var read = PNGFile.read(png);
			var difference = (read.problems.length > 0 ? read.problems.join("; ") : firstDifference(21, pixels, read.pixels));
			var decoded = Image.fromBytes(jpeg);

			if (difference != "" || decoded == null || decoded.width != 21 || decoded.height != 17)
			{
				Assert.equals("", difference, "PNG " + i);
				Assert.notNull(decoded, "JPEG " + i);
				return;
			}
		}

		Assert.pass();
	}

	// Helpers

	private static inline function rgba(r:Int, g:Int, b:Int, a:Int):Int
	{
		return (r << 24) | (g << 16) | (b << 8) | a;
	}

	private static function hex(value:Int, digits:Int = 8):String
	{
		return StringTools.hex(value, digits);
	}

	/** Colours that change across the image, with every kind of alpha **/
	private static function pattern(width:Int, height:Int):Array<Int>
	{
		return [
			for (y in 0...height)
				for (x in 0...width)
					rgba((x * 37 + y * 11) & 0xFF, (x * 7 + y * 53 + 90) & 0xFF, (x * y * 13 + 200) & 0xFF, ALPHAS[(y * width + x) % ALPHAS.length])
		];
	}

	/** Opaque colours that change from pixel to pixel, which JPEG finds hard **/
	private static function noise(width:Int, height:Int):Array<Int>
	{
		var state = 0x2545F491;
		var pixels = [];

		for (y in 0...height)
		{
			for (x in 0...width)
			{
				state ^= state << 13;
				state ^= state >>> 17;
				state ^= state << 5;
				var n = (state >>> 26) & 63;
				pixels.push(rgba((x * 4 + n) & 0xFF, (y * 4 + n) & 0xFF, (128 + n * 2) & 0xFF, 255));
			}
		}

		return pixels;
	}

	private static function opaque(pixels:Array<Int>):Array<Int>
	{
		return [for (pixel in pixels) pixel | 0xFF];
	}

	/** An image of 0xRRGGBBAA pixels, stored in `format`, with alpha multiplied in when `premultiplied` **/
	private static function imageOf(width:Int, pixels:Array<Int>, format:PixelFormat = RGBA32, premultiplied:Bool = false):Image
	{
		var height = Std.int(pixels.length / width);
		var data = new UInt8Array(width * height * 4);

		for (i in 0...pixels.length)
		{
			var a = pixels[i] & 0xFF;
			var r = (pixels[i] >>> 24) & 0xFF;
			var g = (pixels[i] >>> 16) & 0xFF;
			var b = (pixels[i] >>> 8) & 0xFF;

			if (premultiplied)
			{
				r = Math.round(r * a / 255);
				g = Math.round(g * a / 255);
				b = Math.round(b * a / 255);
			}

			var order = switch (format)
			{
				case BGRA32: [b, g, r, a];
				case ARGB32: [a, r, g, b];
				default: [r, g, b, a];
			}

			for (c in 0...4)
			{
				data[i * 4 + c] = order[c];
			}
		}

		var buffer = new ImageBuffer(data, width, height, 32, format);
		buffer.premultiplied = premultiplied;
		return new Image(buffer);
	}

	private static function describe(image:Image):String
	{
		if (image == null) return "null";

		var pixels = [];
		for (y in 0...image.height)
		{
			for (x in 0...image.width)
			{
				pixels.push(image.getPixel32(x, y, RGBA32));
			}
		}

		return describeRows(image.width, pixels).join("\n");
	}

	private static function describeRows(width:Int, pixels:Array<Int>):Array<String>
	{
		var rows = [];
		var y = 0;

		while (y * width < pixels.length)
		{
			rows.push([for (x in 0...width) hex(pixels[y * width + x])].join(" "));
			y++;
		}

		return rows;
	}

	private static function assertPixels(expected:Array<String>, image:Image, name:String = "", ?pos:haxe.PosInfos):Void
	{
		Assert.notNull(image, name + (name == "" ? "" : ": ") + "the image did not decode", pos);
		if (image == null) return;

		Assert.equals(expected[0].split(" ").length + "x" + expected.length, image.width + "x" + image.height, name, pos);
		Assert.equals(expected.join("\n"), describe(image), name, pos);
	}

	/** Where `actual` first differs from `expected`, or "" when it doesn't **/
	private static function firstDifference(width:Int, expected:Array<Int>, actual:Array<Int>):String
	{
		if (actual.length != expected.length) return actual.length + " pixels, not " + expected.length;

		for (i in 0...expected.length)
		{
			if (actual[i] != expected[i])
			{
				return "(" + (i % width) + ", " + Std.int(i / width) + ") is " + hex(actual[i]) + ", not " + hex(expected[i]);
			}
		}

		return "";
	}

	private static function firstPixelDifference(width:Int, expected:Array<Int>, image:Image):String
	{
		if (image == null) return "the image did not decode";
		if (image.width != width || image.height * width != expected.length) return "the image is " + image.width + "x" + image.height;

		return firstDifference(width, expected, [for (y in 0...image.height) for (x in 0...image.width) image.getPixel32(x, y, RGBA32)]);
	}

	private static function firstNot(value:Int, values:Array<Int>):Int
	{
		for (i in 0...values.length)
		{
			if (values[i] != value) return i;
		}

		return -1;
	}

	/** Whether each colour channel is within `tolerance`, and alpha within `alphaTolerance` **/
	private static function closeTo(expected:Int, actual:Int, tolerance:Int, alphaTolerance:Int):Bool
	{
		for (shift in [24, 16, 8])
		{
			if (Math.abs(((expected >>> shift) & 0xFF) - ((actual >>> shift) & 0xFF)) > tolerance) return false;
		}

		return Math.abs((expected & 0xFF) - (actual & 0xFF)) <= alphaTolerance;
	}

	private static function meanError(expected:Array<Int>, image:Image):Float
	{
		if (image == null) return 255;

		var total = 0.0;
		for (i in 0...expected.length)
		{
			var actual = image.getPixel32(i % image.width, Std.int(i / image.width), RGBA32);
			for (shift in [24, 16, 8])
			{
				total += Math.abs(((expected[i] >>> shift) & 0xFF) - ((actual >>> shift) & 0xFF));
			}
		}

		return total / (expected.length * 3);
	}

	private static function assertDoesNotDecode(bytes:Bytes, name:String, ?pos:haxe.PosInfos):Void
	{
		var result = unexpectedImage(bytes);
		Assert.isNull(result, name + ": " + result, pos);
	}

	/** What decoding gave when it should have failed, or null when it failed cleanly **/
	private static function unexpectedImage(bytes:Bytes):String
	{
		try
		{
			var image = Image.fromBytes(bytes);
			return (image == null ? null : "decoded to a " + image.width + "x" + image.height + " image");
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	private static function encodeQuietly(image:Image, format:ImageFileFormat):Bytes
	{
		try
		{
			return image.encode(format, 90);
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	private static function withChunks(chunks:Array<Bytes>):Bytes
	{
		var out = new BytesOutput();
		out.write(PNGFile.signature());

		for (chunk in chunks)
		{
			out.write(chunk);
		}

		out.write(PNGFile.chunk("IEND", Bytes.alloc(0)));
		return out.getBytes();
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

	/** Takes memory the collector just freed, so anything still reading it reads something else **/
	private static function churn(size:Int):Void
	{
		for (i in 0...16)
		{
			var bytes = Bytes.alloc(size);
			bytes.fill(0, size, 0xA5);
		}
	}

	/** A 24-bit BMP with a BITMAPINFOHEADER, its rows padded to 4 bytes **/
	private static function createBMP(width:Int, pixels:Array<Int>, topDown:Bool):Bytes
	{
		var height = Std.int(pixels.length / width);
		var stride = ((24 * width + 31) >> 5) * 4;
		var out = new BytesOutput();
		out.bigEndian = false;

		out.writeString("BM");
		out.writeInt32(54 + stride * height);
		out.writeInt32(0);
		out.writeInt32(54);

		out.writeInt32(40);
		out.writeInt32(width);
		out.writeInt32(topDown ? -height : height);
		out.writeUInt16(1);
		out.writeUInt16(24);
		out.writeInt32(0);
		out.writeInt32(stride * height);
		out.writeInt32(2835);
		out.writeInt32(2835);
		out.writeInt32(0);
		out.writeInt32(0);

		for (i in 0...height)
		{
			var y = (topDown ? i : height - 1 - i);

			for (x in 0...width)
			{
				var pixel = pixels[y * width + x];
				out.writeByte((pixel >>> 8) & 0xFF);
				out.writeByte((pixel >>> 16) & 0xFF);
				out.writeByte((pixel >>> 24) & 0xFF);
			}

			for (i in 0...stride - width * 3)
			{
				out.writeByte(0);
			}
		}

		return out.getBytes();
	}

	/** Reads a BMP file: its BITMAPFILEHEADER, then its bitmap **/
	private static function readBMP(bytes:Bytes):BMPImage
	{
		if (bytes == null || bytes.length < 54 || bytes.getString(0, 2) != "BM")
		{
			var result = readDIB(Bytes.alloc(0), 0, 0, false);
			result.problems = ["not a BMP file"];
			return result;
		}

		var result = readDIB(bytes, 14, bytes.getInt32(10), false);

		// bfSize is the size of the file
		if (bytes.getInt32(2) != bytes.length) result.problems.push("bfSize is " + bytes.getInt32(2) + ", but the file is " + bytes.length + " bytes");
		if (bytes.getUInt16(6) != 0 || bytes.getUInt16(8) != 0) result.problems.push("the reserved fields are not zero");
		if (result.pixelEnd > bytes.length) result.problems.push("the pixels run past the end of the file");

		return result;
	}

	/**
		Reads a bitmap at `start`: a BITMAPINFOHEADER or later, any bit field masks, then the pixel array at
		`pixelOffset` (or straight after the masks when -1). An icon's bitmap gives twice its height.
	**/
	private static function readDIB(bytes:Bytes, start:Int, pixelOffset:Int, icon:Bool):BMPImage
	{
		var result:BMPImage = {
			width: 0,
			height: 0,
			topDown: false,
			bitCount: 0,
			compression: -1,
			headerSize: 0,
			alphaMask: 0,
			stride: 0,
			pixelOffset: pixelOffset,
			pixelEnd: 0,
			pixels: [],
			problems: []
		};
		var problems = result.problems;

		if (bytes.length < start + 40)
		{
			problems.push("no bitmap header");
			return result;
		}

		result.headerSize = bytes.getInt32(start);
		result.width = bytes.getInt32(start + 4);
		var height = bytes.getInt32(start + 8);
		var planes = bytes.getUInt16(start + 12);
		result.bitCount = bytes.getUInt16(start + 14);
		result.compression = bytes.getInt32(start + 16);
		var sizeImage = bytes.getInt32(start + 20);

		if ([40, 52, 56, 108, 124].indexOf(result.headerSize) < 0) problems.push("the header is " + result.headerSize + " bytes");
		if (planes != 1) problems.push("biPlanes is " + planes);
		if (result.bitCount != 24 && result.bitCount != 32) problems.push("biBitCount is " + result.bitCount);

		result.topDown = (height < 0);
		var rows = Std.int(Math.abs(height));

		if (icon)
		{
			if (height <= 0 || height % 2 != 0) problems.push("an icon's height is " + height + ", not twice its own");
			rows = Std.int(rows / 2);
		}

		result.height = rows;

		var masks = [0x00FF0000, 0x0000FF00, 0x000000FF, 0];
		var maskBytes = 0;

		switch (result.compression)
		{
			case 0:
				// BI_RGB: the fourth byte of a 32-bit pixel is not alpha, except in an icon, where it is
				if (icon && result.bitCount == 32) masks[3] = 0xFF000000;
			case 3, 6:
				// BI_BITFIELDS and BI_ALPHABITFIELDS
				var count = (result.compression == 6 ? 4 : 3);
				var maskStart = start + 40;

				if (result.headerSize >= 52)
				{
					if (result.headerSize >= 56) count = 4;
				}
				else
				{
					maskBytes = count * 4;
				}

				for (i in 0...count)
				{
					masks[i] = bytes.getInt32(maskStart + i * 4);
				}
			default:
				problems.push("biCompression is " + result.compression);
		}

		result.alphaMask = masks[3];
		result.stride = ((result.bitCount * result.width + 31) >> 5) * 4;
		if (result.pixelOffset < 0) result.pixelOffset = start + result.headerSize + maskBytes;
		if (result.pixelOffset < start + result.headerSize + maskBytes) problems.push("the pixels start inside the header");
		result.pixelEnd = result.pixelOffset + result.stride * rows;

		if (!icon && sizeImage != 0 && sizeImage != result.stride * rows)
		{
			problems.push("biSizeImage is " + sizeImage + ", not " + (result.stride * rows));
		}

		if (result.pixelEnd > bytes.length)
		{
			problems.push("the pixels need " + result.pixelEnd + " bytes, but there are " + bytes.length);
			return result;
		}

		if (problems.length > 0) return result;

		for (y in 0...rows)
		{
			var row = result.pixelOffset + (result.topDown ? y : rows - 1 - y) * result.stride;

			for (x in 0...result.width)
			{
				if (result.bitCount == 24)
				{
					var offset = row + x * 3;
					result.pixels.push(rgba(bytes.get(offset + 2), bytes.get(offset + 1), bytes.get(offset), 255));
				}
				else
				{
					var value = bytes.getInt32(row + x * 4);
					var a = (masks[3] == 0 ? 255 : channel(value, masks[3]));
					result.pixels.push(rgba(channel(value, masks[0]), channel(value, masks[1]), channel(value, masks[2]), a));
				}
			}
		}

		return result;
	}

	private static function channel(value:Int, mask:Int):Int
	{
		if (mask == 0) return 0;

		var shift = 0;
		while ((mask >>> shift) & 1 == 0)
		{
			shift++;
		}

		var bits = 0;
		while (shift + bits < 32 && (mask >>> (shift + bits)) & 1 == 1)
		{
			bits++;
		}

		var sample = (value & mask) >>> shift;
		return (bits == 8 ? sample : Math.round(sample * 255 / ((1 << bits) - 1)));
	}
	#end
}
