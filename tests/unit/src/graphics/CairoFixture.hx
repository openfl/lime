package graphics;

import haxe.PosInfos;
#if (lime_cffi && lime_cairo && !macro)
import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoImageSurface;
import lime.graphics.cairo.CairoOperator;
import lime.graphics.cairo.CairoSurface;
import lime.graphics.Image;
import lime.math.Matrix3;
import lime.math.Vector2;
import utest.Assert;
#end

/**
	A Cairo context that draws into a Lime image, so that a test can read what
	was drawn from the image's own bytes.

	Cairo's ARGB32 is a premultiplied 32-bit value in the machine's byte order.
	Lime only builds for little-endian machines, where that is BGRA in memory.
	Colors read back here are ARGB and still premultiplied, as Cairo stored
	them.
**/
class CairoFixture
{
	public static inline var CLEAR = 0x00000000;
	public static inline var BLACK = 0xFF000000;
	public static inline var WHITE = 0xFFFFFFFF;
	public static inline var RED = 0xFFFF0000;
	public static inline var GREEN = 0xFF00FF00;
	public static inline var BLUE = 0xFF0000FF;

	#if (lime_cffi && lime_cairo && !macro)
	public var cairo(default, null):Cairo;
	public var image(default, null):Image;
	public var surface(default, null):CairoSurface;

	/**
		@param	color	The ARGB color every pixel starts with, not premultiplied
	**/
	public function new(width:Int, height:Int, color:Int = 0)
	{
		image = ImageFixture.create(width, height, color, BGRA32, true);
		surface = CairoImageSurface.fromImage(image);
		cairo = new Cairo(surface);
	}

	/**
		A fixture that starts with rows of ARGB colors, not premultiplied.
	**/
	public static function fromRows(rows:Array<Array<Int>>):CairoFixture
	{
		var fixture = new CairoFixture(rows[0].length, rows.length);

		for (y in 0...rows.length)
		{
			for (x in 0...rows[y].length)
			{
				ImageFixture.poke(fixture.image, x, y, rows[y][x]);
			}
		}

		return fixture;
	}

	/**
		Copies a surface Cairo owns the memory of into an image that can be read.
	**/
	public static function copyOf(source:CairoSurface, width:Int, height:Int):CairoFixture
	{
		var fixture = new CairoFixture(width, height);
		fixture.cairo.setOperator(CairoOperator.SOURCE);
		fixture.cairo.setSourceSurface(source, 0, 0);
		fixture.cairo.paint();
		return fixture;
	}

	/**
		Runs the garbage collector, which is when a native object nothing
		refers to any more is released.
	**/
	public static function collect():Void
	{
		#if cpp
		cpp.vm.Gc.run(true);
		#elseif neko
		neko.vm.Gc.run(true);
		#elseif hl
		hl.Gc.major();
		#end
	}

	public function pixel(x:Int, y:Int):Int
	{
		surface.flush();
		return ImageFixture.peek(image, x, y);
	}

	public function alpha(x:Int, y:Int):Int
	{
		return pixel(x, y) >>> 24;
	}

	public function pixels():Array<Int>
	{
		return [for (y in 0...image.height) for (x in 0...image.width) pixel(x, y)];
	}

	public function assertPixel(expected:Int, x:Int, y:Int, ?tolerance:Int, ?label:String, ?pos:PosInfos):Void
	{
		ImageFixture.assertColor(expected, pixel(x, y), tolerance, (label != null ? label + ", " : "") + "pixel " + x + "," + y, pos);
	}

	/**
		Compares the whole image with a picture of it, one character for each
		pixel: `.` transparent, `K` black, `W` white, `R` red, `G` green,
		`B` blue, and `?` for a pixel that may hold anything.
	**/
	public function assertRows(rows:Array<String>, ?tolerance:Int, ?label:String, ?pos:PosInfos):Void
	{
		if (tolerance == null) tolerance = 0;
		var prefix = label != null ? label + ": " : "";

		if (rows.length != image.height)
		{
			Assert.fail(prefix + "expected " + rows.length + " rows but the image has " + image.height, pos);
			return;
		}

		var differences = [];

		for (y in 0...rows.length)
		{
			if (rows[y].length != image.width)
			{
				Assert.fail(prefix + "row " + y + " has " + rows[y].length + " pixels but the image is " + image.width + " wide", pos);
				return;
			}

			for (x in 0...image.width)
			{
				var character = rows[y].charAt(x);
				if (character == "?") continue;

				var expected = colorOf(character);
				var actual = pixel(x, y);

				if (!ImageFixture.sameColor(expected, actual, tolerance))
				{
					differences.push(x + "," + y + " expected " + ImageFixture.hex(expected) + " was " + ImageFixture.hex(actual));
				}
			}
		}

		Assert.isTrue(differences.length == 0, prefix + differences.join("; "), pos);
	}

	/**
		Compares a matrix with `[a, b, c, d, tx, ty]`.
	**/
	public static function assertMatrix(expected:Array<Float>, matrix:Matrix3, ?pos:PosInfos):Void
	{
		if (matrix == null)
		{
			Assert.fail("expected matrix(" + expected.join(", ") + ") but was null", pos);
			return;
		}

		var actual = [matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty];
		var same = true;

		for (i in 0...6)
		{
			if (Math.abs(expected[i] - actual[i]) > 0.00001) same = false;
		}

		Assert.isTrue(same, "expected matrix(" + expected.join(", ") + ") but was matrix(" + actual.join(", ") + ")", pos);
	}

	public static function assertPoint(x:Float, y:Float, point:Vector2, ?pos:PosInfos):Void
	{
		if (point == null)
		{
			Assert.fail("expected (" + x + ", " + y + ") but was null", pos);
			return;
		}

		Assert.isTrue(Math.abs(x - point.x) < 0.00001 && Math.abs(y - point.y) < 0.00001,
			"expected (" + x + ", " + y + ") but was (" + point.x + ", " + point.y + ")", pos);
	}

	private static function colorOf(character:String):Int
	{
		return switch (character)
		{
			case "K": BLACK;
			case "W": WHITE;
			case "R": RED;
			case "G": GREEN;
			case "B": BLUE;
			default: CLEAR;
		}
	}
	#end
}
