package math;

import haxe.PosInfos;
import lime.graphics.PixelFormat;
import lime.utils.UInt8Array;
import utest.Assert;

/**
	Checks shared by the RGBA, ARGB and BGRA suites. Multiplying or dividing a
	channel by alpha has to round to a whole byte, so a channel may be one away
	from the exact value, whichever way it rounds.
**/
class ColorAssert
{
	public static function color(expected:Int, actual:Int, ?message:String, ?pos:PosInfos):Void
	{
		Assert.isTrue(expected == actual, (message != null ? message + ": " : "") + "expected 0x" + StringTools.hex(expected, 8) + " but was 0x"
			+ StringTools.hex(actual, 8), pos);
	}

	public static function channels(r:Float, g:Float, b:Float, actualR:Int, actualG:Int, actualB:Int, ?message:String, ?pos:PosInfos):Void
	{
		var matches = Math.abs(r - actualR) <= 1 && Math.abs(g - actualG) <= 1 && Math.abs(b - actualB) <= 1;
		Assert.isTrue(matches, (message != null ? message + ": " : "") + "expected about (" + round(r) + ", " + round(g) + ", " + round(b) + ") but was ("
			+ actualR + ", " + actualG + ", " + actualB + ")", pos);
	}

	/**
		Adds a failure when multiplying (r, g, b, a) by alpha gave a channel more
		than one away from channel * a / 255, or changed alpha.
	**/
	public static function collectMultiplied(failures:Array<String>, r:Int, g:Int, b:Int, a:Int, actualR:Int, actualG:Int, actualB:Int,
			actualA:Int):Void
	{
		var matches = Math.abs(r * a / 255 - actualR) <= 1 && Math.abs(g * a / 255 - actualG) <= 1 && Math.abs(b * a / 255 - actualB) <= 1
			&& actualA == a;
		if (!matches)
		{
			failures.push("(" + r + ", " + g + ", " + b + ", " + a + ") multiplied to (" + actualR + ", " + actualG + ", " + actualB + ", " + actualA + ")");
		}
	}

	/**
		Adds a failure when a multiply and unmultiply moved a channel by more
		than its rounding error allows, or changed alpha. Multiplying rounds to
		within one of a / 255 of the channel, which dividing by a / 255 again
		grows to 255 / a, and dividing rounds by one more.
	**/
	public static function collectRoundTrip(failures:Array<String>, r:Int, g:Int, b:Int, a:Int, actualR:Int, actualG:Int, actualB:Int,
			actualA:Int):Void
	{
		var bound = 255 / a + 1;
		var matches = Math.abs(r - actualR) <= bound && Math.abs(g - actualG) <= bound && Math.abs(b - actualB) <= bound && actualA == a;
		if (!matches)
		{
			failures.push("(" + r + ", " + g + ", " + b + ", " + a + ") came back as (" + actualR + ", " + actualG + ", " + actualB + ", " + actualA
				+ "), allowed " + round(bound));
		}
	}

	public static function bytes(expected:Array<Int>, actual:UInt8Array, ?message:String, ?pos:PosInfos):Void
	{
		// Typed, since HashLink reads typed array elements as Null<UInt> (#2129)
		var values:Array<Int> = [for (i in 0...actual.length) (actual[i] : Int)];
		var matches = values.length == expected.length;
		for (i in 0...expected.length)
		{
			if (values[i] != expected[i]) matches = false;
		}
		Assert.isTrue(matches, (message != null ? message + ": " : "") + "expected " + hex(expected) + " but was " + hex(values), pos);
	}

	public static function formatName(format:PixelFormat):String
	{
		return switch (format)
		{
			case RGBA32: "RGBA32";
			case ARGB32: "ARGB32";
			case BGRA32: "BGRA32";
			default: "format " + (format : Int);
		}
	}

	private static function hex(values:Array<Int>):String
	{
		return "[" + [for (value in values) "0x" + StringTools.hex(value, 2)].join(", ") + "]";
	}

	private static function round(value:Float):Float
	{
		return Math.round(value * 100) / 100;
	}
}
