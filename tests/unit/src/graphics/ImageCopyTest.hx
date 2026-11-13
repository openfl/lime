package graphics;

import graphics.ImageFixture.*;
import lime.graphics.Image;
import lime.graphics.ImageChannel;
import lime.graphics.PixelFormat;
import lime.math.Rectangle;
import lime.math.Vector2;
import utest.Assert;
import utest.Test;

/**
	Operations that read one image into another: `copyPixels`, `copyChannel`,
	`merge` and `threshold`, each of which mirrors the `BitmapData` method of
	the same name in Flash.
**/
class ImageCopyTest extends Test
{
	private static var FORMATS:Array<PixelFormat> = [RGBA32, ARGB32, BGRA32];

	private static inline var BLACK = 0xFF000000;
	private static inline var BLUE = 0xFF0000FF;
	private static inline var GREEN = 0xFF00FF00;
	private static inline var RED = 0xFFFF0000;

	public function new()
	{
		super();
	}

	public function testCopyPixelsReplacesTheDestinationWithoutMergeAlpha():Void
	{
		var source = fromRows([[0x80FF0000, 0x00000000], [GREEN, 0x40112233]]);
		var dest = create(3, 3, BLUE);

		dest.copyPixels(source, new Rectangle(0, 0, 2, 2), new Vector2(1, 1));

		assertPixels([BLUE, BLUE, BLUE, BLUE, 0x80FF0000, 0x00000000, BLUE, GREEN, 0x40112233], dest);
	}

	public function testCopyPixelsMergesAlphaOnlyWhenAsked():Void
	{
		var source = fromRows([[0x80FF0000, 0x00000000], [GREEN, 0x40112233]]);
		var dest = create(2, 2, BLUE);

		dest.copyPixels(source, new Rectangle(0, 0, 2, 2), new Vector2(0, 0), null, null, true);

		// Source over destination; blending divides by 255, so a channel may round either way
		assertPixels([0xFF80007F, BLUE, GREEN, 0xFF0409CC], dest, 1);
	}

	public function testCopyPixelsMergingOntoTransparentPixelsCopiesTheSource():Void
	{
		var source = fromRows([[0x80FF0000, 0x40112233]]);
		var dest = create(2, 1);

		dest.copyPixels(source, new Rectangle(0, 0, 2, 1), new Vector2(0, 0), null, null, true);

		assertPixels([0x80FF0000, 0x40112233], dest, 1);
	}

	public function testCopyPixelsMergingTwoTranslucentPixels():Void
	{
		var source = fromRows([[0x80FF0000]]);
		var dest = create(1, 1, 0x800000FF);

		dest.copyPixels(source, new Rectangle(0, 0, 1, 1), new Vector2(0, 0), null, null, true);

		// Alpha is 0x80 + 0x80 * (1 - 0x80 / 0xFF); dividing the colors by it again magnifies rounding to about two
		assertPixels([0xC0AA0055], dest, 2);
	}

	public function testCopyPixelsMergingIntoAPremultipliedImage():Void
	{
		var source = fromRows([[0x80FF0000]]);
		var dest = create(1, 1, BLUE, null, true);

		dest.copyPixels(source, new Rectangle(0, 0, 1, 1), new Vector2(0, 0), null, null, true);

		assertPixels([0xFF80007F], dest, 1);
	}

	public function testCopyPixelsClipsAtEveryEdge():Void
	{
		var points = [[-1, -1], [2, -1], [-1, 2], [2, 2], [-2, 1], [1, -2], [3, 3], [-2, -2], [4, 0], [0, 4], [-3, 0], [0, -3]];

		for (point in points)
		{
			var source = numbered(3, 3);
			var dest = create(4, 4, BLACK);
			var sourceRect = new Rectangle(0, 0, 3, 3);
			var destPoint = new Vector2(point[0], point[1]);
			var expected = copied(source, sourceRect, destPoint, dest);

			dest.copyPixels(source, sourceRect, destPoint);

			assertPixels(expected, dest, 0, "at " + point[0] + "," + point[1]);
		}
	}

	@Ignored("Waiting on #2170")
	public function testCopyPixelsClipsASourceRectThatLeavesTheSource():Void
	{
		// Each source pixel lands at destPoint plus its place in sourceRect, if it is in the source at all
		var rects = [[-1, -1, 3, 3], [1, 1, 5, 5], [-2, 1, 4, 1], [2, -1, 3, 3]];

		for (r in rects)
		{
			for (point in [[0, 0], [1, 1]])
			{
				var source = numbered(3, 3);
				var dest = create(4, 4, BLACK);
				var expected = copied(source, new Rectangle(r[0], r[1], r[2], r[3]), new Vector2(point[0], point[1]), dest);

				dest.copyPixels(source, new Rectangle(r[0], r[1], r[2], r[3]), new Vector2(point[0], point[1]));

				assertPixels(expected, dest, 0, "from " + r.join(",") + " at " + point[0] + "," + point[1]);
			}
		}
	}

	#if flash
	@Ignored("Waiting on #2212")
	#end
	public function testCopyPixelsWithinOneImageCopiesThePixelsAsTheyWere():Void
	{
		var row = fromRows([[0xFF000001, 0xFF000002, 0xFF000003, 0xFF000004]]);
		row.copyPixels(row, new Rectangle(0, 0, 3, 1), new Vector2(1, 0));
		assertPixels([0xFF000001, 0xFF000001, 0xFF000002, 0xFF000003], row, 0, "right");

		row = fromRows([[0xFF000001, 0xFF000002, 0xFF000003, 0xFF000004]]);
		row.copyPixels(row, new Rectangle(1, 0, 3, 1), new Vector2(0, 0));
		assertPixels([0xFF000002, 0xFF000003, 0xFF000004, 0xFF000004], row, 0, "left");

		var column = fromRows([[0xFF000001], [0xFF000002], [0xFF000003], [0xFF000004]]);
		column.copyPixels(column, new Rectangle(0, 0, 1, 3), new Vector2(0, 1));
		assertPixels([0xFF000001, 0xFF000001, 0xFF000002, 0xFF000003], column, 0, "down");

		column = fromRows([[0xFF000001], [0xFF000002], [0xFF000003], [0xFF000004]]);
		column.copyPixels(column, new Rectangle(0, 1, 1, 3), new Vector2(0, 0));
		assertPixels([0xFF000002, 0xFF000003, 0xFF000004, 0xFF000004], column, 0, "up");

		var square = numbered(3, 3);
		var expected = copied(numbered(3, 3), new Rectangle(0, 0, 2, 2), new Vector2(1, 1), numbered(3, 3));
		square.copyPixels(square, new Rectangle(0, 0, 2, 2), new Vector2(1, 1));
		assertPixels(expected, square, 0, "down and right");
	}

	@Ignored("Waiting on #2174")
	public function testCopyPixelsIntoAnImageWithAnOffsetWritesOnlyItsOwnPart():Void
	{
		var whole = create(4, 4);
		var part = new Image(whole.buffer, 1, 1, 2, 2, null, DATA);

		part.copyPixels(create(2, 2, RED), new Rectangle(0, 0, 2, 2), new Vector2(0, 0));

		assertPixels([0, 0, 0, 0, 0, RED, RED, 0, 0, RED, RED, 0, 0, 0, 0, 0], whole);
	}

	@Ignored("Waiting on #2174")
	public function testCopyPixelsIntoAnOpaqueImageKeepsItOpaque():Void
	{
		// An opaque image has no alpha to hold, as in Flash
		var whole = create(2, 1, BLACK, null, false, false);
		whole.copyPixels(fromRows([[0x80FF0000, 0x00000000]]), new Rectangle(0, 0, 2, 1), new Vector2(0, 0));
		Assert.equals("FF,FF", [for (x in 0...2) StringTools.hex((peek(whole, x, 0) >>> 24) & 0xFF, 2)].join(","), "whole image");

		var part = create(3, 1, BLACK, null, false, false);
		part.copyPixels(fromRows([[0x80FF0000, 0x00000000]]), new Rectangle(0, 0, 2, 1), new Vector2(1, 0));
		Assert.equals("FF,FF,FF", [for (x in 0...3) StringTools.hex((peek(part, x, 0) >>> 24) & 0xFF, 2)].join(","), "part of the image");
	}

	public function testCopyPixelsBetweenFormats():Void
	{
		for (sourceFormat in FORMATS)
		{
			for (destFormat in FORMATS)
			{
				var source = fromRows([[0x80FF8040, 0xFF112233]], sourceFormat);
				var dest = create(2, 1, 0, destFormat);

				dest.copyPixels(source, new Rectangle(0, 0, 2, 1), new Vector2(0, 0));

				assertPixels([0x80FF8040, 0xFF112233], dest, 0, formatName(sourceFormat) + " to " + formatName(destFormat));
			}
		}
	}

	@Ignored("Waiting on #2174")
	public function testCopyPixelsBetweenPremultipliedAndPlainImages():Void
	{
		var premultiplied = fromRows([[0x80FF8040, 0xFF112233]], null, true);
		var plain = create(2, 1);
		plain.copyPixels(premultiplied, new Rectangle(0, 0, 2, 1), new Vector2(0, 0));
		assertPixels([0x80FF8040, 0xFF112233], plain, 1, "into a plain image");

		plain = fromRows([[0x80FF8040, 0xFF112233]]);
		premultiplied = create(2, 1, 0, null, true);
		premultiplied.copyPixels(plain, new Rectangle(0, 0, 2, 1), new Vector2(0, 0));
		assertColor(0x80804020, peek(premultiplied, 0, 0), 1, "stored premultiplied");
		assertPixels([0x80FF8040, 0xFF112233], premultiplied, 1, "into a premultiplied image");
	}

	public function testCopyPixelsTakesAlphaFromTheAlphaImage():Void
	{
		// Flash: "If the source image has alpha data, both sets of alpha data are used"
		var source = fromRows([[RED, GREEN, 0x80112233]]);
		var alpha = fromRows([[0x80000000, 0x40FFFFFF, 0x80FFFFFF]]);
		var dest = create(3, 1, BLUE);

		dest.copyPixels(source, new Rectangle(0, 0, 3, 1), new Vector2(0, 0), alpha, new Vector2(0, 0), false);

		// Alpha multiplied by alpha, then divided by 255
		assertPixels([0x80FF0000, 0x4000FF00, 0x40112233], dest, 1);
	}

	public function testCopyPixelsMergesThroughTheAlphaImage():Void
	{
		var source = fromRows([[RED]]);
		var alpha = fromRows([[0x80000000]]);
		var dest = create(1, 1, BLUE);

		dest.copyPixels(source, new Rectangle(0, 0, 1, 1), new Vector2(0, 0), alpha, new Vector2(0, 0), true);

		assertPixels([0xFF80007F], dest, 1);
	}

	@Ignored("Waiting on #2173")
	public function testCopyPixelsReadsTheAlphaImageFromTheAlphaPoint():Void
	{
		// Flash: alphaPoint is "the point in the alpha image that corresponds to the upper-left corner of the source rectangle"
		var source = fromRows([[RED, RED]]);
		var alpha = fromRows([[0x00000000, 0xFF000000, 0x80000000]]);
		var dest = create(2, 1, BLUE);
		dest.copyPixels(source, new Rectangle(0, 0, 2, 1), new Vector2(0, 0), alpha, new Vector2(1, 0));
		assertPixels([RED, 0x80FF0000], dest, 1, "alpha point");

		source = fromRows([[RED, GREEN, BLUE]]);
		alpha = fromRows([[0xFF000000, 0x80000000]]);
		dest = create(2, 1, BLACK);
		dest.copyPixels(source, new Rectangle(1, 0, 2, 1), new Vector2(0, 0), alpha, new Vector2(0, 0));
		assertPixels([GREEN, 0x800000FF], dest, 1, "source rect");
	}

	public function testCopyPixelsLeavesPixelsTheAlphaImageDoesNotCover():Void
	{
		// Flash: "Any pixels outside the intersection of the source image and alpha image are not copied"
		var source = fromRows([[RED, GREEN]]);
		var dest = create(2, 1, BLUE);
		dest.copyPixels(source, new Rectangle(0, 0, 2, 1), new Vector2(0, 0), fromRows([[0xFF000000]]), new Vector2(0, 0));
		assertPixels([RED, BLUE], dest, 0, "smaller alpha image");

		dest = create(2, 1, BLUE);
		dest.copyPixels(source, new Rectangle(0, 0, 2, 1), new Vector2(0, 0), fromRows([[0xFF000000, 0xFF000000]]), new Vector2(1, 0));
		assertPixels([RED, BLUE], dest, 0, "alpha point near its edge");
	}

	public function testCopyPixelsMovesTheAlphaPointWithAClippedDestPoint():Void
	{
		var source = fromRows([[RED, GREEN, BLUE]]);
		var alpha = fromRows([[0x40000000, 0x80000000, 0xFF000000]]);
		var dest = create(3, 1, BLACK);

		dest.copyPixels(source, new Rectangle(0, 0, 3, 1), new Vector2(-1, 0), alpha, new Vector2(0, 0));

		assertPixels([0x8000FF00, BLUE, BLACK], dest, 1);
	}

	public function testCopyChannelCopiesEachChannelIntoEachOther():Void
	{
		var channels = [ImageChannel.RED, ImageChannel.GREEN, ImageChannel.BLUE, ImageChannel.ALPHA];

		for (sourceChannel in channels)
		{
			for (destChannel in channels)
			{
				var source = fromRows([[0x80112233]]);
				var dest = create(1, 1, 0xC0445566);
				var value = (0x80112233 >>> shift(sourceChannel)) & 0xFF;
				var expected = (0xC0445566 & ~(0xFF << shift(destChannel))) | (value << shift(destChannel));

				dest.copyChannel(source, new Rectangle(0, 0, 1, 1), new Vector2(0, 0), sourceChannel, destChannel);

				assertPixels([expected], dest, 0, sourceChannel + " to " + destChannel);
			}
		}
	}

	@Ignored("Waiting on #2170")
	public function testCopyChannelClipsAtEveryEdge():Void
	{
		for (point in [[1, 1], [-1, -1], [2, -1], [-1, 2], [2, 2], [4, 0], [-3, 0]])
		{
			var source = numbered(3, 3);
			var dest = create(4, 4, BLACK);
			var destPoint = new Vector2(point[0], point[1]);
			var expected = copied(source, new Rectangle(0, 0, 3, 3), destPoint, dest);

			// Only red goes into blue, so take the rest from the destination again
			for (i in 0...expected.length)
			{
				expected[i] = BLACK | ((expected[i] >>> 16) & 0xFF);
			}

			dest.copyChannel(source, new Rectangle(0, 0, 3, 3), destPoint, ImageChannel.RED, ImageChannel.BLUE);

			assertPixels(expected, dest, 0, "at " + point[0] + "," + point[1]);
		}
	}

	@Ignored("Waiting on #2170")
	public function testCopyChannelWithinOneImage():Void
	{
		var image = fromRows([[0xFF100000, 0xFF200000, 0xFF300000]]);
		image.copyChannel(image, new Rectangle(0, 0, 3, 1), new Vector2(0, 0), ImageChannel.RED, ImageChannel.GREEN);
		assertPixels([0xFF101000, 0xFF202000, 0xFF303000], image, 0, "red into green");

		image = fromRows([[0xFF100000, 0xFF200000, 0xFF300000]]);
		image.copyChannel(image, new Rectangle(0, 0, 2, 1), new Vector2(1, 0), ImageChannel.RED, ImageChannel.RED);
		assertPixels([0xFF100000, 0xFF100000, 0xFF200000], image, 0, "red one pixel along");
	}

	public function testCopyChannelReadsUnmultipliedChannels():Void
	{
		var source = fromRows([[0x80FF0000]], null, true);
		var dest = create(1, 1, BLACK);

		dest.copyChannel(source, new Rectangle(0, 0, 1, 1), new Vector2(0, 0), ImageChannel.RED, ImageChannel.GREEN);

		assertPixels([0xFF00FF00], dest, 1);
	}

	public function testCopyChannelIntoTheAlphaOfAPremultipliedImageKeepsItsColor():Void
	{
		var source = fromRows([[0x80000000]]);
		var dest = create(1, 1, 0xFF804020, null, true);

		dest.copyChannel(source, new Rectangle(0, 0, 1, 1), new Vector2(0, 0), ImageChannel.ALPHA, ImageChannel.ALPHA);

		assertPixels([0x80804020], dest, 1);
	}

	public function testMergeBlendsEachChannelByItsMultiplier():Void
	{
		// Flash: new = (source * multiplier + dest * (256 - multiplier)) / 256, in whole numbers
		var source = fromRows([[0xFFC86432]]);
		var dest = create(1, 1, 0xFF14283C);

		dest.merge(source, new Rectangle(0, 0, 1, 1), new Vector2(0, 0), 64, 128, 192, 256);

		assertPixels([0xFF414634], dest);
	}

	public function testMergeWithFullOrNoMultipliers():Void
	{
		var dest = create(1, 1, 0xFF14283C);
		dest.merge(fromRows([[0x80C86432]]), new Rectangle(0, 0, 1, 1), new Vector2(0, 0), 256, 256, 256, 256);
		assertPixels([0x80C86432], dest, 0, "256 takes the source");

		dest = create(1, 1, 0xFF14283C);
		dest.merge(fromRows([[0x80C86432]]), new Rectangle(0, 0, 1, 1), new Vector2(0, 0), 0, 0, 0, 0);
		assertPixels([0xFF14283C], dest, 0, "0 keeps the destination");
	}

	public function testMergeBlendsAlphaByTheAlphaMultiplier():Void
	{
		var dest = create(1, 1, 0xFF102030);

		dest.merge(fromRows([[0x00102030]]), new Rectangle(0, 0, 1, 1), new Vector2(0, 0), 0, 0, 0, 128);

		// 0xFF * 128 / 256
		assertPixels([0x7F102030], dest);
	}

	@Ignored("Waiting on #2170")
	public function testMergeClipsAtTheEdges():Void
	{
		for (point in [[-1, -1], [2, 2], [-1, 2], [2, -1]])
		{
			var source = numbered(3, 3);
			var dest = create(4, 4, BLACK);
			var destPoint = new Vector2(point[0], point[1]);
			var expected = copied(source, new Rectangle(0, 0, 3, 3), destPoint, dest);

			dest.merge(source, new Rectangle(0, 0, 3, 3), destPoint, 256, 256, 256, 256);

			assertPixels(expected, dest, 0, "at " + point[0] + "," + point[1]);
		}
	}

	public function testMergeBlendsUnmultipliedColors():Void
	{
		var source = fromRows([[0x80FF0000]], null, true);
		var dest = create(1, 1, 0x800000FF, null, true);

		dest.merge(source, new Rectangle(0, 0, 1, 1), new Vector2(0, 0), 128, 128, 128, 128);

		assertPixels([0x807F007F], dest, 1);
	}

	public function testThresholdComparesWithEachOperation():Void
	{
		var reds = [0x10, 0x20, 0x30, 0x40, 0x50];
		var tests:Array<{operation:String, passes:Int->Bool}> = [
			{operation: "<", passes: function(red) return red < 0x30},
			{operation: "<=", passes: function(red) return red <= 0x30},
			{operation: ">", passes: function(red) return red > 0x30},
			{operation: ">=", passes: function(red) return red >= 0x30},
			{operation: "==", passes: function(red) return red == 0x30},
			{operation: "!=", passes: function(red) return red != 0x30}
		];

		for (test in tests)
		{
			var source = fromRows([[for (red in reds) 0xFF000000 | (red << 16) | 0x0505]]);
			var dest = create(5, 1, BLACK);

			var count = dest.threshold(source, new Rectangle(0, 0, 5, 1), new Vector2(0, 0), test.operation, 0x00300000, GREEN, 0x00FF0000, false, ARGB32);

			var expected = [for (red in reds) test.passes(red) ? GREEN : BLACK];
			assertPixels(expected, dest, 0, test.operation);
			Assert.equals(expected.filter(function(color) return color == GREEN).length, count, test.operation + " count");
		}
	}

	public function testThresholdComparesAlphaAsUnsigned():Void
	{
		// The example from the documentation: clear every pixel whose alpha is under 0x7F
		var alphas = [0x00, 0x7E, 0x7F, 0x80, 0xFF];
		var source = fromRows([[for (alpha in alphas) (alpha << 24) | 0x112233]]);

		var dest = create(5, 1, 0xFF445566);
		var count = dest.threshold(source, new Rectangle(0, 0, 5, 1), new Vector2(0, 0), "<", 0x7F000000, 0x00000000, 0xFF000000, false, ARGB32);
		assertPixels([0, 0, 0xFF445566, 0xFF445566, 0xFF445566], dest, 0, "<");
		Assert.equals(2, count, "< count");

		dest = create(5, 1, 0xFF445566);
		count = dest.threshold(source, new Rectangle(0, 0, 5, 1), new Vector2(0, 0), ">=", 0x80000000, GREEN, 0xFF000000, false, ARGB32);
		assertPixels([0xFF445566, 0xFF445566, 0xFF445566, GREEN, GREEN], dest, 0, ">=");
		Assert.equals(2, count, ">= count");
	}

	@Ignored("Waiting on #2172")
	public function testThresholdComparesWholeColorsAsNumbers():Void
	{
		// Flash compares the masked 32-bit ARGB values, in which alpha is the highest byte
		var source = fromRows([[0x7FFFFFFF, 0x80000000, 0x80000001, 0x01FF0000]]);
		var dest = create(4, 1, BLACK);

		var count = dest.threshold(source, new Rectangle(0, 0, 4, 1), new Vector2(0, 0), "<", 0x80000001, GREEN, 0xFFFFFFFF, false, ARGB32);

		assertPixels([GREEN, GREEN, BLACK, GREEN], dest);
		Assert.equals(3, count);
	}

	public function testThresholdCopiesTheSourceWhereTheTestFails():Void
	{
		var source = fromRows([[0xFF100000, 0x80300000, 0xFF500000]]);
		var dest = create(3, 1, BLUE);

		dest.threshold(source, new Rectangle(0, 0, 3, 1), new Vector2(0, 0), "==", 0x00300000, GREEN, 0x00FF0000, true, ARGB32);

		assertPixels([0xFF100000, GREEN, 0xFF500000], dest);
	}

	@Ignored("Waiting on #2172")
	public function testThresholdComparesOnlyTheMaskedBits():Void
	{
		var source = fromRows([[0xFF114400, 0x80FF44FF, 0xFF114500]]);
		var dest = create(3, 1, BLACK);

		var count = dest.threshold(source, new Rectangle(0, 0, 3, 1), new Vector2(0, 0), "==", 0x12344456, GREEN, 0x0000FF00, false, ARGB32);

		assertPixels([GREEN, GREEN, BLACK], dest);
		Assert.equals(2, count);
	}

	public function testThresholdTakesColorsAsRGBAByDefault():Void
	{
		var source = fromRows([[0x40112233, 0x80112233, 0xFF112233]]);
		var dest = create(3, 1, BLACK);

		var count = dest.threshold(source, new Rectangle(0, 0, 3, 1), new Vector2(0, 0), "<", 0x0000007F, 0x00FF00FF, 0x000000FF);

		assertPixels([GREEN, BLACK, BLACK], dest);
		Assert.equals(1, count);
	}

	@Ignored("Waiting on #2170")
	public function testThresholdWritesAtTheDestPointAndClips():Void
	{
		var source = create(2, 2, 0xFF300000);

		var dest = create(3, 3, BLACK);
		var count = dest.threshold(source, new Rectangle(0, 0, 2, 2), new Vector2(2, 2), "==", 0x00300000, GREEN, 0x00FF0000, false, ARGB32);
		assertPixels([BLACK, BLACK, BLACK, BLACK, BLACK, BLACK, BLACK, BLACK, GREEN], dest, 0, "bottom right");
		Assert.equals(1, count, "bottom right count");

		dest = create(3, 3, BLACK);
		count = dest.threshold(source, new Rectangle(0, 0, 2, 2), new Vector2(-1, -1), "==", 0x00300000, GREEN, 0x00FF0000, false, ARGB32);
		assertPixels([GREEN, BLACK, BLACK, BLACK, BLACK, BLACK, BLACK, BLACK, BLACK], dest, 0, "top left");
		Assert.equals(1, count, "top left count");

		dest = create(3, 3, BLACK);
		count = dest.threshold(source, new Rectangle(0, 0, 2, 2), new Vector2(1, 0), "==", 0x00300000, GREEN, 0x00FF0000, false, ARGB32);
		assertPixels([BLACK, GREEN, GREEN, BLACK, GREEN, GREEN, BLACK, BLACK, BLACK], dest, 0, "inside");
		Assert.equals(4, count, "inside count");
	}

	public function testThresholdReadsTheSourceRect():Void
	{
		var source = fromRows([[0xFF100000, 0xFF300000], [0xFF300000, 0xFF100000]]);
		var dest = create(1, 2, BLACK);

		dest.threshold(source, new Rectangle(1, 0, 1, 2), new Vector2(0, 0), "==", 0x00300000, GREEN, 0x00FF0000, false, ARGB32);

		assertPixels([GREEN, BLACK], dest);
	}

	public function testThresholdWithinOneImage():Void
	{
		var image = fromRows([[0xFF100000, 0xFF300000, 0xFF500000]]);

		var count = image.threshold(image, new Rectangle(0, 0, 3, 1), new Vector2(0, 0), ">", 0x00200000, GREEN, 0x00FF0000, false, ARGB32);

		assertPixels([0xFF100000, GREEN, GREEN], image);
		Assert.equals(2, count);
	}

	public function testThresholdComparesUnmultipliedColors():Void
	{
		var source = fromRows([[0x80FF0000, 0x80800000]], null, true);
		var dest = create(2, 1, BLACK);

		var count = dest.threshold(source, new Rectangle(0, 0, 2, 1), new Vector2(0, 0), "==", 0x00FF0000, GREEN, 0x00FF0000, false, ARGB32);

		assertPixels([GREEN, BLACK], dest);
		Assert.equals(1, count);
	}

	public function testThresholdSetsTheColorInAPremultipliedImage():Void
	{
		var source = fromRows([[0xFF300000]]);
		var dest = create(1, 1, BLACK, null, true);

		dest.threshold(source, new Rectangle(0, 0, 1, 1), new Vector2(0, 0), "==", 0x00300000, 0x80FF8040, 0x00FF0000, false, ARGB32);

		assertPixels([0x80FF8040], dest, 1);
	}

	/**
		What Flash leaves in `dest` after copying `sourceRect` to `destPoint`:
		each pixel of the rect that is inside the source lands at `destPoint`
		plus its place in the rect, if that is inside the destination.
	**/
	private static function copied(source:Image, sourceRect:Rectangle, destPoint:Vector2, dest:Image):Array<Int>
	{
		var result = pixels(dest);

		for (y in 0...dest.height)
		{
			for (x in 0...dest.width)
			{
				var sourceX = Std.int(x - destPoint.x + sourceRect.x);
				var sourceY = Std.int(y - destPoint.y + sourceRect.y);

				if (sourceX >= sourceRect.x && sourceX < sourceRect.x + sourceRect.width && sourceY >= sourceRect.y
					&& sourceY < sourceRect.y + sourceRect.height && sourceX >= 0 && sourceX < source.width && sourceY >= 0 && sourceY < source.height)
				{
					result[y * dest.width + x] = read(source, sourceX, sourceY);
				}
			}
		}

		return result;
	}

	private static function shift(channel:ImageChannel):Int
	{
		return switch (channel)
		{
			case ImageChannel.RED: 16;
			case ImageChannel.GREEN: 8;
			case ImageChannel.BLUE: 0;
			case ImageChannel.ALPHA: 24;
		}
	}
}
