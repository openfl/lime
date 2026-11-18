package math;

import lime.math.ColorMatrix;
import math.MathAssert.*;
import utest.Assert;
import utest.Test;

// ColorMatrix mirrors Flash's flash.geom.ColorTransform for its multipliers,
// offsets and color: each channel becomes channel * multiplier + offset.
class ColorMatrixTest extends Test
{
	public function new()
	{
		super();
	}

	public function testNewMatrixLeavesColorsAlone():Void
	{
		var cm = new ColorMatrix();
		near(1, cm.redMultiplier, "redMultiplier");
		near(1, cm.greenMultiplier, "greenMultiplier");
		near(1, cm.blueMultiplier, "blueMultiplier");
		near(1, cm.alphaMultiplier, "alphaMultiplier");
		near(0, cm.redOffset, "redOffset");
		near(0, cm.greenOffset, "greenOffset");
		near(0, cm.blueOffset, "blueOffset");
		near(0, cm.alphaOffset, "alphaOffset");
	}

	public function testMultipliersAndOffsetsAreIndependent():Void
	{
		var cm = new ColorMatrix();
		cm.redMultiplier = 0.1;
		cm.greenMultiplier = 0.2;
		cm.blueMultiplier = 0.3;
		cm.alphaMultiplier = 0.4;
		cm.redOffset = 10;
		cm.greenOffset = 20;
		cm.blueOffset = 30;
		cm.alphaOffset = 40;

		near(0.1, cm.redMultiplier, "redMultiplier");
		near(0.2, cm.greenMultiplier, "greenMultiplier");
		near(0.3, cm.blueMultiplier, "blueMultiplier");
		near(0.4, cm.alphaMultiplier, "alphaMultiplier");
		near(10, cm.redOffset, "redOffset");
		near(20, cm.greenOffset, "greenOffset");
		near(30, cm.blueOffset, "blueOffset");
		near(40, cm.alphaOffset, "alphaOffset");
	}

	public function testIdentityResets():Void
	{
		var cm = new ColorMatrix();
		cm.redMultiplier = 0.5;
		cm.alphaOffset = 20;
		cm.identity();
		near(1, cm.redMultiplier, "redMultiplier");
		near(0, cm.alphaOffset, "alphaOffset");
	}

	@Ignored("Waiting on #2143")
	public function testTablesFollowTheDocumentedExamples():Void
	{
		var cm = new ColorMatrix();
		cm.redOffset = 16;
		cm.greenOffset = 16;
		cm.blueOffset = 16;
		cm.alphaOffset = 12;

		var red = cm.getRedTable();
		Assert.equals(16, red[0], "red 0, was " + red[0]);
		Assert.equals(17, red[1], "red 1, was " + red[1]);
		var green = cm.getGreenTable();
		Assert.equals(16, green[0], "green 0, was " + green[0]);
		Assert.equals(17, green[1], "green 1, was " + green[1]);
		var blue = cm.getBlueTable();
		Assert.equals(16, blue[0], "blue 0, was " + blue[0]);
		Assert.equals(17, blue[1], "blue 1, was " + blue[1]);
		var alpha = cm.getAlphaTable();
		Assert.equals(12, alpha[0], "alpha 0, was " + alpha[0]);
		Assert.equals(13, alpha[1], "alpha 1, was " + alpha[1]);
		Assert.equals(256, alpha.length, "256 values, was " + alpha.length);
	}

	public function testTablesApplyTheMultiplier():Void
	{
		var cm = new ColorMatrix();
		cm.redMultiplier = 0.5;
		var red = cm.getRedTable();
		Assert.equals(0, red[0], "red 0, was " + red[0]);
		Assert.equals(50, red[100], "red 100, was " + red[100]);
		Assert.equals(100, red[200], "red 200, was " + red[200]);

		cm.redMultiplier = 2;
		red = cm.getRedTable();
		Assert.equals(200, red[100], "red 100 after changing the multiplier, was " + red[100]);
	}

	@Ignored("Waiting on #2143")
	public function testTablesAreClampedToAByte():Void
	{
		var cm = new ColorMatrix();
		cm.greenMultiplier = 2;
		cm.blueOffset = -16;
		cm.alphaOffset = 300;

		var green = cm.getGreenTable();
		Assert.equals(254, green[127], "green 127, was " + green[127]);
		Assert.equals(255, green[128], "green 128, was " + green[128]);
		Assert.equals(255, green[255], "green 255, was " + green[255]);

		var blue = cm.getBlueTable();
		Assert.equals(0, blue[0], "blue 0, was " + blue[0]);
		Assert.equals(0, blue[16], "blue 16, was " + blue[16]);
		Assert.equals(1, blue[17], "blue 17, was " + blue[17]);

		var alpha = cm.getAlphaTable();
		Assert.equals(255, alpha[0], "alpha 0, was " + alpha[0]);
	}

	@Ignored("Waiting on #2143")
	public function testTablesAddWholeOffsetsExactly():Void
	{
		// With a multiplier of 1, a whole offset moves every value by exactly
		// that much: table[i] = clamp(i + offset)
		var failures = [];
		var cm = new ColorMatrix();

		for (offset in -255...256)
		{
			cm.redOffset = offset;
			var red = cm.getRedTable();

			for (i in 0...256)
			{
				var expected = i + offset;
				if (expected < 0) expected = 0;
				if (expected > 255) expected = 255;

				if (red[i] != expected)
				{
					failures.push("offset " + offset + " gave red[" + i + "] = " + red[i] + ", not " + expected);
					break;
				}
			}
		}

		Assert.equals(0, failures.length, failures.length + " of 511 offsets: " + failures.slice(0, 5).join("; "));
	}

	public function testSettingColorSetsTheOffsetsAndClearsTheMultipliers():Void
	{
		// Flash: setting color changes the red, green and blue offsets, sets
		// their multipliers to 0, and leaves alpha alone
		var cm = new ColorMatrix();
		cm.alphaMultiplier = 0.5;
		cm.alphaOffset = 10;
		cm.color = 0x336699;

		near(0x33, cm.redOffset, "redOffset");
		near(0x66, cm.greenOffset, "greenOffset");
		near(0x99, cm.blueOffset, "blueOffset");
		near(0, cm.redMultiplier, "redMultiplier");
		near(0, cm.greenMultiplier, "greenMultiplier");
		near(0, cm.blueMultiplier, "blueMultiplier");
		near(0.5, cm.alphaMultiplier, "alphaMultiplier");
		near(10, cm.alphaOffset, "alphaOffset");
	}

	public function testColorReadsTheOffsets():Void
	{
		var cm = new ColorMatrix();
		cm.color = 0x336699;
		Assert.equals(0x336699, cm.color, "after setting color, was " + cm.color);

		cm.identity();
		cm.redOffset = 0x12;
		cm.greenOffset = 0x34;
		cm.blueOffset = 0x56;
		Assert.equals(0x123456, cm.color, "from the offsets, was " + cm.color);
	}

	public function testSettingColorTintsTheTables():Void
	{
		var cm = new ColorMatrix();
		cm.color = 0xFF8000;
		Assert.equals(0xFF, cm.getRedTable()[10], "red, was " + cm.getRedTable()[10]);
		Assert.equals(0x80, cm.getGreenTable()[200], "green, was " + cm.getGreenTable()[200]);
		Assert.equals(0x00, cm.getBlueTable()[255], "blue, was " + cm.getBlueTable()[255]);
	}

	@Ignored("Waiting on #2143")
	public function testConcatMultipliesTheMultipliers():Void
	{
		// Both orders of applying two multipliers give their product
		var cm = new ColorMatrix();
		cm.redMultiplier = 2;
		cm.greenMultiplier = 0.5;
		cm.blueMultiplier = 0.25;
		cm.alphaMultiplier = 0.5;

		var second = new ColorMatrix();
		second.redMultiplier = 3;
		second.greenMultiplier = 0.5;
		second.blueMultiplier = 4;
		second.alphaMultiplier = 0.5;

		cm.concat(second);
		near(6, cm.redMultiplier, "redMultiplier");
		near(0.25, cm.greenMultiplier, "greenMultiplier");
		near(1, cm.blueMultiplier, "blueMultiplier");
		near(0.25, cm.alphaMultiplier, "alphaMultiplier");
		near(3, second.redMultiplier, "the second matrix is not modified");
	}

	@Ignored("Waiting on #2143")
	public function testConcatAddsTheOffsetsOfUnscaledMatrices():Void
	{
		// With multipliers of 1, both orders add the offsets
		var cm = new ColorMatrix();
		cm.redOffset = 10;
		cm.greenOffset = -20;
		cm.blueOffset = 30;
		cm.alphaOffset = 5;

		var second = new ColorMatrix();
		second.redOffset = 20;
		second.greenOffset = 5;
		second.blueOffset = -10;
		second.alphaOffset = 5;

		cm.concat(second);
		near(30, cm.redOffset, "redOffset");
		near(-15, cm.greenOffset, "greenOffset");
		near(20, cm.blueOffset, "blueOffset");
		near(10, cm.alphaOffset, "alphaOffset");
		near(1, cm.redMultiplier, "redMultiplier");
	}

	public function testCloneAndCopyFromAreIndependent():Void
	{
		var cm = new ColorMatrix();
		cm.redMultiplier = 0.5;
		cm.blueOffset = 20;

		var copy = cm.clone();
		near(0.5, copy.redMultiplier, "clone redMultiplier");
		near(20, copy.blueOffset, "clone blueOffset");
		copy.redMultiplier = 0.25;
		near(0.5, cm.redMultiplier, "original after changing the clone");

		var target = new ColorMatrix();
		target.copyFrom(cm);
		near(0.5, target.redMultiplier, "copyFrom redMultiplier");
		near(20, target.blueOffset, "copyFrom blueOffset");
		cm.blueOffset = 40;
		near(20, target.blueOffset, "copy after changing the source");
	}
}
