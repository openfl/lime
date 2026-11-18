package math;

import haxe.PosInfos;
import lime.math.Matrix3;
import lime.math.Matrix4;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.math.Vector4;
import utest.Assert;

/**
	Float comparisons for the math suites. `Matrix3`, `Matrix4` and `ColorMatrix`
	keep their values in a `Float32Array`, so the tolerance allows for single
	precision, relative to the size of the values compared.
**/
class MathAssert
{
	public static inline var EPSILON:Float = 1e-5;

	public static function isNear(expected:Float, actual:Float, epsilon:Float = EPSILON):Bool
	{
		if (Math.isNaN(expected) || Math.isNaN(actual)) return false;
		if (expected == actual) return true;
		var scale = Math.max(1.0, Math.max(Math.abs(expected), Math.abs(actual)));
		return Math.abs(expected - actual) <= epsilon * scale;
	}

	public static function near(expected:Float, actual:Float, ?message:String, ?pos:PosInfos):Void
	{
		Assert.isTrue(isNear(expected, actual), label(message) + "expected " + expected + " but was " + actual, pos);
	}

	public static function vector2(x:Float, y:Float, actual:Vector2, ?message:String, ?pos:PosInfos):Void
	{
		var matches = actual != null && isNear(x, actual.x) && isNear(y, actual.y);
		Assert.isTrue(matches, label(message) + "expected (" + x + ", " + y + ") but was " + describeVector2(actual), pos);
	}

	/**
		Compares x, y and z only, as most `Vector4` operations mirror Flash's
		`Vector3D` and leave w alone.
	**/
	public static function vector3(x:Float, y:Float, z:Float, actual:Vector4, ?message:String, ?pos:PosInfos):Void
	{
		var matches = actual != null && isNear(x, actual.x) && isNear(y, actual.y) && isNear(z, actual.z);
		Assert.isTrue(matches, label(message) + "expected (" + x + ", " + y + ", " + z + ") but was " + describeVector4(actual), pos);
	}

	public static function vector4(x:Float, y:Float, z:Float, w:Float, actual:Vector4, ?message:String, ?pos:PosInfos):Void
	{
		var matches = actual != null && isNear(x, actual.x) && isNear(y, actual.y) && isNear(z, actual.z) && isNear(w, actual.w);
		Assert.isTrue(matches, label(message) + "expected (" + x + ", " + y + ", " + z + ", " + w + ") but was " + describeVector4(actual), pos);
	}

	public static function matrix3(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float, actual:Matrix3, ?message:String, ?pos:PosInfos):Void
	{
		var matches = isNear(a, actual.a) && isNear(b, actual.b) && isNear(c, actual.c) && isNear(d, actual.d) && isNear(tx, actual.tx)
			&& isNear(ty, actual.ty);
		Assert.isTrue(matches, label(message) + "expected (a=" + a + ", b=" + b + ", c=" + c + ", d=" + d + ", tx=" + tx + ", ty=" + ty + ") but was "
			+ describeMatrix3(actual), pos);
	}

	public static function sameMatrix3(expected:Matrix3, actual:Matrix3, ?message:String, ?pos:PosInfos):Void
	{
		matrix3(expected.a, expected.b, expected.c, expected.d, expected.tx, expected.ty, actual, message, pos);
	}

	/**
		Compares the raw, column-major values of a `Matrix4`.
	**/
	public static function matrix4(expected:Array<Float>, actual:Matrix4, ?message:String, ?pos:PosInfos):Void
	{
		var matches = true;
		for (i in 0...16)
		{
			if (!isNear(expected[i], actual[i])) matches = false;
		}
		Assert.isTrue(matches, label(message) + "expected " + expected + " but was " + describeMatrix4(actual), pos);
	}

	public static function sameMatrix4(expected:Matrix4, actual:Matrix4, ?message:String, ?pos:PosInfos):Void
	{
		matrix4([for (i in 0...16) expected[i]], actual, message, pos);
	}

	public static function rectangle(x:Float, y:Float, width:Float, height:Float, actual:Rectangle, ?message:String, ?pos:PosInfos):Void
	{
		var matches = actual != null && isNear(x, actual.x) && isNear(y, actual.y) && isNear(width, actual.width) && isNear(height, actual.height);
		Assert.isTrue(matches, label(message) + "expected (x=" + x + ", y=" + y + ", width=" + width + ", height=" + height + ") but was "
			+ describeRectangle(actual), pos);
	}

	public static function describeVector2(v:Vector2):String
	{
		return v == null ? "null" : "(" + v.x + ", " + v.y + ")";
	}

	public static function describeVector4(v:Vector4):String
	{
		return v == null ? "null" : "(" + v.x + ", " + v.y + ", " + v.z + ", " + v.w + ")";
	}

	public static function describeMatrix3(m:Matrix3):String
	{
		return "(a=" + m.a + ", b=" + m.b + ", c=" + m.c + ", d=" + m.d + ", tx=" + m.tx + ", ty=" + m.ty + ")";
	}

	public static function describeMatrix4(m:Matrix4):String
	{
		return "[" + [for (i in 0...16) m[i]].join(", ") + "]";
	}

	public static function describeRectangle(r:Rectangle):String
	{
		return r == null ? "null" : "(x=" + r.x + ", y=" + r.y + ", width=" + r.width + ", height=" + r.height + ")";
	}

	private static function label(message:String):String
	{
		return message != null ? message + ": " : "";
	}
}
