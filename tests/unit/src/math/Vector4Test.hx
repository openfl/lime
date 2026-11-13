package math;

import lime.math.Vector4;
import math.MathAssert.*;
import utest.Assert;
import utest.Test;

// Vector4 mirrors Flash's flash.geom.Vector3D: most operations work on x, y and
// z, and leave w alone.
class Vector4Test extends Test
{
	public function new()
	{
		super();
	}

	public function testNewVectorIsZero():Void
	{
		vector4(0, 0, 0, 0, new Vector4());
		vector4(1, 2, 3, 4, new Vector4(1, 2, 3, 4));
	}

	public function testAxes():Void
	{
		vector3(1, 0, 0, Vector4.X_AXIS, "X_AXIS");
		vector3(0, 1, 0, Vector4.Y_AXIS, "Y_AXIS");
		vector3(0, 0, 1, Vector4.Z_AXIS, "Z_AXIS");
	}

	public function testLengthIgnoresW():Void
	{
		var v = new Vector4(2, 3, 6, 100);
		near(7, v.length);
		near(49, v.lengthSquared);
	}

	public function testAddReturnsANewVector():Void
	{
		var v = new Vector4(1, 2, 3, 4);
		var sum = v.add(new Vector4(10, 20, 30, 40));
		vector3(11, 22, 33, sum);
		vector4(1, 2, 3, 4, v, "the vector itself is unchanged");
		Assert.isFalse(sum == v, "a new vector");
	}

	public function testSubtractTakesTheOtherVectorAway():Void
	{
		var v = new Vector4(5, 7, 9, 1);
		vector3(4, 5, 6, v.subtract(new Vector4(1, 2, 3, 1)));
		vector4(5, 7, 9, 1, v, "the vector itself is unchanged");
	}

	public function testAddAndSubtractFillTheResultGiven():Void
	{
		var v = new Vector4(5, 7, 9);
		var result = new Vector4();
		Assert.isTrue(v.add(new Vector4(1, 2, 3), result) == result, "add returns the result given");
		vector3(6, 9, 12, result);
		Assert.isTrue(v.subtract(new Vector4(1, 2, 3), result) == result, "subtract returns the result given");
		vector3(4, 5, 6, result);
	}

	public function testIncrementAndDecrementByChangeXYZOnly():Void
	{
		var v = new Vector4(1, 2, 3, 4);
		v.incrementBy(new Vector4(10, 20, 30, 40));
		vector4(11, 22, 33, 4, v, "incrementBy");
		v.decrementBy(new Vector4(1, 2, 3, 4));
		vector4(10, 20, 30, 4, v, "decrementBy");
	}

	public function testScaleByScalesXYZOnly():Void
	{
		// Flash: "The Vector3D object's x, y, and z elements are multiplied by the scalar"
		var v = new Vector4(1, -2, 3, 4);
		v.scaleBy(2);
		vector4(2, -4, 6, 4, v);
	}

	public function testNegateNegatesXYZOnly():Void
	{
		var v = new Vector4(1, -2, 3, 4);
		v.negate();
		vector4(-1, 2, -3, 4, v);
	}

	public function testCrossProductOfTheAxes():Void
	{
		vector3(0, 0, 1, new Vector4(1, 0, 0).crossProduct(new Vector4(0, 1, 0)), "x cross y");
		vector3(1, 0, 0, new Vector4(0, 1, 0).crossProduct(new Vector4(0, 0, 1)), "y cross z");
		vector3(0, 1, 0, new Vector4(0, 0, 1).crossProduct(new Vector4(1, 0, 0)), "z cross x");
		vector3(0, 0, -1, new Vector4(0, 1, 0).crossProduct(new Vector4(1, 0, 0)), "y cross x");
	}

	public function testCrossProductOfAnyTwoVectors():Void
	{
		// (1, 2, 3) x (4, 5, 6) = (2 * 6 - 3 * 5, 3 * 4 - 1 * 6, 1 * 5 - 2 * 4)
		var a = new Vector4(1, 2, 3, 7);
		var b = new Vector4(4, 5, 6, 7);
		vector3(-3, 6, -3, a.crossProduct(b));
		vector4(1, 2, 3, 7, a, "the vector itself is unchanged");
	}

	public function testCrossProductFillsTheResultGiven():Void
	{
		var result = new Vector4();
		var returned = new Vector4(1, 0, 0).crossProduct(new Vector4(0, 1, 0), result);
		Assert.isTrue(returned == result, "returns the result given");
		vector3(0, 0, 1, result);
	}

	public function testDotProductIgnoresW():Void
	{
		near(32, new Vector4(1, 2, 3, 10).dotProduct(new Vector4(4, 5, 6, 10)));
		near(0, new Vector4(1, 0, 0).dotProduct(new Vector4(0, 1, 0)), "perpendicular");
	}

	public function testNormalizeReturnsThePreviousLength():Void
	{
		var v = new Vector4(3, 0, 4, 9);
		near(5, v.normalize());
		vector4(0.6, 0, 0.8, 9, v);
		near(1, v.length, "now a unit vector");
	}

	public function testNormalizeLeavesTheZeroVectorFinite():Void
	{
		var v = new Vector4(0, 0, 0, 1);
		var length = v.normalize();
		near(0, length, "the previous length");
		vector3(0, 0, 0, v);
	}

	public function testAngleBetweenIsInRadians():Void
	{
		// Flash: "Returns the angle in radians between two vectors"
		near(Math.PI / 2, Vector4.angleBetween(new Vector4(1, 0, 0), new Vector4(0, 1, 0)), "perpendicular");
		near(0, Vector4.angleBetween(new Vector4(1, 2, 3), new Vector4(2, 4, 6)), "parallel");
		near(Math.PI, Vector4.angleBetween(new Vector4(1, 0, 0), new Vector4(-1, 0, 0)), "opposite");
		near(Math.PI / 4, Vector4.angleBetween(new Vector4(1, 1, 0), new Vector4(3, 0, 0)), "eighth of a turn");
	}

	public function testDistanceIgnoresW():Void
	{
		var a = new Vector4(1, 2, 3, 0);
		var b = new Vector4(3, 5, 9, 100);
		near(7, Vector4.distance(a, b));
		near(49, Vector4.distanceSquared(a, b));
		near(7, Vector4.distance(b, a), "either way round");
	}

	public function testEqualsComparesWOnlyWhenAsked():Void
	{
		var v = new Vector4(1, 2, 3, 4);
		Assert.isTrue(v.equals(new Vector4(1, 2, 3, 4)));
		Assert.isTrue(v.equals(new Vector4(1, 2, 3, 5)), "w differs, not compared");
		Assert.isFalse(v.equals(new Vector4(1, 2, 3, 5), true), "w differs, compared");
		Assert.isTrue(v.equals(new Vector4(1, 2, 3, 4), true), "w the same, compared");
		Assert.isFalse(v.equals(new Vector4(1, 2, 4, 4)), "z differs");
		Assert.isFalse(v.equals(new Vector4(1, 3, 3, 4)), "y differs");
		Assert.isFalse(v.equals(new Vector4(0, 2, 3, 4)), "x differs");
	}

	public function testNearEqualsWithinTheTolerance():Void
	{
		var v = new Vector4(1, 2, 3, 4);
		Assert.isTrue(v.nearEquals(new Vector4(1.05, 2, 3, 4), 0.1), "x 0.05 above");
		Assert.isTrue(v.nearEquals(new Vector4(0.95, 2, 3, 4), 0.1), "x 0.05 below");
		Assert.isFalse(v.nearEquals(new Vector4(1.05, 2, 3, 4), 0.01), "x 0.05 above, tolerance 0.01");
		Assert.isFalse(v.nearEquals(new Vector4(0.5, 2, 3, 4), 0.1), "x 0.5 below");
		Assert.isFalse(v.nearEquals(new Vector4(1, 2.5, 3, 4), 0.1), "y 0.5 above");
		Assert.isFalse(v.nearEquals(new Vector4(1, 2, 2.5, 4), 0.1), "z 0.5 below");
	}

	public function testNearEqualsComparesWOnlyWhenAsked():Void
	{
		var v = new Vector4(1, 2, 3, 4);
		Assert.isTrue(v.nearEquals(new Vector4(1, 2, 3, 9), 0.1), "w differs, not compared");
		Assert.isFalse(v.nearEquals(new Vector4(1, 2, 3, 9), 0.1, true), "w differs, compared");
		Assert.isFalse(v.nearEquals(new Vector4(1, 2, 3, -1), 0.1, true), "w far below, compared");
		Assert.isTrue(v.nearEquals(new Vector4(1, 2, 3, 4.05), 0.1, true), "w near, compared");
	}

	public function testProjectDividesByW():Void
	{
		var v = new Vector4(2, 4, 6, 2);
		v.project();
		vector4(1, 2, 3, 2, v);
	}

	public function testCloneCopiesAllFour():Void
	{
		var v = new Vector4(1, 2, 3, 4);
		var copy = v.clone();
		vector4(1, 2, 3, 4, copy);
		copy.x = 10;
		near(1, v.x, "original after changing the clone");
	}

	public function testCopyFromCopiesXYZ():Void
	{
		var v = new Vector4();
		v.copyFrom(new Vector4(1, 2, 3, 4));
		vector3(1, 2, 3, v);
	}

	public function testSetToSetsXYZ():Void
	{
		var v = new Vector4(0, 0, 0, 4);
		v.setTo(1, 2, 3);
		vector4(1, 2, 3, 4, v);
	}
}
