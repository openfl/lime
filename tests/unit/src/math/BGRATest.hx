package math;

import lime.graphics.PixelFormat;
import lime.math.ARGB;
import lime.math.BGRA;
import lime.math.RGBA;
import lime.utils.UInt8Array;
import utest.Assert;
import utest.Test;

class BGRATest extends Test
{
	public function new()
	{
		super();
	}

	public function testChannelsFollowTheDocumentedExample():Void
	{
		var color:BGRA = 0x003388FF;
		Assert.equals(0x00, color.b, "b");
		Assert.equals(0x33, color.g, "g");
		Assert.equals(0x88, color.r, "r");
		Assert.equals(0xFF, color.a, "a");
	}

	public function testCreateTakesBlueGreenRedAlpha():Void
	{
		ColorAssert.color(0x11223344, BGRA.create(0x11, 0x22, 0x33, 0x44), "create");

		var color = new BGRA();
		color.set(0x55, 0x66, 0x77, 0x88);
		ColorAssert.color(0x55667788, color, "set");
	}

	public function testChannelSettersChangeOneChannel():Void
	{
		var color:BGRA = 0x11223344;
		color.r = 0xAA;
		ColorAssert.color(0x1122AA44, color, "r");
		color.g = 0xBB;
		ColorAssert.color(0x11BBAA44, color, "g");
		color.b = 0xCC;
		ColorAssert.color(0xCCBBAA44, color, "b");
		color.a = 0xDD;
		ColorAssert.color(0xCCBBAADD, color, "a");
	}

	public function testConvertsToARGB():Void
	{
		var color:BGRA = 0x003388FF;
		var argb:ARGB = color;
		ColorAssert.color(0xFF883300, argb, "the documented example");

		var other:BGRA = 0x33221144;
		argb = other;
		ColorAssert.color(0x44112233, argb);
	}

	public function testConvertsToRGBA():Void
	{
		var color:BGRA = 0x33221144;
		var rgba:RGBA = color;
		ColorAssert.color(0x11223344, rgba);
	}

	public function testMultiplyAlphaWithFullAlphaChangesNothing():Void
	{
		var color = make(200, 100, 50, 255);
		color.multiplyAlpha();
		ColorAssert.color(make(200, 100, 50, 255), color);
	}

	public function testMultiplyAlphaWithZeroAlphaClearsTheColor():Void
	{
		var color = make(200, 100, 50, 0);
		color.multiplyAlpha();
		ColorAssert.color(0, color);
	}

	public function testMultiplyAlphaScalesByAlpha():Void
	{
		var color = make(200, 100, 50, 128);
		color.multiplyAlpha();
		ColorAssert.channels(200 * 128 / 255, 100 * 128 / 255, 50 * 128 / 255, color.r, color.g, color.b);
		Assert.equals(128, color.a, "alpha is unchanged");
	}

	public function testUnmultiplyAlphaWithFullAlphaChangesNothing():Void
	{
		var color = make(200, 100, 50, 255);
		color.unmultiplyAlpha();
		ColorAssert.color(make(200, 100, 50, 255), color);
	}

	public function testUnmultiplyAlphaWithZeroAlphaStaysClear():Void
	{
		var color = make(0, 0, 0, 0);
		color.unmultiplyAlpha();
		ColorAssert.color(0, color);
	}

	public function testUnmultiplyAlphaDividesByAlpha():Void
	{
		var color = make(100, 50, 25, 128);
		color.unmultiplyAlpha();
		ColorAssert.channels(100 * 255 / 128, 50 * 255 / 128, 25 * 255 / 128, color.r, color.g, color.b);
		Assert.equals(128, color.a, "alpha is unchanged");
	}

	public function testUnmultiplyAlphaKeepsEachChannelInItsByte():Void
	{
		var color = make(200, 0, 0, 100);
		color.unmultiplyAlpha();
		Assert.equals(255, color.r, "r is clamped");
		Assert.equals(0, color.g, "g");
		Assert.equals(0, color.b, "b");
		Assert.equals(100, color.a, "a");
	}

	@Ignored("Waiting on #2141")
	public function testUnmultiplyAlphaClampsChannelsFarAboveAlpha():Void
	{
		var color = make(255, 128, 0, 1);
		color.unmultiplyAlpha();
		ColorAssert.color(make(255, 255, 0, 1), color);
	}

	public function testMultiplyAlphaIsCloseForEveryValue():Void
	{
		var failures = [];
		for (a in 0...256)
		{
			for (c in 0...256)
			{
				var color = make(c, 255 - c, c >> 1, a);
				color.multiplyAlpha();
				ColorAssert.collectMultiplied(failures, c, 255 - c, c >> 1, a, color.r, color.g, color.b, color.a);
			}
		}
		Assert.equals(0, failures.length, failures.slice(0, 5).join("; "));
	}

	public function testMultiplyThenUnmultiplyRoundTripsWithinTheRoundingError():Void
	{
		var failures = [];
		for (a in 1...256)
		{
			for (c in 0...256)
			{
				var color = make(c, 255 - c, c >> 1, a);
				color.multiplyAlpha();
				color.unmultiplyAlpha();
				ColorAssert.collectRoundTrip(failures, c, 255 - c, c >> 1, a, color.r, color.g, color.b, color.a);
			}
		}
		Assert.equals(0, failures.length, failures.slice(0, 5).join("; "));
	}

	public function testReadUInt8InEachFormat():Void
	{
		var data = new UInt8Array([0xEE, 0x11, 0x22, 0x33, 0x44, 0xEE]);
		var color = new BGRA();

		color.readUInt8(data, 1, RGBA32);
		ColorAssert.color(make(0x11, 0x22, 0x33, 0x44), color, "RGBA32");
		color.readUInt8(data, 1, ARGB32);
		ColorAssert.color(make(0x22, 0x33, 0x44, 0x11), color, "ARGB32");
		color.readUInt8(data, 1, BGRA32);
		ColorAssert.color(make(0x33, 0x22, 0x11, 0x44), color, "BGRA32");

		color.readUInt8(data, 1);
		ColorAssert.color(make(0x11, 0x22, 0x33, 0x44), color, "RGBA32 by default");
	}

	public function testReadUInt8UnmultipliesPremultipliedData():Void
	{
		var formats:Array<PixelFormat> = [RGBA32, ARGB32, BGRA32];
		var bytes = [[0x40, 0x20, 0x10, 0x80], [0x80, 0x40, 0x20, 0x10], [0x10, 0x20, 0x40, 0x80]];

		for (i in 0...3)
		{
			var color = new BGRA();
			color.readUInt8(new UInt8Array(bytes[i]), 0, formats[i], true);
			ColorAssert.channels(0x40 * 255 / 0x80, 0x20 * 255 / 0x80, 0x10 * 255 / 0x80, color.r, color.g, color.b, ColorAssert.formatName(formats[i]));
			Assert.equals(0x80, color.a, ColorAssert.formatName(formats[i]) + " alpha");
		}
	}

	public function testReadUInt8OfClearPremultipliedDataIsClear():Void
	{
		var color:BGRA = 0x11223344;
		color.readUInt8(new UInt8Array([0, 0, 0, 0]), 0, RGBA32, true);
		ColorAssert.color(0, color);
	}

	public function testWriteUInt8InEachFormat():Void
	{
		var color = make(0x11, 0x22, 0x33, 0x44);
		var formats:Array<PixelFormat> = [RGBA32, ARGB32, BGRA32];
		var expected = [[0x11, 0x22, 0x33, 0x44], [0x44, 0x11, 0x22, 0x33], [0x33, 0x22, 0x11, 0x44]];

		for (i in 0...3)
		{
			var data = new UInt8Array([0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE]);
			color.writeUInt8(data, 1, formats[i]);
			ColorAssert.bytes([0xEE].concat(expected[i]).concat([0xEE]), data, ColorAssert.formatName(formats[i]));
		}

		var data = new UInt8Array(4);
		color.writeUInt8(data, 0);
		ColorAssert.bytes([0x11, 0x22, 0x33, 0x44], data, "RGBA32 by default");
		ColorAssert.color(make(0x11, 0x22, 0x33, 0x44), color, "the color is unchanged");
	}

	public function testWriteUInt8PremultipliesWhenAsked():Void
	{
		var formats:Array<PixelFormat> = [RGBA32, ARGB32, BGRA32];
		var order = [[0, 1, 2, 3], [1, 2, 3, 0], [2, 1, 0, 3]];

		for (i in 0...3)
		{
			var color = make(200, 100, 50, 128);
			var data = new UInt8Array(4);
			color.writeUInt8(data, 0, formats[i], true);
			var name = ColorAssert.formatName(formats[i]);
			ColorAssert.channels(200 * 128 / 255, 100 * 128 / 255, 50 * 128 / 255, data[order[i][0]], data[order[i][1]], data[order[i][2]], name);
			Assert.equals(128, data[order[i][3]], name + " alpha");
		}
	}

	@Ignored("Waiting on #2141")
	public function testWriteUInt8PremultipliedLeavesTheColorUnchanged():Void
	{
		var color = make(200, 100, 50, 128);
		var first = new UInt8Array(4);
		var second = new UInt8Array(4);
		color.writeUInt8(first, 0, RGBA32, true);
		ColorAssert.color(make(200, 100, 50, 128), color, "the color after writing");
		color.writeUInt8(second, 0, RGBA32, true);
		ColorAssert.bytes([for (i in 0...4) first[i]], second, "the second write");
	}

	public function testWriteUInt8OfClearColorIsPremultipliedToZero():Void
	{
		var color = make(200, 100, 50, 0);
		var data = new UInt8Array([0xEE, 0xEE, 0xEE, 0xEE]);
		color.writeUInt8(data, 0, RGBA32, true);
		ColorAssert.bytes([0, 0, 0, 0], data);
	}

	private static inline function make(r:Int, g:Int, b:Int, a:Int):BGRA
	{
		return BGRA.create(b, g, r, a);
	}
}
