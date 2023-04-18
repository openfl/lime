package lime._internal.unifill;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;

abstract Utf8(StringU8)
{
	/**
		Converts the code point `code` to a character as a Utf8 string.
	**/
	public static inline function fromCodePoint(codePoint:Int):Utf8
	{
		var buf = new BytesBuffer();
		Utf8Impl.encode_code_point(function(c) buf.addByte(c), codePoint);
		return new Utf8(StringU8.ofBytes(buf.getBytes()));
	}

	/**
		Converts `codePoints` to a Utf8 string.
	**/
	public static inline function fromCodePoints(codePoints:Iterable<Int>):Utf8
	{
		var buf = new BytesBuffer();
		for (c in codePoints)
		{
			Utf8Impl.encode_code_point(function(c) buf.addByte(c), c);
		}
		return new Utf8(StringU8.ofBytes(buf.getBytes()));
	}

	public static inline function fromString(s:String):Utf8
	{
		return new Utf8(StringU8.fromString(s));
	}

	public static inline function fromBytes(b:Bytes):Utf8
	{
		return new Utf8(StringU8.fromBytes(b));
	}

	public static inline function encodeWith(f:Int->Void, c:Int):Void
	{
		Utf8Impl.encode_code_point(f, c);
	}

	public var length(get, never):Int;

	/**
		Returns the UTF-8 code unit at position `index` of `this`.
	**/
	public inline function codeUnitAt(index:Int):Int
	{
		return this.codeUnitAt(index);
	}

	/**
		Returns the Unicode code point at position `index` of
		`this`.
	**/
	public function codePointAt(index:Int):Int
	{
		return Utf8Impl.decode_code_point(length, function(i) return codeUnitAt(i), index);
	}

	/**
		Returns the character as a String at position `index` of
		`this`.
	**/
	public inline function charAt(index:Int):Utf8
	{
		return new Utf8(this.substr(index, codePointWidthAt(index)));
	}

	/**
		Returns the number of Unicode code points from `beginIndex`
		to `endIndex` in `this`.
	**/
	public function codePointCount(beginIndex:Int, endIndex:Int):Int
	{
		var index = beginIndex;
		var i = 0;
		while (index < endIndex)
		{
			index += codePointWidthAt(index);
			++i;
		}
		return i;
	}

	/**
		Returns the number of units of the code point at position
		`index` of `this`.
	**/
	public inline function codePointWidthAt(index:Int):Int
	{
		var c = codeUnitAt(index);
		return Utf8Impl.code_point_width(c);
	}

	/**
		Returns the number of units of the code point before
		position `index` of `this`.
	**/
	public inline function codePointWidthBefore(index:Int):Int
	{
		return Utf8Impl.find_prev_code_point(function(i) return codeUnitAt(i), index);
	}

	/**
		Returns the index within `this` that is offset from
		position `index` by `codePointOffset` code points.
	**/
	public inline function offsetByCodePoints(index:Int, codePointOffset:Int):Int
	{
		return if (codePointOffset >= 0)
		{
			forward_offset_by_code_points(index, codePointOffset);
		}
		else
		{
			backward_offset_by_code_points(index, -codePointOffset);
		}
	}

	/**
		Returns `len` code units of `this`, starting at position pos.
	**/
	public inline function substr(index:Int, ?len:Int):Utf8
	{
		return new Utf8(this.substr(index, len));
	}

	/**
		Validates `this` Utf8 string.

		If the code unit sequence of `this` is invalid,
		`Exception.InvalidCodeUnitSequence` is throwed.
	**/
	public function validate():Void
	{
		var len = this.length;
		var accessor = function(i) return codeUnitAt(i);
		var i = 0;
		while (i < len)
		{
			Utf8Impl.decode_code_point(len, accessor, i);
			i += codePointWidthAt(i);
		}
	}

	public inline function toString():String
	{
		return this.toString();
	}

	public inline function toBytes():Bytes
	{
		return this.toBytes();
	}

	inline function new(s:StringU8)
	{
		this = s;
	}

	inline function get_length():Int
	{
		return this.length;
	}

	inline function forward_offset_by_code_points(index:Int, codePointOffset:Int):Int
	{
		var len = this.length;
		var i = 0;
		while (i < codePointOffset && index < len)
		{
			index += codePointWidthAt(index);
			++i;
		}
		return index;
	}

	inline function backward_offset_by_code_points(index:Int, codePointOffset:Int):Int
	{
		var count = 0;
		while (count < codePointOffset && 0 < index)
		{
			index -= codePointWidthBefore(index);
			++count;
		}
		return index;
	}
}

private class Utf8Impl
{
	public static inline function code_point_width(c:Int):Int
	{
		return (c < 0xC0) ? 1 : (c < 0xE0) ? 2 : (c < 0xF0) ? 3 : (c < 0xF8) ? 4 : 1;
	}

	public static inline function find_prev_code_point(accessor:Int->Int, index:Int):Int
	{
		var c1 = accessor(index - 1);
		return
			(c1 < 0x80 || c1 >= 0xC0) ? 1 : (accessor(index - 2) & 0xE0 == 0xC0) ? 2 : (accessor(index - 3) & 0xF0 == 0xE0) ? 3 : (accessor(index - 4) & 0xF8 == 0xF0) ? 4 : 1;
	}

	public static inline function encode_code_point(addUnit:Int->Void, codePoint:Int):Void
	{
		if (codePoint <= 0x7F)
		{
			addUnit(codePoint);
		}
		else if (codePoint <= 0x7FF)
		{
			addUnit(0xC0 | (codePoint >> 6));
			addUnit(0x80 | (codePoint & 0x3F));
		}
		else if (codePoint <= 0xFFFF)
		{
			addUnit(0xE0 | (codePoint >> 12));
			addUnit(0x80 | ((codePoint >> 6) & 0x3F));
			addUnit(0x80 | (codePoint & 0x3F));
		}
		else if (codePoint <= 0x10FFFF)
		{
			addUnit(0xF0 | (codePoint >> 18));
			addUnit(0x80 | ((codePoint >> 12) & 0x3F));
			addUnit(0x80 | ((codePoint >> 6) & 0x3F));
			addUnit(0x80 | (codePoint & 0x3F));
		}
		else
		{
			throw new Exception.InvalidCodePoint(codePoint);
		}
	}

	public static function decode_code_point(len:Int, accessor:Int->Int, index:Int):Int
	{
		var i = index;
		if (i < 0 || len <= i) throw new Exception.InvalidCodeUnitSequence(index);
		var c1 = accessor(i);
		if (c1 < 0x80)
		{
			return c1;
		}
		if (c1 < 0xC0)
		{
			throw new Exception.InvalidCodeUnitSequence(index);
		}
		++i;
		if (i < 0 || len <= i) throw new Exception.InvalidCodeUnitSequence(index);
		var c2 = accessor(i);
		if (c1 < 0xE0)
		{
			if ((c1 & 0x1E != 0) && (c2 & 0xC0 == 0x80)) return ((c1 & 0x3F) << 6) | (c2 & 0x7F);
			else
				throw new Exception.InvalidCodeUnitSequence(index);
		}
		++i;
		if (i < 0 || len <= i) throw new Exception.InvalidCodeUnitSequence(index);
		var c3 = accessor(i);
		if (c1 < 0xF0)
		{
			if (((c1 & 0x0F != 0) || (c2 & 0x20 != 0))
				&& (c2 & 0xC0 == 0x80)
				&& (c3 & 0xC0 == 0x80)
				&& !(c1 == 0xED && 0xA0 <= c2 && c2 <= 0xBF)) return ((c1 & 0x1F) << 12) | ((c2 & 0x7F) << 6) | (c3 & 0x7F);
			else
				throw new Exception.InvalidCodeUnitSequence(index);
		}
		++i;
		if (i < 0 || len <= i) throw new Exception.InvalidCodeUnitSequence(index);
		var c4 = accessor(i);
		if (c1 < 0xF8)
		{
			if (((c1 & 0x07 != 0) || (c2 & 0x30 != 0))
				&& (c2 & 0xC0 == 0x80)
				&& (c3 & 0xC0 == 0x80)
				&& (c4 & 0xC0 == 0x80)
				&& !((c1 == 0xF4 && c2 > 0x8F) || c1 > 0xF4)) return ((c1 & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 & 0x7F) << 6) | (c4 & 0x7F);
			else
				throw new Exception.InvalidCodeUnitSequence(index);
		}
		throw new Exception.InvalidCodeUnitSequence(index);
	}
}

#if (neko || php || cpp || lua || macro)
private abstract StringU8(String)
{
	public static inline function fromString(s:String):StringU8
	{
		return new StringU8(s);
	}

	public static inline function ofBytes(b:Bytes):StringU8
	{
		return new StringU8(b.toString());
	}

	public static inline function fromBytes(b:Bytes):StringU8
	{
		return new StringU8(b.toString());
	}

	public var length(get, never):Int;

	public inline function codeUnitAt(index:Int):Int
	{
		return StringTools.fastCodeAt(this, index);
	}

	public inline function substr(index:Int, ?len:Int):StringU8
	{
		return new StringU8(this.substr(index, len));
	}

	public inline function toString():String
	{
		return this;
	}

	public inline function toBytes():Bytes
	{
		return Bytes.ofString(this);
	}

	inline function new(s:String)
	{
		this = s;
	}

	inline function get_length():Int
	{
		return this.length;
	}
}
#else
private abstract StringU8(Bytes)
{
	public static function fromString(s:String):StringU8
	{
		var buf = new BytesBuffer();
		var addUnit = buf.addByte;
		for (i in new InternalEncodingIter(s, 0, s.length))
		{
			var c = InternalEncoding.codePointAt(s, i);
			Utf8Impl.encode_code_point(addUnit, c);
		}
		return new StringU8(buf.getBytes());
	}

	public static inline function ofBytes(b:Bytes):StringU8
	{
		return new StringU8(b);
	}

	public static inline function fromBytes(b:Bytes):StringU8
	{
		var nb = clone_bytes(b);
		return new StringU8(nb);
	}

	public var length(get, never):Int;

	public inline function codeUnitAt(index:Int):Int
	{
		return this.get(index);
	}

	public inline function substr(index:Int, ?len:Int):StringU8
	{
		if (index < 0)
		{
			index += this.length;
			if (index < 0) index = 0;
		}
		if (len == null) len = this.length - index;
		var b = this.sub(index, len);
		return new StringU8(b);
	}

	public function toString():String
	{
		var buf = new StringBuf();
		var i = 0;
		var len = this.length;
		var cua = function(i) return this.get(i);
		while (i < len)
		{
			var u = Utf8Impl.decode_code_point(len, cua, i);
			buf.add(InternalEncoding.fromCodePoint(u));
			i += Utf8Impl.code_point_width(codeUnitAt(i));
		}
		return buf.toString();
	}

	public inline function toBytes():Bytes
	{
		return clone_bytes(this);
	}

	static inline function clone_bytes(b:Bytes):Bytes
	{
		var nb = Bytes.alloc(b.length);
		nb.blit(0, b, 0, b.length);
		return nb;
	}

	inline function new(b:Bytes)
	{
		this = b;
	}

	inline function get_length():Int
	{
		return this.length;
	}
}
#end
