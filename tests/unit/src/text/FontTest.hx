package text;

import lime.text.Font;
import utest.Assert;
import utest.Test;

/**
	assets/mono.ttf is a subset of Noto Mono, under the SIL Open Font License
	in assets/mono-OFL.txt.
**/
class FontTest extends Test
{
	private static inline var PATH = "assets/mono.ttf";
	private static inline var VARIABLE_PATH = "assets/variable.ttf";

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	private function variableFont():Font
	{
		var font = Font.fromFile(VARIABLE_PATH);
		Assert.notNull(font, "cannot open " + VARIABLE_PATH);
		return font;
	}

	// Compare a glyph to the same font on this runner, not platform-specific golden pixels.
	private function coverage(font:Font):String
	{
		var image = font.renderGlyph(font.getGlyphs("H")[0], 32);
		Assert.notNull(image);
		if (image == null) return "";
		return image.width + "x" + image.height + ":" + haxe.crypto.Md5.make(image.buffer.data.toBytes()).toHex();
	}

	public function testVariableWeightChangesOutlinesAndCanBeReset():Void
	{
		var font = variableFont();
		if (font == null) return;
		Assert.isTrue(font.setVariation("wght", 400));
		var regular = coverage(font);
		Assert.isFalse(font.isBold);
		Assert.isTrue(font.setVariation("wght", 700));
		Assert.isTrue(font.isBold);
		Assert.notEquals(regular, coverage(font), "a successful variation must change the rendered outlines");
		Assert.isTrue(font.setVariation("wght", 400));
		Assert.isFalse(font.isBold);
		Assert.equals(regular, coverage(font), "resetting weight must restore the original outlines");
	}

	public function testVariableAxesKeepTheirOtherCoordinates():Void
	{
		var font = variableFont();
		if (font == null) return;
		var defaultOptical = coverage(font);
		Assert.isTrue(font.setVariation("opsz", 32));
		var optical = coverage(font);
		Assert.notEquals(defaultOptical, optical, "fixture optical size must visibly affect the glyph");
		Assert.isTrue(font.setVariation("wght", 700));
		Assert.isTrue(font.setVariation("wght", 400));
		Assert.equals(optical, coverage(font), "changing weight must not reset optical size");
	}

	public function testVariableCoordinatesAreClampedToAxisBounds():Void
	{
		var font = variableFont();
		if (font == null) return;
		Assert.isTrue(font.setVariation("wght", 900));
		var maximum = coverage(font);
		Assert.isTrue(font.setVariation("wght", 10000));
		Assert.equals(maximum, coverage(font));
		Assert.isTrue(font.isBold);
		Assert.isTrue(font.setVariation("wght", 100));
		var minimum = coverage(font);
		Assert.isTrue(font.setVariation("wght", -10000));
		Assert.equals(minimum, coverage(font));
		Assert.isFalse(font.isBold);
	}

	public function testSeparateVariableFontFacesRemainIndependent():Void
	{
		var regular = variableFont();
		var bold = variableFont();
		if (regular == null || bold == null) return;
		var original = coverage(regular);
		Assert.isTrue(bold.setVariation("wght", 700));
		Assert.notEquals(original, coverage(bold));
		Assert.equals(original, coverage(regular), "another face's variation must not change this face");
		Assert.isFalse(regular.isBold);
		Assert.isTrue(bold.isBold);
	}

	public function testMissingAxisAndStaticFontDoNotChangeOutlines():Void
	{
		var variable = variableFont();
		if (variable == null) return;
		var original = coverage(variable);
		Assert.isFalse(variable.setVariation("xxxx", 700));
		Assert.isFalse(variable.setVariation("ital", 1), "the upright fixture has no italic axis");
		Assert.equals(original, coverage(variable));
		var fixed = Font.fromFile(PATH);
		Assert.notNull(fixed);
		if (fixed == null) return;
		original = coverage(fixed);
		Assert.isFalse(fixed.setVariation("wght", 700));
		Assert.equals(original, coverage(fixed));
	}

	public function testInvalidVariationRequestsAreRejectedWithoutMutation():Void
	{
		var font = variableFont();
		if (font == null) return;
		var original = coverage(font);
		for (tag in [null, "", "wgh", "weight", "\nabc", "\u00e9abc"])
			Assert.isFalse(font.setVariation(tag, 700));
		for (value in [Math.NaN, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY])
			Assert.isFalse(font.setVariation("wght", value));
		Assert.equals(original, coverage(font));
	}

	public function testVariableFontLoadedFromBytes():Void
	{
		var font = Font.fromBytes(sys.io.File.getBytes(VARIABLE_PATH));
		Assert.notNull(font);
		if (font == null) return;
		var original = coverage(font);
		Assert.isTrue(font.setVariation("wght", 700));
		Assert.notEquals(original, coverage(font));
	}

	public function testRenderGlyphsGivesEachGlyphItsCoverage():Void
	{
		var font = Font.fromFile(PATH);
		if (font == null)
		{
			Assert.fail("cannot open " + PATH);
			return;
		}

		var glyphs = font.getGlyphs("0123456789");
		var images = font.renderGlyphs(glyphs, 24);
		Assert.notNull(images);
		if (images == null) return;

		var buffer = null;

		for (glyph in glyphs)
		{
			var image = images.get(glyph);
			Assert.notNull(image, "glyph " + glyph + " was not rendered");
			if (image == null) continue;

			// Every glyph shares one 8-bit atlas, and lies inside it
			if (buffer == null) buffer = image.buffer;
			Assert.equals(buffer, image.buffer);
			Assert.equals(8, image.buffer.bitsPerPixel);
			Assert.isTrue(image.width > 0 && image.height > 0);
			Assert.isTrue(image.offsetX + image.width <= buffer.width && image.offsetY + image.height <= buffer.height);

			// A digit covers some of its box fully, and leaves some of it empty
			var covered = 0;
			var empty = 0;

			for (y in 0...image.height)
			{
				for (x in 0...image.width)
				{
					var coverage = buffer.data[(image.offsetY + y) * buffer.width + image.offsetX + x];
					if (coverage > 200) covered++;
					if (coverage == 0) empty++;
				}
			}

			Assert.isTrue(covered > 0, "glyph " + glyph + " has no coverage");
			Assert.isTrue(empty > 0, "glyph " + glyph + " covers its whole box");
		}
	}
	#end
}
