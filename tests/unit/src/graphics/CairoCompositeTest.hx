package graphics;

#if (lime_cffi && lime_cairo && !macro)
import graphics.CairoFixture.*;
import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoContent;
import lime.graphics.cairo.CairoOperator;
import lime.graphics.cairo.CairoPattern;
import lime.graphics.cairo.CairoStatus;
#end
import utest.Assert;
import utest.Test;

/**
	What reaches the surface: the source, how `paint()` and `mask()` lay it
	down, the compositing operators and groups. Behaviour is as the cairo
	manual gives it for `cairo_set_source_*()`, `cairo_paint()`,
	`cairo_mask()` and `cairo_push_group()`
	(cairographics.org/manual/cairo-cairo-t.html), and the result of each
	operator is worked out from the formulas on cairographics.org/operators,
	which are those of the PDF blend modes.

	Colors are premultiplied, as Cairo stores them.
**/
class CairoCompositeTest extends Test
{
	// Colors for the blend modes, chosen so that no two modes agree
	private static inline var ABOVE = 0xFFFF8040;
	private static inline var BELOW = 0xFF4080BF;

	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_cairo && !macro)
	// Sources

	public function testTheDefaultSourceIsOpaqueBlack():Void
	{
		var fixture = new CairoFixture(2, 2);

		fixture.cairo.paint();

		fixture.assertRows(["KK", "KK"]);
	}

	public function testSetSourceRGBTakesRedThenGreenThenBlue():Void
	{
		var fixture = new CairoFixture(1, 1);

		fixture.cairo.setSourceRGB(1, 0.5, 0.25);
		fixture.cairo.paint();

		fixture.assertPixel(0xFFFF8040, 0, 0, 1);
	}

	public function testSetSourceRGBATakesAlphaLast():Void
	{
		var fixture = new CairoFixture(1, 1);

		fixture.cairo.setSourceRGBA(0.25, 0.5, 1, 0.5);
		fixture.cairo.paint();

		// Each color is stored multiplied by the alpha
		fixture.assertPixel(0x80204080, 0, 0, 1);
	}

	public function testColorComponentsOutsideZeroToOneAreClamped():Void
	{
		var fixture = new CairoFixture(1, 1);

		fixture.cairo.setSourceRGBA(2, -1, 0.5, 3);
		fixture.cairo.paint();

		fixture.assertPixel(0xFFFF0080, 0, 0, 1);
	}

	public function testSetSourceSurfacePutsTheSurfaceOriginAtThePointGiven():Void
	{
		var source = fromRows([[RED, GREEN], [BLUE, WHITE]]);
		var fixture = new CairoFixture(6, 4);

		fixture.cairo.setSourceSurface(source.surface, 3, 1);
		fixture.cairo.paint();

		fixture.assertRows(["......", "...RG.", "...BW.", "......"]);
	}

	public function testSetSourceSurfaceIsPlacedInUserSpace():Void
	{
		var source = fromRows([[RED, GREEN]]);
		var fixture = new CairoFixture(6, 2);

		fixture.cairo.translate(2, 1);
		fixture.cairo.setSourceSurface(source.surface, 1, 0);
		fixture.cairo.paint();

		fixture.assertRows(["......", "...RG."]);
	}

	public function testSourceGivesBackTheSolidColorThatWasSet():Void
	{
		var first = new CairoFixture(1, 1).cairo;
		first.setSourceRGBA(0, 1, 0, 1);
		var pattern = first.source;

		var fixture = new CairoFixture(2, 1);
		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		Assert.equals(CairoStatus.SUCCESS, fixture.cairo.status());
		fixture.assertRows(["GG"]);
	}

	public function testSourceGivesBackThePatternThatWasSet():Void
	{
		var pattern = CairoPattern.createLinear(0, 0, 4, 0);
		pattern.addColorStopRGB(0, 1, 0, 0);
		pattern.addColorStopRGB(0.5, 0, 1, 0);
		pattern.addColorStopRGB(1, 0, 0, 1);

		var cairo = new CairoFixture(2, 1).cairo;
		cairo.source = pattern;

		Assert.equals(3, cairo.source.colorStopCount);
	}

	public function testASourceSetAsAPatternIsPainted():Void
	{
		var fixture = new CairoFixture(2, 1);

		fixture.cairo.source = CairoPattern.createRGB(0, 0, 1);
		fixture.cairo.paint();

		fixture.assertRows(["BB"]);
	}

	// Paint

	public function testPaintWithAlphaFadesTheSource():Void
	{
		var clear = new CairoFixture(1, 1);
		clear.cairo.setSourceRGB(1, 0, 0);
		clear.cairo.paintWithAlpha(0.5);
		clear.assertPixel(0x80800000, 0, 0, 1);

		var blue = new CairoFixture(1, 1, BLUE);
		blue.cairo.setSourceRGB(1, 0, 0);
		blue.cairo.paintWithAlpha(0.25);
		blue.assertPixel(0xFF4000BF, 0, 0, 1);
	}

	public function testPaintWithAlphaOfZeroOrOnePaintsNothingOrEverything():Void
	{
		var nothing = new CairoFixture(2, 1, BLUE);
		nothing.cairo.setSourceRGB(1, 0, 0);
		nothing.cairo.paintWithAlpha(0);
		nothing.assertRows(["BB"]);

		var everything = new CairoFixture(2, 1, BLUE);
		everything.cairo.setSourceRGB(1, 0, 0);
		everything.cairo.paintWithAlpha(1);
		everything.assertRows(["RR"]);
	}

	// Operators

	public function testEveryPorterDuffOperatorCombinesSourceAndDestination():Void
	{
		// What is left where both are opaque, where only the source is and
		// where only the destination is
		var expected:Array<Array<Int>> = [
			[CairoOperator.CLEAR, CLEAR, CLEAR, CLEAR],
			[CairoOperator.SOURCE, RED, RED, CLEAR],
			[CairoOperator.OVER, RED, RED, BLUE],
			[CairoOperator.IN, RED, CLEAR, CLEAR],
			[CairoOperator.OUT, CLEAR, RED, CLEAR],
			[CairoOperator.ATOP, RED, CLEAR, BLUE],
			[CairoOperator.DEST, BLUE, CLEAR, BLUE],
			[CairoOperator.DEST_OVER, BLUE, RED, BLUE],
			[CairoOperator.DEST_IN, BLUE, CLEAR, CLEAR],
			[CairoOperator.DEST_OUT, CLEAR, CLEAR, BLUE],
			[CairoOperator.DEST_ATOP, BLUE, RED, CLEAR],
			[CairoOperator.XOR, CLEAR, RED, BLUE],
			[CairoOperator.ADD, 0xFFFF00FF, RED, BLUE],
			[CairoOperator.SATURATE, BLUE, RED, BLUE]
		];

		for (row in expected)
		{
			var fixture = composite(row[0], RED, BLUE);
			var label = "operator " + row[0];

			fixture.assertPixel(row[1], 0, 0, label + " over both");
			fixture.assertPixel(row[2], 1, 0, label + " over the source alone");
			fixture.assertPixel(row[3], 0, 1, label + " over the destination alone");
			fixture.assertPixel(CLEAR, 1, 1, label + " over neither");
		}
	}

	public function testSaturateAddsOnlyAsMuchSourceAsTheDestinationHasRoomFor():Void
	{
		var half = new CairoFixture(1, 1, 0x800000FF);
		half.cairo.setOperator(CairoOperator.SATURATE);
		half.cairo.setSourceRGBA(1, 0, 0, 0.5);
		half.cairo.paint();
		half.assertPixel(0xFF800080, 0, 0, 2);

		// Three quarters full, so only half of the source's alpha fits
		var most = new CairoFixture(1, 1, 0xC00000FF);
		most.cairo.setOperator(CairoOperator.SATURATE);
		most.cairo.setSourceRGBA(1, 0, 0, 0.5);
		most.cairo.paint();
		most.assertPixel(0xFF4000C0, 0, 0, 2);
	}

	public function testEveryBlendModeMixesTheColorsWhereBothAreOpaque():Void
	{
		var modes = [
			CairoOperator.MULTIPLY, CairoOperator.SCREEN, CairoOperator.OVERLAY, CairoOperator.DARKEN, CairoOperator.LIGHTEN, CairoOperator.COLOR_DODGE,
			CairoOperator.COLOR_BURN, CairoOperator.HARD_LIGHT, CairoOperator.SOFT_LIGHT, CairoOperator.DIFFERENCE, CairoOperator.EXCLUSION,
			CairoOperator.HSL_HUE, CairoOperator.HSL_SATURATION, CairoOperator.HSL_COLOR, CairoOperator.HSL_LUMINOSITY
		];

		for (mode in modes)
		{
			var fixture = composite(mode, ABOVE, BELOW);
			var label = "operator " + mode;

			fixture.assertPixel(blend(mode, ABOVE, BELOW), 0, 0, 3, label + " over both");
			fixture.assertPixel(ABOVE, 1, 0, label + " over the source alone");
			fixture.assertPixel(BELOW, 0, 1, label + " over the destination alone");
			fixture.assertPixel(CLEAR, 1, 1, label + " over neither");
		}
	}

	public function testTheOperatorAppliesToFillAndStroke():Void
	{
		var fixture = new CairoFixture(4, 2, BLUE);
		var cairo = fixture.cairo;

		cairo.setOperator(CairoOperator.CLEAR);
		cairo.rectangle(1, 0, 1, 2);
		cairo.fill();
		cairo.setOperator(CairoOperator.ADD);
		cairo.setSourceRGB(1, 0, 0);
		cairo.lineWidth = 2;
		cairo.moveTo(3, 0);
		cairo.lineTo(3, 2);
		cairo.stroke();

		fixture.assertPixel(BLUE, 0, 0);
		fixture.assertPixel(CLEAR, 1, 0);
		fixture.assertPixel(0xFFFF00FF, 2, 1);
		fixture.assertPixel(0xFFFF00FF, 3, 1);
	}

	// Masks

	public function testMaskPaintsTheSourceThroughTheAlphaOfAPattern():Void
	{
		var fixture = new CairoFixture(1, 1);

		// Only the alpha of the mask counts, not its color
		fixture.cairo.setSourceRGB(1, 0, 0);
		fixture.cairo.mask(CairoPattern.createRGBA(0, 1, 0, 0.5));

		fixture.assertPixel(0x80800000, 0, 0, 1);
	}

	public function testMaskPaintsOnlyWhereThePatternIsOpaque():Void
	{
		var mask = CairoPattern.createLinear(0, 0, 4, 0);
		mask.addColorStopRGBA(0, 0, 0, 0, 1);
		mask.addColorStopRGBA(0.5, 0, 0, 0, 1);
		mask.addColorStopRGBA(0.5, 0, 0, 0, 0);
		mask.addColorStopRGBA(1, 0, 0, 0, 0);

		var fixture = new CairoFixture(4, 2, BLUE);
		fixture.cairo.setSourceRGB(1, 0, 0);
		fixture.cairo.mask(mask);

		fixture.assertRows(["RRBB", "RRBB"]);
	}

	public function testMaskSurfacePutsTheSurfaceOriginAtThePointGiven():Void
	{
		var mask = fromRows([[BLACK, CLEAR], [CLEAR, WHITE]]);
		var fixture = new CairoFixture(6, 4);

		fixture.cairo.setSourceRGB(1, 0, 0);
		fixture.cairo.maskSurface(mask.surface, 3, 1);

		fixture.assertRows(["......", "...R..", "....R.", "......"]);
	}

	// Groups

	public function testAGroupIsDrawnApartUntilItIsPainted():Void
	{
		var fixture = new CairoFixture(2, 1);
		var cairo = fixture.cairo;

		cairo.pushGroup();
		cairo.setSourceRGB(1, 0, 0);
		cairo.paint();
		fixture.assertRows([".."], "inside the group");

		cairo.popGroupToSource();
		fixture.assertRows([".."], "after the group");

		cairo.paint();
		fixture.assertRows(["RR"], "painted");
		Assert.equals(CairoStatus.SUCCESS, cairo.status());
	}

	public function testPopGroupGivesAPatternOfWhatWasDrawn():Void
	{
		var fixture = new CairoFixture(4, 2, BLUE);
		var cairo = fixture.cairo;

		cairo.pushGroup();
		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(1, 0, 2, 1);
		cairo.fill();
		var group = cairo.popGroup();

		Assert.notNull(group);
		fixture.assertRows(["BBBB", "BBBB"]);

		cairo.source = group;
		cairo.paint();

		fixture.assertRows(["BRRB", "BBBB"]);
	}

	public function testAGroupIsCompositedAsASingleLayer():Void
	{
		var fixture = new CairoFixture(3, 1);
		var cairo = fixture.cairo;

		cairo.pushGroup();
		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 2, 1);
		cairo.fill();
		cairo.rectangle(1, 0, 2, 1);
		cairo.fill();
		cairo.popGroupToSource();
		cairo.paintWithAlpha(0.5);

		// Painted one at a time, the middle pixel would be covered twice
		fixture.assertPixel(0x80800000, 0, 0, 1);
		fixture.assertPixel(0x80800000, 1, 0, 1);
		fixture.assertPixel(0x80800000, 2, 0, 1);
	}

	public function testPushGroupWithContentKeepsOnlyThatContent():Void
	{
		// A group with color and alpha keeps both
		var both = contentGroup(CairoContent.COLOR_ALPHA);
		both.assertRows(["BRRB", "BBBB"]);

		// One with alpha alone paints black wherever it was drawn on
		var alpha = contentGroup(CairoContent.ALPHA);
		alpha.assertRows(["BKKB", "BBBB"]);

		// One with color alone is opaque, and black where nothing was drawn
		var color = contentGroup(CairoContent.COLOR);
		color.assertRows(["KRRK", "KKKK"]);
	}

	public function testTheGraphicsStateChangedInAGroupIsRestoredAfterIt():Void
	{
		var cairo = new CairoFixture(2, 2).cairo;

		cairo.lineWidth = 3;
		cairo.pushGroup();
		cairo.lineWidth = 9;
		cairo.translate(5, 5);
		cairo.popGroupToSource();

		Assert.floatEquals(3.0, cairo.lineWidth);
		assertMatrix([1, 0, 0, 1, 0, 0], cairo.matrix);
	}

	public function testGroupsNest():Void
	{
		var fixture = new CairoFixture(3, 1);
		var cairo = fixture.cairo;

		cairo.pushGroup();
		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 1, 1);
		cairo.fill();
		cairo.pushGroup();
		cairo.setSourceRGB(0, 0, 1);
		cairo.rectangle(2, 0, 1, 1);
		cairo.fill();
		cairo.popGroupToSource();
		cairo.paint();
		cairo.popGroupToSource();
		cairo.paint();

		fixture.assertRows(["R.B"]);
	}

	public function testGroupTargetIsTheSurfaceBeingDrawnTo():Void
	{
		var fixture = new CairoFixture(2, 1);
		var cairo = fixture.cairo;

		// Outside a group it is the surface the context was made for
		var outside = new Cairo(cairo.groupTarget);
		outside.setSourceRGB(1, 0, 0);
		outside.rectangle(0, 0, 1, 1);
		outside.fill();
		fixture.assertRows(["R."]);

		cairo.pushGroup();
		var inside = new Cairo(cairo.groupTarget);
		inside.setSourceRGB(0, 0, 1);
		inside.rectangle(1, 0, 1, 1);
		inside.fill();
		fixture.assertRows(["R."], "inside the group");

		cairo.popGroupToSource();
		cairo.paint();
		fixture.assertRows(["RB"], "painted");
	}

	// Draws on a blue image through a group with the given content
	private static function contentGroup(content:CairoContent):CairoFixture
	{
		var fixture = new CairoFixture(4, 2, BLUE);
		var cairo = fixture.cairo;

		cairo.pushGroupWithContent(content);
		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(1, 0, 2, 1);
		cairo.fill();
		cairo.popGroupToSource();
		cairo.paint();

		return fixture;
	}

	// Paints a source that fills the top row over a destination that fills
	// the left column, so each corner holds a different pairing of the two
	private static function composite(op:CairoOperator, source:Int, destination:Int):CairoFixture
	{
		var above = fromRows([[source, source], [CLEAR, CLEAR]]);
		var fixture = fromRows([[destination, CLEAR], [destination, CLEAR]]);

		fixture.cairo.setOperator(op);
		fixture.cairo.setSourceSurface(above.surface, 0, 0);
		fixture.cairo.paint();

		return fixture;
	}

	// The color a blend mode gives for an opaque source over an opaque destination
	private static function blend(mode:CairoOperator, source:Int, destination:Int):Int
	{
		var above = [for (shift in [16, 8, 0]) ((source >> shift) & 0xFF) / 255];
		var below = [for (shift in [16, 8, 0]) ((destination >> shift) & 0xFF) / 255];

		var mixed = switch (mode)
		{
			case HSL_HUE: setLuminosity(setSaturation(above, saturation(below)), luminosity(below));
			case HSL_SATURATION: setLuminosity(setSaturation(below, saturation(above)), luminosity(below));
			case HSL_COLOR: setLuminosity(above, luminosity(below));
			case HSL_LUMINOSITY: setLuminosity(below, luminosity(above));
			default: [for (i in 0...3) blendChannel(mode, above[i], below[i])];
		}

		return ImageFixture.argb(0xFF, Math.round(mixed[0] * 255), Math.round(mixed[1] * 255), Math.round(mixed[2] * 255));
	}

	private static function blendChannel(mode:CairoOperator, a:Float, b:Float):Float
	{
		return switch (mode)
		{
			case MULTIPLY: a * b;
			case SCREEN: a + b - a * b;
			case OVERLAY: b <= 0.5 ? 2 * a * b : 1 - 2 * (1 - a) * (1 - b);
			case DARKEN: Math.min(a, b);
			case LIGHTEN: Math.max(a, b);
			case COLOR_DODGE: a < 1 ? Math.min(1, b / (1 - a)) : 1;
			case COLOR_BURN: a > 0 ? 1 - Math.min(1, (1 - b) / a) : 0;
			case HARD_LIGHT: a <= 0.5 ? 2 * a * b : 1 - 2 * (1 - a) * (1 - b);
			case SOFT_LIGHT:
				if (a <= 0.5)
				{
					b - (1 - 2 * a) * b * (1 - b);
				}
				else
				{
					var g = b <= 0.25 ? ((16 * b - 12) * b + 4) * b : Math.sqrt(b);
					b + (2 * a - 1) * (g - b);
				}
			case DIFFERENCE: Math.abs(a - b);
			case EXCLUSION: a + b - 2 * a * b;
			default: a;
		}
	}

	private static function luminosity(color:Array<Float>):Float
	{
		return 0.3 * color[0] + 0.59 * color[1] + 0.11 * color[2];
	}

	private static function saturation(color:Array<Float>):Float
	{
		return Math.max(color[0], Math.max(color[1], color[2])) - Math.min(color[0], Math.min(color[1], color[2]));
	}

	private static function setLuminosity(color:Array<Float>, value:Float):Array<Float>
	{
		var shift = value - luminosity(color);
		var shifted = [for (channel in color) channel + shift];
		var low = Math.min(shifted[0], Math.min(shifted[1], shifted[2]));
		var high = Math.max(shifted[0], Math.max(shifted[1], shifted[2]));

		// Pull an out-of-range color back toward its luminosity
		if (low < 0) shifted = [for (channel in shifted) value + (channel - value) * value / (value - low)];
		if (high > 1) shifted = [for (channel in shifted) value + (channel - value) * (1 - value) / (high - value)];

		return shifted;
	}

	private static function setSaturation(color:Array<Float>, value:Float):Array<Float>
	{
		var low = Math.min(color[0], Math.min(color[1], color[2]));
		var high = Math.max(color[0], Math.max(color[1], color[2]));

		if (high == low) return [0.0, 0.0, 0.0];
		return [for (channel in color) (channel - low) * value / (high - low)];
	}
	#end
}
