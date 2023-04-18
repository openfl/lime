package lime.text;

#if !haxe4
import haxe.Utf8;
import lime._internal.unifill.Unifill;
import lime._internal.unifill.CodePoint;
import lime.system.Locale;

abstract UTF8String(String) from String to String
{
	#if sys
	private static var lowercaseMap:Map<Int, Int>;
	private static var uppercaseMap:Map<Int, Int>;
	#end

	/**
		The number of characters in `this` String.
	**/
	public var length(get, never):Int;

	/**
		Creates a copy from a given String.
	**/
	public function new(str:String)
	{
		this = new String(str);
	}

	/**
		Returns the character at position `index` of `this` String.

		If `index` is negative or exceeds `this.length`, the empty String `""`
		is returned.
	**/
	public function charAt(index:Int):String
	{
		return Unifill.uCharAt(this, index);
	}

	/**
		Returns the character code at position `index` of `this` String.

		If `index` is negative or exceeds `this.length`, `null` is returned.

		To obtain the character code of a single character, `"x".code` can be
		used instead to inline the character code at compile time. Note that
		this only works on String literals of length 1.
	**/
	public function charCodeAt(index:Int):Null<Int>
	{
		if (index < 0 || index >= Unifill.uLength(this)) return null;
		return Unifill.uCharCodeAt(this, index);
	}

	/**
		Returns the String corresponding to the character code `code`.

		If `code` is negative or has another invalid value, the result is
		unspecified.
	**/
	public static function fromCharCode(code:Int):String
	{
		return CodePoint.fromInt(code);
	}

	/**
		Returns the string corresponding to the array of character codes `codes`.

		If #unifill is defined, these codes will be treated as UTF-8 code points,
		otherwise it will default to using String.fromCharCode() for each character
	**/
	public static function fromCharCodes(codes:Array<Int>):String
	{
		var s = "";

		for (code in codes)
		{
			s += CodePoint.fromInt(code);
		}

		return s;
	}

	/**
		Returns the position of the leftmost occurence of `str` within `this`
		String.

		If `startIndex` is given, the search is performed within the substring
		of `this` String starting from `startIndex`. Otherwise the search is
		performed within `this` String. In either case, the returned position
		is relative to the beginning of `this` String.

		If `str` cannot be found, -1 is returned.
	**/
	public function indexOf(str:String, startIndex:Int = 0):Int
	{
		return Unifill.uIndexOf(this, str, startIndex);
	}

	/**
		Returns the position of the rightmost occurence of `str` within `this`
		String.

		If `startIndex` is given, the search is performed within the substring
		of `this` String from 0 to `startIndex`. Otherwise the search is
		performed within `this` String. In either case, the returned position
		is relative to the beginning of `this` String.

		If `str` cannot be found, -1 is returned.
	**/
	public function lastIndexOf(str:String, ?startIndex:Int):Int
	{
		return Unifill.uLastIndexOf(this, str, startIndex);
	}

	/**
		Splits `this` String at each occurence of `delimiter`.

		If `this` String is the empty String `""`, the result is not consistent
		across targets and may either be `[]` (on Js, Cpp) or `[""]`.

		If `delimiter` is the empty String `""`, `this` String is split into an
		Array of `this.length` elements, where the elements correspond to the
		characters of `this` String.

		If `delimiter` is not found within `this` String, the result is an Array
		with one element, which equals `this` String.

		If `delimiter` is null, the result is unspecified.

		Otherwise, `this` String is split into parts at each occurence of
		`delimiter`. If `this` String starts (or ends) with `delimiter`, the
		result `Array` contains a leading (or trailing) empty String `""` element.
		Two subsequent delimiters also result in an empty String `""` element.
	**/
	public function split(delimiter:String):Array<String>
	{
		return Unifill.uSplit(this, delimiter);
	}

	/**
		Returns `len` characters of `this` String, starting at position `pos`.

		If `len` is omitted, all characters from position `pos` to the end of
		`this` String are included.

		If `pos` is negative, its value is calculated from the end of `this`
		String by `this.length + pos`. If this yields a negative value, 0 is
		used instead.

		If the calculated position + `len` exceeds `this.length`, the characters
		from that position to the end of `this` String are returned.

		If `len` is negative, the result is unspecified.
	**/
	public function substr(pos:Int, ?len:Int):String
	{
		if (len == null)
		{
			len = (this : UTF8String).length - pos;
		}

		return Utf8.sub(this, pos, len);
	}

	/**
		Returns the part of `this` String from `startIndex` to but not including `endIndex`.

		If `startIndex` or `endIndex` are negative, 0 is used instead.

		If `startIndex` exceeds `endIndex`, they are swapped.

		If the (possibly swapped) `endIndex` is omitted or exceeds
		`this.length`, `this.length` is used instead.

		If the (possibly swapped) `startIndex` exceeds `this.length`, the empty
		String `""` is returned.
	**/
	public function substring(startIndex:Int, ?endIndex:Int):String
	{
		return Unifill.uSubstring(this, startIndex, endIndex);
	}

	/**
		Returns a String where all characters of `this` String are lower case.

		Affects the characters `A-Z`. Other characters remain unchanged.

		If `language` is specified, language-specific casing rules will be followed.
	**/
	public function toLowerCase(locale:Locale = null):String
	{
		#if sys
		if (lowercaseMap == null)
		{
			lowercaseMap = new Map<Int, Int>();
			Utf8Ext.fillUpperToLowerMap(lowercaseMap);
		}

		var r = new Utf8();

		Utf8.iter(this, function(v)
		{
			if (locale != null)
			{
				var v2 = toLowerCaseLocaleFixes(v, locale);
				if (v2 != v)
				{
					r.addChar(v2);
					return;
				}
			}
			r.addChar(lowercaseMap.exists(v) ? lowercaseMap[v] : v);
		});

		return r.toString();
		#else
		return this.toLowerCase();
		#end
	}

	private static function toLowerCaseLocaleFixes(v:Int, locale:Locale):Int
	{
		return switch (locale.language)
		{
			case "tr":
				switch (v)
				{
					case 0xC4B0: 0x69; // İ-->i (large dotted İ to small i) //probably redundant and can be removed, presented here for logical symmtery for when genuine cases are needed
					default: v;
				}
			default: v;
		}
	}

	/**
		Returns the String itself.
	**/
	public function toString():String
	{
		return this;
	}

	/**
		Returns a String where all characters of `this` String are upper case.

		Affects the characters `a-z`. Other characters remain unchanged.

		If `language` is specified, language-specific casing rules will be followed.
	**/
	public function toUpperCase(locale:Locale = null):String
	{
		#if sys
		if (uppercaseMap == null)
		{
			uppercaseMap = new Map<Int, Int>();
			Utf8Ext.fillLowerToUpperMap(uppercaseMap);
		}

		var r = new Utf8();

		Utf8.iter(this, function(v)
		{
			if (locale != null)
			{
				var v2 = toUpperCaseLocaleFixes(v, locale);
				if (v2 != v)
				{
					r.addChar(v2);
					return;
				}
			}
			r.addChar(uppercaseMap.exists(v) ? uppercaseMap[v] : v);
		});

		return r.toString();
		#else
		return this.toUpperCase();
		#end
	}

	private static function toUpperCaseLocaleFixes(v:Int, locale:Locale):Int
	{
		return switch (locale.language)
		{
			case "tr":
				switch (v)
				{
					case 0x69: 0xC4B0; // i-->İ (small i to large dotted İ)
					default: v;
				}
			default: v;
		}
	}

	@:op(A == B) private static function equals(a:UTF8String, b:UTF8String):Bool
	{
		if (a == null || b == null) return (a : String) == (b : String);
		return Unifill.uCompare(a, b) == 0;
	}

	@:op(A < B) private static function lt(a:UTF8String, b:UTF8String):Bool
	{
		if (b == null) return false;
		if (a == null) return true;
		return Unifill.uCompare(a, b) == -1;
	}

	@:op(A > B) private static function gt(a:UTF8String, b:UTF8String):Bool
	{
		if (a == null) return false;
		if (b == null) return true;
		return Unifill.uCompare(a, b) == 1;
	}

	@:op(A <= B) private static function lteq(a:UTF8String, b:UTF8String):Bool
	{
		if (b == null) return (a == null);
		if (a == null) return true;
		return Unifill.uCompare(a, b) != 1;
	}

	@:op(A >= B) private static function gteq(a:UTF8String, b:UTF8String):Bool
	{
		if (a == null) return (b == null);
		if (b == null) return true;
		return Unifill.uCompare(a, b) != -1;
	}

	@:op(A + B) private static function plus(a:UTF8String, b:UTF8String):UTF8String
	{
		if (a == null && b == null) return null;
		if (a == null) return b;
		if (b == null) return a;

		var sb = new StringBuf();
		sb.add(Std.string(a));
		sb.add(Std.string(b));
		return sb.toString();
	}

	@:from static function fromDynamic(value:Dynamic):UTF8String
	{
		return Std.string(value);
	}

	// Get & Set Methods
	@:noCompletion private function get_length():Int
	{
		return this == null ? 0 : Unifill.uLength(this);
	}
}

// generated from org.zamedev.lib.tools.CaseMapsGenerator
private class Utf8Ext
{
	public static function fillUpperToLowerMap(map:Map<Int, Int>):Void
	{
		var i = 0;
		for (i in 0...26)
			map[0x41 + i] = 0x61 + i;
		for (i in 0...23)
			map[0xC0 + i] = 0xE0 + i;
		for (i in 0...7)
			map[0xD8 + i] = 0xF8 + i;
		while (i < 48)
		{
			map[0x100 + i] = 0x101 + i;
			i += 2;
		}
		i = 0;
		map[0x130] = 0x69;
		while (i < 6)
		{
			map[0x132 + i] = 0x133 + i;
			i += 2;
		}
		i = 0;
		while (i < 16)
		{
			map[0x139 + i] = 0x13A + i;
			i += 2;
		}
		i = 0;
		while (i < 46)
		{
			map[0x14A + i] = 0x14B + i;
			i += 2;
		}
		i = 0;
		map[0x178] = 0xFF;
		while (i < 6)
		{
			map[0x179 + i] = 0x17A + i;
			i += 2;
		}
		i = 0;
		map[0x181] = 0x253;
		while (i < 4)
		{
			map[0x182 + i] = 0x183 + i;
			i += 2;
		}
		i = 0;
		map[0x186] = 0x254;
		map[0x187] = 0x188;
		for (i in 0...2)
			map[0x189 + i] = 0x256 + i;
		map[0x18B] = 0x18C;
		map[0x18E] = 0x1DD;
		map[0x18F] = 0x259;
		map[0x190] = 0x25B;
		map[0x191] = 0x192;
		map[0x193] = 0x260;
		map[0x194] = 0x263;
		map[0x196] = 0x269;
		map[0x197] = 0x268;
		map[0x198] = 0x199;
		map[0x19C] = 0x26F;
		map[0x19D] = 0x272;
		map[0x19F] = 0x275;
		while (i < 6)
		{
			map[0x1A0 + i] = 0x1A1 + i;
			i += 2;
		}
		i = 0;
		map[0x1A6] = 0x280;
		map[0x1A7] = 0x1A8;
		map[0x1A9] = 0x283;
		map[0x1AC] = 0x1AD;
		map[0x1AE] = 0x288;
		map[0x1AF] = 0x1B0;
		for (i in 0...2)
			map[0x1B1 + i] = 0x28A + i;
		while (i < 4)
		{
			map[0x1B3 + i] = 0x1B4 + i;
			i += 2;
		}
		i = 0;
		map[0x1B7] = 0x292;
		map[0x1B8] = 0x1B9;
		map[0x1BC] = 0x1BD;
		map[0x1C4] = 0x1C6;
		map[0x1C7] = 0x1C9;
		map[0x1CA] = 0x1CC;
		while (i < 16)
		{
			map[0x1CD + i] = 0x1CE + i;
			i += 2;
		}
		i = 0;
		while (i < 18)
		{
			map[0x1DE + i] = 0x1DF + i;
			i += 2;
		}
		i = 0;
		map[0x1F1] = 0x1F3;
		map[0x1F4] = 0x1F5;
		map[0x1F6] = 0x195;
		map[0x1F7] = 0x1BF;
		while (i < 40)
		{
			map[0x1F8 + i] = 0x1F9 + i;
			i += 2;
		}
		i = 0;
		map[0x220] = 0x19E;
		while (i < 18)
		{
			map[0x222 + i] = 0x223 + i;
			i += 2;
		}
		i = 0;
		map[0x23A] = 0x2C65;
		map[0x23B] = 0x23C;
		map[0x23D] = 0x19A;
		map[0x23E] = 0x2C66;
		map[0x241] = 0x242;
		map[0x243] = 0x180;
		map[0x244] = 0x289;
		map[0x245] = 0x28C;
		while (i < 10)
		{
			map[0x246 + i] = 0x247 + i;
			i += 2;
		}
		i = 0;
		while (i < 4)
		{
			map[0x370 + i] = 0x371 + i;
			i += 2;
		}
		i = 0;
		map[0x376] = 0x377;
		map[0x37F] = 0x3F3;
		map[0x386] = 0x3AC;
		for (i in 0...3)
			map[0x388 + i] = 0x3AD + i;
		map[0x38C] = 0x3CC;
		for (i in 0...2)
			map[0x38E + i] = 0x3CD + i;
		for (i in 0...17)
			map[0x391 + i] = 0x3B1 + i;
		for (i in 0...9)
			map[0x3A3 + i] = 0x3C3 + i;
		map[0x3CF] = 0x3D7;
		while (i < 24)
		{
			map[0x3D8 + i] = 0x3D9 + i;
			i += 2;
		}
		i = 0;
		map[0x3F4] = 0x3B8;
		map[0x3F7] = 0x3F8;
		map[0x3F9] = 0x3F2;
		map[0x3FA] = 0x3FB;
		for (i in 0...3)
			map[0x3FD + i] = 0x37B + i;
		for (i in 0...16)
			map[0x400 + i] = 0x450 + i;
		for (i in 0...32)
			map[0x410 + i] = 0x430 + i;
		while (i < 34)
		{
			map[0x460 + i] = 0x461 + i;
			i += 2;
		}
		i = 0;
		while (i < 54)
		{
			map[0x48A + i] = 0x48B + i;
			i += 2;
		}
		i = 0;
		map[0x4C0] = 0x4CF;
		while (i < 14)
		{
			map[0x4C1 + i] = 0x4C2 + i;
			i += 2;
		}
		i = 0;
		while (i < 96)
		{
			map[0x4D0 + i] = 0x4D1 + i;
			i += 2;
		}
		i = 0;
		for (i in 0...38)
			map[0x531 + i] = 0x561 + i;
		for (i in 0...38)
			map[0x10A0 + i] = 0x2D00 + i;
		map[0x10C7] = 0x2D27;
		map[0x10CD] = 0x2D2D;
		for (i in 0...80)
			map[0x13A0 + i] = 0xAB70 + i;
		for (i in 0...6)
			map[0x13F0 + i] = 0x13F8 + i;
		while (i < 150)
		{
			map[0x1E00 + i] = 0x1E01 + i;
			i += 2;
		}
		i = 0;
		map[0x1E9E] = 0xDF;
		while (i < 96)
		{
			map[0x1EA0 + i] = 0x1EA1 + i;
			i += 2;
		}
		i = 0;
		for (i in 0...8)
			map[0x1F08 + i] = 0x1F00 + i;
		for (i in 0...6)
			map[0x1F18 + i] = 0x1F10 + i;
		for (i in 0...8)
			map[0x1F28 + i] = 0x1F20 + i;
		for (i in 0...8)
			map[0x1F38 + i] = 0x1F30 + i;
		for (i in 0...6)
			map[0x1F48 + i] = 0x1F40 + i;
		while (i < 8)
		{
			map[0x1F59 + i] = 0x1F51 + i;
			i += 2;
		}
		i = 0;
		for (i in 0...8)
			map[0x1F68 + i] = 0x1F60 + i;
		for (i in 0...2)
			map[0x1FB8 + i] = 0x1FB0 + i;
		for (i in 0...2)
			map[0x1FBA + i] = 0x1F70 + i;
		for (i in 0...4)
			map[0x1FC8 + i] = 0x1F72 + i;
		for (i in 0...2)
			map[0x1FD8 + i] = 0x1FD0 + i;
		for (i in 0...2)
			map[0x1FDA + i] = 0x1F76 + i;
		for (i in 0...2)
			map[0x1FE8 + i] = 0x1FE0 + i;
		for (i in 0...2)
			map[0x1FEA + i] = 0x1F7A + i;
		map[0x1FEC] = 0x1FE5;
		for (i in 0...2)
			map[0x1FF8 + i] = 0x1F78 + i;
		for (i in 0...2)
			map[0x1FFA + i] = 0x1F7C + i;
		map[0x2126] = 0x3C9;
		map[0x212A] = 0x6B;
		map[0x212B] = 0xE5;
		map[0x2132] = 0x214E;
		map[0x2183] = 0x2184;
		for (i in 0...47)
			map[0x2C00 + i] = 0x2C30 + i;
		map[0x2C60] = 0x2C61;
		map[0x2C62] = 0x26B;
		map[0x2C63] = 0x1D7D;
		map[0x2C64] = 0x27D;
		while (i < 6)
		{
			map[0x2C67 + i] = 0x2C68 + i;
			i += 2;
		}
		i = 0;
		map[0x2C6D] = 0x251;
		map[0x2C6E] = 0x271;
		map[0x2C6F] = 0x250;
		map[0x2C70] = 0x252;
		map[0x2C72] = 0x2C73;
		map[0x2C75] = 0x2C76;
		for (i in 0...2)
			map[0x2C7E + i] = 0x23F + i;
		while (i < 100)
		{
			map[0x2C80 + i] = 0x2C81 + i;
			i += 2;
		}
		i = 0;
		while (i < 4)
		{
			map[0x2CEB + i] = 0x2CEC + i;
			i += 2;
		}
		i = 0;
		map[0x2CF2] = 0x2CF3;
		while (i < 46)
		{
			map[0xA640 + i] = 0xA641 + i;
			i += 2;
		}
		i = 0;
		while (i < 28)
		{
			map[0xA680 + i] = 0xA681 + i;
			i += 2;
		}
		i = 0;
		while (i < 14)
		{
			map[0xA722 + i] = 0xA723 + i;
			i += 2;
		}
		i = 0;
		while (i < 62)
		{
			map[0xA732 + i] = 0xA733 + i;
			i += 2;
		}
		i = 0;
		while (i < 4)
		{
			map[0xA779 + i] = 0xA77A + i;
			i += 2;
		}
		i = 0;
		map[0xA77D] = 0x1D79;
		while (i < 10)
		{
			map[0xA77E + i] = 0xA77F + i;
			i += 2;
		}
		i = 0;
		map[0xA78B] = 0xA78C;
		map[0xA78D] = 0x265;
		while (i < 4)
		{
			map[0xA790 + i] = 0xA791 + i;
			i += 2;
		}
		i = 0;
		while (i < 20)
		{
			map[0xA796 + i] = 0xA797 + i;
			i += 2;
		}
		i = 0;
		map[0xA7AA] = 0x266;
		map[0xA7AB] = 0x25C;
		map[0xA7AC] = 0x261;
		map[0xA7AD] = 0x26C;
		map[0xA7AE] = 0x26A;
		map[0xA7B0] = 0x29E;
		map[0xA7B1] = 0x287;
		map[0xA7B2] = 0x29D;
		map[0xA7B3] = 0xAB53;
		while (i < 4)
		{
			map[0xA7B4 + i] = 0xA7B5 + i;
			i += 2;
		}
		i = 0;
		for (i in 0...26)
			map[0xFF21 + i] = 0xFF41 + i;
		for (i in 0...40)
			map[0x10400 + i] = 0x10428 + i;
		for (i in 0...36)
			map[0x104B0 + i] = 0x104D8 + i;
		for (i in 0...51)
			map[0x10C80 + i] = 0x10CC0 + i;
		for (i in 0...32)
			map[0x118A0 + i] = 0x118C0 + i;
		for (i in 0...34)
			map[0x1E900 + i] = 0x1E922 + i;
	}

	public static function fillLowerToUpperMap(map:Map<Int, Int>):Void
	{
		var i = 0;
		for (i in 0...26)
			map[0x61 + i] = 0x41 + i;
		map[0xB5] = 0x39C;
		for (i in 0...23)
			map[0xE0 + i] = 0xC0 + i;
		for (i in 0...7)
			map[0xF8 + i] = 0xD8 + i;
		map[0xFF] = 0x178;
		while (i < 48)
		{
			map[0x101 + i] = 0x100 + i;
			i += 2;
		}
		i = 0;
		map[0x131] = 0x49;
		while (i < 6)
		{
			map[0x133 + i] = 0x132 + i;
			i += 2;
		}
		i = 0;
		while (i < 16)
		{
			map[0x13A + i] = 0x139 + i;
			i += 2;
		}
		i = 0;
		while (i < 46)
		{
			map[0x14B + i] = 0x14A + i;
			i += 2;
		}
		i = 0;
		while (i < 6)
		{
			map[0x17A + i] = 0x179 + i;
			i += 2;
		}
		i = 0;
		map[0x17F] = 0x53;
		map[0x180] = 0x243;
		while (i < 4)
		{
			map[0x183 + i] = 0x182 + i;
			i += 2;
		}
		i = 0;
		map[0x188] = 0x187;
		map[0x18C] = 0x18B;
		map[0x192] = 0x191;
		map[0x195] = 0x1F6;
		map[0x199] = 0x198;
		map[0x19A] = 0x23D;
		map[0x19E] = 0x220;
		while (i < 6)
		{
			map[0x1A1 + i] = 0x1A0 + i;
			i += 2;
		}
		i = 0;
		map[0x1A8] = 0x1A7;
		map[0x1AD] = 0x1AC;
		map[0x1B0] = 0x1AF;
		while (i < 4)
		{
			map[0x1B4 + i] = 0x1B3 + i;
			i += 2;
		}
		i = 0;
		map[0x1B9] = 0x1B8;
		map[0x1BD] = 0x1BC;
		map[0x1BF] = 0x1F7;
		map[0x1C6] = 0x1C4;
		map[0x1C9] = 0x1C7;
		map[0x1CC] = 0x1CA;
		while (i < 16)
		{
			map[0x1CE + i] = 0x1CD + i;
			i += 2;
		}
		i = 0;
		map[0x1DD] = 0x18E;
		while (i < 18)
		{
			map[0x1DF + i] = 0x1DE + i;
			i += 2;
		}
		i = 0;
		map[0x1F0] = 0x4A;
		map[0x1F3] = 0x1F1;
		map[0x1F5] = 0x1F4;
		while (i < 40)
		{
			map[0x1F9 + i] = 0x1F8 + i;
			i += 2;
		}
		i = 0;
		while (i < 18)
		{
			map[0x223 + i] = 0x222 + i;
			i += 2;
		}
		i = 0;
		map[0x23C] = 0x23B;
		for (i in 0...2)
			map[0x23F + i] = 0x2C7E + i;
		map[0x242] = 0x241;
		while (i < 10)
		{
			map[0x247 + i] = 0x246 + i;
			i += 2;
		}
		i = 0;
		map[0x250] = 0x2C6F;
		map[0x251] = 0x2C6D;
		map[0x252] = 0x2C70;
		map[0x253] = 0x181;
		map[0x254] = 0x186;
		for (i in 0...2)
			map[0x256 + i] = 0x189 + i;
		map[0x259] = 0x18F;
		map[0x25B] = 0x190;
		map[0x25C] = 0xA7AB;
		map[0x260] = 0x193;
		map[0x261] = 0xA7AC;
		map[0x263] = 0x194;
		map[0x265] = 0xA78D;
		map[0x266] = 0xA7AA;
		map[0x268] = 0x197;
		map[0x269] = 0x196;
		map[0x26A] = 0xA7AE;
		map[0x26B] = 0x2C62;
		map[0x26C] = 0xA7AD;
		map[0x26F] = 0x19C;
		map[0x271] = 0x2C6E;
		map[0x272] = 0x19D;
		map[0x275] = 0x19F;
		map[0x27D] = 0x2C64;
		map[0x280] = 0x1A6;
		map[0x283] = 0x1A9;
		map[0x287] = 0xA7B1;
		map[0x288] = 0x1AE;
		map[0x289] = 0x244;
		for (i in 0...2)
			map[0x28A + i] = 0x1B1 + i;
		map[0x28C] = 0x245;
		map[0x292] = 0x1B7;
		map[0x29D] = 0xA7B2;
		map[0x29E] = 0xA7B0;
		while (i < 4)
		{
			map[0x371 + i] = 0x370 + i;
			i += 2;
		}
		i = 0;
		map[0x377] = 0x376;
		for (i in 0...3)
			map[0x37B + i] = 0x3FD + i;
		map[0x390] = 0x3AA;
		map[0x3AC] = 0x386;
		for (i in 0...3)
			map[0x3AD + i] = 0x388 + i;
		map[0x3B0] = 0x3AB;
		for (i in 0...17)
			map[0x3B1 + i] = 0x391 + i;
		map[0x3C2] = 0x3A3;
		for (i in 0...9)
			map[0x3C3 + i] = 0x3A3 + i;
		map[0x3CC] = 0x38C;
		for (i in 0...2)
			map[0x3CD + i] = 0x38E + i;
		map[0x3D0] = 0x392;
		map[0x3D1] = 0x398;
		map[0x3D5] = 0x3A6;
		map[0x3D6] = 0x3A0;
		map[0x3D7] = 0x3CF;
		while (i < 24)
		{
			map[0x3D9 + i] = 0x3D8 + i;
			i += 2;
		}
		i = 0;
		map[0x3F0] = 0x39A;
		map[0x3F1] = 0x3A1;
		map[0x3F2] = 0x3F9;
		map[0x3F3] = 0x37F;
		map[0x3F5] = 0x395;
		map[0x3F8] = 0x3F7;
		map[0x3FB] = 0x3FA;
		for (i in 0...32)
			map[0x430 + i] = 0x410 + i;
		for (i in 0...16)
			map[0x450 + i] = 0x400 + i;
		while (i < 34)
		{
			map[0x461 + i] = 0x460 + i;
			i += 2;
		}
		i = 0;
		while (i < 54)
		{
			map[0x48B + i] = 0x48A + i;
			i += 2;
		}
		i = 0;
		while (i < 14)
		{
			map[0x4C2 + i] = 0x4C1 + i;
			i += 2;
		}
		i = 0;
		map[0x4CF] = 0x4C0;
		while (i < 96)
		{
			map[0x4D1 + i] = 0x4D0 + i;
			i += 2;
		}
		i = 0;
		for (i in 0...38)
			map[0x561 + i] = 0x531 + i;
		for (i in 0...6)
			map[0x13F8 + i] = 0x13F0 + i;
		map[0x1C80] = 0x412;
		map[0x1C81] = 0x414;
		map[0x1C82] = 0x41E;
		for (i in 0...2)
			map[0x1C83 + i] = 0x421 + i;
		map[0x1C85] = 0x422;
		map[0x1C86] = 0x42A;
		map[0x1C87] = 0x462;
		map[0x1C88] = 0xA64A;
		map[0x1D79] = 0xA77D;
		map[0x1D7D] = 0x2C63;
		while (i < 150)
		{
			map[0x1E01 + i] = 0x1E00 + i;
			i += 2;
		}
		i = 0;
		map[0x1E96] = 0x48;
		map[0x1E97] = 0x54;
		map[0x1E98] = 0x57;
		map[0x1E99] = 0x59;
		map[0x1E9B] = 0x1E60;
		while (i < 96)
		{
			map[0x1EA1 + i] = 0x1EA0 + i;
			i += 2;
		}
		i = 0;
		for (i in 0...8)
			map[0x1F00 + i] = 0x1F08 + i;
		for (i in 0...6)
			map[0x1F10 + i] = 0x1F18 + i;
		for (i in 0...8)
			map[0x1F20 + i] = 0x1F28 + i;
		for (i in 0...8)
			map[0x1F30 + i] = 0x1F38 + i;
		for (i in 0...6)
			map[0x1F40 + i] = 0x1F48 + i;
		map[0x1F50] = 0x3A5;
		map[0x1F51] = 0x1F59;
		map[0x1F52] = 0x3A5;
		map[0x1F53] = 0x1F5B;
		map[0x1F54] = 0x3A5;
		map[0x1F55] = 0x1F5D;
		map[0x1F56] = 0x3A5;
		map[0x1F57] = 0x1F5F;
		for (i in 0...8)
			map[0x1F60 + i] = 0x1F68 + i;
		for (i in 0...2)
			map[0x1F70 + i] = 0x1FBA + i;
		for (i in 0...4)
			map[0x1F72 + i] = 0x1FC8 + i;
		for (i in 0...2)
			map[0x1F76 + i] = 0x1FDA + i;
		for (i in 0...2)
			map[0x1F78 + i] = 0x1FF8 + i;
		for (i in 0...2)
			map[0x1F7A + i] = 0x1FEA + i;
		for (i in 0...2)
			map[0x1F7C + i] = 0x1FFA + i;
		for (i in 0...8)
			map[0x1F80 + i] = 0x1F88 + i;
		for (i in 0...8)
			map[0x1F90 + i] = 0x1F98 + i;
		for (i in 0...8)
			map[0x1FA0 + i] = 0x1FA8 + i;
		for (i in 0...3)
			map[0x1FB0 + i] = 0x1FB8 + i;
		map[0x1FB3] = 0x1FBC;
		map[0x1FB4] = 0x386;
		map[0x1FB6] = 0x391;
		map[0x1FB7] = 0x391;
		map[0x1FBE] = 0x399;
		map[0x1FC2] = 0x1FCA;
		map[0x1FC3] = 0x1FCC;
		map[0x1FC4] = 0x389;
		map[0x1FC6] = 0x397;
		map[0x1FC7] = 0x397;
		for (i in 0...2)
			map[0x1FD0 + i] = 0x1FD8 + i;
		map[0x1FD2] = 0x3AA;
		map[0x1FD3] = 0x3AA;
		map[0x1FD6] = 0x399;
		map[0x1FD7] = 0x3AA;
		for (i in 0...2)
			map[0x1FE0 + i] = 0x1FE8 + i;
		map[0x1FE2] = 0x3AB;
		map[0x1FE3] = 0x3AB;
		map[0x1FE4] = 0x3A1;
		map[0x1FE5] = 0x1FEC;
		map[0x1FE6] = 0x3A5;
		map[0x1FE7] = 0x3AB;
		map[0x1FF2] = 0x1FFA;
		map[0x1FF3] = 0x1FFC;
		map[0x1FF4] = 0x38F;
		map[0x1FF6] = 0x3A9;
		map[0x1FF7] = 0x3A9;
		map[0x214E] = 0x2132;
		map[0x2184] = 0x2183;
		for (i in 0...47)
			map[0x2C30 + i] = 0x2C00 + i;
		map[0x2C61] = 0x2C60;
		map[0x2C65] = 0x23A;
		map[0x2C66] = 0x23E;
		while (i < 6)
		{
			map[0x2C68 + i] = 0x2C67 + i;
			i += 2;
		}
		i = 0;
		map[0x2C73] = 0x2C72;
		map[0x2C76] = 0x2C75;
		while (i < 100)
		{
			map[0x2C81 + i] = 0x2C80 + i;
			i += 2;
		}
		i = 0;
		while (i < 4)
		{
			map[0x2CEC + i] = 0x2CEB + i;
			i += 2;
		}
		i = 0;
		map[0x2CF3] = 0x2CF2;
		for (i in 0...38)
			map[0x2D00 + i] = 0x10A0 + i;
		map[0x2D27] = 0x10C7;
		map[0x2D2D] = 0x10CD;
		while (i < 46)
		{
			map[0xA641 + i] = 0xA640 + i;
			i += 2;
		}
		i = 0;
		while (i < 28)
		{
			map[0xA681 + i] = 0xA680 + i;
			i += 2;
		}
		i = 0;
		while (i < 14)
		{
			map[0xA723 + i] = 0xA722 + i;
			i += 2;
		}
		i = 0;
		while (i < 62)
		{
			map[0xA733 + i] = 0xA732 + i;
			i += 2;
		}
		i = 0;
		while (i < 4)
		{
			map[0xA77A + i] = 0xA779 + i;
			i += 2;
		}
		i = 0;
		while (i < 10)
		{
			map[0xA77F + i] = 0xA77E + i;
			i += 2;
		}
		i = 0;
		map[0xA78C] = 0xA78B;
		while (i < 4)
		{
			map[0xA791 + i] = 0xA790 + i;
			i += 2;
		}
		i = 0;
		while (i < 20)
		{
			map[0xA797 + i] = 0xA796 + i;
			i += 2;
		}
		i = 0;
		while (i < 4)
		{
			map[0xA7B5 + i] = 0xA7B4 + i;
			i += 2;
		}
		i = 0;
		map[0xAB53] = 0xA7B3;
		for (i in 0...80)
			map[0xAB70 + i] = 0x13A0 + i;
		for (i in 0...26)
			map[0xFF41 + i] = 0xFF21 + i;
		for (i in 0...40)
			map[0x10428 + i] = 0x10400 + i;
		for (i in 0...36)
			map[0x104D8 + i] = 0x104B0 + i;
		for (i in 0...51)
			map[0x10CC0 + i] = 0x10C80 + i;
		for (i in 0...32)
			map[0x118C0 + i] = 0x118A0 + i;
		for (i in 0...34)
			map[0x1E922 + i] = 0x1E900 + i;
	}
}
#else
typedef UTF8String = UnicodeString;
#end
