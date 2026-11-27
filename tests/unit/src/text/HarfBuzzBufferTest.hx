package text;

#if (lime_cffi && lime_harfbuzz && !macro)
import haxe.io.Bytes;
import lime.text.harfbuzz.HBBuffer;
import lime.text.harfbuzz.HBBufferClusterLevel;
import lime.text.harfbuzz.HBBufferContentType;
import lime.text.harfbuzz.HBBufferFlags;
import lime.text.harfbuzz.HBDirection;
import lime.text.harfbuzz.HBLanguage;
import lime.text.harfbuzz.HBScript;
import lime.utils.DataPointer;
#end
import utest.Assert;
import utest.Test;

/**
	`HBBuffer` against HarfBuzz's API reference for hb_buffer_t: what a new buffer
	holds, how text of each encoding is added with its clusters, and what the
	properties and the operations on the contents are documented to do. The scripts
	expected of characters are those of the Unicode Character Database.
**/
class HarfBuzzBufferTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_harfbuzz && !macro)
	// A character of each script in HBScript that text can have, from Scripts.txt
	private static var SCRIPT_SAMPLES:Array<Array<Int>> = [
		[HBScript.ARABIC, 0x0627],
		[HBScript.ARMENIAN, 0x0531],
		[HBScript.BENGALI, 0x0995],
		[HBScript.CYRILLIC, 0x0416],
		[HBScript.DEVANAGARI, 0x0915],
		[HBScript.GEORGIAN, 0x10D0],
		[HBScript.GREEK, 0x03A9],
		[HBScript.GUJARATI, 0x0A95],
		[HBScript.GURMUKHI, 0x0A15],
		[HBScript.HANGUL, 0xAC00],
		[HBScript.HAN, 0x4E2D],
		[HBScript.HEBREW, 0x05D0],
		[HBScript.HIRAGANA, 0x3042],
		[HBScript.KANNADA, 0x0C95],
		[HBScript.KATAKANA, 0x30A2],
		[HBScript.LAO, 0x0E81],
		[HBScript.LATIN, 0x0041],
		[HBScript.MALAYALAM, 0x0D15],
		[HBScript.ORIYA, 0x0B15],
		[HBScript.TAMIL, 0x0B95],
		[HBScript.TELUGU, 0x0C15],
		[HBScript.THAI, 0x0E01],
		[HBScript.TIBETAN, 0x0F40],
		[HBScript.BOPOMOFO, 0x3105],
		[HBScript.BRAILLE, 0x2801],
		[HBScript.CANADIAN_SYLLABICS, 0x1401],
		[HBScript.CHEROKEE, 0x13A0],
		[HBScript.ETHIOPIC, 0x1200],
		[HBScript.KHMER, 0x1780],
		[HBScript.MONGOLIAN, 0x1820],
		[HBScript.MYANMAR, 0x1000],
		[HBScript.OGHAM, 0x1681],
		[HBScript.RUNIC, 0x16A0],
		[HBScript.SINHALA, 0x0D85],
		[HBScript.SYRIAC, 0x0710],
		[HBScript.THAANA, 0x0780],
		[HBScript.YI, 0xA000],
		[HBScript.DESERET, 0x10400],
		[HBScript.GOTHIC, 0x10330],
		[HBScript.OLD_ITALIC, 0x10300],
		[HBScript.BUHID, 0x1740],
		[HBScript.HANUNOO, 0x1720],
		[HBScript.TAGALOG, 0x1700],
		[HBScript.TAGBANWA, 0x1760],
		[HBScript.CYPRIOT, 0x10800],
		[HBScript.LIMBU, 0x1900],
		[HBScript.LINEAR_B, 0x10000],
		[HBScript.OSMANYA, 0x10480],
		[HBScript.SHAVIAN, 0x10450],
		[HBScript.TAI_LE, 0x1950],
		[HBScript.UGARITIC, 0x10380],
		[HBScript.BUGINESE, 0x1A00],
		[HBScript.COPTIC, 0x2C80],
		[HBScript.GLAGOLITIC, 0x2C00],
		[HBScript.KHAROSHTHI, 0x10A00],
		[HBScript.NEW_TAI_LUE, 0x1980],
		[HBScript.OLD_PERSIAN, 0x103A0],
		[HBScript.SYLOTI_NAGRI, 0xA800],
		[HBScript.TIFINAGH, 0x2D30],
		[HBScript.BALINESE, 0x1B05],
		[HBScript.CUNEIFORM, 0x12000],
		[HBScript.NKO, 0x07CA],
		[HBScript.PHAGS_PA, 0xA840],
		[HBScript.PHOENICIAN, 0x10900],
		[HBScript.CARIAN, 0x102A0],
		[HBScript.CHAM, 0xAA00],
		[HBScript.KAYAH_LI, 0xA90A],
		[HBScript.LEPCHA, 0x1C00],
		[HBScript.LYCIAN, 0x10280],
		[HBScript.LYDIAN, 0x10920],
		[HBScript.OL_CHIKI, 0x1C5A],
		[HBScript.REJANG, 0xA930],
		[HBScript.SAURASHTRA, 0xA882],
		[HBScript.SUNDANESE, 0x1B83],
		[HBScript.VAI, 0xA500],
		[HBScript.AVESTAN, 0x10B00],
		[HBScript.BAMUM, 0xA6A0],
		[HBScript.EGYPTIAN_HIEROGLYPHS, 0x13000],
		[HBScript.IMPERIAL_ARAMAIC, 0x10840],
		[HBScript.INSCRIPTIONAL_PAHLAVI, 0x10B60],
		[HBScript.INSCRIPTIONAL_PARTHIAN, 0x10B40],
		[HBScript.JAVANESE, 0xA984],
		[HBScript.KAITHI, 0x11083],
		[HBScript.LISU, 0xA4D0],
		[HBScript.MEETEI_MAYEK, 0xABC0],
		[HBScript.OLD_SOUTH_ARABIAN, 0x10A60],
		[HBScript.OLD_TURKIC, 0x10C00],
		[HBScript.SAMARITAN, 0x0800],
		[HBScript.TAI_THAM, 0x1A20],
		[HBScript.TAI_VIET, 0xAA80],
		[HBScript.BATAK, 0x1BC0],
		[HBScript.BRAHMI, 0x11005],
		[HBScript.MANDAIC, 0x0840],
		[HBScript.CHAKMA, 0x11103],
		[HBScript.MEROITIC_CURSIVE, 0x109A0],
		[HBScript.MEROITIC_HIEROGLYPHS, 0x10980],
		[HBScript.MIAO, 0x16F00],
		[HBScript.SHARADA, 0x11183],
		[HBScript.SORA_SOMPENG, 0x110D0],
		[HBScript.TAKRI, 0x11680],
		[HBScript.BASSA_VAH, 0x16AD0],
		[HBScript.CAUCASIAN_ALBANIAN, 0x10530],
		[HBScript.DUPLOYAN, 0x1BC00],
		[HBScript.ELBASAN, 0x10500],
		[HBScript.GRANTHA, 0x11305],
		[HBScript.KHOJKI, 0x11200],
		[HBScript.KHUDAWADI, 0x112B0],
		[HBScript.LINEAR_A, 0x10600],
		[HBScript.MAHAJANI, 0x11150],
		[HBScript.MANICHAEAN, 0x10AC0],
		[HBScript.MENDE_KIKAKUI, 0x1E800],
		[HBScript.MODI, 0x11600],
		[HBScript.MRO, 0x16A40],
		[HBScript.NABATAEAN, 0x10880],
		[HBScript.OLD_NORTH_ARABIAN, 0x10A80],
		[HBScript.OLD_PERMIC, 0x10350],
		[HBScript.PAHAWH_HMONG, 0x16B00],
		[HBScript.PALMYRENE, 0x10860],
		[HBScript.PAU_CIN_HAU, 0x11AC0],
		[HBScript.PSALTER_PAHLAVI, 0x10B80],
		[HBScript.SIDDHAM, 0x11580],
		[HBScript.TIRHUTA, 0x11481],
		[HBScript.WARANG_CITI, 0x118A0],
		[HBScript.AHOM, 0x11700],
		[HBScript.ANATOLIAN_HIEROGLYPHS, 0x14400],
		[HBScript.HATRAN, 0x108E0],
		[HBScript.MULTANI, 0x11280],
		[HBScript.OLD_HUNGARIAN, 0x10C80],
		[HBScript.SIGNWRITING, 0x1D800],
		[HBScript.ADLAM, 0x1E900],
		[HBScript.BHAIKSUKI, 0x11C00],
		[HBScript.MARCHEN, 0x11C72],
		[HBScript.OSAGE, 0x104B0],
		[HBScript.TANGUT, 0x17000],
		[HBScript.NEWA, 0x11400],
		[HBScript.MASARAM_GONDI, 0x11D00],
		[HBScript.NUSHU, 0x1B170],
		[HBScript.SOYOMBO, 0x11A50],
		[HBScript.ZANABAZAR_SQUARE, 0x11A00],
		[HBScript.DOGRA, 0x11800],
		[HBScript.GUNJALA_GONDI, 0x11D60],
		[HBScript.HANIFI_ROHINGYA, 0x10D00],
		[HBScript.MAKASAR, 0x11EE0],
		[HBScript.MEDEFAIDRIN, 0x16E40],
		[HBScript.OLD_SOGDIAN, 0x10F00],
		[HBScript.SOGDIAN, 0x10F30]
	];

	// A new buffer

	public function testANewBufferIsEmptyWithNothingSet():Void
	{
		// hb_buffer_create, and the defaults each getter documents
		var buffer = new HBBuffer();

		Assert.equals(0, buffer.length);
		Assert.isTrue(buffer.allocationSuccessful);
		Assert.equals((HBBufferContentType.INVALID : Int), (buffer.contentType : Int));
		Assert.equals((HBDirection.INVALID : Int), (buffer.direction : Int));
		Assert.equals((HBScript.INVALID : Int), (buffer.script : Int));
		Assert.isNull(languageOf(buffer));
		Assert.equals((HBBufferFlags.DEFAULT : Int), buffer.flags);
		Assert.equals((HBBufferClusterLevel.DEFAULT : Int), (buffer.clusterLevel : Int));
		// HB_BUFFER_REPLACEMENT_CODEPOINT_DEFAULT
		Assert.equals(0xFFFD, buffer.replacementCodepoint);
	}

	public function testAnEmptyBufferHasNoGlyphs():Void
	{
		var buffer = new HBBuffer();
		var infos = buffer.getGlyphInfo();
		var positions = buffer.getGlyphPositions();

		Assert.isTrue(infos == null || infos.length == 0);
		Assert.isTrue(positions == null || positions.length == 0);
	}

	// Adding text

	public function testAddAppendsACodepointWithItsCluster():Void
	{
		var buffer = new HBBuffer();
		buffer.add(0x41, 0);
		buffer.add(0x1F600, 7);
		buffer.add(0x10FFFF, 300000);

		Assert.equals(3, buffer.length);
		Assert.same([0x41, 0x1F600, 0x10FFFF], codepoints(buffer));
		Assert.same([0, 7, 300000], clusters(buffer));
	}

	public function testAddUTF8GivesEachCharacterTheOffsetOfItsFirstByte():Void
	{
		// One, two, three and four bytes, then one
		var buffer = new HBBuffer();
		buffer.addUTF8("aé€\u{1F600}b", 0, -1);

		Assert.equals(5, buffer.length);
		Assert.same([0x61, 0xE9, 0x20AC, 0x1F600, 0x62], codepoints(buffer));
		Assert.same([0, 1, 3, 6, 10], clusters(buffer));
		Assert.equals((HBBufferContentType.UNICODE : Int), (buffer.contentType : Int));
	}

	public function testAddUTF8ReadsCharactersLedByE0EDAndF4():Void
	{
		// U+0800 is E0 A0 80, U+D7FF is ED 9F BF and U+10FFFF is F4 8F BF BF
		var buffer = new HBBuffer();
		buffer.addUTF8("ࠀ퟿\u{10FFFF}", 0, -1);

		Assert.same([0x800, 0xD7FF, 0x10FFFF], codepoints(buffer));
		Assert.same([0, 3, 6], clusters(buffer));
	}

	public function testAddUTF8TakesItsItemOffsetAndLengthInBytes():Void
	{
		// The item is the part of the text to add, the rest is its context
		var buffer = new HBBuffer();
		buffer.addUTF8("abcdef", 2, 3);
		Assert.same([0x63, 0x64, 0x65], codepoints(buffer));
		Assert.same([2, 3, 4], clusters(buffer));

		buffer = new HBBuffer();
		buffer.addUTF8("aé€b", 1, 5);
		Assert.same([0xE9, 0x20AC], codepoints(buffer));
		Assert.same([1, 3], clusters(buffer));

		// A length of -1 runs to the end of the text
		buffer = new HBBuffer();
		buffer.addUTF8("abcdef", 4, -1);
		Assert.same([0x65, 0x66], codepoints(buffer));
		Assert.same([4, 5], clusters(buffer));
	}

	public function testAddingAgainAppendsToTheContents():Void
	{
		var buffer = new HBBuffer();
		buffer.addUTF8("ab", 0, -1);
		buffer.addUTF8("cd", 0, -1);

		Assert.same([0x61, 0x62, 0x63, 0x64], codepoints(buffer));
		// Clusters index the text of each call
		Assert.same([0, 1, 0, 1], clusters(buffer));
	}

	public function testAddUTF8OfNoTextAddsNothing():Void
	{
		var buffer = new HBBuffer();
		buffer.addUTF8("", 0, -1);
		Assert.equals(0, buffer.length);
	}

	public function testAddUTF16JoinsSurrogatePairsAndCountsInCodeUnits():Void
	{
		// a, U+1F600 as D83D DE00, b
		var text = utf16([0x61, 0xD83D, 0xDE00, 0x62]);
		var buffer = new HBBuffer();
		buffer.addUTF16(DataPointer.fromBytes(text), 4, 0, -1);

		Assert.same([0x61, 0x1F600, 0x62], codepoints(buffer));
		Assert.same([0, 1, 3], clusters(buffer));
		Assert.equals((HBBufferContentType.UNICODE : Int), (buffer.contentType : Int));

		buffer = new HBBuffer();
		buffer.addUTF16(DataPointer.fromBytes(text), 4, 1, 2);
		Assert.same([0x1F600], codepoints(buffer));
		Assert.same([1], clusters(buffer));

		buffer = new HBBuffer();
		buffer.addUTF16(DataPointer.fromBytes(text), 4, 3, 1);
		Assert.same([0x62], codepoints(buffer));
		Assert.same([3], clusters(buffer));
	}

	public function testAddUTF16ReplacesASurrogateWithoutItsPair():Void
	{
		// hb_buffer_add_utf16: invalid UTF-16 becomes the replacement code point
		var text = utf16([0xD83D, 0x62, 0xDE00]);
		var buffer = new HBBuffer();
		buffer.addUTF16(DataPointer.fromBytes(text), 3, 0, -1);

		Assert.same([0xFFFD, 0x62, 0xFFFD], codepoints(buffer));
		Assert.same([0, 1, 2], clusters(buffer));
	}

	public function testAddUTF32TakesCodePointsAndReplacesInvalidOnes():Void
	{
		var text = utf32([0x61, 0x1F600, 0x10FFFF, 0x62]);
		var buffer = new HBBuffer();
		buffer.addUTF32(DataPointer.fromBytes(text), 4, 0, -1);

		Assert.same([0x61, 0x1F600, 0x10FFFF, 0x62], codepoints(buffer));
		Assert.same([0, 1, 2, 3], clusters(buffer));

		buffer = new HBBuffer();
		buffer.addUTF32(DataPointer.fromBytes(text), 4, 1, 2);
		Assert.same([0x1F600, 0x10FFFF], codepoints(buffer));
		Assert.same([1, 2], clusters(buffer));

		// A surrogate and a value past U+10FFFF are not characters
		buffer = new HBBuffer();
		buffer.addUTF32(DataPointer.fromBytes(utf32([0xD800, 0x41, 0x110000])), 3, 0, -1);
		Assert.same([0xFFFD, 0x41, 0xFFFD], codepoints(buffer));
	}

	public function testTheReplacementCodepointStandsInForInvalidText():Void
	{
		var buffer = new HBBuffer();
		buffer.replacementCodepoint = 0x3F;
		Assert.equals(0x3F, buffer.replacementCodepoint);

		buffer.addUTF32(DataPointer.fromBytes(utf32([0x41, 0xDFFF])), 2, 0, -1);
		Assert.same([0x41, 0x3F], codepoints(buffer));
	}

	public function testAddCodepointsKeepsValuesAsTheyAre():Void
	{
		// hb_buffer_add_codepoints does not check its text, where hb_buffer_add_utf32 does
		var text = utf32([0x61, 0xD800, 0x110000, 0x1F600]);
		var buffer = new HBBuffer();
		buffer.addCodepoints(DataPointer.fromBytes(text), 4, 0, -1);

		Assert.same([0x61, 0xD800, 0x110000, 0x1F600], codepoints(buffer));
		Assert.same([0, 1, 2, 3], clusters(buffer));
		Assert.equals((HBBufferContentType.UNICODE : Int), (buffer.contentType : Int));

		buffer = new HBBuffer();
		buffer.addCodepoints(DataPointer.fromBytes(text), 4, 3, 1);
		Assert.same([0x1F600], codepoints(buffer));
		Assert.same([3], clusters(buffer));
	}

	public function testAddStringGivesClustersThatIndexTheString():Void
	{
		// However the target stores a String, a cluster is where its character starts in it
		var text = "a\u{1F600}b";
		var last = text.length - 1;
		var buffer = new HBBuffer();
		buffer.addString(text, 0, -1);

		Assert.same([0x61, 0x1F600, 0x62], codepoints(buffer));
		Assert.same([0, 1, last], clusters(buffer));
		Assert.equals("b", text.charAt(clusters(buffer)[2]));

		buffer = new HBBuffer();
		buffer.addString(text, last, 1);
		Assert.same([0x62], codepoints(buffer));
		Assert.same([last], clusters(buffer));

		buffer = new HBBuffer();
		buffer.addString(text, 1, last - 1);
		Assert.same([0x1F600], codepoints(buffer));
		Assert.same([1], clusters(buffer));
	}

	public function testAddStringOfPlainTextCountsCharacters():Void
	{
		var buffer = new HBBuffer();
		buffer.addString("abcdef", 2, 3);

		Assert.same([0x63, 0x64, 0x65], codepoints(buffer));
		Assert.same([2, 3, 4], clusters(buffer));
	}

	// Contents

	public function testPositionsAreZeroBeforeShaping():Void
	{
		// hb_buffer_get_glyph_positions: positions a buffer did not have start as zeros
		var buffer = new HBBuffer();
		buffer.addUTF8("abc", 0, -1);
		var positions = buffer.getGlyphPositions();

		Assert.notNull(positions);
		if (positions == null) return;

		Assert.equals(3, positions.length);

		for (position in positions)
		{
			Assert.equals(0, position.xAdvance);
			Assert.equals(0, position.yAdvance);
			Assert.equals(0, position.xOffset);
			Assert.equals(0, position.yOffset);
		}
	}

	public function testSettingALengthCutsOrExtendsTheContents():Void
	{
		// hb_buffer_set_length: items past the old length are cleared
		var buffer = new HBBuffer();
		buffer.addUTF8("abc", 0, -1);

		buffer.length = 2;
		Assert.equals(2, buffer.length);
		Assert.same([0x61, 0x62], codepoints(buffer));

		buffer.length = 4;
		Assert.equals(4, buffer.length);
		Assert.same([0x61, 0x62, 0, 0], codepoints(buffer));
		Assert.same([0, 1, 0, 0], clusters(buffer));

		buffer.length = 0;
		Assert.equals(0, buffer.length);
	}

	public function testReverseReversesTheContents():Void
	{
		var buffer = new HBBuffer();
		buffer.addUTF8("abc", 0, -1);
		buffer.reverse();

		Assert.same([0x63, 0x62, 0x61], codepoints(buffer));
		Assert.same([2, 1, 0], clusters(buffer));
	}

	public function testReverseClustersKeepsTheOrderInsideEachCluster():Void
	{
		// hb_buffer_reverse_clusters: the contents are reversed, then each run of one cluster is reversed again
		var buffer = new HBBuffer();
		buffer.add(0x41, 0);
		buffer.add(0x42, 0);
		buffer.add(0x43, 1);
		buffer.add(0x44, 2);
		buffer.add(0x45, 2);
		buffer.reverseClusters();

		Assert.same([0x44, 0x45, 0x43, 0x41, 0x42], codepoints(buffer));
		Assert.same([2, 2, 1, 0, 0], clusters(buffer));
	}

	public function testPreallocateLeavesTheContentsAlone():Void
	{
		var buffer = new HBBuffer();
		buffer.addUTF8("ab", 0, -1);

		Assert.isTrue(buffer.preallocate(4096));
		Assert.isTrue(buffer.allocationSuccessful);
		Assert.equals(2, buffer.length);
		Assert.same([0x61, 0x62], codepoints(buffer));
	}

	public function testClearContentsEmptiesTheBufferAndKeepsTheReplacementCodepoint():Void
	{
		// hb_buffer_clear_contents: as hb_buffer_reset, but the replacement code point stays
		var buffer = filledBuffer();
		buffer.clearContents();

		Assert.equals(0, buffer.length);
		Assert.equals((HBBufferContentType.INVALID : Int), (buffer.contentType : Int));
		Assert.equals((HBDirection.INVALID : Int), (buffer.direction : Int));
		Assert.isNull(languageOf(buffer));
		Assert.equals(0x3F, buffer.replacementCodepoint);

		// The buffer takes new text
		buffer.addUTF8("z", 0, -1);
		Assert.same([0x7A], codepoints(buffer));
	}

	public function testResetReturnsTheBufferToHowItWasCreated():Void
	{
		var buffer = filledBuffer();
		buffer.reset();

		Assert.equals(0, buffer.length);
		Assert.equals((HBBufferContentType.INVALID : Int), (buffer.contentType : Int));
		Assert.equals((HBDirection.INVALID : Int), (buffer.direction : Int));
		Assert.equals((HBScript.INVALID : Int), (buffer.script : Int));
		Assert.isNull(languageOf(buffer));
		Assert.equals((HBBufferFlags.DEFAULT : Int), buffer.flags);
		Assert.equals((HBBufferClusterLevel.DEFAULT : Int), (buffer.clusterLevel : Int));
		Assert.equals(0xFFFD, buffer.replacementCodepoint);
	}

	// Properties

	public function testDirectionIsKept():Void
	{
		var buffer = new HBBuffer();

		for (direction in [HBDirection.LTR, HBDirection.RTL, HBDirection.TTB, HBDirection.BTT, HBDirection.INVALID])
		{
			buffer.direction = direction;
			Assert.equals((direction : Int), (buffer.direction : Int));
		}
	}

	public function testScriptIsKept():Void
	{
		var buffer = new HBBuffer();

		for (script in [HBScript.LATIN, HBScript.ARABIC, HBScript.HAN, HBScript.COMMON, HBScript.INVALID])
		{
			buffer.script = script;
			Assert.equals(tag(script), tag(buffer.script));
		}
	}

	public function testLanguageIsKept():Void
	{
		var buffer = new HBBuffer();
		buffer.language = new HBLanguage("fr");
		Assert.equals("fr", languageOf(buffer));

		buffer.language = new HBLanguage("ar");
		Assert.equals("ar", languageOf(buffer));
	}

	public function testFlagsAreKept():Void
	{
		var buffer = new HBBuffer();
		var both:Int = (HBBufferFlags.BOT : Int) | (HBBufferFlags.EOT : Int);

		buffer.flags = both;
		Assert.equals(both, buffer.flags);

		buffer.flags = HBBufferFlags.PRESERVE_DEFAULT_IGNORABLES;
		Assert.equals((HBBufferFlags.PRESERVE_DEFAULT_IGNORABLES : Int), buffer.flags);

		buffer.flags = HBBufferFlags.DEFAULT;
		Assert.equals(0, buffer.flags);
	}

	public function testClusterLevelIsKept():Void
	{
		var buffer = new HBBuffer();

		for (level in [
			HBBufferClusterLevel.CHARACTERS,
			HBBufferClusterLevel.MONOTONE_CHARACTERS,
			HBBufferClusterLevel.MONOTONE_GRAPHEMES
		])
		{
			buffer.clusterLevel = level;
			Assert.equals((level : Int), (buffer.clusterLevel : Int));
		}
	}

	public function testContentTypeIsKept():Void
	{
		var buffer = new HBBuffer();
		buffer.add(0x41, 0);

		buffer.contentType = HBBufferContentType.UNICODE;
		Assert.equals((HBBufferContentType.UNICODE : Int), (buffer.contentType : Int));

		buffer.contentType = HBBufferContentType.GLYPHS;
		Assert.equals((HBBufferContentType.GLYPHS : Int), (buffer.contentType : Int));
	}

	public function testSegmentPropertiesAreThoseOfTheBuffer():Void
	{
		// hb_buffer_get_segment_properties: the direction, script and language together
		var buffer = new HBBuffer();
		buffer.direction = HBDirection.RTL;
		buffer.language = new HBLanguage("he");

		Assert.notNull(buffer.segmentProperties);
	}

	public function testSegmentPropertiesCopyFromOneBufferToAnother():Void
	{
		// hb_buffer_set_segment_properties: as setting the direction, script and language one by one
		var source = new HBBuffer();
		source.direction = HBDirection.RTL;
		source.language = new HBLanguage("he");

		var target = new HBBuffer();
		target.segmentProperties = source.segmentProperties;

		Assert.equals((HBDirection.RTL : Int), (target.direction : Int));
		Assert.equals("he", languageOf(target));
	}

	// Guessing the properties

	public function testGuessingGivesLatinTextItsScriptAndDirection():Void
	{
		var buffer = new HBBuffer();
		buffer.addUTF8("Hello", 0, -1);
		buffer.guessSegmentProperties();

		Assert.equals(tag(HBScript.LATIN), tag(buffer.script));
		Assert.equals((HBDirection.LTR : Int), (buffer.direction : Int));
		// An unset language becomes the default one
		Assert.notNull(languageOf(buffer));
		Assert.equals(new HBLanguage().toString(), languageOf(buffer));
	}

	public function testGuessingGivesHebrewAndArabicTextTheirScriptsFromRightToLeft():Void
	{
		var buffer = new HBBuffer();
		buffer.addUTF8("שלום", 0, -1);
		buffer.guessSegmentProperties();
		Assert.equals(tag(HBScript.HEBREW), tag(buffer.script));
		Assert.equals((HBDirection.RTL : Int), (buffer.direction : Int));

		buffer = new HBBuffer();
		buffer.addUTF8("سلام", 0, -1);
		buffer.guessSegmentProperties();
		Assert.equals(tag(HBScript.ARABIC), tag(buffer.script));
		Assert.equals((HBDirection.RTL : Int), (buffer.direction : Int));
	}

	public function testGuessingSkipsCharactersWithoutAScriptOfTheirOwn():Void
	{
		// Digits, spaces and punctuation are Common, so the first letter decides
		var buffer = new HBBuffer();
		buffer.addUTF8("12 (Ж)", 0, -1);
		buffer.guessSegmentProperties();
		Assert.equals(tag(HBScript.CYRILLIC), tag(buffer.script));
		Assert.equals((HBDirection.LTR : Int), (buffer.direction : Int));

		// With nothing but Common characters the script stays unset, and the direction is left to right
		buffer = new HBBuffer();
		buffer.addUTF8("123", 0, -1);
		buffer.guessSegmentProperties();
		Assert.equals(tag(HBScript.INVALID), tag(buffer.script));
		Assert.equals((HBDirection.LTR : Int), (buffer.direction : Int));
	}

	public function testGuessingLeavesPropertiesThatAreSet():Void
	{
		var buffer = new HBBuffer();
		buffer.addUTF8("Hello", 0, -1);
		buffer.direction = HBDirection.RTL;
		buffer.language = new HBLanguage("tr");
		buffer.guessSegmentProperties();

		Assert.equals((HBDirection.RTL : Int), (buffer.direction : Int));
		Assert.equals("tr", languageOf(buffer));
		Assert.equals(tag(HBScript.LATIN), tag(buffer.script));
	}

	public function testEveryScriptConstantIsTheTagHarfBuzzGivesItsCharacters():Void
	{
		for (sample in SCRIPT_SAMPLES)
		{
			var buffer = new HBBuffer();
			buffer.add(sample[1], 0);
			buffer.contentType = HBBufferContentType.UNICODE;
			buffer.guessSegmentProperties();

			Assert.equals(tag(sample[0]), tag(buffer.script), "U+" + StringTools.hex(sample[1], 4));
		}
	}

	// Helpers

	private static function codepoints(buffer:HBBuffer):Array<Int>
	{
		var infos = buffer.getGlyphInfo();
		return infos == null ? [] : [for (info in infos) info.codepoint];
	}

	private static function clusters(buffer:HBBuffer):Array<Int>
	{
		var infos = buffer.getGlyphInfo();
		return infos == null ? [] : [for (info in infos) info.cluster];
	}

	private static function languageOf(buffer:HBBuffer):String
	{
		var language = buffer.language;
		return language == null ? null : language.toString();
	}

	/** A script as the four letters of its tag, which reads better in a failure than a number **/
	private static function tag(script:HBScript):String
	{
		var value:Int = script;
		if (value == 0) return "none";
		return String.fromCharCode((value >>> 24) & 0xFF) + String.fromCharCode((value >> 16) & 0xFF) + String.fromCharCode((value >> 8) & 0xFF)
			+ String.fromCharCode(value & 0xFF);
	}

	/** A buffer with contents and every property changed from its default **/
	private static function filledBuffer():HBBuffer
	{
		var buffer = new HBBuffer();
		buffer.addUTF8("abc", 0, -1);
		buffer.direction = HBDirection.RTL;
		buffer.script = HBScript.COMMON;
		buffer.language = new HBLanguage("en");
		buffer.flags = HBBufferFlags.BOT;
		buffer.clusterLevel = HBBufferClusterLevel.CHARACTERS;
		buffer.replacementCodepoint = 0x3F;
		return buffer;
	}

	private static function utf16(units:Array<Int>):Bytes
	{
		var bytes = Bytes.alloc(units.length * 2);

		for (i in 0...units.length)
		{
			bytes.setUInt16(i * 2, units[i]);
		}

		return bytes;
	}

	private static function utf32(codes:Array<Int>):Bytes
	{
		var bytes = Bytes.alloc(codes.length * 4);

		for (i in 0...codes.length)
		{
			bytes.setInt32(i * 4, codes[i]);
		}

		return bytes;
	}
	#end
}
