package graphics;

#if (lime_cffi && lime_cairo && !macro)
import graphics.CairoFixture.*;
import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoAntialias;
import lime.graphics.cairo.CairoFillRule;
import lime.graphics.cairo.CairoImageSurface;
import lime.graphics.cairo.CairoLineCap;
import lime.graphics.cairo.CairoLineJoin;
import lime.graphics.cairo.CairoOperator;
import lime.graphics.cairo.CairoStatus;
import lime.graphics.CairoRenderContext;
import lime.math.Matrix3;
#end
import utest.Assert;
import utest.Test;

/**
	The drawing state of a Cairo context, set and read back through Lime's
	`Cairo` class. The defaults, what `save()` and `restore()` cover and the
	status each misuse leaves behind are those the cairo manual gives for
	`cairo_t` and `cairo_status_t` (cairographics.org/manual/cairo-cairo-t.html
	and cairo-Error-handling.html).
**/
class CairoTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_cairo && !macro)
	public function testANewContextHasTheDefaultState():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		Assert.equals(CairoStatus.SUCCESS, cairo.status());
		Assert.equals(CairoOperator.OVER, cairo.getOperator());
		Assert.equals(CairoAntialias.DEFAULT, cairo.antialias);
		Assert.equals(CairoFillRule.WINDING, cairo.fillRule);
		Assert.equals(CairoLineCap.BUTT, cairo.lineCap);
		Assert.equals(CairoLineJoin.MITER, cairo.lineJoin);
		Assert.floatEquals(2.0, cairo.lineWidth);
		Assert.floatEquals(10.0, cairo.miterLimit);
		Assert.floatEquals(0.1, cairo.tolerance);
		Assert.equals(0, cairo.dashCount);
		Assert.same([], cairo.dash);
		Assert.isFalse(cairo.hasCurrentPoint);
	}

	public function testLineWidthIsReadBackAsSet():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		for (width in [3.75, 0.125, 0.0, 1000.5])
		{
			cairo.lineWidth = width;
			Assert.floatEquals(width, cairo.lineWidth);
		}

		Assert.equals(CairoStatus.SUCCESS, cairo.status());
	}

	public function testLineWidthIsNotChangedByALaterTransformation():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.lineWidth = 3.5;
		cairo.scale(4, 0.5);

		Assert.floatEquals(3.5, cairo.lineWidth);
	}

	public function testEveryLineCapIsReadBackAsSet():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		for (cap in [CairoLineCap.ROUND, CairoLineCap.SQUARE, CairoLineCap.BUTT])
		{
			cairo.lineCap = cap;
			Assert.equals(cap, cairo.lineCap);
		}
	}

	public function testEveryLineJoinIsReadBackAsSet():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		for (join in [CairoLineJoin.ROUND, CairoLineJoin.BEVEL, CairoLineJoin.MITER])
		{
			cairo.lineJoin = join;
			Assert.equals(join, cairo.lineJoin);
		}
	}

	public function testMiterLimitIsReadBackAsSet():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		for (limit in [4.5, 1.0, 250.25])
		{
			cairo.miterLimit = limit;
			Assert.floatEquals(limit, cairo.miterLimit);
		}
	}

	public function testEveryFillRuleIsReadBackAsSet():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		for (rule in [CairoFillRule.EVEN_ODD, CairoFillRule.WINDING])
		{
			cairo.fillRule = rule;
			Assert.equals(rule, cairo.fillRule);
		}
	}

	public function testEveryAntialiasModeIsReadBackAsSet():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;
		var modes = [
			CairoAntialias.NONE,
			CairoAntialias.GRAY,
			CairoAntialias.SUBPIXEL,
			CairoAntialias.FAST,
			CairoAntialias.GOOD,
			CairoAntialias.BEST,
			CairoAntialias.DEFAULT
		];

		for (mode in modes)
		{
			cairo.antialias = mode;
			Assert.equals(mode, cairo.antialias);
		}
	}

	public function testToleranceIsReadBackAsSet():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		for (tolerance in [0.25, 2.5, 0.015625])
		{
			cairo.tolerance = tolerance;
			Assert.floatEquals(tolerance, cairo.tolerance);
		}
	}

	public function testEveryOperatorIsReadBackAsSet():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		// HSL_LUMINOSITY is the last of cairo_operator_t
		for (value in 0...(CairoOperator.HSL_LUMINOSITY : Int) + 1)
		{
			var op:CairoOperator = value;
			Assert.equals(op, cairo.setOperator(op));
			Assert.equals(op, cairo.getOperator());
		}

		Assert.equals(CairoStatus.SUCCESS, cairo.status());
	}

	public function testDashIsReadBackAsSet():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.dash = [4.5, 1.5, 2];

		Assert.equals(3, cairo.dashCount);
		Assert.same([4.5, 1.5, 2.0], cairo.dash);

		cairo.dash = [7];

		Assert.equals(1, cairo.dashCount);
		Assert.same([7.0], cairo.dash);
	}

	public function testAnEmptyDashTurnsDashingOff():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.dash = [3, 1];
		cairo.dash = [];

		Assert.equals(0, cairo.dashCount);
		Assert.same([], cairo.dash);
		Assert.equals(CairoStatus.SUCCESS, cairo.status());
	}

	public function testSettersGiveBackTheValueSet():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		Assert.floatEquals(6.5, cairo.lineWidth = 6.5);
		Assert.floatEquals(3.0, cairo.miterLimit = 3);
		Assert.floatEquals(0.5, cairo.tolerance = 0.5);
		Assert.equals(CairoLineCap.SQUARE, cairo.lineCap = CairoLineCap.SQUARE);
		Assert.equals(CairoLineJoin.BEVEL, cairo.lineJoin = CairoLineJoin.BEVEL);
		Assert.equals(CairoFillRule.EVEN_ODD, cairo.fillRule = CairoFillRule.EVEN_ODD);
		Assert.equals(CairoAntialias.NONE, cairo.antialias = CairoAntialias.NONE);
		Assert.same([2.0, 5.0], cairo.dash = [2.0, 5.0]);
	}

	public function testRestoreBringsBackTheSavedSettings():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.lineWidth = 3.5;
		cairo.lineCap = CairoLineCap.ROUND;
		cairo.lineJoin = CairoLineJoin.BEVEL;
		cairo.miterLimit = 4;
		cairo.dash = [3, 1];
		cairo.fillRule = CairoFillRule.EVEN_ODD;
		cairo.antialias = CairoAntialias.NONE;
		cairo.tolerance = 0.5;
		cairo.setOperator(CairoOperator.ADD);
		cairo.translate(3, 5);

		cairo.save();
		cairo.lineWidth = 9;
		cairo.lineCap = CairoLineCap.SQUARE;
		cairo.lineJoin = CairoLineJoin.ROUND;
		cairo.miterLimit = 2;
		cairo.dash = [8];
		cairo.fillRule = CairoFillRule.WINDING;
		cairo.antialias = CairoAntialias.GRAY;
		cairo.tolerance = 2;
		cairo.setOperator(CairoOperator.XOR);
		cairo.scale(2, 2);
		cairo.restore();

		Assert.floatEquals(3.5, cairo.lineWidth);
		Assert.equals(CairoLineCap.ROUND, cairo.lineCap);
		Assert.equals(CairoLineJoin.BEVEL, cairo.lineJoin);
		Assert.floatEquals(4.0, cairo.miterLimit);
		Assert.same([3.0, 1.0], cairo.dash);
		Assert.equals(CairoFillRule.EVEN_ODD, cairo.fillRule);
		Assert.equals(CairoAntialias.NONE, cairo.antialias);
		Assert.floatEquals(0.5, cairo.tolerance);
		Assert.equals(CairoOperator.ADD, cairo.getOperator());
		assertMatrix([1, 0, 0, 1, 3, 5], cairo.matrix);
		Assert.equals(CairoStatus.SUCCESS, cairo.status());
	}

	public function testRestoreBringsBackTheSavedSourceAndClip():Void
	{
		var fixture = new CairoFixture(4, 2);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.save();
		cairo.setSourceRGB(0, 0, 1);
		cairo.rectangle(0, 0, 2, 2);
		cairo.clip();
		cairo.restore();
		cairo.paint();

		fixture.assertRows(["RRRR", "RRRR"]);
	}

	public function testSavedStatesAreRestoredLastFirst():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.lineWidth = 1;
		cairo.save();
		cairo.lineWidth = 2;
		cairo.save();
		cairo.lineWidth = 3;

		cairo.restore();
		Assert.floatEquals(2.0, cairo.lineWidth);
		cairo.restore();
		Assert.floatEquals(1.0, cairo.lineWidth);
		Assert.equals(CairoStatus.SUCCESS, cairo.status());
	}

	public function testRestoreWithoutSaveIsAnInvalidRestore():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.restore();

		Assert.equals(CairoStatus.INVALID_RESTORE, cairo.status());
	}

	public function testPopGroupWithoutPushGroupIsAnInvalidPopGroup():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.popGroupToSource();

		Assert.equals(CairoStatus.INVALID_POP_GROUP, cairo.status());
	}

	public function testARelativeLineWithoutACurrentPointIsAnError():Void
	{
		var line = new CairoFixture(4, 4).cairo;
		line.relLineTo(1, 1);
		Assert.equals(CairoStatus.NO_CURRENT_POINT, line.status());

		var move = new CairoFixture(4, 4).cairo;
		move.relMoveTo(1, 1);
		Assert.equals(CairoStatus.NO_CURRENT_POINT, move.status());

		var curve = new CairoFixture(4, 4).cairo;
		curve.relCurveTo(1, 1, 2, 2, 3, 3);
		Assert.equals(CairoStatus.NO_CURRENT_POINT, curve.status());
	}

	public function testAMatrixThatCannotBeInvertedIsAnInvalidMatrix():Void
	{
		var set = new CairoFixture(4, 4).cairo;
		set.matrix = new Matrix3(0, 0, 0, 0, 0, 0);
		Assert.equals(CairoStatus.INVALID_MATRIX, set.status());

		var transformed = new CairoFixture(4, 4).cairo;
		transformed.transform(new Matrix3(1, 2, 2, 4, 0, 0));
		Assert.equals(CairoStatus.INVALID_MATRIX, transformed.status());

		var scaled = new CairoFixture(4, 4).cairo;
		scaled.scale(0, 1);
		Assert.equals(CairoStatus.INVALID_MATRIX, scaled.status());
	}

	public function testADashThatIsNegativeOrAllZerosIsAnInvalidDash():Void
	{
		var negative = new CairoFixture(4, 4).cairo;
		negative.dash = [2, -1];
		Assert.equals(CairoStatus.INVALID_DASH, negative.status());

		var zeros = new CairoFixture(4, 4).cairo;
		zeros.dash = [0, 0];
		Assert.equals(CairoStatus.INVALID_DASH, zeros.status());
	}

	public function testAContextInErrorStaysInErrorAndDrawsNothing():Void
	{
		var fixture = new CairoFixture(2, 2);
		var cairo = fixture.cairo;

		cairo.restore();
		cairo.save();
		cairo.setSourceRGB(1, 0, 0);
		cairo.paint();
		cairo.restore();

		Assert.equals(CairoStatus.INVALID_RESTORE, cairo.status());
		fixture.assertRows(["..", ".."]);
	}

	public function testTargetIsTheSurfaceTheContextDrawsTo():Void
	{
		var fixture = new CairoFixture(5, 3);
		var target:CairoImageSurface = fixture.cairo.target;

		Assert.equals(5, target.width);
		Assert.equals(3, target.height);

		var other = new Cairo(target);
		other.setSourceRGB(0, 1, 0);
		other.rectangle(4, 2, 1, 1);
		other.fill();

		fixture.assertRows([".....", ".....", "....G"]);
	}

	public function testCopyPageKeepsWhatWasDrawn():Void
	{
		var fixture = new CairoFixture(2, 1);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.paint();
		cairo.copyPage();

		Assert.equals(CairoStatus.SUCCESS, cairo.status());
		fixture.assertRows(["RR"]);
	}

	public function testShowPageLeavesTheContextUsable():Void
	{
		var fixture = new CairoFixture(2, 1);
		var cairo = fixture.cairo;

		cairo.showPage();
		cairo.setSourceRGB(0, 0, 1);
		cairo.paint();

		Assert.equals(CairoStatus.SUCCESS, cairo.status());
		fixture.assertRows(["BB"]);
	}

	public function testVersionStringSpellsOutTheEncodedVersion():Void
	{
		var version = Cairo.version;
		var major = Std.int(version / 10000);
		var minor = Std.int(version / 100) % 100;
		var micro = version % 100;

		Assert.isTrue(major >= 1, "version " + version);
		Assert.equals(major + "." + minor + "." + micro, Cairo.versionString);
	}

	public function testARenderContextForwardsToItsCairoContext():Void
	{
		var fixture = new CairoFixture(2, 1);
		var context:CairoRenderContext = fixture.cairo;

		context.setSourceRGB(0, 1, 0);
		context.paint();
		context.lineWidth = 5;

		var cairo:Cairo = context;
		Assert.floatEquals(5.0, cairo.lineWidth);
		fixture.assertRows(["GG"]);
	}
	#end
}
