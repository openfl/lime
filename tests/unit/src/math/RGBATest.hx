package math;

import lime.graphics.PixelFormat;
import lime.math.ARGB;
import lime.math.BGRA;
import lime.math.RGBA;
import lime.utils.UInt8Array;
import utest.Assert;
import utest.Test;

class RGBATest extends Test
{
	public function new()
	{
		super();
	}

	public function testChannelsFollowTheDocumentedExample():Void
	{
		var color:RGBA = 0x883300FF;
		Assert.equals(0x88, color.r, "r");
		Assert.equals(0x33, color.g, "g");
		Assert.equals(0x00, color.b, "b");
		Assert.equals(0xFF, color.a, "a");
	}

	public function testCreateTakesRedGreenBlueAlpha():Void
	{
		ColorAssert.color(0x11223344, RGBA.create(0x11, 0x22, 0x33, 0x44), "create");

		var color = new RGBA();
		color.set(0x55, 0x66, 0x77, 0x88);
		ColorAssert.color(0x55667788, color, "set");
	}

	public function testChannelSettersChangeOneChannel():Void
	{
		var color:RGBA = 0x11223344;
		color.r = 0xAA;
		ColorAssert.color(0xAA223344, color, "r");
		color.g = 0xBB;
		ColorAssert.color(0xAABB3344, color, "g");
		color.b = 0xCC;
		ColorAssert.color(0xAABBCC44, color, "b");
		color.a = 0xDD;
		ColorAssert.color(0xAABBCCDD, color, "a");
	}

	public function testConvertsToARGB():Void
	{
		var color:RGBA = 0x883300FF;
		var argb:ARGB = color;
		ColorAssert.color(0xFF883300, argb, "the documented example");

		var other:RGBA = 0x11223344;
		argb = other;
		ColorAssert.color(0x44112233, argb);
	}

	public function testConvertsToBGRA():Void
	{
		var color:RGBA = 0x11223344;
		var bgra:BGRA = color;
		ColorAssert.color(0x33221144, bgra);
	}

	public function testMultiplyAlphaWithFullAlphaChangesNothing():Void
	{
		var color = RGBA.create(200, 100, 50, 255);
		color.multiplyAlpha();
		ColorAssert.color(RGBA.create(200, 100, 50, 255), color);
	}

	public function testMultiplyAlphaWithZeroAlphaClearsTheColor():Void
	{
		var color = RGBA.create(200, 100, 50, 0);
		color.multiplyAlpha();
		ColorAssert.color(0, color);
	}

	public function testMultiplyAlphaScalesByAlpha():Void
	{
		var color = RGBA.create(200, 100, 50, 128);
		color.multiplyAlpha();
		ColorAssert.channels(200 * 128 / 255, 100 * 128 / 255, 50 * 128 / 255, color.r, color.g, color.b);
		Assert.equals(128, color.a, "alpha is unchanged");
	}

	public function testUnmultiplyAlphaWithFullAlphaChangesNothing():Void
	{
		var color = RGBA.create(200, 100, 50, 255);
		color.unmultiplyAlpha();
		ColorAssert.color(RGBA.create(200, 100, 50, 255), color);
	}

	public function testUnmultiplyAlphaWithZeroAlphaStaysClear():Void
	{
		var color = RGBA.create(0, 0, 0, 0);
		color.unmultiplyAlpha();
		ColorAssert.color(0, color);
	}

	public function testUnmultiplyAlphaDividesByAlpha():Void
	{
		var color = RGBA.create(100, 50, 25, 128);
		color.unmultiplyAlpha();
		ColorAssert.channels(100 * 255 / 128, 50 * 255 / 128, 25 * 255 / 128, color.r, color.g, color.b);
		Assert.equals(128, color.a, "alpha is unchanged");
	}

	public function testUnmultiplyAlphaKeepsEachChannelInItsByte():Void
	{
		// A channel above alpha is not valid premultiplied data, but must not
		// spill into the other channels
		var color = RGBA.create(200, 0, 0, 100);
		color.unmultiplyAlpha();
		Assert.equals(255, color.r, "r is clamped");
		Assert.equals(0, color.g, "g");
		Assert.equals(0, color.b, "b");
		Assert.equals(100, color.a, "a");
	}

	@Ignored("Waiting on #2141")
	public function testUnmultiplyAlphaClampsChannelsFarAboveAlpha():Void
	{
		// 255 / 1 * 255 is far past a byte; it clamps like any other channel
		var color = RGBA.create(255, 128, 0, 1);
		color.unmultiplyAlpha();
		ColorAssert.color(RGBA.create(255, 255, 0, 1), color);
	}

	public function testMultiplyAlphaIsCloseForEveryValue():Void
	{
		var failures = [];
		for (a in 0...256)
		{
			for (c in 0...256)
			{
				var color = RGBA.create(c, 255 - c, c >> 1, a);
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
				var color = RGBA.create(c, 255 - c, c >> 1, a);
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
		var color = new RGBA();

		color.readUInt8(data, 1, RGBA32);
		ColorAssert.color(RGBA.create(0x11, 0x22, 0x33, 0x44), color, "RGBA32");
		color.readUInt8(data, 1, ARGB32);
		ColorAssert.color(RGBA.create(0x22, 0x33, 0x44, 0x11), color, "ARGB32");
		color.readUInt8(data, 1, BGRA32);
		ColorAssert.color(RGBA.create(0x33, 0x22, 0x11, 0x44), color, "BGRA32");

		color.readUInt8(data, 1);
		ColorAssert.color(RGBA.create(0x11, 0x22, 0x33, 0x44), color, "RGBA32 by default");
	}

	public function testReadUInt8UnmultipliesPremultipliedData():Void
	{
		var formats:Array<PixelFormat> = [RGBA32, ARGB32, BGRA32];
		var bytes = [[0x40, 0x20, 0x10, 0x80], [0x80, 0x40, 0x20, 0x10], [0x10, 0x20, 0x40, 0x80]];

		for (i in 0...3)
		{
			var color = new RGBA();
			color.readUInt8(new UInt8Array(bytes[i]), 0, formats[i], true);
			ColorAssert.channels(0x40 * 255 / 0x80, 0x20 * 255 / 0x80, 0x10 * 255 / 0x80, color.r, color.g, color.b, ColorAssert.formatName(formats[i]));
			Assert.equals(0x80, color.a, ColorAssert.formatName(formats[i]) + " alpha");
		}
	}

	public function testReadUInt8OfClearPremultipliedDataIsClear():Void
	{
		var color:RGBA = 0x11223344;
		color.readUInt8(new UInt8Array([0, 0, 0, 0]), 0, RGBA32, true);
		ColorAssert.color(0, color);
	}

	public function testWriteUInt8InEachFormat():Void
	{
		var color = RGBA.create(0x11, 0x22, 0x33, 0x44);
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
		ColorAssert.color(RGBA.create(0x11, 0x22, 0x33, 0x44), color, "the color is unchanged");
	}

	public function testWriteUInt8PremultipliesWhenAsked():Void
	{
		var formats:Array<PixelFormat> = [RGBA32, ARGB32, BGRA32];
		var order = [[0, 1, 2, 3], [1, 2, 3, 0], [2, 1, 0, 3]];

		for (i in 0...3)
		{
			var color = RGBA.create(200, 100, 50, 128);
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
		// Writing a color out must not change it: writing the same color
		// twice gives the same bytes twice
		var color = RGBA.create(200, 100, 50, 128);
		var first = new UInt8Array(4);
		var second = new UInt8Array(4);
		color.writeUInt8(first, 0, RGBA32, true);
		ColorAssert.color(RGBA.create(200, 100, 50, 128), color, "the color after writing");
		color.writeUInt8(second, 0, RGBA32, true);
		ColorAssert.bytes([for (i in 0...4) first[i]], second, "the second write");
	}

	public function testWriteUInt8OfClearColorIsPremultipliedToZero():Void
	{
		var color = RGBA.create(200, 100, 50, 0);
		var data = new UInt8Array([0xEE, 0xEE, 0xEE, 0xEE]);
		color.writeUInt8(data, 0, RGBA32, true);
		ColorAssert.bytes([0, 0, 0, 0], data);
	}
}
