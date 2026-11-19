package text;

#if (lime_cffi && lime_harfbuzz && !macro)
import haxe.io.Bytes;
import lime.math.Vector2;
import lime.text.Font;
import lime.text.harfbuzz.HBBlob;
import lime.text.harfbuzz.HBDirection;
import lime.text.harfbuzz.HBFTFont;
import lime.text.harfbuzz.HBFace;
import lime.text.harfbuzz.HBFont;
import lime.text.harfbuzz.HBLanguage;
import lime.text.harfbuzz.HBMemoryMode;
import lime.utils.DataPointer;
#end
import utest.Assert;
import utest.Test;

/**
	`HBBlob`, `HBFace`, `HBFont`, `HBFTFont` and `HBLanguage` against HarfBuzz's
	API reference for hb_blob_t, hb_face_t, hb_font_t, hb-ft and hb_language_t.
	The numbers expected of the fonts are in `FontFixture`, read from their tables.
**/
class HarfBuzzFontTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_harfbuzz && !macro)
	// The glyph of H in the monospaced font
	private static inline var H = 41;

	// FT_LOAD_NO_HINTING and FT_LOAD_FORCE_AUTOHINT
	private static inline var NO_HINTING = 0x2;
	private static inline var FORCE_AUTOHINT = 0x20;

	private static inline var HANDLES = 100;
	private static inline var ROUNDS = 12;

	// Blobs

	public function testABlobHoldsAsManyBytesAsItWasGiven():Void
	{
		var bytes = FontFixture.monoBytes();
		var blob = new HBBlob(DataPointer.fromBytes(bytes), bytes.length, HBMemoryMode.DUPLICATE);

		Assert.equals(bytes.length, blob.length);
		Assert.isFalse(blob.immutable);
		Assert.isTrue(address(blob.data) != 0);
	}

	public function testADuplicatedBlobKeepsACopyOfItsOwn():Void
	{
		// HB_MEMORY_MODE_DUPLICATE: the data is copied at once, so the caller's may change
		var bytes = FontFixture.monoBytes();
		var source = DataPointer.fromBytes(bytes);
		var blob = new HBBlob(source, bytes.length, HBMemoryMode.DUPLICATE);
		Assert.isTrue(address(blob.data) != address(source));

		bytes.fill(0, bytes.length, 0);

		var face = new HBFace(blob, 0);
		Assert.equals(FontFixture.MONO_UPEM, face.upem);
		Assert.equals(FontFixture.MONO_GLYPHS, face.glyphCount);
	}

	public function testABlobCanBeMadeImmutable():Void
	{
		var bytes = FontFixture.monoBytes();
		var blob = new HBBlob(DataPointer.fromBytes(bytes), bytes.length, HBMemoryMode.DUPLICATE);
		blob.makeImmutable();

		Assert.isTrue(blob.immutable);
		Assert.equals(bytes.length, blob.length);
	}

	public function testAnImmutableBlobHasNoWritableData():Void
	{
		// hb_blob_get_data_writable: fails, giving NULL, once the blob has been made immutable
		var bytes = FontFixture.monoBytes();
		var blob = new HBBlob(DataPointer.fromBytes(bytes), bytes.length, HBMemoryMode.DUPLICATE);
		Assert.isTrue(address(blob.dataWritable) != 0);

		blob.makeImmutable();
		Assert.isTrue(address(blob.dataWritable) == 0);
	}

	public function testWritableDataOfAReadOnlyBlobIsNotTheCallersMemory():Void
	{
		// HB_MEMORY_MODE_READONLY: nothing writes to the data given, so writing takes a copy
		var bytes = FontFixture.monoBytes();
		var source = DataPointer.fromBytes(bytes);
		var blob = new HBBlob(source, bytes.length, HBMemoryMode.READONLY);
		var writable = blob.dataWritable;

		Assert.isTrue(address(writable) != 0);
		Assert.isTrue(address(writable) != address(source));
	}

	public function testASubBlobIsARangeOfItsParent():Void
	{
		var bytes = FontFixture.monoBytes();
		var blob = new HBBlob(DataPointer.fromBytes(bytes), bytes.length, HBMemoryMode.DUPLICATE);
		var sub = blob.createSubBlob(16, 64);

		Assert.equals(64, sub.length);
		// hb_blob_create_sub_blob makes its parent immutable
		Assert.isTrue(blob.immutable);

		// A range past the end is cut to what the parent holds
		Assert.equals(bytes.length - 16, blob.createSubBlob(16, bytes.length).length);
		Assert.equals(0, blob.createSubBlob(bytes.length, 8).length);
	}

	public function testASubBlobOfAWholeFontReadsAsTheFont():Void
	{
		var bytes = FontFixture.monoBytes();
		var blob = new HBBlob(DataPointer.fromBytes(bytes), bytes.length, HBMemoryMode.DUPLICATE);
		var face = new HBFace(blob.createSubBlob(0, bytes.length), 0);

		Assert.equals(FontFixture.MONO_UPEM, face.upem);
		Assert.equals(FontFixture.MONO_GLYPHS, face.glyphCount);
	}

	public function testTheEmptyBlobHasNoBytes():Void
	{
		Assert.equals(0, HBBlob.empty.length);
	}

	// Faces

	public function testAFaceReadsItsFontsTables():Void
	{
		// head.unitsPerEm and maxp.numGlyphs
		var mono = new HBFace(blobOf(FontFixture.monoBytes()), 0);
		Assert.equals(FontFixture.MONO_UPEM, mono.upem);
		Assert.equals(FontFixture.MONO_GLYPHS, mono.glyphCount);
		Assert.equals(0, mono.index);
		Assert.isFalse(mono.immutable);

		var variable = new HBFace(blobOf(FontFixture.variableBytes()), 0);
		Assert.equals(FontFixture.VARIABLE_UPEM, variable.upem);
		Assert.equals(FontFixture.VARIABLE_GLYPHS, variable.glyphCount);
	}

	public function testAFacesValuesCanBeSet():Void
	{
		var face = new HBFace(blobOf(FontFixture.monoBytes()), 0);

		face.upem = 1000;
		Assert.equals(1000, face.upem);

		face.glyphCount = 12;
		Assert.equals(12, face.glyphCount);

		face.index = 3;
		Assert.equals(3, face.index);
	}

	public function testAFaceOfBytesThatAreNotAFontHasNoGlyphs():Void
	{
		var face = new HBFace(blobOf(Bytes.ofString("This is not a font, and has no tables to read.")), 0);
		Assert.equals(0, face.glyphCount);
	}

	public function testTheEmptyFaceHasNoGlyphs():Void
	{
		Assert.equals(0, HBFace.empty.glyphCount);
	}

	// Fonts

	public function testANewFontIsScaledToItsFacesUnitsPerEm():Void
	{
		var font = monoFont();

		assertVector(FontFixture.MONO_UPEM, FontFixture.MONO_UPEM, font.scale);
		Assert.isFalse(font.immutable);
	}

	public function testScaleIsKeptAndScalesWhatTheFontMeasures():Void
	{
		var font = monoFont();
		font.scale = new Vector2(4096, 1024);

		assertVector(4096, 1024, font.scale);
		assertVector(FontFixture.MONO_ADVANCE * 2, 0, font.getGlyphAdvanceForDirection(H, HBDirection.LTR));
	}

	public function testPpemIsUnsetOnANewFont():Void
	{
		// hb_font_set_ppem: a font's pixels per em can be left unset, which is 0
		assertVector(0, 0, monoFont().ppem);
	}

	public function testPpemIsKept():Void
	{
		var font = monoFont();
		font.ppem = new Vector2(12, 16);

		assertVector(12, 16, font.ppem);
		assertVector(FontFixture.MONO_UPEM, FontFixture.MONO_UPEM, font.scale);
	}

	public function testAnImmutableFontIgnoresItsSetters():Void
	{
		var font = monoFont();
		font.makeImmutable();
		Assert.isTrue(font.immutable);

		font.scale = new Vector2(10, 10);
		assertVector(FontFixture.MONO_UPEM, FontFixture.MONO_UPEM, font.scale);
	}

	public function testASubFontStartsWithItsParentsScale():Void
	{
		// hb_font_create_sub_font: the new font replicates its parent's properties
		var font = monoFont();
		font.scale = new Vector2(4096, 4096);
		var sub = font.createSubFont();

		assertVector(4096, 4096, sub.scale);
		assertVector(FontFixture.MONO_ADVANCE * 2, 0, sub.getGlyphAdvanceForDirection(H, HBDirection.LTR));

		// Its own scale measures its parent's glyphs at that scale
		sub.scale = new Vector2(2048, 2048);
		assertVector(2048, 2048, sub.scale);
		assertVector(4096, 4096, font.scale);
		assertVector(FontFixture.MONO_ADVANCE, 0, sub.getGlyphAdvanceForDirection(H, HBDirection.LTR));
	}

	// Glyph functions

	public function testHorizontalAdvancesComeFromHmtx():Void
	{
		var mono = monoFont();
		assertVector(FontFixture.MONO_ADVANCE, 0, mono.getGlyphAdvanceForDirection(H, HBDirection.LTR));
		assertVector(FontFixture.MONO_ADVANCE, 0, mono.getGlyphAdvanceForDirection(H, HBDirection.RTL));

		// Each glyph of the proportional font has its own
		var variable = variableFont();

		for (glyph in 0...FontFixture.VARIABLE_ADVANCES.length)
		{
			var advance = variable.getGlyphAdvanceForDirection(glyph, HBDirection.LTR);
			Assert.equals(FontFixture.VARIABLE_ADVANCES[glyph], Std.int(advance.x), "glyph " + glyph);
			Assert.equals(0, Std.int(advance.y), "glyph " + glyph);
		}
	}

	public function testVerticalAdvancesRunDownThePage():Void
	{
		// The y axis points up, so an advance down the page is negative
		var advance = monoFont().getGlyphAdvanceForDirection(H, HBDirection.TTB);

		Assert.equals(0, Std.int(advance.x));
		Assert.isTrue(advance.y < 0, "advanced " + advance.y);
	}

	public function testAGlyphsOriginIsTheBaselineForHorizontalText():Void
	{
		var font = monoFont();
		assertVector(0, 0, font.getGlyphOriginForDirection(H, HBDirection.LTR));

		// For vertical text HarfBuzz centers the glyph on the line, above the baseline
		var origin = font.getGlyphOriginForDirection(H, HBDirection.TTB);
		Assert.equals(Std.int(FontFixture.MONO_ADVANCE / 2), Std.int(origin.x));
		Assert.isTrue(origin.y > 0, "origin at " + origin.y);
	}

	public function testAFontWithoutAKernTableHasNoKerning():Void
	{
		// hb_font_get_glyph_kerning_for_direction reads kern, which neither font has
		assertVector(0, 0, monoFont().getGlyphKerningForDirection(0, 34, 55, HBDirection.LTR));
		assertVector(0, 0, variableFont().getGlyphKerningForDirection(0, 9, 6, HBDirection.LTR));
	}

	public function testAGlyphWithoutANameIsNamedByItsNumber():Void
	{
		// hb_font_glyph_to_string: gidDDD when the font has no name for the glyph, as with post format 3
		var font = monoFont();

		Assert.equals("gid" + H, font.glyphToString(H));
		Assert.equals("gid0", font.glyphToString(0));
	}

	public function testGlyphFromStringReadsNumbersAndCharacters():Void
	{
		// hb_font_glyph_from_string: gidDDD and uniUUUU are parsed
		var font = monoFont();

		Assert.equals(H, font.glyphFromString("gid" + H));
		Assert.equals(H, font.glyphFromString("uni0048"));
		Assert.equals(FontFixture.monoGlyph("~".code), font.glyphFromString("uni007E"));
		Assert.isTrue(font.glyphFromString("no-such-glyph") < 0);
	}

	// FreeType fonts

	public function testAnFTFontIsScaledToItsFontsSize():Void
	{
		// hb-ft gives positions in 26.6 pixels, so a 32 pixel font has a scale of 32 * 64
		var font = sizedFont(FontFixture.MONO_PATH, 32);
		var hbFont = new HBFTFont(font);

		assertVector(32 * 64, 32 * 64, hbFont.scale);
		// At that size an em is 2048 units, as in the font
		assertVector(FontFixture.MONO_ADVANCE, 0, hbFont.getGlyphAdvanceForDirection(H, HBDirection.LTR));
	}

	public function testAnFTFontMeasuresWithoutHintingUnlessToldTo():Void
	{
		// hb_ft_font_set_load_flags: the default is FT_LOAD_DEFAULT | FT_LOAD_NO_HINTING
		var font = sizedFont(FontFixture.MONO_PATH, 20);
		var hbFont = new HBFTFont(font);
		Assert.equals(NO_HINTING, hbFont.loadFlags);

		// 1229 / 2048 of 20 pixels, in 26.6: not a whole pixel
		var advance = hbFont.getGlyphAdvanceForDirection(H, HBDirection.LTR);
		Assert.isTrue(Math.abs(advance.x - FontFixture.MONO_ADVANCE * 20 * 64 / FontFixture.MONO_UPEM) <= 1, "advanced " + advance.x);

		// A hinted advance is a whole number of pixels
		hbFont.loadFlags = FORCE_AUTOHINT;
		Assert.equals(FORCE_AUTOHINT, hbFont.loadFlags);
		advance = hbFont.getGlyphAdvanceForDirection(H, HBDirection.LTR);
		Assert.equals(0, Std.int(advance.x) % 64, "advanced " + advance.x);
		Assert.isTrue(Math.abs(advance.x - 768) <= 64, "advanced " + advance.x);
	}

	public function testChangedTakesUpTheFontsNewSize():Void
	{
		// hb_ft_font_changed: to be called after the size of the FT_Face changes
		var font = sizedFont(FontFixture.MONO_PATH, 32);
		var hbFont = new HBFTFont(font);

		@:privateAccess font.__setSize(16);
		hbFont.changed();

		assertVector(16 * 64, 16 * 64, hbFont.scale);
	}

	public function testAnFTFontNamesAndFindsGlyphsAsTheFontDoes():Void
	{
		var hbFont = new HBFTFont(sizedFont(FontFixture.MONO_PATH, 32));

		Assert.equals("gid" + H, hbFont.glyphToString(H));
		Assert.equals(H, hbFont.glyphFromString("uni0048"));
	}

	public function testAFontWithoutDataGivesNoFTFont():Void
	{
		var hbFont = new HBFTFont(new Font());
		Assert.isTrue(hbFont == null);
	}

	public function testAnFTFontOutlivesTheFontItWasMadeFrom():Void
	{
		// hb_ft_font_create_referenced: the FT_Face stays alive for as long as the font made from it
		var hbFonts = [for (i in 0...HANDLES) orphanedFTFont()];

		for (round in 0...ROUNDS)
		{
			churn();
			collect();
		}

		for (hbFont in hbFonts)
		{
			assertVector(FontFixture.MONO_ADVANCE, 0, hbFont.getGlyphAdvanceForDirection(H, HBDirection.LTR));
		}
	}

	public function testReadingAFontsFaceLeavesTheFaceInUse():Void
	{
		// hb_font_get_face returns the font's own face, not a reference to release
		var face = new HBFace(blobOf(FontFixture.monoBytes()), 0);
		var font = new HBFont(face);

		for (round in 0...ROUNDS)
		{
			Assert.equals(HANDLES * FontFixture.MONO_GLYPHS, countGlyphsThroughFace(font));
			collect();
		}

		Assert.equals(FontFixture.MONO_UPEM, face.upem);
		Assert.equals(FontFixture.MONO_GLYPHS, face.glyphCount);
		assertVector(FontFixture.MONO_ADVANCE, 0, font.getGlyphAdvanceForDirection(H, HBDirection.LTR));
	}

	public function testReadingASubFontsParentLeavesTheParentInUse():Void
	{
		// hb_font_get_parent returns the font's own parent, not a reference to release
		var font = monoFont();
		var sub = font.createSubFont();

		for (round in 0...ROUNDS)
		{
			Assert.equals(HANDLES * FontFixture.MONO_UPEM, sumScalesThroughParent(sub));
			collect();
		}

		assertVector(FontFixture.MONO_UPEM, FontFixture.MONO_UPEM, font.scale);
		assertVector(FontFixture.MONO_ADVANCE, 0, sub.getGlyphAdvanceForDirection(H, HBDirection.LTR));
	}

	private static function orphanedFTFont():HBFTFont
	{
		return new HBFTFont(sizedFont(FontFixture.MONO_PATH, 32));
	}

	private static function countGlyphsThroughFace(font:HBFont):Int
	{
		var count = 0;

		for (i in 0...HANDLES)
		{
			count += font.face.glyphCount;
		}

		return count;
	}

	private static function sumScalesThroughParent(font:HBFont):Int
	{
		var sum = 0;

		for (i in 0...HANDLES)
		{
			sum += Std.int(font.parent.scale.x);
		}

		return sum;
	}

	// Garbage of the size of a font, to be given the memory a freed one had
	private static function churn():Void
	{
		var kept = [];

		for (i in 0...64)
		{
			var bytes = Bytes.alloc(16384);
			bytes.fill(0, bytes.length, 0xAA);
			kept.push(bytes);
		}
	}

	private static function collect():Void
	{
		#if cpp
		cpp.vm.Gc.run(true);
		#elseif neko
		neko.vm.Gc.run(true);
		#elseif hl
		hl.Gc.major();
		#end
	}

	// Languages

	public function testALanguageKeepsItsTag():Void
	{
		Assert.equals("en", new HBLanguage("en").toString());
		Assert.equals("zh-hant", new HBLanguage("zh-hant").toString());
	}

	public function testLanguageTagsAreNotCaseSensitive():Void
	{
		// BCP 47 tags compare without case, and HarfBuzz gives them back in lower case
		Assert.equals("pt-br", new HBLanguage("pt-BR").toString().toLowerCase());
		Assert.equals(new HBLanguage("pt-br").toString(), new HBLanguage("PT-BR").toString());
	}

	public function testAStringConvertsToALanguage():Void
	{
		var language:HBLanguage = "de";
		Assert.equals("de", language.toString());
	}

	public function testTheDefaultLanguageHasATag():Void
	{
		// hb_language_get_default: the language of the process's locale
		var tag = new HBLanguage().toString();

		Assert.notNull(tag);
		if (tag == null) return;
		Assert.isTrue(tag.length > 0);
		Assert.equals(tag, new HBLanguage().toString());
	}

	public function testAnEmptyTagIsNoLanguage():Void
	{
		// hb_language_from_string gives HB_LANGUAGE_INVALID, which has no string
		Assert.isNull(new HBLanguage("").toString());
	}

	// Helpers

	private static function blobOf(bytes:Bytes):HBBlob
	{
		return new HBBlob(DataPointer.fromBytes(bytes), bytes.length, HBMemoryMode.DUPLICATE);
	}

	private static function monoFont():HBFont
	{
		return new HBFont(new HBFace(blobOf(FontFixture.monoBytes()), 0));
	}

	private static function variableFont():HBFont
	{
		return new HBFont(new HBFace(blobOf(FontFixture.variableBytes()), 0));
	}

	/** A font at `size` pixels to the em, as OpenFL's text engine sizes one before shaping with it **/
	private static function sizedFont(path:String, size:Int):Font
	{
		var font = Font.fromFile(path);
		@:privateAccess font.__setSize(size);
		return font;
	}

	private static function address(pointer:DataPointer):Float
	{
		return pointer;
	}

	private static function assertVector(x:Float, y:Float, actual:Vector2, ?pos:haxe.PosInfos):Void
	{
		Assert.notNull(actual, pos);
		if (actual == null) return;

		Assert.isTrue(actual.x == x && actual.y == y, "expected (" + x + ", " + y + ") but it is (" + actual.x + ", " + actual.y + ")", pos);
	}
	#end
}
