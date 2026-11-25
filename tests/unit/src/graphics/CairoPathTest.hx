package graphics;

#if (lime_cffi && lime_cairo && !macro)
import graphics.CairoFixture.*;
import lime.graphics.cairo.CairoFillRule;
import lime.graphics.cairo.CairoLineCap;
import lime.graphics.cairo.CairoStatus;
#end
import utest.Assert;
import utest.Test;

/**
	Building a path, and asking Cairo about it. Where each call leaves the
	current point, which way an arc turns and what the hit tests and extents
	report are as the cairo manual gives them for paths
	(cairographics.org/manual/cairo-Paths.html) and for `cairo_in_fill()`,
	`cairo_in_stroke()`, `cairo_fill_extents()` and `cairo_stroke_extents()`
	(cairo-cairo-t.html).

	Shapes sit on whole pixels wherever every pixel is compared, so that
	antialiasing has no edge to soften.
**/
class CairoPathTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_cairo && !macro)
	// The current point

	public function testANewPathHasNoCurrentPoint():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		Assert.isFalse(cairo.hasCurrentPoint);
		assertPoint(0, 0, cairo.currentPoint);
	}

	public function testMoveToSetsTheCurrentPoint():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.moveTo(12.5, 7.25);

		Assert.isTrue(cairo.hasCurrentPoint);
		assertPoint(12.5, 7.25, cairo.currentPoint);
	}

	public function testLineToEndsAtItsPoint():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.moveTo(1, 2);
		cairo.lineTo(-30.5, 40);

		assertPoint(-30.5, 40, cairo.currentPoint);
	}

	public function testLineToWithoutACurrentPointMovesThere():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.lineTo(6, 9);

		Assert.isTrue(cairo.hasCurrentPoint);
		assertPoint(6, 9, cairo.currentPoint);
		Assert.equals(CairoStatus.SUCCESS, cairo.status());
	}

	public function testRelativeMovesAndLinesAreMeasuredFromTheCurrentPoint():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.moveTo(10, 20);
		cairo.relMoveTo(3, -4);
		assertPoint(13, 16, cairo.currentPoint);

		cairo.relLineTo(-5, 7);
		assertPoint(8, 23, cairo.currentPoint);
	}

	public function testCurveToEndsAtItsLastPoint():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.moveTo(1, 2);
		cairo.curveTo(3, 4, 5, 6, 7, 8);

		assertPoint(7, 8, cairo.currentPoint);
	}

	public function testRelCurveToMeasuresEveryPointFromWhereItStarts():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.moveTo(10, 20);
		cairo.relCurveTo(1, 2, 3, 4, 5, 6);

		assertPoint(15, 26, cairo.currentPoint);
	}

	public function testRectangleEndsAtItsOrigin():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.rectangle(10, 20, 30, 40);

		Assert.isTrue(cairo.hasCurrentPoint);
		assertPoint(10, 20, cairo.currentPoint);
	}

	public function testClosePathReturnsToTheStartOfTheSubPath():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.moveTo(3, 4);
		cairo.lineTo(10, 4);
		cairo.lineTo(10, 12);
		cairo.closePath();

		assertPoint(3, 4, cairo.currentPoint);
	}

	public function testArcEndsAtItsSecondAngle():Void
	{
		var forward = new CairoFixture(4, 4).cairo;
		forward.arc(10, 20, 5, 0, Math.PI / 2);
		assertPoint(10, 25, forward.currentPoint);

		var backward = new CairoFixture(4, 4).cairo;
		backward.arcNegative(10, 20, 5, 0, -Math.PI / 2);
		assertPoint(10, 15, backward.currentPoint);
	}

	public function testNewPathLeavesNoCurrentPoint():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.rectangle(1, 1, 2, 2);
		cairo.newPath();

		Assert.isFalse(cairo.hasCurrentPoint);
	}

	// The shape of a path

	public function testRectangleTakesACornerThenASize():Void
	{
		var fixture = new CairoFixture(8, 6);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(2, 1, 4, 3);
		cairo.fill();

		fixture.assertRows([
			"........",
			"..RRRR..",
			"..RRRR..",
			"..RRRR..",
			"........",
			"........"
		]);
	}

	public function testLinesBuildAPolygon():Void
	{
		var fixture = new CairoFixture(8, 6);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.moveTo(1, 2);
		cairo.lineTo(7, 2);
		cairo.lineTo(7, 5);
		cairo.lineTo(1, 5);
		cairo.closePath();
		cairo.fill();

		fixture.assertRows([
			"........",
			"........",
			".RRRRRR.",
			".RRRRRR.",
			".RRRRRR.",
			"........"
		]);
	}

	public function testRelativeLinesBuildTheSamePolygon():Void
	{
		var fixture = new CairoFixture(8, 6);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.moveTo(0, 2);
		cairo.relMoveTo(1, 0);
		cairo.relLineTo(6, 0);
		cairo.relLineTo(0, 3);
		cairo.relLineTo(-6, 0);
		cairo.closePath();
		cairo.fill();

		fixture.assertRows([
			"........",
			"........",
			".RRRRRR.",
			".RRRRRR.",
			".RRRRRR.",
			"........"
		]);
	}

	public function testMoveToStartsAnotherSubPath():Void
	{
		var fixture = new CairoFixture(8, 4);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(0, 0, 1);
		cairo.moveTo(0, 0);
		cairo.lineTo(2, 0);
		cairo.lineTo(2, 2);
		cairo.lineTo(0, 2);
		cairo.moveTo(5, 1);
		cairo.lineTo(8, 1);
		cairo.lineTo(8, 4);
		cairo.lineTo(5, 4);
		cairo.fill();

		fixture.assertRows([
			"BB......",
			"BB...BBB",
			".....BBB",
			".....BBB"
		]);
	}

	public function testNewPathDiscardsWhatWasBuilt():Void
	{
		var fixture = new CairoFixture(4, 2);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 4, 2);
		cairo.newPath();
		cairo.rectangle(3, 1, 1, 1);
		cairo.fill();

		fixture.assertRows(["....", "...R"]);
	}

	public function testCurveToTakesTwoControlPointsThenTheEnd():Void
	{
		var cairo = new CairoFixture(16, 16).cairo;

		cairo.moveTo(2, 12);
		cairo.curveTo(2, 2, 10, 2, 14, 12);
		cairo.closePath();

		// Halfway along, a cubic curve is at (start + 3 * first + 3 * second + end) / 8,
		// here (6.5, 4.5), with the filled side below it
		Assert.isTrue(cairo.inFill(6.5, 5.5));
		Assert.isFalse(cairo.inFill(6.5, 3.5));
		Assert.isTrue(cairo.inFill(13, 11));
		Assert.isFalse(cairo.inFill(13, 5));
	}

	public function testRelCurveToDrawsTheCurveCurveToDoes():Void
	{
		var absolute = new CairoFixture(16, 16);
		absolute.cairo.moveTo(2, 12);
		absolute.cairo.curveTo(2, 2, 10, 2, 14, 12);
		absolute.cairo.fill();

		var relative = new CairoFixture(16, 16);
		relative.cairo.moveTo(2, 12);
		relative.cairo.relCurveTo(0, -10, 8, -10, 12, 0);
		relative.cairo.fill();

		Assert.equals(BLACK, absolute.pixel(6, 8));
		Assert.same(absolute.pixels(), relative.pixels());
	}

	public function testArcTakesACenterThenARadius():Void
	{
		var fixture = new CairoFixture(16, 16);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.arc(10, 6, 4, 0, 2 * Math.PI);
		cairo.fill();

		fixture.assertPixel(RED, 10, 6);
		fixture.assertPixel(RED, 12, 6);
		fixture.assertPixel(RED, 10, 8);
		fixture.assertPixel(CLEAR, 15, 6);
		fixture.assertPixel(CLEAR, 10, 11);
		fixture.assertPixel(CLEAR, 6, 10);
	}

	public function testArcTurnsFromThePositiveXAxisTowardThePositiveYAxis():Void
	{
		var fixture = new CairoFixture(16, 16);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.moveTo(8, 8);
		cairo.arc(8, 8, 6, 0, Math.PI / 2);
		cairo.closePath();
		cairo.fill();

		fixture.assertPixel(RED, 10, 10);
		fixture.assertPixel(CLEAR, 5, 10);
		fixture.assertPixel(CLEAR, 5, 5);
		fixture.assertPixel(CLEAR, 10, 5);
	}

	public function testArcNegativeTurnsTheOtherWay():Void
	{
		var fixture = new CairoFixture(16, 16);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.moveTo(8, 8);
		cairo.arcNegative(8, 8, 6, 0, Math.PI / 2);
		cairo.closePath();
		cairo.fill();

		fixture.assertPixel(CLEAR, 10, 10);
		fixture.assertPixel(RED, 5, 10);
		fixture.assertPixel(RED, 5, 5);
		fixture.assertPixel(RED, 10, 5);
	}

	public function testArcIsJoinedToTheCurrentPointByALine():Void
	{
		var joined = new CairoFixture(16, 16).cairo;
		joined.moveTo(2, 2);
		joined.arc(10, 10, 4, 0, Math.PI / 2);

		// From (2, 2) to the start of the arc at (14, 10)
		Assert.isTrue(joined.inStroke(8, 6));

		var alone = new CairoFixture(16, 16).cairo;
		alone.arc(10, 10, 4, 0, Math.PI / 2);

		Assert.isFalse(alone.inStroke(8, 6));
		Assert.isTrue(alone.inStroke(12.83, 12.83));
	}

	// Hit tests

	public function testInFillTestsAPointAgainstThePath():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.rectangle(10, 20, 30, 5);

		Assert.isTrue(cairo.inFill(35, 22));
		Assert.isFalse(cairo.inFill(22, 35));
		Assert.isFalse(cairo.inFill(5, 22));
		Assert.isFalse(cairo.inFill(41, 22));
		Assert.isFalse(cairo.inFill(35, 26));
	}

	public function testInFillFollowsTheFillRule():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		// Two rectangles wound the same way, one inside the other
		cairo.rectangle(0, 0, 30, 30);
		cairo.rectangle(10, 10, 10, 10);

		cairo.fillRule = CairoFillRule.WINDING;
		Assert.isTrue(cairo.inFill(15, 15));

		cairo.fillRule = CairoFillRule.EVEN_ODD;
		Assert.isFalse(cairo.inFill(15, 15));
		Assert.isTrue(cairo.inFill(5, 15));
	}

	public function testInStrokeTestsAPointAgainstTheStrokedLine():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.moveTo(10, 10);
		cairo.lineTo(50, 10);
		cairo.lineWidth = 6;

		Assert.isTrue(cairo.inStroke(30, 12));
		Assert.isFalse(cairo.inStroke(30, 14));
		Assert.isFalse(cairo.inStroke(12, 30));
		Assert.isFalse(cairo.inStroke(8, 10));
	}

	public function testInStrokeFollowsTheLineCap():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.moveTo(10, 10);
		cairo.lineTo(50, 10);
		cairo.lineWidth = 6;
		cairo.lineCap = CairoLineCap.SQUARE;

		Assert.isTrue(cairo.inStroke(8, 10));
		Assert.isFalse(cairo.inStroke(6, 10));
	}

	public function testHitTestsLeaveThePathInPlace():Void
	{
		var fixture = new CairoFixture(4, 2);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(1, 0, 2, 2);
		cairo.inFill(2, 1);
		cairo.inStroke(2, 1);

		assertPoint(1, 0, cairo.currentPoint);
		cairo.fill();
		fixture.assertRows([".RR.", ".RR."]);
	}

	// Extents

	public function testExtentsLeaveThePathInPlace():Void
	{
		var fixture = new CairoFixture(4, 2);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(1, 0, 2, 2);
		cairo.fillExtents(0, 0, 0, 0);
		cairo.strokeExtents(0, 0, 0, 0);
		cairo.clipExtents(0, 0, 0, 0);

		Assert.equals(CairoStatus.SUCCESS, cairo.status());
		assertPoint(1, 0, cairo.currentPoint);
		cairo.fill();
		fixture.assertRows([".RR.", ".RR."]);
	}
	#end
}
