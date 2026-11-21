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
	public function testAFontWithoutAFullNameIsNamedAfterItsFamily():Void
	{
		// BDF isn't SFNT, so it has no name records, only the family FreeType reads
		var bdf = [
			"STARTFONT 2.1",
			"FONT -lime-test-medium-r-normal--8-80-75-75-c-80-iso10646-1",
			"SIZE 8 75 75",
			"FONTBOUNDINGBOX 8 8 0 0",
			"STARTPROPERTIES 3",
			"FAMILY_NAME \"Lime Test\"",
			"FONT_ASCENT 8",
			"FONT_DESCENT 0",
			"ENDPROPERTIES",
			"CHARS 1",
			"STARTCHAR A",
			"ENCODING 65",
			"SWIDTH 500 0",
			"DWIDTH 8 0",
			"BBX 8 8 0 0",
			"BITMAP",
			"18", "24", "42", "42", "7E", "42", "42", "00",
			"ENDCHAR",
			"ENDFONT",
			""
		].join("\n");

		var font = Font.fromBytes(lime.utils.Bytes.ofString(bdf));
		Assert.notNull(font, "the BDF font did not open");
		if (font != null) Assert.equals("Lime Test", font.name);
	}

	public function testDecomposeGivesTheFontsName():Void
	{
		var font = Font.fromFile(PATH);
		Assert.notNull(font, "cannot open " + PATH);
		if (font == null) return;

		Assert.isTrue(font.name != null && font.name.length > 0, "the font has no name");

		var data = font.decompose();
		Assert.notNull(data, "decompose() gave nothing");
		if (data != null) Assert.equals(font.name, data.family_name);
	}

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

	public function testStemDarkeningSetBeforeLoadingIsKept():Void
	{
		// A font with no data used to pass a null handle to the native font
		var early = new Font();
		early.stemDarkening = true;
		early.stemDarkeningParameters = [500, 400, 1000, 275, 1667, 275, 2333, 0];
		@:privateAccess early.__fromFile(PATH);

		var late = Font.fromFile(PATH);
		late.stemDarkening = true;
		late.stemDarkeningParameters = [500, 400, 1000, 275, 1667, 275, 2333, 0];

		Assert.isTrue(early.stemDarkening);
		Assert.equals(coverage(late), coverage(early));
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

	public function testAShiftedGlyphIsRenderedAsAnUnshiftedOne():Void
	{
		var font = Font.fromFile(PATH);
		if (font == null)
		{
			Assert.fail("cannot open " + PATH);
			return;
		}

		var glyph = font.getGlyphs("H")[0];
		var whole = font.renderGlyphWithLoadFlags(glyph, 32);
		var shifted = font.renderGlyphWithLoadFlags(glyph, 32, 96, null, 1 / 64);
		Assert.notNull(whole);
		Assert.notNull(shifted);
		if (whole == null || shifted == null) return;

		// A 1/64 pixel shift moves the edges a little, but keeps the hinting and the
		// colored subpixel coverage that renderGlyph() gives
		Assert.equals(whole.height, shifted.height);
		Assert.isTrue(Math.abs(whole.width - shifted.width) <= 1);
		Assert.isTrue(hasColoredCoverage(whole));
		Assert.isTrue(hasColoredCoverage(shifted));
	}

	private static function hasColoredCoverage(image:lime.graphics.Image):Bool
	{
		var data = image.buffer.data;
		var i = 0;

		while (i < data.length)
		{
			if (data[i + 3] > 0 && (data[i] != data[i + 1] || data[i + 1] != data[i + 2])) return true;
			i += 4;
		}

		return false;
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

	public function testAFontsOwnBitmapsAreRenderedAsTheyAre():Void
	{
		// A BDF font has only 1-bit bitmaps, which FreeType gives as they are,
		// where it renders an outline as LCD. They were read as LCD, a third as
		// wide, and past the end of FreeType's bitmap.
		var rows = ["18", "24", "42", "42", "7E", "42", "42", "00"];
		var bdf = [
			"STARTFONT 2.1",
			"FONT -lime-test-medium-r-normal--8-80-72-72-c-80-iso10646-1",
			"SIZE 8 72 72",
			"FONTBOUNDINGBOX 8 8 0 0",
			"STARTPROPERTIES 3",
			"FAMILY_NAME \"Lime Bitmap Test\"",
			"FONT_ASCENT 8",
			"FONT_DESCENT 0",
			"ENDPROPERTIES",
			"CHARS 1",
			"STARTCHAR A",
			"ENCODING 65",
			"SWIDTH 500 0",
			"DWIDTH 8 0",
			"BBX 8 8 0 0",
			"BITMAP"
		].concat(rows).concat(["ENDCHAR", "ENDFONT", ""]).join("\n");

		var expected = [];
		for (row in rows)
		{
			var bits = Std.parseInt("0x" + row);
			expected.push([for (x in 0...8) (bits & (0x80 >> x)) != 0 ? "#" : "."].join(""));
		}

		var font = Font.fromBytes(lime.utils.Bytes.ofString(bdf));
		Assert.notNull(font, "the BDF font did not open");
		if (font == null) return;

		var glyph = font.getGlyph("A");

		// Twice, as the bytes past the bitmap changed from one render to the next
		for (i in 0...2)
		{
			var image = font.renderGlyphWithLoadFlags(glyph, 8, 72);
			Assert.equals(expected.join("\n"), describeAlpha(image), "renderGlyphWithLoadFlags()");
		}

		var images = font.renderGlyphs([glyph], 8);
		Assert.equals(expected.join("\n"), describeAlpha(images != null ? images.get(glyph) : null), "renderGlyphs()");
	}

	/** Each pixel as # where it is covered and . where it isn't, a line a row **/
	private static function describeAlpha(image:lime.graphics.Image):String
	{
		if (image == null) return "null";

		// renderGlyph() gives RGBA images of their own, renderGlyphs() 8-bit
		// coverage within one buffer
		var buffer = image.buffer;
		var lines = [];
		for (y in 0...image.height)
		{
			var line = "";
			for (x in 0...image.width)
			{
				var pixel = (image.offsetY + y) * buffer.width + image.offsetX + x;
				var coverage = buffer.bitsPerPixel == 8 ? buffer.data[pixel] : buffer.data[pixel * 4 + 3];
				line += coverage > 127 ? "#" : ".";
			}
			lines.push(line);
		}
		return lines.join("\n");
	}

	// Lime 8.3 subclasses override renderGlyph(glyph, fontSize) and decompose(),
	// as OverridingFont does, so a parameter added to either would stop them
	// compiling
	public function testRenderGlyphRendersAt96DPIAsBefore():Void
	{
		var font = new OverridingFont();
		@:privateAccess font.__fromFile(PATH);
		var glyph = font.getGlyphs("H")[0];

		var image = font.renderGlyph(glyph, 32);
		var at96 = font.renderGlyphWithLoadFlags(glyph, 32, 96);
		Assert.notNull(image);
		Assert.notNull(at96);
		if (image == null || at96 == null) return;

		Assert.equals(1, font.rendered);
		Assert.equals(at96.width + "x" + at96.height, image.width + "x" + image.height);
		Assert.isTrue(at96.buffer.data.toBytes().compare(image.buffer.data.toBytes()) == 0, "renderGlyph() and renderGlyphWithLoadFlags() at 96 DPI differ");
	}

	public function testDecomposeUnhintedGivesTheSameGlyphs():Void
	{
		var font = new OverridingFont();
		@:privateAccess font.__fromFile(PATH);

		var hinted = font.decompose();
		var unhinted = font.decomposeUnhinted();
		Assert.notNull(hinted);
		Assert.notNull(unhinted);
		if (hinted == null || unhinted == null) return;

		Assert.equals(1, font.decomposed);
		Assert.equals(hinted.family_name, unhinted.family_name);
		// HashLink gives glyphs as a native array, not an Array, so they are counted by num_glyphs
		Assert.equals(hinted.num_glyphs, unhinted.num_glyphs);
		Assert.isTrue(unhinted.num_glyphs > 0);
	}
	#end
}

#if (lime_cffi && !macro)
private class OverridingFont extends Font
{
	public var decomposed:Int = 0;
	public var rendered:Int = 0;

	override public function decompose():lime.text.Font.NativeFontData
	{
		decomposed++;
		return super.decompose();
	}

	override public function renderGlyph(glyph:lime.text.Glyph, fontSize:Int):lime.graphics.Image
	{
		rendered++;
		return super.renderGlyph(glyph, fontSize);
	}
}
#end
