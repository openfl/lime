package graphics;

#if (lime_cffi && lime_cairo && !macro)
import graphics.CairoFixture.*;
import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoAntialias;
import lime.graphics.cairo.CairoFillRule;
import lime.graphics.cairo.CairoLineCap;
import lime.graphics.cairo.CairoLineJoin;
import lime.math.Matrix3;
#end
import utest.Assert;
import utest.Test;

/**
	Filling, stroking and clipping, read from the pixels drawn. What each
	call paints, what it does with the path, and how the fill rule, line
	width, caps, joins, miter limit and dashes shape the result are as the
	cairo manual describes them for `cairo_fill()`, `cairo_stroke()`,
	`cairo_clip()` and the `cairo_set_*` functions
	(cairographics.org/manual/cairo-cairo-t.html).

	Pixels compared are wholly inside or wholly outside a shape, where
	antialiasing leaves nothing to chance, unless a test is about a pixel
	that is partly covered.
**/
class CairoDrawTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_cairo && !macro)
	// Fill

	public function testFillCoversAPixelByTheShareOfItInsideThePath():Void
	{
		var fixture = new CairoFixture(3, 1);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0.5, 0, 1.5, 1);
		cairo.fill();

		fixture.assertPixel(0x80800000, 0, 0, 2);
		fixture.assertPixel(RED, 1, 0);
		fixture.assertPixel(CLEAR, 2, 0);
	}

	public function testFillClearsThePath():Void
	{
		var fixture = new CairoFixture(4, 2);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(1, 0, 2, 2);
		cairo.fill();

		Assert.isFalse(cairo.hasCurrentPoint);

		cairo.setSourceRGB(0, 0, 1);
		cairo.fill();

		fixture.assertRows([".RR.", ".RR."]);
	}

	public function testFillPreserveKeepsThePath():Void
	{
		var fixture = new CairoFixture(4, 2);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(1, 0, 2, 2);
		cairo.fillPreserve();

		Assert.isTrue(cairo.hasCurrentPoint);
		fixture.assertRows([".RR.", ".RR."]);

		cairo.setSourceRGB(0, 0, 1);
		cairo.fill();

		fixture.assertRows([".BB.", ".BB."]);
	}

	public function testFillClosesAnOpenSubPath():Void
	{
		var fixture = new CairoFixture(4, 4);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.moveTo(1, 1);
		cairo.lineTo(3, 1);
		cairo.lineTo(3, 3);
		cairo.lineTo(1, 3);
		cairo.fill();

		fixture.assertRows(["....", ".RR.", ".RR.", "...."]);
	}

	public function testTheEvenOddRuleLeavesAHoleWhereSubPathsOverlap():Void
	{
		var fixture = new CairoFixture(6, 6);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.fillRule = CairoFillRule.EVEN_ODD;
		cairo.rectangle(0, 0, 6, 6);
		cairo.rectangle(2, 1, 3, 2);
		cairo.fill();

		fixture.assertRows([
			"RRRRRR",
			"RR...R",
			"RR...R",
			"RRRRRR",
			"RRRRRR",
			"RRRRRR"
		]);
	}

	public function testTheWindingRuleFillsWhereSubPathsWoundTheSameWayOverlap():Void
	{
		var fixture = new CairoFixture(6, 6);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 6, 6);
		cairo.rectangle(2, 1, 3, 2);
		cairo.fill();

		fixture.assertRows(["RRRRRR", "RRRRRR", "RRRRRR", "RRRRRR", "RRRRRR", "RRRRRR"]);
	}

	public function testTheWindingRuleLeavesAHoleInsideASubPathWoundTheOtherWay():Void
	{
		var fixture = new CairoFixture(6, 6);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 6, 6);

		// rectangle() goes right, down, left and up; this goes down first
		cairo.moveTo(2, 1);
		cairo.lineTo(2, 3);
		cairo.lineTo(5, 3);
		cairo.lineTo(5, 1);
		cairo.closePath();
		cairo.fill();

		fixture.assertRows([
			"RRRRRR",
			"RR...R",
			"RR...R",
			"RRRRRR",
			"RRRRRR",
			"RRRRRR"
		]);
	}

	// Stroke

	public function testStrokeCoversHalfTheLineWidthOnEachSideOfThePath():Void
	{
		var fixture = new CairoFixture(8, 6);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.moveTo(1, 3);
		cairo.lineTo(7, 3);
		cairo.lineWidth = 2;
		cairo.stroke();

		fixture.assertRows([
			"........",
			"........",
			".RRRRRR.",
			".RRRRRR.",
			"........",
			"........"
		]);
	}

	public function testStrokeUsesTheLineWidthSetWhenItIsCalled():Void
	{
		var fixture = new CairoFixture(4, 6);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.lineWidth = 2;
		cairo.moveTo(0, 3);
		cairo.lineTo(4, 3);
		cairo.lineWidth = 4;
		cairo.stroke();

		fixture.assertRows(["....", "RRRR", "RRRR", "RRRR", "RRRR", "...."]);
	}

	public function testStrokeClearsThePath():Void
	{
		var fixture = new CairoFixture(4, 2);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.moveTo(0, 1);
		cairo.lineTo(4, 1);
		cairo.stroke();

		Assert.isFalse(cairo.hasCurrentPoint);

		cairo.setSourceRGB(0, 0, 1);
		cairo.stroke();

		fixture.assertRows(["RRRR", "RRRR"]);
	}

	public function testStrokePreserveKeepsThePath():Void
	{
		var fixture = new CairoFixture(4, 4);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(1, 1, 2, 2);
		cairo.lineWidth = 2;
		cairo.strokePreserve();

		Assert.isTrue(cairo.hasCurrentPoint);
		fixture.assertRows(["RRRR", "RRRR", "RRRR", "RRRR"]);

		cairo.setSourceRGB(0, 0, 1);
		cairo.fill();

		fixture.assertRows(["RRRR", "RBBR", "RBBR", "RRRR"]);
	}

	public function testClosePathStrokesTheLineBackToTheStart():Void
	{
		var closed = new CairoFixture(12, 12);
		closed.cairo.setSourceRGB(1, 0, 0);
		closed.cairo.lineWidth = 2;
		square(closed.cairo);
		closed.cairo.closePath();
		closed.cairo.stroke();

		closed.assertRows([
			"............",
			"............",
			"..RRRRRRRR..",
			"..RRRRRRRR..",
			"..RR....RR..",
			"..RR....RR..",
			"..RR....RR..",
			"..RR....RR..",
			"..RRRRRRRR..",
			"..RRRRRRRR..",
			"............",
			"............"
		]);

		var open = new CairoFixture(12, 12);
		open.cairo.setSourceRGB(1, 0, 0);
		open.cairo.lineWidth = 2;
		square(open.cairo);
		open.cairo.stroke();

		// Without it both ends are cut square, where the path starts and stops
		open.assertRows([
			"............",
			"............",
			"...RRRRRRR..",
			"...RRRRRRR..",
			"........RR..",
			"........RR..",
			"........RR..",
			"........RR..",
			"...RRRRRRR..",
			"...RRRRRRR..",
			"............",
			"............"
		]);
	}

	public function testLineCapsEndALineAtItsEndPointOrHalfTheLineWidthPast():Void
	{
		var butt = cappedLine(CairoLineCap.BUTT);
		butt.assertPixel(RED, 6, 6);
		butt.assertPixel(CLEAR, 5, 6);

		// A half circle around the end point at (6, 6)
		var round = cappedLine(CairoLineCap.ROUND);
		round.assertPixel(RED, 4, 5);
		round.assertPixel(RED, 3, 6);
		round.assertPixel(CLEAR, 2, 2);
		round.assertPixel(CLEAR, 0, 6);

		// A square that reaches from 2 to 6 across and 2 to 10 down
		var square = cappedLine(CairoLineCap.SQUARE);
		square.assertPixel(RED, 2, 2);
		square.assertPixel(RED, 2, 9);
		square.assertPixel(CLEAR, 1, 6);
	}

	public function testLineJoinsShapeTheOutsideOfACorner():Void
	{
		// The corner is at (14, 14) and the stroke reaches 8 pixels past it
		var miter = corner(CairoLineJoin.MITER, 10);
		miter.assertPixel(RED, 21, 21);
		miter.assertPixel(CLEAR, 22, 22);

		var round = corner(CairoLineJoin.ROUND, 10);
		round.assertPixel(RED, 19, 18);
		round.assertPixel(CLEAR, 21, 21);

		// Cut straight from (22, 14) to (14, 22)
		var bevel = corner(CairoLineJoin.BEVEL, 10);
		bevel.assertPixel(RED, 15, 15);
		bevel.assertPixel(CLEAR, 19, 18);
	}

	public function testAMiterLongerThanTheMiterLimitIsBeveled():Void
	{
		// At a right angle a miter is 1.414 line widths long
		var within = corner(CairoLineJoin.MITER, 1.5);
		within.assertPixel(RED, 21, 21);

		var beyond = corner(CairoLineJoin.MITER, 1.25);
		beyond.assertPixel(RED, 15, 15);
		beyond.assertPixel(CLEAR, 19, 18);
		beyond.assertPixel(CLEAR, 21, 21);
	}

	public function testDashLengthsAlternateBetweenOnAndOff():Void
	{
		var fixture = new CairoFixture(16, 4);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.lineWidth = 2;
		cairo.dash = [4, 2];
		cairo.moveTo(0, 2);
		cairo.lineTo(16, 2);
		cairo.stroke();

		fixture.assertRows([
			"................",
			"RRRR..RRRR..RRRR",
			"RRRR..RRRR..RRRR",
			"................"
		]);
	}

	public function testASingleDashLengthIsUsedForBothOnAndOff():Void
	{
		var fixture = new CairoFixture(16, 2);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.lineWidth = 2;
		cairo.dash = [3];
		cairo.moveTo(0, 1);
		cairo.lineTo(16, 1);
		cairo.stroke();

		fixture.assertRows(["RRR...RRR...RRR.", "RRR...RRR...RRR."]);
	}

	public function testAnEmptyDashStrokesASolidLine():Void
	{
		var fixture = new CairoFixture(8, 2);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.lineWidth = 2;
		cairo.dash = [2, 2];
		cairo.dash = [];
		cairo.moveTo(0, 1);
		cairo.lineTo(8, 1);
		cairo.stroke();

		fixture.assertRows(["RRRRRRRR", "RRRRRRRR"]);
	}

	// Strokes under a matrix

	// A matrix that stretches one axis by about as much as it squashes the other looked to cairo
	// 1.18.2 as if it kept sizes, and a thick stroke under it was clipped short of the line width
	// (#2031, cairo issue 927, fixed upstream in cairo merge request 647)
	public function testAThickStrokeUnderAStretchAndASquashIsNotClipped():Void
	{
		// The issue's square, whose stroke reaches from 100 + 2.7925 * -25 = 30.2 to
		// 100 + 2.7925 * 225 = 728.3 across, and from 100 + 0.3575 * -25 = 91.1 to
		// 100 + 0.3575 * 225 = 180.4 down. Cairo 1.18.2 drew it from x 75 to 683.
		var extent = strokeExtent(800, 200, new Matrix3(2.7925, 0, 0, 0.3575, 100, 100), 50, bigSquare);

		assertNear(30, extent.minX, "the stroke's left edge");
		assertNear(727, extent.maxX, "the stroke's right edge");
		assertNear(91, extent.minY, "the stroke's top edge");
		assertNear(179, extent.maxY, "the stroke's bottom edge");
	}

	public function testCairosBug927StrokeReachesItsRoundJoin():Void
	{
		// Cairo's own test for the bug: a V under (1/3, 0, 0, 3, 0, -100) with a line width of 20,
		// whose round join reaches 3 * (50 + 10) - 100 = 80 down. Cairo 1.18.2 stopped at 59.
		var extent = strokeExtent(30, 100, new Matrix3(1 / 3, 0, 0, 3, 0, -100), 20, function(cairo)
		{
			cairo.moveTo(-50, -50);
			cairo.lineTo(50, 50);
			cairo.lineTo(150, -50);
		});

		Assert.equals(0, extent.minY, "the top of the stroke");
		assertNear(79, extent.maxY, "the bottom of the stroke's join");
	}

	public function testAStrokeUnderAMatrixThatKeepsSizesCoversTheLineWidth():Void
	{
		// The square's stroke reaches 25 past each side of it, whole pixels each way
		Assert.equals("x 75..324, y 75..324", describe(strokeExtent(560, 340, new Matrix3(1, 0, 0, 1, 100, 100), 50, bigSquare)), "the identity");
		Assert.equals("x 275..524, y 75..324", describe(strokeExtent(560, 340, new Matrix3(-1, 0, 0, 1, 500, 100), 50, bigSquare)), "a flip");
		Assert.equals("x 175..424, y 75..324", describe(strokeExtent(560, 340, new Matrix3(0, 1, -1, 0, 400, 100), 50, bigSquare)), "a quarter turn");
	}

	// Antialiasing

	public function testAntialiasingShadesThePixelsAnEdgeCrosses():Void
	{
		var fixture = triangle(CairoAntialias.DEFAULT);

		// The edge runs along x + y = 8.5, an eighth of the way into one
		// of these pixels and an eighth short of the end of the other
		fixture.assertPixel(RED, 2, 2);
		fixture.assertPixel(CLEAR, 5, 5);
		Assert.isTrue(fixture.alpha(3, 4) > 0xC0 && fixture.alpha(3, 4) < 0xF8, "pixel 3,4 is " + ImageFixture.hex(fixture.pixel(3, 4)));
		Assert.isTrue(fixture.alpha(4, 4) > 0x08 && fixture.alpha(4, 4) < 0x40, "pixel 4,4 is " + ImageFixture.hex(fixture.pixel(4, 4)));
	}

	public function testWithoutAntialiasingEveryPixelIsPaintedOrNot():Void
	{
		var fixture = triangle(CairoAntialias.NONE);

		// A pixel is painted when its center is inside the shape
		fixture.assertRows([
			"RRRRRRRR",
			"RRRRRRR.",
			"RRRRRR..",
			"RRRRR...",
			"RRRR....",
			"RRR.....",
			"RR......",
			"R......."
		]);
	}

	// Clip

	public function testClipKeepsDrawingInsideThePath():Void
	{
		var fixture = new CairoFixture(6, 4);
		var cairo = fixture.cairo;

		cairo.rectangle(1, 1, 3, 2);
		cairo.clip();
		cairo.setSourceRGB(1, 0, 0);
		cairo.paint();

		fixture.assertRows(["......", ".RRR..", ".RRR..", "......"]);
	}

	public function testClipClearsThePathAndClipPreserveKeepsIt():Void
	{
		var cleared = new CairoFixture(4, 4).cairo;
		cleared.rectangle(1, 1, 2, 2);
		cleared.clip();
		Assert.isFalse(cleared.hasCurrentPoint);

		var fixture = new CairoFixture(4, 4);
		var kept = fixture.cairo;
		kept.rectangle(1, 1, 2, 2);
		kept.clipPreserve();
		Assert.isTrue(kept.hasCurrentPoint);

		// The path that was kept is stroked, but only inside itself
		kept.setSourceRGB(1, 0, 0);
		kept.lineWidth = 2;
		kept.stroke();
		fixture.assertRows(["....", ".RR.", ".RR.", "...."]);
	}

	public function testASecondClipIsIntersectedWithTheFirst():Void
	{
		var fixture = new CairoFixture(6, 6);
		var cairo = fixture.cairo;

		cairo.rectangle(0, 0, 4, 3);
		cairo.clip();
		cairo.rectangle(2, 1, 4, 5);
		cairo.clip();
		cairo.setSourceRGB(1, 0, 0);
		cairo.paint();

		fixture.assertRows([
			"......",
			"..RR..",
			"..RR..",
			"......",
			"......",
			"......"
		]);
	}

	public function testResetClipRemovesTheClip():Void
	{
		var fixture = new CairoFixture(4, 2);
		var cairo = fixture.cairo;

		cairo.rectangle(0, 0, 1, 1);
		cairo.clip();
		cairo.resetClip();
		cairo.setSourceRGB(1, 0, 0);
		cairo.paint();

		fixture.assertRows(["RRRR", "RRRR"]);
	}

	public function testClipFollowsTheFillRule():Void
	{
		var fixture = new CairoFixture(4, 4);
		var cairo = fixture.cairo;

		cairo.fillRule = CairoFillRule.EVEN_ODD;
		cairo.rectangle(0, 0, 4, 4);
		cairo.rectangle(1, 1, 2, 1);
		cairo.clip();
		cairo.setSourceRGB(1, 0, 0);
		cairo.paint();

		fixture.assertRows(["RRRR", "R..R", "RRRR", "RRRR"]);
	}

	public function testClipAppliesToFillAndStroke():Void
	{
		var fixture = new CairoFixture(6, 4);
		var cairo = fixture.cairo;

		cairo.rectangle(2, 0, 2, 4);
		cairo.clip();
		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 6, 1);
		cairo.fill();
		cairo.setSourceRGB(0, 0, 1);
		cairo.lineWidth = 2;
		cairo.moveTo(0, 3);
		cairo.lineTo(6, 3);
		cairo.stroke();

		fixture.assertRows(["..RR..", "......", "..BB..", "..BB.."]);
	}

	public function testInClipTestsAPointAgainstTheClip():Void
	{
		var cairo = new CairoFixture(64, 64).cairo;

		Assert.isTrue(cairo.inClip(22, 35));

		cairo.rectangle(10, 20, 30, 5);
		cairo.clip();

		Assert.isTrue(cairo.inClip(35, 22));
		Assert.isFalse(cairo.inClip(22, 35));
		Assert.isFalse(cairo.inClip(5, 22));

		cairo.resetClip();

		Assert.isTrue(cairo.inClip(22, 35));
	}

	private static function square(cairo:Cairo):Void
	{
		cairo.moveTo(3, 3);
		cairo.lineTo(9, 3);
		cairo.lineTo(9, 9);
		cairo.lineTo(3, 9);
	}

	// A line 8 wide from (6, 6) to the right edge
	private static function cappedLine(cap:CairoLineCap):CairoFixture
	{
		var fixture = new CairoFixture(16, 12);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.lineWidth = 8;
		cairo.lineCap = cap;
		cairo.moveTo(6, 6);
		cairo.lineTo(16, 6);
		cairo.stroke();

		return fixture;
	}

	// A line 16 wide that comes in from the left and turns up at (14, 14)
	private static function corner(join:CairoLineJoin, miterLimit:Float):CairoFixture
	{
		var fixture = new CairoFixture(32, 32);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.lineWidth = 16;
		cairo.lineJoin = join;
		cairo.miterLimit = miterLimit;
		cairo.moveTo(0, 14);
		cairo.lineTo(14, 14);
		cairo.lineTo(14, 0);
		cairo.stroke();

		return fixture;
	}

	private static function bigSquare(cairo:Cairo):Void
	{
		cairo.rectangle(0, 0, 200, 200);
	}

	/**
		Strokes `path` in white with round joins under `matrix`, and gives the smallest rectangle
		around the pixels it covers more than half of.
	**/
	private static function strokeExtent(width:Int, height:Int, matrix:Matrix3, lineWidth:Float, path:Cairo->Void):StrokeExtent
	{
		var fixture = new CairoFixture(width, height);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 1, 1);
		cairo.lineWidth = lineWidth;
		cairo.lineJoin = CairoLineJoin.ROUND;
		cairo.matrix = matrix;
		path(cairo);
		cairo.stroke();
		fixture.surface.flush();

		// Read from the bytes, as a pixel at a time is slow for this many. BGRA32 has alpha last.
		var data = fixture.image.buffer.data;
		var stride = fixture.image.buffer.stride;
		var extent = {minX: width, maxX: -1, minY: height, maxY: -1};

		for (y in 0...height)
		{
			for (x in 0...width)
			{
				if (data[y * stride + x * 4 + 3] > 127)
				{
					if (x < extent.minX) extent.minX = x;
					if (x > extent.maxX) extent.maxX = x;
					if (y < extent.minY) extent.minY = y;
					if (y > extent.maxY) extent.maxY = y;
				}
			}
		}

		return extent;
	}

	private static function describe(extent:StrokeExtent):String
	{
		return "x " + extent.minX + ".." + extent.maxX + ", y " + extent.minY + ".." + extent.maxY;
	}

	/** Within two pixels, as an edge that isn't on a pixel's side can round either way **/
	private static function assertNear(expected:Int, actual:Int, label:String, ?pos:haxe.PosInfos):Void
	{
		Assert.isTrue(Math.abs(expected - actual) <= 2, label + ": expected about " + expected + " but was " + actual, pos);
	}

	private static function triangle(antialias:CairoAntialias):CairoFixture
	{
		var fixture = new CairoFixture(8, 8);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.antialias = antialias;
		cairo.moveTo(0, 0);
		cairo.lineTo(8.5, 0);
		cairo.lineTo(0, 8.5);
		cairo.closePath();
		cairo.fill();

		return fixture;
	}
	#end
}

#if (lime_cffi && lime_cairo && !macro)
private typedef StrokeExtent =
{
	var minX:Int;
	var maxX:Int;
	var minY:Int;
	var maxY:Int;
}
#end
