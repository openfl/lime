package text;

import haxe.io.Bytes;
import haxe.io.Encoding;
import lime.text.UTF8String;
import utest.Assert;
import utest.Test;

/**
	`UTF8String` follows the Haxe `String` API, with every index, length and
	position counted in Unicode code points.
**/
class UTF8StringTest extends Test
{
	// "a", "é" (2 bytes), "€" (3 bytes), "😀" U+1F600 (4 bytes), "e" + U+0301 COMBINING ACUTE ACCENT, "z", "€"
	private static inline var MIXED = "aé€\u{1F600}éz€";
	private static var MIXED_CODES:Array<Int> = [0x61, 0xE9, 0x20AC, 0x1F600, 0x65, 0x301, 0x7A, 0x20AC];

	public function new()
	{
		super();
	}

	private function assertCodes(expected:Array<Int>, value:UTF8String, ?pos:haxe.PosInfos):Void
	{
		var text:String = value;
		Assert.equals(expected.length, value.length, 'length of "$text"', pos);
		for (i in 0...expected.length)
		{
			var code = value.charCodeAt(i);
			Assert.equals(expected[i], code, 'expected 0x${StringTools.hex(expected[i])} at index $i of "$text" but got $code', pos);
		}
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testLengthCountsCodePoints():Void
	{
		Assert.equals(0, (("" : UTF8String)).length);
		Assert.equals(5, (("hello" : UTF8String)).length);
		Assert.equals(1, (("é" : UTF8String)).length);
		Assert.equals(1, (("€" : UTF8String)).length);
		Assert.equals(1, (("\u{1F600}" : UTF8String)).length);
		// A combining mark is a code point of its own
		Assert.equals(2, (("é" : UTF8String)).length);
		Assert.equals(8, ((MIXED : UTF8String)).length);
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testLengthOfCharactersLedByE0EDF0():Void
	{
		// Devanagari, Thai, Hangul and emoji start with the lead bytes 0xE0, 0xED and 0xF0
		Assert.equals(1, (("अ" : UTF8String)).length);
		Assert.equals(1, (("ก" : UTF8String)).length);
		Assert.equals(1, (("한" : UTF8String)).length);
		Assert.equals(4, (("अก한\u{1F600}" : UTF8String)).length);
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testCharAt():Void
	{
		var s:UTF8String = MIXED;
		Assert.equals("a", s.charAt(0));
		Assert.equals("é", s.charAt(1));
		Assert.equals("€", s.charAt(2));
		Assert.equals("\u{1F600}", s.charAt(3));
		Assert.equals("e", s.charAt(4));
		Assert.equals("́", s.charAt(5));
		Assert.equals("z", s.charAt(6));
		Assert.equals("€", s.charAt(7));
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testCharAtOutOfRangeIsEmpty():Void
	{
		var s:UTF8String = MIXED;
		Assert.equals("", s.charAt(-1));
		Assert.equals("", s.charAt(8));
		Assert.equals("", s.charAt(100));
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testCharCodeAt():Void
	{
		assertCodes(MIXED_CODES, MIXED);
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testCharCodeAtOutOfRangeIsNull():Void
	{
		var s:UTF8String = MIXED;
		Assert.isNull(s.charCodeAt(-1));
		Assert.isNull(s.charCodeAt(8));
		Assert.isNull(s.charCodeAt(100));
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testCharCodeAtEncodingBoundaries():Void
	{
		// The first and last code point of each UTF-8 sequence length
		assertCodes([0x7F, 0x80, 0x7FF, 0x800, 0xFFFF, 0x10000, 0x10FFFF], "\u007F\u0080߿ࠀ￿\u{10000}\u{10FFFF}");
		// Sequences led by 0xE0, 0xED and 0xF0 have narrower second-byte ranges
		assertCodes([0x905, 0xE01, 0xD55C, 0xD7FF, 0xE000, 0x1F600], "अก한퟿\u{1F600}");
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testIndexOf():Void
	{
		var s:UTF8String = MIXED;
		Assert.equals(0, s.indexOf("a"));
		Assert.equals(2, s.indexOf("€"));
		Assert.equals(3, s.indexOf("\u{1F600}"));
		Assert.equals(4, s.indexOf("é"));
		// No normalization: the combining mark is found on its own
		Assert.equals(5, s.indexOf("́"));
		Assert.equals(6, s.indexOf("z"));
		Assert.equals(-1, s.indexOf("x"));
		Assert.equals(-1, s.indexOf("É"));
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testIndexOfWithStartIndex():Void
	{
		var s:UTF8String = MIXED;
		Assert.equals(2, s.indexOf("€", 0));
		Assert.equals(2, s.indexOf("€", 2));
		Assert.equals(7, s.indexOf("€", 3));
		Assert.equals(7, s.indexOf("€", 7));
		Assert.equals(6, s.indexOf("z", 4));
		// String: "If startIndex exceeds this.length, -1 is returned."
		Assert.equals(-1, s.indexOf("€", 8));
		Assert.equals(-1, s.indexOf("a", 9));
	}

	#if !neko
	@Ignored("Waiting on #2153")
	#end
	public function testIndexOfEmptyString():Void
	{
		var s:UTF8String = MIXED;
		Assert.equals(0, s.indexOf(""));
		Assert.equals(3, s.indexOf("", 3));
		Assert.equals(8, s.indexOf("", 8));
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testLastIndexOf():Void
	{
		var s:UTF8String = MIXED;
		Assert.equals(7, s.lastIndexOf("€"));
		Assert.equals(3, s.lastIndexOf("\u{1F600}"));
		Assert.equals(0, s.lastIndexOf("a"));
		Assert.equals(5, s.lastIndexOf("́"));
		Assert.equals(-1, s.lastIndexOf("x"));
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testLastIndexOfWithStartIndex():Void
	{
		var s:UTF8String = MIXED;
		// String: the search is performed within the substring from 0 to startIndex + str.length
		Assert.equals(7, s.lastIndexOf("€", 7));
		Assert.equals(2, s.lastIndexOf("€", 6));
		Assert.equals(2, s.lastIndexOf("€", 2));
		Assert.equals(-1, s.lastIndexOf("€", 1));
		Assert.equals(3, s.lastIndexOf("\u{1F600}e", 3));
		Assert.equals(0, s.lastIndexOf("a", 0));
		Assert.equals(7, s.lastIndexOf("€", 100));
	}

	public function testSplit():Void
	{
		var s:UTF8String = "a€b€c";
		Assert.same(["a", "b", "c"], s.split("€"));

		var multiByteDelimiter:UTF8String = "é\u{1F600}€\u{1F600}z";
		Assert.same(["é", "€", "z"], multiByteDelimiter.split("\u{1F600}"));

		var notFound:UTF8String = MIXED;
		Assert.same([MIXED], notFound.split("x"));
	}

	public function testSplitDelimiterAtEnds():Void
	{
		// String: a leading or trailing delimiter gives a leading or trailing ""
		var s:UTF8String = "€a€";
		Assert.same(["", "a", ""], s.split("€"));

		var twice:UTF8String = "é€€é";
		Assert.same(["é", "", "é"], twice.split("€"));

		var only:UTF8String = "\u{1F600}";
		Assert.same(["", ""], only.split("\u{1F600}"));
	}

	@Ignored("Waiting on #2153")
	public function testSplitEmptyDelimiterGivesCodePoints():Void
	{
		// String: an Array of this.length elements, one for each character
		var s:UTF8String = MIXED;
		Assert.same(["a", "é", "€", "\u{1F600}", "e", "́", "z", "€"], s.split(""));
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testSubstr():Void
	{
		var s:UTF8String = MIXED;
		Assert.equals("é€", s.substr(1, 2));
		Assert.equals("\u{1F600}", s.substr(3, 1));
		Assert.equals("\u{1F600}éz€", s.substr(3));
		Assert.equals("z€", s.substr(6, 100));
		Assert.equals("", s.substr(0, 0));
		Assert.equals("", s.substr(8));
		Assert.equals("", s.substr(100));
		Assert.equals(MIXED, s.substr(0));
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testSubstrNegativePosition():Void
	{
		var s:UTF8String = MIXED;
		// String: a negative pos is this.length + pos, and 0 if that is still negative
		Assert.equals("z€", s.substr(-2));
		Assert.equals("́z", s.substr(-3, 2));
		Assert.equals("\u{1F600}", s.substr(-5, 1));
		Assert.equals(MIXED, s.substr(-100));
		Assert.equals("aé", s.substr(-100, 2));
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testSubstring():Void
	{
		var s:UTF8String = MIXED;
		Assert.equals("é€", s.substring(1, 3));
		Assert.equals("\u{1F600}éz€", s.substring(3));
		Assert.equals("z€", s.substring(6, 100));
		Assert.equals("", s.substring(4, 4));
		Assert.equals("", s.substring(8));
		Assert.equals("", s.substring(100));
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testSubstringSwapsAndClampsArguments():Void
	{
		var s:UTF8String = MIXED;
		// String: startIndex > endIndex are swapped
		Assert.equals("é€", s.substring(3, 1));
		// String: a negative index is 0
		Assert.equals("aé", s.substring(-5, 2));
		// -1 becomes 0, then the arguments are swapped
		Assert.equals("aé", s.substring(2, -1));
		Assert.equals("z€", s.substring(100, 6));
	}

	public function testToUpperCaseKeepsMultiByteCharacters():Void
	{
		var s:UTF8String = "abc €\u{1F600} xyz";
		var upper:UTF8String = s.toUpperCase();
		Assert.equals("ABC €\u{1F600} XYZ", upper);
		Assert.equals(s.length, upper.length);
	}

	public function testToLowerCaseKeepsMultiByteCharacters():Void
	{
		var s:UTF8String = "ABC €\u{1F600} XYZ";
		var lower:UTF8String = s.toLowerCase();
		Assert.equals("abc €\u{1F600} xyz", lower);
		Assert.equals(s.length, lower.length);
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testCaseConversionOfNonAsciiLetters():Void
	{
		// String: "all characters of this String are upper case"
		var lower:UTF8String = "éж";
		var upper:UTF8String = "ÉЖ";
		Assert.equals("ÉЖ", lower.toUpperCase());
		Assert.equals("éж", upper.toLowerCase());
	}

	public function testEquality():Void
	{
		var a:UTF8String = MIXED;
		var b:UTF8String = "aé€" + "\u{1F600}éz€";
		Assert.isTrue(a == b);
		Assert.isFalse(a != b);

		// Canonically equivalent but different code points are not equal
		var precomposed:UTF8String = "é";
		var decomposed:UTF8String = "é";
		Assert.isFalse(precomposed == decomposed);
		Assert.isTrue(precomposed != decomposed);
	}

	#if !neko
	@Ignored("Waiting on #2153")
	#end
	public function testComparisonOrdersByCodePoint():Void
	{
		var a:UTF8String = "a";
		var b:UTF8String = "b";
		var ab:UTF8String = "ab";
		Assert.isTrue(a < b);
		Assert.isTrue(a < ab);
		Assert.isTrue(b > ab);
		Assert.isTrue(a <= a);
		Assert.isTrue(a >= a);

		// U+FF61 is before U+1F600, though its UTF-16 code unit sorts after the surrogate 0xD83D
		var halfwidth:UTF8String = "｡";
		var emoji:UTF8String = "\u{1F600}";
		Assert.isTrue(halfwidth < emoji);
		Assert.isFalse(halfwidth > emoji);
		Assert.isTrue(emoji > halfwidth);

		var e:UTF8String = "e";
		var eAcute:UTF8String = "é";
		Assert.isTrue(e < eAcute);
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testConcatenationCountsCodePoints():Void
	{
		var a:UTF8String = "é€";
		var b:UTF8String = "\u{1F600}";
		var c:UTF8String = a + b;
		Assert.equals(3, c.length);
		Assert.equals(0x1F600, c.charCodeAt(2));
	}

	public function testToBytesIsUtf8():Void
	{
		var s:UTF8String = MIXED;
		var bytes = Bytes.ofString(s, Encoding.UTF8);
		Assert.equals(17, bytes.length);
		Assert.equals("61c3a9e282acf09f988065cc817ae282ac", bytes.toHex());
	}

	#if neko
	@Ignored("Waiting on #2153")
	#end
	public function testFromBytesRoundTrip():Void
	{
		var s:UTF8String = Bytes.ofHex("61c3a9e282acf09f988065cc817ae282ac").getString(0, 17, Encoding.UTF8);
		Assert.isTrue(s == (MIXED : UTF8String));
		assertCodes(MIXED_CODES, s);

		var hangul:UTF8String = Bytes.ofHex("ed959c").toString();
		assertCodes([0xD55C], hangul);
	}

	public function testValidateAcceptsCharactersLedByE0EDF0():Void
	{
		for (hex in ["00", "7f", "c280", "dfbf", "e0a080", "e0a485", "e0b881", "ed959c", "ed9fbf", "ee8080", "efbfbf", "f0908080",
			"f09f9880", "f48fbfbf"])
		{
			Assert.isTrue(UTF8String.validate(Bytes.ofHex(hex), Encoding.UTF8), hex + " is valid UTF-8");
		}
	}

	public function testValidateRejectsInvalidUtf8():Void
	{
		// Overlong forms, UTF-16 surrogates, code points beyond U+10FFFF, bytes that never appear, and cut sequences
		for (hex in ["c080", "c1bf", "e08080", "e09fbf", "eda080", "edbfbf", "eda0bdedb880", "f0808080", "f08fbfbf", "f4908080", "f5808080",
			"ff", "80", "bf", "e282", "f09f98", "61e2"])
		{
			Assert.isFalse(UTF8String.validate(Bytes.ofHex(hex), Encoding.UTF8), hex + " is not valid UTF-8");
		}
	}

	#if target.unicode
	public function testIterationYieldsCodePoints():Void
	{
		var s:UTF8String = MIXED;
		var codes = [for (code in s) code];
		Assert.same(MIXED_CODES, codes);
	}
	#end
}
