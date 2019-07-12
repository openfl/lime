package lime._internal.unifill;

#if python
import python.Syntax;
import python.lib.Builtins;

/**
	Utf32 provides a UTF-32-encoded string.
**/
abstract Utf32(String)
{
	public static inline function fromCodePoint(codePoint:Int):Utf32
	{
		return new Utf32(String.fromCharCode(codePoint));
	}

	public static inline function fromCodePoints(codePoints:Iterable<Int>):Utf32
	{
		return fromArray([for (c in codePoints) c]);
	}

	public static inline function fromString(string:String):Utf32
	{
		return new Utf32(string);
	}

	public static inline function fromArray(a:Array<Int>):Utf32
	{
		var s:String = Syntax.callField('', "join", Syntax.callField(Builtins, "map", Builtins.chr, a));
		return new Utf32(s);
	}

	public static inline function encodeWith(f:Int->Void, c:Int):Void
	{
		f(c);
	}

	public var length(get, never):Int;

	public inline function charAt(index:Int):Utf32
	{
		return new Utf32(this.charAt(index));
	}

	public inline function codeUnitAt(index:Int):Int
	{
		return this.charCodeAt(index);
	}

	public inline function codePointAt(index:Int):Int
	{
		return this.charCodeAt(index);
	}

	public inline function codePointWidthAt(index:Int):Int
	{
		return 1;
	}

	public inline function codePointWidthBefore(index:Int):Int
	{
		return 1;
	}

	public function codePointCount(beginIndex:Int, endIndex:Int):Int
	{
		return if (endIndex < beginIndex)
		{
			0;
		}
		else
		{
			endIndex - beginIndex;
		}
	}

	public inline function offsetByCodePoints(index:Int, codePointOffset:Int):Int
	{
		var p = index + codePointOffset;
		return if (p < 0)
		{
			0;
		}
		else if (p > this.length)
		{
			this.length;
		}
		else
		{
			p;
		}
	}

	public inline function toString():String
	{
		return this;
	}

	public inline function toArray():Array<Int>
	{
		return [for (i in 0...this.length) this.charCodeAt(i)];
	}

	public function validate():Void
	{
		var i = 0;
		var len = this.length;
		for (i in 0...len)
		{
			if (!Unicode.isScalar(this.charCodeAt(i)))
			{
				throw new Exception.InvalidCodeUnitSequence(i);
			}
		}
	}

	@:op(A + B)
	static inline function concat(a:Utf32, b:Utf32):Utf32
	{
		return new Utf32(a.toString() + b.toString());
	}

	@:op(A == B)
	static inline function eq(a:Utf32, b:Utf32):Bool
	{
		return a.toString() == b.toString();
	}

	@:op(A != B)
	static inline function ne(a:Utf32, b:Utf32):Bool
	{
		return !eq(a, b);
	}

	@:op(A + B)
	static inline function cons(a:CodePoint, b:Utf32):Utf32
	{
		return new Utf32(a.toString() + b.toString());
	}

	@:op(A + B)
	static inline function snoc(a:Utf32, b:CodePoint):Utf32
	{
		return new Utf32(a.toString() + b.toString());
	}

	inline function get_length():Int
	{
		return this.length;
	}

	inline function new(s:String)
	{
		this = s;
	}
}
#else

/**
	Utf32 provides a UTF-32-encoded string.
**/
abstract Utf32(Array<Int>)
{
	public static inline function fromCodePoint(codePoint:Int):Utf32
	{
		return new Utf32([codePoint]);
	}

	public static inline function fromCodePoints(codePoints:Iterable<Int>):Utf32
	{
		return fromArray([for (c in codePoints) c]);
	}

	public static inline function fromString(string:String):Utf32
	{
		var u = [
			for (c in new InternalEncodingIter(string, 0, string.length))
				InternalEncoding.codePointAt(string, c)
		];
		return new Utf32(u);
	}

	public static inline function fromArray(a:Array<Int>):Utf32
	{
		return new Utf32(a.copy());
	}

	public static inline function encodeWith(f:Int->Void, c:Int):Void
	{
		f(c);
	}

	public var length(get, never):Int;

	public inline function charAt(index:Int):Utf32
	{
		if (0 <= index && index < this.length)
		{
			return new Utf32([this[index]]);
		}
		else
		{
			return new Utf32([]);
		}
	}

	public inline function codeUnitAt(index:Int):Int
	{
		return this[index];
	}

	public inline function codePointAt(index:Int):Int
	{
		return this[index];
	}

	public inline function codePointWidthAt(index:Int):Int
	{
		return 1;
	}

	public inline function codePointWidthBefore(index:Int):Int
	{
		return 1;
	}

	public inline function toString():String
	{
		return InternalEncoding.fromCodePoints(this);
	}

	public inline function toArray():Array<Int>
	{
		return this.copy();
	}

	public function validate():Void
	{
		var i = 0;
		var len = this.length;
		while (i < len)
		{
			if (!Unicode.isScalar(this[i++]))
			{
				throw new Exception.InvalidCodeUnitSequence(i);
			}
		}
	}

	@:op(A + B)
	static inline function concat(a:Utf32, b:Utf32):Utf32
	{
		var s:Array<Int> = a.toArray();
		return new Utf32(s.concat(cast b));
	}

	static function eq_array(a:Array<Int>, b:Array<Int>):Bool
	{
		// assert(a.length == b.length);
		for (i in 0...a.length)
		{
			if (a[i] != b[i]) return false;
		}
		return true;
	}

	@:op(A == B)
	static inline function eq(a:Utf32, b:Utf32):Bool
	{
		return if (a.length != b.length) false; else eq_array(cast a, cast b);
	}

	@:op(A != B)
	static inline function ne(a:Utf32, b:Utf32):Bool
	{
		return !eq(a, b);
	}

	@:op(A + B)
	static inline function cons(a:CodePoint, b:Utf32):Utf32
	{
		var c:Array<Int> = b.toArray();
		c.unshift(a.toInt());
		return new Utf32(c);
	}

	@:op(A + B)
	static inline function snoc(a:Utf32, b:CodePoint):Utf32
	{
		var c:Array<Int> = a.toArray();
		c.push(b.toInt());
		return new Utf32(c);
	}

	inline function get_length():Int
	{
		return this.length;
	}

	inline function new(a:Array<Int>)
	{
		this = a;
	}
}
#end
