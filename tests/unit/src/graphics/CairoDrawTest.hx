package graphics;

#if (lime_cffi && lime_cairo && !macro)
import graphics.CairoFixture.*;
import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoAntialias;
import lime.graphics.cairo.CairoFillRule;
import lime.graphics.cairo.CairoLineCap;
import lime.graphics.cairo.CairoLineJoin;
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
