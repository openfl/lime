package math;

import lime.math.Matrix3;
import lime.math.Vector2;
import lime.math.Vector4;
import lime.utils.Float32Array;
import math.MathAssert.*;
import utest.Assert;
import utest.Test;

// Matrix3 mirrors Flash's flash.geom.Matrix:
//
//     [ a, c, tx ]
//     [ b, d, ty ]
//     [ 0, 0,  1 ]
//
// A point (x, y) becomes (a * x + c * y + tx, b * x + d * y + ty).
class Matrix3Test extends Test
{
	public function new()
	{
		super();
	}

	public function testNewMatrixIsIdentity():Void
	{
		matrix3(1, 0, 0, 1, 0, 0, new Matrix3());
	}

	public function testConstructorSetsEachComponent():Void
	{
		matrix3(1, 2, 3, 4, 5, 6, new Matrix3(1, 2, 3, 4, 5, 6));
	}

	public function testValuesAreStoredInColumnMajorOrder():Void
	{
		// The documented layout, column by column: (a, b, 0), (c, d, 0), (tx, ty, 1)
		var m = new Matrix3(1, 2, 3, 4, 5, 6);
		var expected = [1.0, 2, 0, 3, 4, 0, 5, 6, 1];

		for (i in 0...9)
		{
			near(expected[i], m[i], "index " + i);
		}
	}

	public function testConvertsFromAColumnMajorArrayOfNine():Void
	{
		var m:Matrix3 = new Float32Array([1.0, 2, 0, 3, 4, 0, 5, 6, 1]);
		matrix3(1, 2, 3, 4, 5, 6, m);
	}

	public function testConvertingFromAnArrayOfTheWrongLengthThrows():Void
	{
		Assert.raises(function()
		{
			var m:Matrix3 = new Float32Array([1.0, 0, 0, 1, 0, 0]);
			m.identity();
		});
	}

	public function testSetToReplacesEachComponent():Void
	{
		var m = new Matrix3();
		m.setTo(6, 5, 4, 3, 2, 1);
		matrix3(6, 5, 4, 3, 2, 1, m);
	}

	public function testIdentityResetsTheMatrix():Void
	{
		var m = new Matrix3(2, 3, 4, 5, 6, 7);
		m.identity();
		matrix3(1, 0, 0, 1, 0, 0, m);
	}

	public function testCloneIsIndependent():Void
	{
		var m = new Matrix3(1, 2, 3, 4, 5, 6);
		var copy = m.clone();
		matrix3(1, 2, 3, 4, 5, 6, copy);

		copy.a = 10;
		copy.tx = 20;
		near(1, m.a, "original a after changing the clone");
		near(5, m.tx, "original tx after changing the clone");
	}

	public function testCopyFromCopiesEachComponent():Void
	{
		var source = new Matrix3(1, 2, 3, 4, 5, 6);
		var m = new Matrix3();
		m.copyFrom(source);
		matrix3(1, 2, 3, 4, 5, 6, m);

		source.a = 10;
		near(1, m.a, "copy after changing the source");
	}

	public function testEqualsComparesEveryComponent():Void
	{
		var m = new Matrix3(1, 2, 3, 4, 5, 6);
		Assert.isTrue(m.equals(new Matrix3(1, 2, 3, 4, 5, 6)));
		Assert.isFalse(m.equals(new Matrix3(9, 2, 3, 4, 5, 6)), "a differs");
		Assert.isFalse(m.equals(new Matrix3(1, 9, 3, 4, 5, 6)), "b differs");
		Assert.isFalse(m.equals(new Matrix3(1, 2, 9, 4, 5, 6)), "c differs");
		Assert.isFalse(m.equals(new Matrix3(1, 2, 3, 9, 5, 6)), "d differs");
		Assert.isFalse(m.equals(new Matrix3(1, 2, 3, 4, 9, 6)), "tx differs");
		Assert.isFalse(m.equals(new Matrix3(1, 2, 3, 4, 5, 9)), "ty differs");
	}

	public function testTransformVectorAppliesTheWholeMatrix():Void
	{
		var m = new Matrix3(2, 3, 4, 5, 6, 7);
		// (2 * 1 + 4 * 10 + 6, 3 * 1 + 5 * 10 + 7)
		vector2(48, 60, m.transformVector(new Vector2(1, 10)));
	}

	public function testDeltaTransformVectorIgnoresTranslation():Void
	{
		var m = new Matrix3(2, 3, 4, 5, 6, 7);
		vector2(42, 53, m.deltaTransformVector(new Vector2(1, 10)));
	}

	public function testTransformVectorFillsTheResultGiven():Void
	{
		var m = new Matrix3(1, 0, 0, 1, 5, 6);
		var result = new Vector2();
		var returned = m.transformVector(new Vector2(1, 2), result);
		Assert.isTrue(returned == result, "returns the result given");
		vector2(6, 8, result);

		var delta = new Vector2();
		var returnedDelta = m.deltaTransformVector(new Vector2(1, 2), delta);
		Assert.isTrue(returnedDelta == delta, "returns the result given");
		vector2(1, 2, delta);
	}

	public function testTransformVectorLeavesTheInputAlone():Void
	{
		var m = new Matrix3(2, 0, 0, 2, 5, 6);
		var point = new Vector2(1, 2);
		m.transformVector(point);
		m.deltaTransformVector(point);
		vector2(1, 2, point);
	}

	public function testTranslateAddsToTheTranslationOnly():Void
	{
		// Flash's translate() moves tx and ty, whatever the matrix scales by
		var m = new Matrix3(2, 0, 0, 3, 1, 1);
		m.translate(10, 20);
		matrix3(2, 0, 0, 3, 11, 21, m);
	}

	public function testScaleAppliesAfterTheExistingTransform():Void
	{
		// Flash's scale() scales a, c and tx by sx, and b, d and ty by sy
		var m = new Matrix3(1, 2, 3, 4, 5, 6);
		m.scale(10, 100);
		matrix3(10, 200, 30, 400, 50, 600, m);
	}

	public function testScaleAfterTranslateScalesTheTranslation():Void
	{
		var m = new Matrix3();
		m.translate(10, 20);
		m.scale(2, 3);
		matrix3(2, 0, 0, 3, 20, 60, m);
	}

	public function testTranslateAfterScaleIsNotScaled():Void
	{
		var m = new Matrix3();
		m.scale(2, 3);
		m.translate(10, 20);
		matrix3(2, 0, 0, 3, 10, 20, m);
	}

	@Ignored("Waiting on #2137")
	public function testRotateTakesDegreesAsDocumented():Void
	{
		// The doc comment for rotate() gives theta in degrees. A quarter turn
		// takes (1, 0) to (0, 1), as Flash's rotate(Math.PI / 2) does.
		var m = new Matrix3();
		m.rotate(90);
		matrix3(0, 1, -1, 0, 0, 0, m);
	}

	public function testRotateAppliesAfterTheExistingTransform():Void
	{
		// Whatever the unit, rotating after a translation rotates the
		// translation too, by the same rotation as the a, b, c, d part
		var m = new Matrix3();
		m.translate(3, 4);
		m.rotate(0.7);

		var cos = m.a;
		var sin = m.b;
		Assert.isTrue(Math.abs(sin) > 1e-4, "rotate(0.7) turned the matrix, b was " + sin);
		near(1, cos * cos + sin * sin, "a² + b² for a pure rotation");
		near(cos, m.d, "d equals a for a pure rotation");
		near(-sin, m.c, "c equals -b for a pure rotation");
		near(3 * cos - 4 * sin, m.tx, "tx is the rotated translation");
		near(3 * sin + 4 * cos, m.ty, "ty is the rotated translation");
	}

	public function testRotateAfterScaleKeepsTheScaleOnEachAxis():Void
	{
		// scale(2, 3) then rotate(t): a = 2cos, b = 2sin, c = -3sin, d = 3cos.
		// Rotating first and scaling second would give b = 3sin, c = -2sin.
		var m = new Matrix3();
		m.scale(2, 3);
		m.rotate(0.7);

		near(m.a / 2, m.d / 3, "cos from a and from d");
		near(m.b / 2, -m.c / 3, "sin from b and from c");
		Assert.isTrue(Math.abs(m.b) > 1e-4, "rotate(0.7) turned the matrix");
	}

	public function testConcatAppliesTheSecondMatrixAfterTheFirst():Void
	{
		// Flash: m1.concat(m2) transforms a point by m1, then by m2
		var m1 = new Matrix3(1, 0, 0, 1, 10, 0);
		var m2 = new Matrix3(2, 0, 0, 2, 0, 0);
		m1.concat(m2);
		matrix3(2, 0, 0, 2, 20, 0, m1);
		vector2(22, 0, m1.transformVector(new Vector2(1, 0)));
	}

	public function testConcatMatchesMatrixMultiplication():Void
	{
		var m1 = new Matrix3(1, 2, 3, 4, 5, 6);
		var m2 = new Matrix3(7, 8, 9, 10, 11, 12);
		var point = new Vector2(-3, 5);
		var expected = m2.transformVector(m1.transformVector(point));

		var product = m1.clone();
		product.concat(m2);

		// m2 * m1 in the documented layout
		matrix3(1 * 7 + 2 * 9, 1 * 8 + 2 * 10, 3 * 7 + 4 * 9, 3 * 8 + 4 * 10, 5 * 7 + 6 * 9 + 11, 5 * 8 + 6 * 10 + 12, product);
		vector2(expected.x, expected.y, product.transformVector(point));
		matrix3(7, 8, 9, 10, 11, 12, m2, "the second matrix is not modified");
	}

	public function testInvertUndoesTheTransform():Void
	{
		var m = new Matrix3(2, 0, 0, 4, 10, 20);
		m.invert();
		matrix3(0.5, 0, 0, 0.25, -5, -5, m);
	}

	public function testInvertOfAGeneralMatrixGivesTheIdentityWhenConcatenated():Void
	{
		var m = new Matrix3(1, 2, 3, 4, 5, 6);
		var inverse = m.clone();
		inverse.invert();

		var product = m.clone();
		product.concat(inverse);
		matrix3(1, 0, 0, 1, 0, 0, product, "m then its inverse");

		product = inverse.clone();
		product.concat(m);
		matrix3(1, 0, 0, 1, 0, 0, product, "the inverse then m");

		var point = new Vector2(7, -3);
		vector2(7, -3, inverse.transformVector(m.transformVector(point)), "point round trip");
	}

	public function testInvertReturnsTheSameMatrix():Void
	{
		var m = new Matrix3(2, 0, 0, 2, 0, 0);
		var returned = m.invert();
		matrix3(0.5, 0, 0, 0.5, 0, 0, returned);

		returned.tx = 42;
		near(42, m.tx, "changing the returned matrix changes the original");
	}

	public function testInvertOfASingularMatrixStaysFinite():Void
	{
		// A singular matrix has no inverse; it must not fill with NaN or infinity
		var m = new Matrix3(1, 2, 2, 4, 5, 6);
		m.invert();

		for (value in [m.a, m.b, m.c, m.d, m.tx, m.ty])
		{
			Assert.isFalse(Math.isNaN(value) || !Math.isFinite(value), "singular invert gave " + describeMatrix3(m));
		}
	}

	public function testCreateBoxMatchesIdentityRotateScaleTranslate():Void
	{
		// Documented as the same as identity(), rotate(), scale() then translate()
		var expected = new Matrix3(5, 6, 7, 8, 9, 10);
		expected.identity();
		expected.rotate(0.6);
		expected.scale(2, 3);
		expected.translate(10, 20);

		var m = new Matrix3(5, 6, 7, 8, 9, 10);
		m.createBox(2, 3, 0.6, 10, 20);
		sameMatrix3(expected, m);
	}

	public function testCreateBoxWithoutRotation():Void
	{
		var m = new Matrix3(5, 6, 7, 8, 9, 10);
		m.createBox(2, 3, 0, 10, 20);
		matrix3(2, 0, 0, 3, 10, 20, m);

		m.createBox(4, 5);
		matrix3(4, 0, 0, 5, 0, 0, m, "default rotation and translation");
	}

	public function testCreateGradientBoxScalesTo1638Point4AndCentres():Void
	{
		// Flash's gradient square spans -819.2 to 819.2, so its scale is
		// width / 1638.4 and height / 1638.4, and it is centred on the box
		var m = new Matrix3();
		m.createGradientBox(200, 100, 0, 10, 20);
		matrix3(200 / 1638.4, 0, 0, 100 / 1638.4, 110, 70, m);
	}

	public function testCreateGradientBoxIsACreateBoxOfTheScaledSize():Void
	{
		// Flash: "width and height are scaled to a scaleX/scaleY pair and the
		// tx/ty values are offset by half the width and height"
		var expected = new Matrix3();
		expected.createBox(200 / 1638.4, 100 / 1638.4, 0.6, 10 + 100, 20 + 50);

		var m = new Matrix3();
		m.createGradientBox(200, 100, 0.6, 10, 20);
		sameMatrix3(expected, m);
	}

	public function testCreateGradientBoxRotationKeepsTheScaleOfEachAxis():Void
	{
		var m = new Matrix3();
		m.createGradientBox(200, 100, 0.6);

		var sx = 200 / 1638.4;
		var sy = 100 / 1638.4;
		near(sx * sx, m.a * m.a + m.c * m.c, "a² + c²");
		near(sy * sy, m.b * m.b + m.d * m.d, "b² + d²");
		Assert.isTrue(m.b > 0 && m.c < 0, "a positive rotation gives b > 0 and c < 0, was " + describeMatrix3(m));
		near(100, m.tx, "rotation does not move the centre");
		near(50, m.ty, "rotation does not move the centre");
	}

	public function testCopyColumnToFollowsTheDocumentedLayout():Void
	{
		// Columns are (a, b, 0), (c, d, 0) and (tx, ty, 1); w is left alone
		var m = new Matrix3(1, 2, 3, 4, 5, 6);
		var v = new Vector4(-1, -1, -1, 99);

		m.copyColumnTo(0, v);
		vector4(1, 2, 0, 99, v, "column 0");
		m.copyColumnTo(1, v);
		vector4(3, 4, 0, 99, v, "column 1");
		m.copyColumnTo(2, v);
		vector4(5, 6, 1, 99, v, "column 2");
	}

	public function testCopyRowToFollowsTheDocumentedLayout():Void
	{
		// Rows are (a, c, tx), (b, d, ty) and (0, 0, 1); w is left alone
		var m = new Matrix3(1, 2, 3, 4, 5, 6);
		var v = new Vector4(-1, -1, -1, 99);

		m.copyRowTo(0, v);
		vector4(1, 3, 5, 99, v, "row 0");
		m.copyRowTo(1, v);
		vector4(2, 4, 6, 99, v, "row 1");
		m.copyRowTo(2, v);
		vector4(0, 0, 1, 99, v, "row 2");
	}

	public function testCopyColumnFromSetsOneColumn():Void
	{
		var m = new Matrix3();
		m.copyColumnFrom(0, new Vector4(1, 2, 7, 7));
		matrix3(1, 2, 0, 1, 0, 0, m, "column 0");

		m.identity();
		m.copyColumnFrom(1, new Vector4(3, 4, 7, 7));
		matrix3(1, 0, 3, 4, 0, 0, m, "column 1");

		m.identity();
		m.copyColumnFrom(2, new Vector4(5, 6, 7, 7));
		matrix3(1, 0, 0, 1, 5, 6, m, "column 2");
	}

	public function testCopyRowFromSetsOneRow():Void
	{
		var m = new Matrix3();
		m.copyRowFrom(0, new Vector4(1, 3, 5, 7));
		matrix3(1, 0, 3, 1, 5, 0, m, "row 0");

		m.identity();
		m.copyRowFrom(1, new Vector4(2, 4, 6, 7));
		matrix3(1, 2, 0, 4, 0, 6, m, "row 1");
	}
}
