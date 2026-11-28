package text;

import haxe.io.Bytes;

/**
	What the text tests know about their fonts. assets/mono.ttf is a subset of
	Noto Mono holding printable ASCII, and assets/variable.ttf a subset of Inter
	holding space, H and the digits, each under the SIL Open Font License beside
	it. The numbers here were read from the fonts' own head, hhea, maxp, OS/2,
	post, name, cmap, hmtx, glyf and GPOS tables with a script, not from Lime.
**/
class FontFixture
{
	public static inline var MONO_PATH = "assets/mono.ttf";
	public static inline var VARIABLE_PATH = "assets/variable.ttf";

	// head.unitsPerEm and maxp.numGlyphs
	public static inline var MONO_UPEM = 2048;
	public static inline var MONO_GLYPHS = 96;
	public static inline var VARIABLE_UPEM = 2048;
	public static inline var VARIABLE_GLYPHS = 34;

	// hmtx gives every glyph of the monospaced font one advance
	public static inline var MONO_ADVANCE = 1229;

	// cmap: U+0020 to U+007E are glyphs 1 to 95, in order
	public static inline var MONO_FIRST_CHARACTER = 0x20;
	public static inline var MONO_LAST_CHARACTER = 0x7E;

	// cmap of the variable font: H, then the digits
	public static inline var VARIABLE_H = 1;
	public static inline var VARIABLE_ZERO = 2;

	// hmtx advances of the variable font's glyphs 0 to 11: .notdef, H, then 0 to 9
	public static var VARIABLE_ADVANCES:Array<Int> = [1344, 1522, 1292, 833, 1249, 1265, 1323, 1215, 1270, 1159, 1267, 1270];

	// GPOS kern, as a first glyph's advance changes before a second: 7 then 4, and none for 4 then 7
	public static inline var VARIABLE_KERN_7_4 = -119;

	/**
		Characters of every UTF-8 length, with the lead bytes 0xE0, 0xED, 0xF0 and
		0xF4 among them, mapped onto glyphs of the monospaced font: é to e, U+0800 to B,
		€ to E, U+D7FF to D, U+10000 to A, U+1F600 to H and U+10FFFF to Z.
	**/
	public static var WIDE_GROUPS:Array<Array<Int>> = [
		[0x20, 0x7E, 1],
		[0xE9, 0xE9, 70],
		[0x800, 0x800, 35],
		[0x20AC, 0x20AC, 38],
		[0xD7FF, 0xD7FF, 37],
		[0x10000, 0x10000, 34],
		[0x1F600, 0x1F600, 41],
		[0x10FFFF, 0x10FFFF, 59]
	];

	public static inline function monoGlyph(code:Int):Int
	{
		return code - MONO_FIRST_CHARACTER + 1;
	}

	#if sys
	public static function monoBytes():Bytes
	{
		return sys.io.File.getBytes(MONO_PATH);
	}

	public static function variableBytes():Bytes
	{
		return sys.io.File.getBytes(VARIABLE_PATH);
	}

	/**
		The monospaced font with `WIDE_GROUPS` as its character map.
	**/
	public static function wideMonoBytes():Bytes
	{
		return withCharacterMap(monoBytes(), WIDE_GROUPS);
	}
	#end

	/**
		A copy of a font whose cmap table is replaced by a single format 12 subtable
		for Windows, UCS-4 (platform 3, encoding 10). Each group is a first character,
		a last character and the glyph of the first, in ascending order. No fixture
		has characters past U+FFFF, and this gives them to one without adding a file.
	**/
	public static function withCharacterMap(font:Bytes, groups:Array<Array<Int>>):Bytes
	{
		var cmap = Bytes.alloc(28 + groups.length * 12);
		cmap.fill(0, cmap.length, 0);

		// The cmap header and its one encoding record
		setUInt16(cmap, 2, 1);
		setUInt16(cmap, 4, 3);
		setUInt16(cmap, 6, 10);
		setUInt32(cmap, 8, 12);

		// The subtable: format, length, language and the groups
		setUInt16(cmap, 12, 12);
		setUInt32(cmap, 16, 16 + groups.length * 12);
		setUInt32(cmap, 24, groups.length);

		for (i in 0...groups.length)
		{
			for (j in 0...3)
			{
				setUInt32(cmap, 28 + i * 12 + j * 4, groups[i][j]);
			}
		}

		// Tables start on 4-byte boundaries
		var offset = (font.length + 3) & ~3;
		var result = Bytes.alloc(offset + cmap.length);
		result.fill(0, result.length, 0);
		result.blit(0, font, 0, font.length);
		result.blit(offset, cmap, 0, cmap.length);

		// The table directory follows the 12-byte header: a tag, a checksum, an
		// offset and a length for each table. Neither FreeType nor HarfBuzz checks
		// the checksum.
		var tables = (font.get(4) << 8) | font.get(5);

		for (i in 0...tables)
		{
			var record = 12 + i * 16;

			if (font.getString(record, 4) == "cmap")
			{
				setUInt32(result, record + 8, offset);
				setUInt32(result, record + 12, cmap.length);
			}
		}

		return result;
	}

	private static function setUInt16(bytes:Bytes, position:Int, value:Int):Void
	{
		bytes.set(position, (value >> 8) & 0xFF);
		bytes.set(position + 1, value & 0xFF);
	}

	private static function setUInt32(bytes:Bytes, position:Int, value:Int):Void
	{
		bytes.set(position, (value >>> 24) & 0xFF);
		bytes.set(position + 1, (value >> 16) & 0xFF);
		bytes.set(position + 2, (value >> 8) & 0xFF);
		bytes.set(position + 3, value & 0xFF);
	}
}
