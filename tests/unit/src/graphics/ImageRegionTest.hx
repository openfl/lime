package graphics;

import graphics.ImageFixture.*;
import haxe.PosInfos;
import lime.graphics.Image;
import lime.graphics.PixelFormat;
import lime.math.Rectangle;
import utest.Assert;
import utest.Test;

/**
	Operations over the whole of an image: `scroll`, `getColorBoundsRect` and
	`resize`. The first two mirror Flash's `BitmapData`.
**/
class ImageRegionTest extends Test
{
	private static var FORMATS:Array<PixelFormat> = [RGBA32, ARGB32, BGRA32];

	private static inline var RED = 0xFFFF0000;
	private static inline var WHITE = 0xFFFFFFFF;

	public function new()
	{
		super();
	}

	public function testScrollRightKeepsTheLeftEdge():Void
	{
		// Flash: "Edge regions outside the scrolling area are left unchanged"
		var image = fromRows([[0xFF000001, 0xFF000002, 0xFF000003, 0xFF000004]]);

		image.scroll(1, 0);

		assertPixels([0xFF000001, 0xFF000001, 0xFF000002, 0xFF000003], image);
	}

	public function testScrollLeftKeepsTheRightEdge():Void
	{
		var image = fromRows([[0xFF000001, 0xFF000002, 0xFF000003, 0xFF000004]]);

		image.scroll(-1, 0);

		assertPixels([0xFF000002, 0xFF000003, 0xFF000004, 0xFF000004], image);
	}

	#if flash
	#end
	public function testScrollDownKeepsTheTopEdge():Void
	{
		var image = fromRows([[0xFF000001], [0xFF000002], [0xFF000003], [0xFF000004]]);

		image.scroll(0, 1);

		assertPixels([0xFF000001, 0xFF000001, 0xFF000002, 0xFF000003], image);
	}

	public function testScrollUpKeepsTheBottomEdge():Void
	{
		var image = fromRows([[0xFF000001], [0xFF000002], [0xFF000003], [0xFF000004]]);

		image.scroll(0, -1);

		assertPixels([0xFF000002, 0xFF000003, 0xFF000004, 0xFF000004], image);
	}

	#if flash
	#end
	public function testScrollBothWaysAtOnce():Void
	{
		for (offset in [[1, 1], [-1, -1], [1, -1], [-1, 1], [2, 1], [-1, 2]])
		{
			var image = numbered(3, 3);
			var expected = [];

			for (y in 0...3)
			{
				for (x in 0...3)
				{
					var fromX = x - offset[0];
					var fromY = y - offset[1];
					expected.push(fromX >= 0 && fromX < 3 && fromY >= 0 && fromY < 3 ? number(fromX, fromY) : number(x, y));
				}
			}

			image.scroll(offset[0], offset[1]);

			assertPixels(expected, image, 0, offset[0] + "," + offset[1]);
		}
	}

	// An image that is part of a larger buffer moves its own pixels alone, by the amounts given.
	// The images are of the target's own type, a BitmapData on Flash, so each target's path runs
	public function testScrollingAnImageInALargerBufferMovesOnlyItsOwnPixels():Void
	{
		for (offset in [[1, 0], [0, 1], [-1, 1], [1, -1]])
		{
			var parent = new Image(null, 0, 0, 5, 4, 0);
			for (y in 0...4) for (x in 0...5) parent.setPixel32(x, y, number(x, y), ARGB32);

			var image = new Image(parent.buffer, 1, 1, 3, 2, null, parent.type);
			var label = offset[0] + "," + offset[1];

			image.scroll(offset[0], offset[1]);

			for (y in 0...4)
			{
				for (x in 0...5)
				{
					var expected = number(x, y);
					var insideX = x - 1;
					var insideY = y - 1;

					if (insideX >= 0 && insideX < 3 && insideY >= 0 && insideY < 2)
					{
						var fromX = insideX - offset[0];
						var fromY = insideY - offset[1];
						if (fromX >= 0 && fromX < 3 && fromY >= 0 && fromY < 2) expected = number(fromX + 1, fromY + 1);
					}

					Assert.equals(hex(expected), hex(parent.getPixel32(x, y, ARGB32)), label + " at " + x + "," + y);
				}
			}
		}
	}

	public function testScrollingFurtherThanTheImageChangesNothing():Void
	{
		for (offset in [[0, 0], [3, 0], [-3, 0], [0, 3], [0, -3], [10, -10]])
		{
			var image = numbered(3, 3);

			image.scroll(offset[0], offset[1]);

			assertPixels([for (y in 0...3) for (x in 0...3) number(x, y)], image, 0, offset[0] + "," + offset[1]);
		}
	}

	public function testScrollMovesPremultipliedPixelsAsTheyAre():Void
	{
		var image = fromRows([[0x80FF8040, 0x40112233, 0xFF445566]], null, true);
		var stored = [for (x in 0...3) peek(image, x, 0)];

		image.scroll(1, 0);

		assertColor(stored[0], peek(image, 1, 0), 0, "1,0");
		assertColor(stored[1], peek(image, 2, 0), 0, "2,0");
	}

	public function testScrollInEachBufferFormat():Void
	{
		for (format in FORMATS)
		{
			var image = numbered(3, 1, format);

			image.scroll(-1, 0);

			assertPixels([number(1, 0), number(2, 0), number(2, 0)], image, 0, formatName(format));
		}
	}

	public function testGetColorBoundsRectEnclosesTheMatchingPixels():Void
	{
		var image = create(5, 5, WHITE);
		poke(image, 1, 1, RED);
		poke(image, 3, 2, RED);

		assertRect(1, 1, 3, 2, image.getColorBoundsRect(0xFFFFFFFF, RED, true, ARGB32));
	}

	public function testGetColorBoundsRectEnclosesThePixelsThatDoNotMatch():Void
	{
		var image = create(5, 5, WHITE);
		poke(image, 1, 1, RED);
		poke(image, 3, 2, RED);

		assertRect(1, 1, 3, 2, image.getColorBoundsRect(0xFFFFFFFF, WHITE, false, ARGB32));
	}

	public function testGetColorBoundsRectComparesOnlyTheMaskedBits():Void
	{
		var image = create(5, 5, WHITE);
		poke(image, 1, 1, RED);
		poke(image, 3, 2, RED);

		assertRect(1, 1, 3, 2, image.getColorBoundsRect(0x0000FF00, 0, true, ARGB32), "green is 0");
		assertRect(0, 0, 5, 5, image.getColorBoundsRect(0x00FF0000, 0x00FF0000, true, ARGB32), "red is 0xFF");
	}

	public function testGetColorBoundsRectComparesAlphaAsUnsigned():Void
	{
		var image = create(5, 5, WHITE);
		poke(image, 4, 3, 0x80FFFFFF);

		assertRect(4, 3, 1, 1, image.getColorBoundsRect(0xFF000000, 0x80000000, true, ARGB32), "find");
		assertRect(4, 3, 1, 1, image.getColorBoundsRect(0xFF000000, 0xFF000000, false, ARGB32), "exclude");
	}

	public function testGetColorBoundsRectReachesTheEdges():Void
	{
		var corners = [[[0, 0], [4, 4]], [[4, 0]], [[0, 4]], [[4, 4]], [[0, 0]]];

		for (points in corners)
		{
			var image = create(5, 5, WHITE);
			var left = 5, top = 5, right = 0, bottom = 0;

			for (point in points)
			{
				poke(image, point[0], point[1], RED);
				left = point[0] < left ? point[0] : left;
				top = point[1] < top ? point[1] : top;
				right = point[0] + 1 > right ? point[0] + 1 : right;
				bottom = point[1] + 1 > bottom ? point[1] + 1 : bottom;
			}

			assertRect(left, top, right - left, bottom - top, image.getColorBoundsRect(0xFFFFFFFF, RED, true, ARGB32), Std.string(points));
		}
	}

	public function testGetColorBoundsRectTakesColorsAsRGBAByDefault():Void
	{
		var image = create(5, 5, WHITE);
		poke(image, 1, 1, RED);
		poke(image, 3, 2, RED);

		assertRect(1, 1, 3, 2, image.getColorBoundsRect(0xFFFFFFFF, 0xFF0000FF));
	}

	public function testGetColorBoundsRectWithoutAMatchIsEmpty():Void
	{
		// Lime documents null; Flash returns an empty rectangle
		var image = create(5, 5, WHITE);
		var rect = image.getColorBoundsRect(0xFFFFFFFF, RED, true, ARGB32);

		Assert.isTrue(rect == null || (rect.width == 0 && rect.height == 0), rect == null ? "" : "was " + describe(rect));
	}

	public function testGetColorBoundsRectComparesUnmultipliedColors():Void
	{
		var image = create(5, 5, 0x80FFFFFF, null, true);
		poke(image, 2, 3, 0x80FF0000);

		assertRect(2, 3, 1, 1, image.getColorBoundsRect(0x00FFFFFF, 0x00FF0000, true, ARGB32));
	}

	public function testGetColorBoundsRectInEachBufferFormat():Void
	{
		for (format in FORMATS)
		{
			var image = create(5, 5, WHITE, format);
			poke(image, 1, 1, 0xFF112233);
			poke(image, 3, 2, 0xFF112233);

			assertRect(1, 1, 3, 2, image.getColorBoundsRect(0xFFFFFFFF, 0xFF112233, true, ARGB32), formatName(format));
		}
	}

	public function testGetColorBoundsRectFindsWhatAScanOfEveryPixelFinds():Void
	{
		// with masks of the alpha alone, of one channel and of all four, on images
		// that hold nothing, a few pixels or many, alone in their buffer or a part of it
		var masks = [0xFF000000, 0xFFFFFFFF, 0x00FFFFFF, 0x0000FF00, 0x000000FF, 0];
		var seed = 7;

		function next(n:Int):Int
		{
			seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
			return (seed >> 8) % n;
		}

		for (round in 0...240)
		{
			var buffer = create(1 + next(12), 1 + next(12), 0, FORMATS[next(FORMATS.length)], next(2) == 0);
			var filled = next(4);

			for (y in 0...buffer.height)
			{
				for (x in 0...buffer.width)
				{
					if (filled > 0 && next(filled == 1 ? 9 : 2) == 0)
					{
						poke(buffer, x, y, (next(256) << 24) | (next(256) << 16) | (next(256) << 8) | next(256));
					}
				}
			}

			var image = buffer;

			if (next(3) == 0)
			{
				var x = next(buffer.width), y = next(buffer.height);
				image = new Image(buffer.buffer, x, y, 1 + next(buffer.width - x), 1 + next(buffer.height - y), null, DATA);
			}

			var mask = masks[next(masks.length)];
			var color = switch (next(3))
			{
				case 0: 0;
				case 1: mask & (next(256) * 0x01010101);
				default: image.getPixel32(next(image.width), next(image.height), ARGB32);
			}
			var findColor = next(2) == 0;

			var left = image.width, top = image.height, right = -1, bottom = -1;

			for (y in 0...image.height)
			{
				for (x in 0...image.width)
				{
					var hit = (image.getPixel32(x, y, ARGB32) & mask) == color;

					if (hit == findColor)
					{
						if (x < left) left = x;
						if (x > right) right = x;
						if (y < top) top = y;
						if (y > bottom) bottom = y;
					}
				}
			}

			var rect = image.getColorBoundsRect(mask, color, findColor, ARGB32);
			var message = "round " + round + ", mask " + StringTools.hex(mask, 8) + ", color " + StringTools.hex(color, 8) + ", " + image.width + "x" + image.height;

			if (right < 0)
			{
				Assert.isTrue(rect == null || (rect.width == 0 && rect.height == 0), message);
			}
			else
			{
				assertRect(left, top, right - left + 1, bottom - top + 1, rect, message);
			}
		}
	}

	public function testResizeChangesTheSizeOfTheImageAndItsBuffer():Void
	{
		var image = create(4, 4, 0xFF336699);

		image.resize(8, 6);

		Assert.equals(8, image.width);
		Assert.equals(6, image.height);
		Assert.equals(8, image.buffer.width);
		Assert.equals(6, image.buffer.height);
		Assert.equals(8 * 6 * 4, image.buffer.data.length);
	}

	public function testResizeKeepsAnEvenColor():Void
	{
		for (size in [[8, 6], [3, 2], [1, 1], [4, 9]])
		{
			var image = create(4, 4, 0xFF336699);

			image.resize(size[0], size[1]);

			assertPixels([for (i in 0...size[0] * size[1]) 0xFF336699], image, 0, size[0] + "x" + size[1]);
		}
	}

	public function testResizeKeepsTheFormatAndPremultipliedAlpha():Void
	{
		var image = create(4, 4, 0x80FF8040, BGRA32, true);

		image.resize(6, 6);

		Assert.equals(BGRA32, image.format);
		Assert.isTrue(image.premultiplied);
		assertPixels([for (i in 0...36) 0x80FF8040], image, 1);
	}

	public function testResizeUpKeepsAnEdgeBetweenItsTwoColors():Void
	{
		// Bilinear scaling blends neighbouring pixels and holds the outermost ones at the
		// image's edges, so going from white to black it never leaves that range
		var image = create(2, 1, 0xFFFFFFFF);
		image.setPixel32(1, 0, 0xFF000000, ARGB32);

		image.resize(8, 1);

		var previous = 0xFF;
		for (x in 0...8)
		{
			var red = (image.getPixel32(x, 0, ARGB32) >> 16) & 0xFF;
			Assert.isTrue(red <= previous, 'red $red at x $x, after $previous');
			previous = red;
		}
		Assert.equals(0xFFFFFFFF, image.getPixel32(0, 0, ARGB32));
		Assert.equals(0xFF000000, image.getPixel32(7, 0, ARGB32));
	}

	public function testResizeToTheSameSizeKeepsThePixels():Void
	{
		var image = numbered(3, 3);

		image.resize(3, 3);

		assertPixels([for (y in 0...3) for (x in 0...3) number(x, y)], image);
	}

	private static function assertRect(x:Float, y:Float, width:Float, height:Float, rect:Rectangle, ?label:String, ?pos:PosInfos):Void
	{
		var expected = x + "," + y + " " + width + "x" + height;
		var actual = rect == null ? "null" : describe(rect);
		Assert.equals(expected, actual, label, pos);
	}

	private static function describe(rect:Rectangle):String
	{
		return rect.x + "," + rect.y + " " + rect.width + "x" + rect.height;
	}
}
