package graphics;

#if (lime_cffi && lime_cairo && !macro)
import graphics.CairoFixture.*;
import lime.graphics.cairo.CairoStatus;
import lime.math.Matrix3;
#end
import utest.Assert;
import utest.Test;

/**
	The transformation from user space to the pixels of the surface. The
	cairo manual (cairographics.org/manual/cairo-Transformations.html and
	cairo-cairo-matrix-t.html) has each call change user space, so the last
	one called is the first applied to a point, and maps a point with

		x' = xx * x + xy * y + x0
		y' = yx * x + yy * y + y0

	`lime.math.Matrix3` documents its members as the same matrix with `a`,
	`b`, `c`, `d`, `tx` and `ty` standing for `xx`, `yx`, `xy`, `yy`, `x0`
	and `y0`. It keeps them as 32-bit floats, so the values here are ones
	a 32-bit float holds exactly.
**/
class CairoTransformTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_cairo && !macro)
	public function testANewContextHasTheIdentityMatrix():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		assertMatrix([1, 0, 0, 1, 0, 0], cairo.matrix);
	}

	public function testTranslateMovesTheOrigin():Void
	{
		var fixture = new CairoFixture(6, 4);
		var cairo = fixture.cairo;

		cairo.translate(3, 1);
		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 2, 1);
		cairo.fill();

		fixture.assertRows(["......", "...RR.", "......", "......"]);
		assertMatrix([1, 0, 0, 1, 3, 1], cairo.matrix);
	}

	public function testScaleStretchesEachAxisByItsOwnFactor():Void
	{
		var fixture = new CairoFixture(6, 6);
		var cairo = fixture.cairo;

		cairo.scale(2, 3);
		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(1, 1, 1, 1);
		cairo.fill();

		fixture.assertRows([
			"......",
			"......",
			"......",
			"..RR..",
			"..RR..",
			"..RR.."
		]);
		assertMatrix([2, 0, 0, 3, 0, 0], cairo.matrix);
	}

	public function testRotateTurnsThePositiveXAxisTowardThePositiveYAxis():Void
	{
		var fixture = new CairoFixture(8, 6);
		var cairo = fixture.cairo;

		// A quarter turn sends (x, y) to (-y, x), so this lands on
		// x from 5 to 6 and y from 1 to 5
		cairo.translate(8, 0);
		cairo.rotate(Math.PI / 2);
		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(1, 2, 4, 1);
		cairo.fill();

		fixture.assertRows([
			"........",
			".....R..",
			".....R..",
			".....R..",
			".....R..",
			"........"
		]);
	}

	public function testMatrixGivesARotationItsSineAndCosine():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.rotate(Math.PI / 6);

		assertMatrix([Math.cos(Math.PI / 6), 0.5, -0.5, Math.cos(Math.PI / 6), 0, 0], cairo.matrix);
	}

	public function testTheLastTransformationCalledIsAppliedToAPointFirst():Void
	{
		var translated = new CairoFixture(4, 4).cairo;
		translated.translate(3, 5);
		translated.scale(2, 4);
		assertMatrix([2, 0, 0, 4, 3, 5], translated.matrix);

		var scaled = new CairoFixture(4, 4).cairo;
		scaled.scale(2, 4);
		scaled.translate(3, 5);
		assertMatrix([2, 0, 0, 4, 6, 20], scaled.matrix);
	}

	public function testTransformAppliesAMatrixToUserSpace():Void
	{
		var fixture = new CairoFixture(10, 10);
		var cairo = fixture.cairo;

		// x' = y + 6 and y' = 2x + 2, so the first axis of user space
		// runs down the image at twice the size
		cairo.transform(new Matrix3(0, 2, 1, 0, 6, 2));
		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 3, 1);
		cairo.fill();

		fixture.assertRows([
			"..........",
			"..........",
			"......R...",
			"......R...",
			"......R...",
			"......R...",
			"......R...",
			"......R...",
			"..........",
			".........."
		]);
		assertMatrix([0, 2, 1, 0, 6, 2], cairo.matrix);
	}

	public function testTransformIsAppliedBeforeTheMatrixAlreadyThere():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.translate(10, 20);
		cairo.transform(new Matrix3(2, 0, 0, 4, 3, 5));

		assertMatrix([2, 0, 0, 4, 13, 25], cairo.matrix);
	}

	public function testSettingTheMatrixReplacesTheOneThere():Void
	{
		var fixture = new CairoFixture(10, 10);
		var cairo = fixture.cairo;

		cairo.translate(100, 100);
		cairo.scale(7, 7);
		cairo.matrix = new Matrix3(0, 2, -1, 0, 9, 2);

		assertMatrix([0, 2, -1, 0, 9, 2], cairo.matrix);

		// x' = 9 - y and y' = 2x + 2
		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 3, 1);
		cairo.fill();

		fixture.assertRows([
			"..........",
			"..........",
			"........R.",
			"........R.",
			"........R.",
			"........R.",
			"........R.",
			"........R.",
			"..........",
			".........."
		]);
	}

	public function testMatrixReadsBackEveryMemberItWasSet():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.matrix = new Matrix3(1.5, -0.25, 0.75, 2.5, -30, 12.5);

		assertMatrix([1.5, -0.25, 0.75, 2.5, -30, 12.5], cairo.matrix);
		Assert.equals(CairoStatus.SUCCESS, cairo.status());
	}

	public function testIdentityMatrixRemovesEveryTransformation():Void
	{
		var fixture = new CairoFixture(4, 2);
		var cairo = fixture.cairo;

		cairo.translate(2, 1);
		cairo.scale(3, 3);
		cairo.rotate(1);
		cairo.identityMatrix();

		assertMatrix([1, 0, 0, 1, 0, 0], cairo.matrix);

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 1, 1);
		cairo.fill();

		fixture.assertRows(["R...", "...."]);
	}

	public function testThePathKeepsItsPlaceWhenUserSpaceChanges():Void
	{
		var fixture = new CairoFixture(6, 2);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 2, 1);
		cairo.translate(3, 1);
		cairo.fill();

		fixture.assertRows(["RR....", "......"]);
	}

	public function testTheCurrentPointIsGivenInUserSpace():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.moveTo(30, 40);
		cairo.translate(10, 20);
		assertPoint(20, 20, cairo.currentPoint);

		cairo.scale(4, 2);
		assertPoint(5, 10, cairo.currentPoint);
	}

	public function testHitTestsTakeUserSpaceCoordinates():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.rectangle(10, 20, 30, 5);
		cairo.translate(10, 20);

		Assert.isTrue(cairo.inFill(25, 2));
		Assert.isFalse(cairo.inFill(35, 22));
	}

	public function testTheLineWidthIsMeasuredInUserSpaceWhenStroking():Void
	{
		var fixture = new CairoFixture(8, 8);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.scale(2, 4);
		cairo.lineWidth = 1;
		cairo.moveTo(1, 1);
		cairo.lineTo(3, 1);
		cairo.stroke();

		fixture.assertRows([
			"........",
			"........",
			"..RRRR..",
			"..RRRR..",
			"..RRRR..",
			"..RRRR..",
			"........",
			"........"
		]);
	}

	public function testRestoreBringsBackTheSavedMatrix():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;

		cairo.translate(3, 5);
		cairo.save();
		cairo.scale(2, 2);
		cairo.rotate(1);
		cairo.restore();

		assertMatrix([1, 0, 0, 1, 3, 5], cairo.matrix);
	}
	#end
}
