package lime._internal.unifill;

abstract CodePoint(Int)
{
	@:from
	public static inline function fromInt(code:Int):CodePoint
	{
		if (!Unicode.isScalar(code))
		{
			throw new Exception.InvalidCodePoint(code);
		}
		return new CodePoint(code);
	}

	@:op(A + B)
	public static inline function cons(a:CodePoint, b:String):String
		return a.toString() + b;

	@:op(A + B)
	public static inline function snoc(a:String, b:CodePoint):String
		return a + b.toString();

	@:op(A + B)
	public static inline function addInt(a:CodePoint, b:Int):CodePoint
		return CodePoint.fromInt(a.toInt() + b);

	@:op(A - B)
	public static inline function sub(a:CodePoint, b:CodePoint):Int
		return (a.toInt()) - (b.toInt());

	@:op(A - B)
	public static inline function subInt(a:CodePoint, b:Int):CodePoint
		return CodePoint.fromInt(a.toInt() - b);

	@:op(A == B) public static function eq(a:CodePoint, b:CodePoint):Bool;

	@:op(A != B) public static function ne(a:CodePoint, b:CodePoint):Bool;

	@:op(A < B) public static function lt(a:CodePoint, b:CodePoint):Bool;

	@:op(A <= B) public static function lte(a:CodePoint, b:CodePoint):Bool;

	@:op(A > B) public static function gt(a:CodePoint, b:CodePoint):Bool;

	@:op(A >= B) public static function gte(a:CodePoint, b:CodePoint):Bool;

	inline function new(code:Int):Void
	{
		this = code;
	}

	@:to
	public inline function toString():String
		return InternalEncoding.fromCodePoint(this);

	@:to
	public inline function toInt():Int
		return this;
}
