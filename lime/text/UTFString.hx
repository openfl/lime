package lime.text;

import haxe.Utf8;
#if unifill
import lime.text.unifill.Unifill;
import lime.text.unifill.CodePoint;
#end

/**
 * ...
 * @author
 */
abstract UTFString(String) from String to String
{
	#if (unifill && (neko || php || cpp))
	static var inited:Bool = false;
	static var lcaseMap:Map<Int, Int>;
	static var ucaseMap:Map<Int, Int>;
	#end
	
	/**
		The number of characters in `this` String.
	**/
	public var length(get, never) : Int;
	
	/**
		Creates a copy from a given String.
	**/
	public function new(str:String)
	{
		this = new String(str);
	}
	
	/**
		Caching of character maps in two case sensitivites
	**/
	static function initialize() : Void {
		#if (unifill && (neko || php || cpp))
		lcaseMap = new Map<Int, Int>();
		ucaseMap = new Map<Int, Int>();
		
		Utf8ExtInternal.fillUpperToLowerMap(lcaseMap);
		Utf8ExtInternal.fillLowerToUpperMap(ucaseMap);
		inited = true;
		#end
	}
	
	/**
		Returns a String where all characters of `this` String are upper case.
		
		Affects the characters `a-z`. Other characters remain unchanged.
	**/
	public function toUpperCase() : String
	{
		#if (unifill && (neko || php || cpp))
		if (!inited) initialize();
		
		var r = new Utf8();
		
		Utf8.iter(this, function(v) {
			r.addChar(ucaseMap.exists(v) ? ucaseMap[v] : v);
		});
		
		return r.toString();
		#else
		return this.toUpperCase();
		#end
	}

	/**
		Returns a String where all characters of `this` String are lower case.
		
		Affects the characters `A-Z`. Other characters remain unchanged.
	**/
	public function toLowerCase() : String
	{
		#if (unifill && (neko || php || cpp))
		if (!inited) initialize();
		
		var r = new Utf8();
		
		Utf8.iter(this, function(v) {
			r.addChar(lcaseMap.exists(v) ? lcaseMap[v] : v);
		});
		
		return r.toString();
		#else
		return this.toLowerCase();
		#end
	}

	/**
		Returns the character at position `index` of `this` String.
		
		If `index` is negative or exceeds `this.length`, the empty String `""`
		is returned.
	**/
	public function charAt(index : Int) : String
	{
		#if unifill
		return Unifill.uCharAt(this, index);
		#else
		return this.charAt(index);
		#end
	}

	/**
		Returns the character code at position `index` of `this` String.
		
		If `index` is negative or exceeds `this.length`, `null` is returned.
		
		To obtain the character code of a single character, `"x".code` can be
		used instead to inline the character code at compile time. Note that
		this only works on String literals of length 1.
	**/
	public function charCodeAt(index : Int) : Null<Int>
	{
		#if unifill
		return Utf8.charCodeAt(this, index);
		#else
		return this.charCodeAt(index);
		#end
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
	public function indexOf(str : String, ?startIndex : Int = 0) : Int
	{
		#if unifill
		return Unifill.uIndexOf(this, str, startIndex);
		#else
		return this.indexOf(str, startIndex);
		#end
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
	public function lastIndexOf(str : String, ?startIndex : Int) : Int
	{
		#if unifill
		return Unifill.uLastIndexOf(this, str, startIndex);
		#else
		return this.lastIndexOf(str, startIndex);
		#end
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
	public function split(delimiter : String) : Array<String>
	{
		#if unifill
		return Unifill.uSplit(this, delimiter);
		#else
		return this.split(delimiter);
		#end
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
	public function substr(pos : Int, ?len : Int) : String
	{
		#if unifill
		return Utf8.sub(this, pos, len);
		#else
		return this.substr(pos, len);
		#end
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
	public function substring(startIndex : Int, ?endIndex : Int) : String
	{
		#if unifill
		return Unifill.uSubstring(this, startIndex, endIndex);
		#else
		return this.substring(startIndex, endIndex);
		#end
	}

	/**
		Returns the String itself.
	**/
	public function toString() : String
	{
		return this;
	}

	/**
		Returns the String corresponding to the character code `code`.
		
		If `code` is negative or has another invalid value, the result is
		unspecified.
	**/
	public static function fromCharCode(code : Int) : String
	{
		#if unifill
		//var sb = new StringBuf();
		//sb.addChar(code);
		//return sb.toString();
		return CodePoint.fromInt(code);
		#else
		return String.fromCharCode(code);
		#end
	}
	
	/**
		Returns the string corresponding to the array of character codes `codes`.
		
		If #unifill is defined, these codes will be treated as UTF-8 code points,
		otherwise it will default to using String.fromCharCode() for each character
	 **/
	public static function fromCharCodes(codes : Array<Int>) : String
	{
		var s = "";
		for (code in codes)
		{
			#if unifill
			s += CodePoint.fromInt(code);
			#else
			s += String.fromCharCode(code);
			#end
		}
		return s;
	}
	
	/**********PRIVATE*************/
	
	@:op(A == B) static function equals(a:UTFString, b:UTFString) : Bool
	{
		#if unifill
		return Unifill.uCompare(a, b) == 0;
		#else
		return Std.string(a) == Std.string(b);
		#end
	}
	
	@:op(A < B) static function lt(a:UTFString, b:UTFString) : Bool
	{
		#if unifill
		return Unifill.uCompare(a, b) == -1;
		#else
		return Std.string(a) < Std.string(b);
		#end
	}
	
	@:op(A > B) static function gt(a:UTFString, b:UTFString) : Bool
	{
		#if unifill
		return Unifill.uCompare(a, b) == 1;
		#else
		return Std.string(a) > Std.string(b);
		#end
	}
	
	@:op(A <= B) static function lteq(a:UTFString, b:UTFString) : Bool
	{
		#if unifill
		return Unifill.uCompare(a, b) != 1;
		#else
		return Std.string(a) <= Std.string(b);
		#end
	}
	
	@:op(A >= B) static function gteq(a:UTFString, b:UTFString) : Bool
	{
		#if unifill
		return Unifill.uCompare(a, b) != -1;
		#else
		return Std.string(a) >= Std.string(b);
		#end
	}
	
	@:op(A + B) static function plus(a:UTFString, b:UTFString) : String
	{
		#if unifill
		var sb = new StringBuf();
		sb.add(Std.string(a));
		sb.add(Std.string(b));
		return sb.toString();
		#else
		return Std.string(a) + Std.string(b);
		#end
	}
	
	private function get_length() : Int
	{
		#if unifill
		return Utf8.length(this);
		#else
		return this.length;
		#end
	}
	
}