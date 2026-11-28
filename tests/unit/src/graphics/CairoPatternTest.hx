package graphics;

#if (lime_cffi && lime_cairo && !macro)
import graphics.CairoFixture.*;
import lime.graphics.cairo.CairoExtend;
import lime.graphics.cairo.CairoFilter;
import lime.graphics.cairo.CairoPattern;
import lime.math.Matrix3;
#end
import utest.Assert;
import utest.Test;

/**
	Solid, gradient and surface patterns, painted and read back. Where a
	gradient runs, how its stops are ordered, what each extend mode and
	filter does and which way the pattern matrix maps are as the cairo
	manual gives them for `cairo_pattern_t`
	(cairographics.org/manual/cairo-cairo-pattern-t.html).

	Gradients here mostly have two stops at the same offset, which makes a
	hard edge between two flat colors that can be compared exactly.
**/
class CairoPatternTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_cairo && !macro)
	// Solid patterns

	public function testCreateRGBTakesRedThenGreenThenBlue():Void
	{
		var fixture = new CairoFixture(1, 1);

		fixture.cairo.source = CairoPattern.createRGB(1, 0.5, 0.25);
		fixture.cairo.paint();

		fixture.assertPixel(0xFFFF8040, 0, 0, 1);
	}

	public function testCreateRGBATakesAlphaLast():Void
	{
		var fixture = new CairoFixture(1, 1);

		fixture.cairo.source = CairoPattern.createRGBA(0.25, 0.5, 1, 0.5);
		fixture.cairo.paint();

		fixture.assertPixel(0x80204080, 0, 0, 1);
	}

	// Gradients

	public function testALinearGradientRunsFromItsFirstPointToItsSecond():Void
	{
		var across = new CairoFixture(4, 4);
		across.cairo.source = redThenBlue(CairoPattern.createLinear(0, 0, 4, 0));
		across.cairo.paint();
		across.assertRows(["RRBB", "RRBB", "RRBB", "RRBB"]);

		var down = new CairoFixture(4, 4);
		down.cairo.source = redThenBlue(CairoPattern.createLinear(0, 0, 0, 4));
		down.cairo.paint();
		down.assertRows(["RRRR", "RRRR", "BBBB", "BBBB"]);

		var back = new CairoFixture(8, 1);
		back.cairo.source = redThenBlue(CairoPattern.createLinear(6, 0, 2, 0));
		back.cairo.paint();
		back.assertRows(["BBBBRRRR"]);
	}

	public function testAGradientBlendsFromOneStopToTheNext():Void
	{
		var pattern = CairoPattern.createLinear(0, 0, 4, 0);
		pattern.addColorStopRGB(0, 0, 0, 0);
		pattern.addColorStopRGB(1, 1, 1, 1);

		var fixture = new CairoFixture(4, 1);
		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		// The middle of each pixel is 1, 3, 5 and 7 eighths of the way along
		fixture.assertPixel(0xFF202020, 0, 0, 3);
		fixture.assertPixel(0xFF606060, 1, 0, 3);
		fixture.assertPixel(0xFF9F9F9F, 2, 0, 3);
		fixture.assertPixel(0xFFDFDFDF, 3, 0, 3);
	}

	public function testColorStopsAreOrderedByOffsetThenByWhenTheyWereAdded():Void
	{
		var pattern = CairoPattern.createLinear(0, 0, 4, 0);
		pattern.addColorStopRGB(1, 0, 0, 1);
		pattern.addColorStopRGB(0, 1, 0, 0);
		pattern.addColorStopRGB(0.5, 1, 0, 0);
		pattern.addColorStopRGB(0.5, 0, 0, 1);

		var fixture = new CairoFixture(4, 1);
		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		fixture.assertRows(["RRBB"]);
	}

	public function testAddColorStopRGBTakesTheOffsetThenRedGreenAndBlue():Void
	{
		var pattern = CairoPattern.createLinear(0, 0, 2, 0);
		pattern.addColorStopRGB(0, 1, 0.5, 0.25);
		pattern.addColorStopRGB(1, 1, 0.5, 0.25);

		var fixture = new CairoFixture(2, 1);
		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		fixture.assertPixel(0xFFFF8040, 0, 0, 1);
		fixture.assertPixel(0xFFFF8040, 1, 0, 1);
	}

	public function testAddColorStopRGBATakesAlphaLast():Void
	{
		var pattern = CairoPattern.createLinear(0, 0, 2, 0);
		pattern.addColorStopRGBA(0, 0.25, 0.5, 1, 0.5);
		pattern.addColorStopRGBA(1, 0.25, 0.5, 1, 0.5);

		var fixture = new CairoFixture(2, 1);
		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		fixture.assertPixel(0x80204080, 0, 0, 2);
		fixture.assertPixel(0x80204080, 1, 0, 2);
	}

	public function testARadialGradientRunsFromItsFirstCircleToItsSecond():Void
	{
		// From a circle of radius 2 to one of radius 6 around (4, 12), so
		// the colors change 4 pixels out
		var fixture = new CairoFixture(16, 16);
		fixture.cairo.source = redThenBlue(CairoPattern.createRadial(4, 12, 2, 4, 12, 6));
		fixture.cairo.paint();

		fixture.assertPixel(RED, 4, 12);
		fixture.assertPixel(RED, 6, 12);
		fixture.assertPixel(RED, 4, 9);
		fixture.assertPixel(BLUE, 9, 12);
		fixture.assertPixel(BLUE, 4, 6);
		fixture.assertPixel(BLUE, 12, 4);
	}

	public function testColorStopCountCountsTheStopsAdded():Void
	{
		var linear = CairoPattern.createLinear(0, 0, 4, 0);
		Assert.equals(0, linear.colorStopCount);

		linear.addColorStopRGB(0, 1, 0, 0);
		linear.addColorStopRGBA(0.5, 0, 1, 0, 1);
		linear.addColorStopRGB(1, 0, 0, 1);
		Assert.equals(3, linear.colorStopCount);

		var radial = CairoPattern.createRadial(0, 0, 0, 0, 0, 4);
		radial.addColorStopRGB(0, 1, 0, 0);
		radial.addColorStopRGB(1, 0, 0, 1);
		Assert.equals(2, radial.colorStopCount);
	}

	public function testAPatternThatIsNotAGradientHasNoColorStops():Void
	{
		Assert.equals(0, CairoPattern.createRGB(1, 0, 0).colorStopCount);
		Assert.equals(0, CairoPattern.createRGBA(1, 0, 0, 0.5).colorStopCount);
		Assert.equals(0, CairoPattern.createForSurface(new CairoFixture(2, 2).surface).colorStopCount);
	}

	// Extend

	public function testGradientsArePaddedAndSurfacesAreNotUnlessToldOtherwise():Void
	{
		Assert.equals(CairoExtend.PAD, CairoPattern.createLinear(0, 0, 4, 0).extend);
		Assert.equals(CairoExtend.PAD, CairoPattern.createRadial(0, 0, 0, 0, 0, 4).extend);
		Assert.equals(CairoExtend.NONE, CairoPattern.createForSurface(new CairoFixture(2, 2).surface).extend);
	}

	public function testEveryExtendModeIsReadBackAsSet():Void
	{
		var pattern = CairoPattern.createLinear(0, 0, 4, 0);

		for (extend in [CairoExtend.NONE, CairoExtend.REPEAT, CairoExtend.REFLECT, CairoExtend.PAD])
		{
			Assert.equals(extend, pattern.extend = extend);
			Assert.equals(extend, pattern.extend);
		}
	}

	public function testExtendDecidesWhatASurfacePaintsOutsideItself():Void
	{
		Assert.equals("RB....", extendedSurface(CairoExtend.NONE));
		Assert.equals("RBRBRB", extendedSurface(CairoExtend.REPEAT));
		Assert.equals("RBBRRB", extendedSurface(CairoExtend.REFLECT));
		Assert.equals("RBBBBB", extendedSurface(CairoExtend.PAD));
	}

	public function testExtendDecidesWhatAGradientPaintsOutsideItsPoints():Void
	{
		Assert.equals("..RB....", extendedGradient(CairoExtend.NONE));
		Assert.equals("RBRBRBRB", extendedGradient(CairoExtend.REPEAT));
		Assert.equals("BRRBBRRB", extendedGradient(CairoExtend.REFLECT));
		Assert.equals("RRRBBBBB", extendedGradient(CairoExtend.PAD));
	}

	// Filter

	public function testEveryFilterIsReadBackAsSet():Void
	{
		var pattern = CairoPattern.createForSurface(new CairoFixture(2, 2).surface);
		var filters = [
			CairoFilter.FAST,
			CairoFilter.BEST,
			CairoFilter.NEAREST,
			CairoFilter.BILINEAR,
			CairoFilter.GAUSSIAN,
			CairoFilter.GOOD
		];

		for (filter in filters)
		{
			Assert.equals(filter, pattern.filter = filter);
			Assert.equals(filter, pattern.filter);
		}
	}

	public function testTheNearestFilterEnlargesPixelsAsBlocks():Void
	{
		var fixture = enlarged(CairoFilter.NEAREST);

		fixture.assertRows(["KKKKWWWW"]);
	}

	public function testTheBilinearFilterBlendsBetweenPixels():Void
	{
		var fixture = enlarged(CairoFilter.BILINEAR);

		// The middle of a source pixel is unmixed, and those between two are
		// 3 and 5 eighths of the way from one to the other
		fixture.assertPixel(BLACK, 1, 0, 8);
		fixture.assertPixel(0xFF606060, 3, 0, 8);
		fixture.assertPixel(0xFF9F9F9F, 4, 0, 8);
		fixture.assertPixel(WHITE, 6, 0, 8);
	}

	// Matrix

	public function testANewPatternHasTheIdentityMatrix():Void
	{
		assertMatrix([1, 0, 0, 1, 0, 0], CairoPattern.createLinear(0, 0, 4, 0).matrix);
		assertMatrix([1, 0, 0, 1, 0, 0], CairoPattern.createForSurface(new CairoFixture(2, 2).surface).matrix);
	}

	public function testMatrixReadsBackEveryMemberItWasSet():Void
	{
		var pattern = CairoPattern.createLinear(0, 0, 4, 0);

		pattern.matrix = new Matrix3(1.5, -0.25, 0.75, 2.5, -30, 12.5);

		assertMatrix([1.5, -0.25, 0.75, 2.5, -30, 12.5], pattern.matrix);
	}

	public function testThePatternMatrixMapsUserSpaceToThePattern():Void
	{
		var source = fromRows([[RED, GREEN], [BLUE, WHITE]]);
		var pattern = CairoPattern.createForSurface(source.surface);

		// The pixel at (3, 1) is read from (0, 0) in the pattern
		pattern.matrix = new Matrix3(1, 0, 0, 1, -3, -1);

		var fixture = new CairoFixture(6, 4);
		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		fixture.assertRows(["......", "...RG.", "...BW.", "......"]);
	}

	public function testThePatternMatrixTakesEachAxisFromItsOwnMembers():Void
	{
		var source = fromRows([[RED, GREEN], [BLUE, WHITE]]);
		var pattern = CairoPattern.createForSurface(source.surface);
		pattern.filter = CairoFilter.NEAREST;

		// Across the image moves down the pattern at half the speed, and
		// down the image moves across the pattern
		pattern.matrix = new Matrix3(0, 0.5, 1, 0, 0, 0);

		var fixture = new CairoFixture(4, 2);
		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		fixture.assertRows(["RRBB", "GGWW"]);
	}

	public function testSetSourceSurfaceGivesItsPatternTheOffsetAsATranslation():Void
	{
		var cairo = new CairoFixture(6, 4).cairo;

		cairo.setSourceSurface(new CairoFixture(2, 2).surface, 3, 1);

		assertMatrix([1, 0, 0, 1, -3, -1], cairo.source.matrix);
		Assert.equals(CairoExtend.NONE, cairo.source.extend);
	}

	public function testASourceStaysWhereUserSpaceWasWhenItWasSet():Void
	{
		var source = fromRows([[RED, BLUE]]);

		var before = new CairoFixture(6, 1);
		before.cairo.translate(2, 0);
		before.cairo.source = CairoPattern.createForSurface(source.surface);
		before.cairo.paint();
		before.assertRows(["..RB.."]);

		var after = new CairoFixture(6, 1);
		after.cairo.source = CairoPattern.createForSurface(source.surface);
		after.cairo.translate(2, 0);
		after.cairo.paint();
		after.assertRows(["RB...."]);
	}

	// Red up to halfway along and blue from there on
	private static function redThenBlue(pattern:CairoPattern):CairoPattern
	{
		pattern.addColorStopRGB(0, 1, 0, 0);
		pattern.addColorStopRGB(0.5, 1, 0, 0);
		pattern.addColorStopRGB(0.5, 0, 0, 1);
		pattern.addColorStopRGB(1, 0, 0, 1);
		return pattern;
	}

	// A red and a blue pixel painted across six
	private static function extendedSurface(extend:CairoExtend):String
	{
		var pattern = CairoPattern.createForSurface(fromRows([[RED, BLUE]]).surface);
		pattern.extend = extend;

		var fixture = new CairoFixture(6, 1);
		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		return letters(fixture);
	}

	// A gradient from 2 to 4 painted across eight pixels
	private static function extendedGradient(extend:CairoExtend):String
	{
		var pattern = redThenBlue(CairoPattern.createLinear(2, 0, 4, 0));
		pattern.extend = extend;

		var fixture = new CairoFixture(8, 1);
		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		return letters(fixture);
	}

	// A black and a white pixel drawn four times as wide
	private static function enlarged(filter:CairoFilter):CairoFixture
	{
		var pattern = CairoPattern.createForSurface(fromRows([[BLACK, WHITE]]).surface);
		pattern.extend = CairoExtend.PAD;
		pattern.filter = filter;
		pattern.matrix = new Matrix3(0.25, 0, 0, 1, 0, 0);

		var fixture = new CairoFixture(8, 1);
		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		return fixture;
	}

	private static function letters(fixture:CairoFixture):String
	{
		var result = "";

		for (color in fixture.pixels())
		{
			result += switch (color)
			{
				case RED: "R";
				case BLUE: "B";
				case CLEAR: ".";
				default: "?";
			}
		}

		return result;
	}
	#end
}
