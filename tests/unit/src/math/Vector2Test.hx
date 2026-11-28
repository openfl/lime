package math;

import lime.math.Vector2;
import math.MathAssert.*;
import utest.Assert;
import utest.Test;

// Vector2 mirrors Flash's flash.geom.Point
class Vector2Test extends Test
{
	public function new()
	{
		super();
	}

	public function testNewVectorIsTheOrigin():Void
	{
		vector2(0, 0, new Vector2());
		vector2(3, -4, new Vector2(3, -4));
	}

	public function testLength():Void
	{
		var v = new Vector2(3, -4);
		near(5, v.length);
		near(25, v.lengthSquared);
	}

	public function testAddReturnsANewVector():Void
	{
		var v = new Vector2(1, 2);
		var sum = v.add(new Vector2(10, 20));
		vector2(11, 22, sum);
		vector2(1, 2, v, "the vector itself is unchanged");
		Assert.isFalse(sum == v, "a new vector");
	}

	public function testSubtractTakesTheOtherVectorAway():Void
	{
		// Flash: "Subtracts the coordinates of another point from the
		// coordinates of this point to create a new point"
		var v = new Vector2(5, 7);
		vector2(4, 5, v.subtract(new Vector2(1, 2)));
		vector2(5, 7, v, "the vector itself is unchanged");
	}

	public function testAddAndSubtractFillTheResultGiven():Void
	{
		var v = new Vector2(5, 7);
		var result = new Vector2();
		Assert.isTrue(v.add(new Vector2(1, 2), result) == result, "add returns the result given");
		vector2(6, 9, result);
		Assert.isTrue(v.subtract(new Vector2(1, 2), result) == result, "subtract returns the result given");
		vector2(4, 5, result);
	}

	public function testCloneIsIndependent():Void
	{
		var v = new Vector2(1, 2);
		var copy = v.clone();
		vector2(1, 2, copy);
		copy.x = 10;
		near(1, v.x, "original after changing the clone");
	}

	public function testEquals():Void
	{
		var v = new Vector2(1, 2);
		Assert.isTrue(v.equals(new Vector2(1, 2)));
		Assert.isFalse(v.equals(new Vector2(1, 3)), "y differs");
		Assert.isFalse(v.equals(new Vector2(0, 2)), "x differs");
	}

	public function testSetTo():Void
	{
		var v = new Vector2(1, 2);
		v.setTo(-3, 4);
		vector2(-3, 4, v);
	}

	public function testDistance():Void
	{
		near(5, Vector2.distance(new Vector2(1, 1), new Vector2(4, 5)));
		near(5, Vector2.distance(new Vector2(4, 5), new Vector2(1, 1)), "either way round");
		near(0, Vector2.distance(new Vector2(2, 2), new Vector2(2, 2)), "the same point");
	}

	public function testInterpolateUsesFlashArgumentOrder():Void
	{
		// Flash: the closer f is to 1, the closer the result is to pt1; the
		// closer f is to 0, the closer it is to pt2
		var pt1 = new Vector2(0, 0);
		var pt2 = new Vector2(10, 20);
		vector2(0, 0, Vector2.interpolate(pt1, pt2, 1), "f = 1");
		vector2(10, 20, Vector2.interpolate(pt1, pt2, 0), "f = 0");
		vector2(7.5, 15, Vector2.interpolate(pt1, pt2, 0.25), "f = 0.25");
	}

	public function testInterpolateFillsTheResultGiven():Void
	{
		var result = new Vector2();
		var returned = Vector2.interpolate(new Vector2(0, 0), new Vector2(10, 20), 0.5, result);
		Assert.isTrue(returned == result, "returns the result given");
		vector2(5, 10, result);
	}

	public function testPolarTakesRadians():Void
	{
		// Flash: polar(len, angle) gives (len * cos(angle), len * sin(angle)), angle in radians
		vector2(2, 0, Vector2.polar(2, 0), "angle 0");
		vector2(0, 2, Vector2.polar(2, Math.PI / 2), "angle PI / 2");
		vector2(-2, 0, Vector2.polar(2, Math.PI), "angle PI");
		vector2(Math.sqrt(2), Math.sqrt(2), Vector2.polar(2, Math.PI / 4), "angle PI / 4");
	}

	public function testPolarFillsTheResultGiven():Void
	{
		var result = new Vector2(9, 9);
		var returned = Vector2.polar(3, 0, result);
		Assert.isTrue(returned == result, "returns the result given");
		vector2(3, 0, result);
	}

	public function testNormalizeScalesToTheThickness():Void
	{
		// The documented example: (0, 5) normalized to 1 is (0, 1)
		var v = new Vector2(0, 5);
		v.normalize(1);
		vector2(0, 1, v);

		var w = new Vector2(3, 4);
		w.normalize(10);
		vector2(6, 8, w);
	}

	public function testNormalizeLeavesTheOriginAlone():Void
	{
		// There is no direction to scale along; Flash leaves (0, 0) as it is
		var v = new Vector2(0, 0);
		v.normalize(1);
		vector2(0, 0, v);
	}

	public function testOffsetMovesTheVector():Void
	{
		var v = new Vector2(1, 2);
		v.offset(10, -20);
		vector2(11, -18, v);
	}
}
