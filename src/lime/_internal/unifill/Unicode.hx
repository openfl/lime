package lime._internal.unifill;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Unicode
{
	public static inline var minCodePoint:Int = 0x0000;
	public static inline var maxCodePoint:Int = 0x10FFFF;
	public static inline var minHighSurrogate:Int = 0xD800;
	public static inline var maxHighSurrogate:Int = 0xDBFF;
	public static inline var minLowSurrogate:Int = 0xDC00;
	public static inline var maxLowSurrogate:Int = 0xDFFF;

	public static inline function decodeSurrogate(hi:Int, lo:Int):Int
		return (hi - 0xD7C0 << 10) | (lo & 0x3FF);

	public static inline function encodeHighSurrogate(c:Int):Int
		return (c >> 10) + 0xD7C0;

	public static inline function encodeLowSurrogate(c:Int):Int
		return (c & 0x3FF) | 0xDC00;

	public static inline function isScalar(code:Int):Bool
	{
		return minCodePoint <= code && code <= maxCodePoint && !isHighSurrogate(code) && !isLowSurrogate(code);
	}

	public static inline function isHighSurrogate(code:Int):Bool
	{
		return minHighSurrogate <= code && code <= maxHighSurrogate;
	}

	public static inline function isLowSurrogate(code:Int):Bool
	{
		return minLowSurrogate <= code && code <= maxLowSurrogate;
	}
}
