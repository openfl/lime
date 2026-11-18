package graphics;

import graphics.ImageFixture.*;
import lime.graphics.Image;
import lime.graphics.PixelFormat;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import utest.Test;

/**
	Operations that paint over part of an image: `fillRect`, `floodFill` and
	`colorTransform`, which mirror the `BitmapData` methods of the same name
	in Flash.
**/
class ImageFillTest extends Test
{
	private static var FORMATS:Array<PixelFormat> = [RGBA32, ARGB32, BGRA32];

	private static inline var BLACK = 0xFF000000;
	private static inline var RED = 0xFFFF0000;
	private static inline var WHITE = 0xFFFFFFFF;

	public function new()
	{
		super();
	}

	public function testFillRectFillsOnlyTheRect():Void
	{
		var image = create(4, 4);

		image.fillRect(new Rectangle(1, 1, 2, 2), 0xFF0000FF);

		assertPixels([0, 0, 0, 0, 0, RED, RED, 0, 0, RED, RED, 0, 0, 0, 0, 0], image);
	}

	public function testFillRectTakesTheColorInTheFormatGiven():Void
	{
		for (format in FORMATS)
		{
			var image = create(2, 1);

			image.fillRect(new Rectangle(0, 0, 1, 1), toFormat(0x80FF8040, format), format);

			assertPixels([0x80FF8040, 0], image, 0, formatName(format));
		}
	}

	public function testFillRectStoresTheBufferFormat():Void
	{
		for (format in FORMATS)
		{
			var whole = create(2, 2, 0, format);
			whole.fillRect(new Rectangle(0, 0, 2, 2), 0x11223344, ARGB32);
			assertPixels([for (i in 0...4) 0x11223344], whole, 0, formatName(format) + " whole image");

			var part = create(2, 2, 0, format);
			part.fillRect(new Rectangle(1, 0, 1, 2), 0x11223344, ARGB32);
			assertPixels([0, 0x11223344, 0, 0x11223344], part, 0, formatName(format) + " part");
		}
	}

	public function testFillRectClipsAtEveryEdge():Void
	{
		var rects = [
			new Rectangle(-1, -1, 2, 2),
			new Rectangle(2, 2, 5, 5),
			new Rectangle(-5, 1, 100, 1),
			new Rectangle(1, -5, 1, 100),
			new Rectangle(2, -1, 5, 2),
			new Rectangle(-1, 2, 2, 5)
		];

		for (rect in rects)
		{
			var image = create(3, 3, BLACK);

			image.fillRect(rect, RED, ARGB32);

			var expected = [for (y in 0...3) for (x in 0...3) inside(rect, x, y) ? RED : BLACK];
			assertPixels(expected, image, 0, rect.x + "," + rect.y + " " + rect.width + "x" + rect.height);
		}
	}

	public function testFillRectWithAnEmptyRectChangesNothing():Void
	{
		var rects = [
			new Rectangle(1, 1, 0, 2),
			new Rectangle(1, 1, 2, 0),
			new Rectangle(2, 2, -1, -1),
			new Rectangle(2, 2, -2, 1),
			new Rectangle(3, 0, 1, 1),
			new Rectangle(0, 3, 1, 1),
			new Rectangle(-1, 0, 1, 1),
			new Rectangle(-2, -2, 1, 1)
		];

		for (rect in rects)
		{
			var image = create(3, 3, BLACK);

			image.fillRect(rect, RED, ARGB32);

			assertPixels([for (i in 0...9) BLACK], image, 0, rect.x + "," + rect.y + " " + rect.width + "x" + rect.height);
		}
	}

	public function testFillRectWithTransparentBlackClearsThePixels():Void
	{
		var image = create(2, 1, 0xFF112233);

		image.fillRect(new Rectangle(0, 0, 2, 1), 0, ARGB32);

		assertPixels([0, 0], image);
	}

	public function testFillRectOnAPremultipliedImage():Void
	{
		var image = create(2, 1, 0, null, true);

		image.fillRect(new Rectangle(0, 0, 2, 1), 0x80FF8040, ARGB32);

		assertColor(0x80804020, peek(image, 0, 0), 1, "stored");
		assertPixels([0x80FF8040, 0x80FF8040], image, 1);
	}

	@Ignored("Waiting on #2174")
	public function testFillRectOfAWholePremultipliedImageWithAGrey():Void
	{
		// Every channel the same, so the bytes to store could be mistaken for the color itself
		var image = create(2, 2, 0, null, true);

		image.fillRect(new Rectangle(0, 0, 2, 2), 0x80808080, ARGB32);

		assertColor(0x80404040, peek(image, 0, 0), 1, "stored");
		assertPixels([for (i in 0...4) 0x80808080], image, 1);
	}

	@Ignored("Waiting on #2174")
	public function testFillRectOfAWholeImageWithAnOffsetFillsOnlyItsOwnPart():Void
	{
		var whole = create(4, 4);
		var part = new Image(whole.buffer, 1, 1, 2, 2, null, DATA);

		part.fillRect(new Rectangle(0, 0, 2, 2), WHITE, ARGB32);

		assertPixels([0, 0, 0, 0, 0, WHITE, WHITE, 0, 0, WHITE, WHITE, 0, 0, 0, 0, 0], whole);
	}

	public function testFloodFillFillsTheConnectedRegion():Void
	{
		var image = fromRows([
			[WHITE, WHITE, BLACK, WHITE, WHITE],
			[WHITE, WHITE, BLACK, WHITE, WHITE],
			[WHITE, WHITE, BLACK, WHITE, WHITE]
		]);

		image.floodFill(0, 0, RED, ARGB32);

		assertPixels([RED, RED, BLACK, WHITE, WHITE, RED, RED, BLACK, WHITE, WHITE, RED, RED, BLACK, WHITE, WHITE], image);
	}

	public function testFloodFillDoesNotCrossCorners():Void
	{
		// Flash fills neighbours that share an edge, not those that only touch at a corner
		var image = fromRows([[WHITE, WHITE, BLACK], [BLACK, BLACK, WHITE], [BLACK, BLACK, WHITE]]);

		image.floodFill(0, 0, RED, ARGB32);

		assertPixels([RED, RED, BLACK, BLACK, BLACK, WHITE, BLACK, BLACK, WHITE], image);
	}

	public function testFloodFillFollowsAWindingRegion():Void
	{
		var image = fromRows([
			[WHITE, WHITE, WHITE, WHITE, WHITE],
			[BLACK, BLACK, BLACK, BLACK, WHITE],
			[WHITE, WHITE, WHITE, BLACK, WHITE],
			[WHITE, BLACK, BLACK, BLACK, WHITE],
			[WHITE, WHITE, WHITE, WHITE, WHITE]
		]);

		image.floodFill(2, 2, RED, ARGB32);

		assertPixels([
			RED,   RED,   RED,   RED,   RED,
			BLACK, BLACK, BLACK, BLACK, RED,
			RED,   RED,   RED,   BLACK, RED,
			RED,   BLACK, BLACK, BLACK, RED,
			RED,   RED,   RED,   RED,   RED
		], image);
	}

	public function testFloodFillStopsAtADifferentAlpha():Void
	{
		var image = fromRows([[WHITE, WHITE, 0x80FFFFFF, WHITE]]);

		image.floodFill(0, 0, RED, ARGB32);

		assertPixels([RED, RED, 0x80FFFFFF, WHITE], image);
	}

	public function testFloodFillWithTheColorAlreadyThereChangesNothing():Void
	{
		var image = create(3, 3, WHITE);

		image.floodFill(1, 1, WHITE, ARGB32);

		assertPixels([for (i in 0...9) WHITE], image);
	}

	@Ignored("Waiting on #2171")
	public function testFloodFillOutsideTheImageChangesNothing():Void
	{
		for (point in [[-1, 0], [0, -1], [3, 0], [0, 2], [3, 2]])
		{
			var image = create(3, 2, WHITE);

			image.floodFill(point[0], point[1], RED, ARGB32);

			assertPixels([for (i in 0...6) WHITE], image, 0, point[0] + "," + point[1]);
		}
	}

	@Ignored("Waiting on #2171")
	public function testFloodFillTakesTheColorInTheFormatGiven():Void
	{
		for (format in FORMATS)
		{
			var image = fromRows([[WHITE, WHITE, BLACK]]);

			image.floodFill(0, 0, toFormat(0x80FF8040, format), format);

			assertPixels([0x80FF8040, 0x80FF8040, BLACK], image, 0, formatName(format));
		}
	}

	@Ignored("Waiting on #2171")
	public function testFloodFillFillsALonePixel():Void
	{
		var single = create(1, 1, WHITE);
		single.floodFill(0, 0, RED, ARGB32);
		assertPixels([RED], single, 0, "image of one pixel");

		var walled = fromRows([[WHITE, BLACK, WHITE]]);
		walled.floodFill(0, 0, RED, ARGB32);
		assertPixels([RED, BLACK, WHITE], walled, 0, "pixel by a wall");
	}

	@Ignored("Waiting on #2171")
	public function testFloodFillInAnImageWithAnOffsetFillsOnlyItsOwnPart():Void
	{
		var whole = create(4, 4, WHITE);
		var part = new Image(whole.buffer, 1, 1, 2, 2, null, DATA);

		part.floodFill(0, 0, RED, ARGB32);

		assertPixels([
			WHITE, WHITE, WHITE, WHITE,
			WHITE,   RED,   RED, WHITE,
			WHITE,   RED,   RED, WHITE,
			WHITE, WHITE, WHITE, WHITE
		], whole);
	}

	public function testFloodFillInEachBufferFormat():Void
	{
		for (format in FORMATS)
		{
			var image = fromRows([[WHITE, WHITE, BLACK, WHITE], [BLACK, WHITE, BLACK, WHITE]], format);

			image.floodFill(1, 1, 0x11223344, ARGB32);

			assertPixels([0x11223344, 0x11223344, BLACK, WHITE, BLACK, 0x11223344, BLACK, WHITE], image, 0, formatName(format));
		}
	}

	public function testFloodFillOnAPremultipliedImage():Void
	{
		var image = fromRows([[0x80FF0000, 0x80FF0000, BLACK, 0x80FF0000]], null, true);

		image.floodFill(0, 0, 0x40FFFFFF, ARGB32);

		assertPixels([0x40FFFFFF, 0x40FFFFFF, BLACK, 0x80FF0000], image, 1);
	}

	public function testColorTransformScalesAndOffsetsEachChannel():Void
	{
		var image = create(1, 1, 0xFE804020);
		var matrix = new ColorMatrix();
		matrix.redMultiplier = 0.5;
		matrix.greenOffset = 16;
		matrix.blueMultiplier = 2;
		matrix.alphaMultiplier = 0.5;

		image.colorTransform(new Rectangle(0, 0, 1, 1), matrix);

		assertPixels([0x7F405040], image);
	}

	public function testColorTransformClampsToTheChannelRange():Void
	{
		var image = create(1, 1, 0x80804020);
		var matrix = new ColorMatrix();
		matrix.redOffset = 255;
		matrix.greenMultiplier = 4;
		matrix.blueOffset = -300;
		matrix.alphaOffset = 200;

		image.colorTransform(new Rectangle(0, 0, 1, 1), matrix);

		assertPixels([0xFFFFFF00], image);
	}

	public function testColorTransformOnlyChangesTheRect():Void
	{
		var rects = [new Rectangle(1, 1, 1, 1), new Rectangle(1, 1, 5, 5), new Rectangle(-1, -1, 2, 2), new Rectangle(0, 2, 3, 3)];

		for (rect in rects)
		{
			var image = create(3, 3, 0xFF808080);
			var matrix = new ColorMatrix();
			matrix.redMultiplier = 0.5;

			image.colorTransform(rect, matrix);

			var expected = [for (y in 0...3) for (x in 0...3) inside(rect, x, y) ? 0xFF408080 : 0xFF808080];
			assertPixels(expected, image, 0, rect.x + "," + rect.y + " " + rect.width + "x" + rect.height);
		}
	}

	public function testColorTransformInEachBufferFormat():Void
	{
		for (format in FORMATS)
		{
			var image = create(1, 1, 0xFF804020, format);
			var matrix = new ColorMatrix();
			matrix.redMultiplier = 0.5;
			matrix.blueOffset = 16;

			image.colorTransform(new Rectangle(0, 0, 1, 1), matrix);

			assertPixels([0xFF404030], image, 0, formatName(format));
		}
	}

	public function testColorTransformOffsetsUnmultipliedColors():Void
	{
		// An offset added to a premultiplied channel would come out doubled at half alpha
		var image = create(1, 1, 0x80FF0000, null, true);
		var matrix = new ColorMatrix();
		matrix.greenOffset = 0x40;

		image.colorTransform(new Rectangle(0, 0, 1, 1), matrix);

		assertPixels([0x80FF4000], image, 1);
	}

	@Ignored("Waiting on #2175")
	public function testColorTransformOfAlphaKeepsThePremultipliedColor():Void
	{
		var image = create(1, 1, 0xFF804020, null, true);
		var matrix = new ColorMatrix();
		matrix.alphaMultiplier = 0.4;

		image.colorTransform(new Rectangle(0, 0, 1, 1), matrix);

		assertPixels([0x66804020], image, 1);
	}

	private static function inside(rect:Rectangle, x:Int, y:Int):Bool
	{
		return x >= rect.x && x < rect.x + rect.width && y >= rect.y && y < rect.y + rect.height;
	}
}
