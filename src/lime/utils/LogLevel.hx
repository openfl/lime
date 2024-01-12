package lime.utils;

#if (haxe_ver >= 4.0) enum #else @:enum #end abstract LogLevel(Int) from Int to Int from UInt to UInt
{
	var NONE = 0;
	var ERROR = 1;
	var WARN = 2;
	var INFO = 3;
	var DEBUG = 4;
	var VERBOSE = 5;

	@:op(A > B) private static inline function gt(a:LogLevel, b:LogLevel):Bool
	{
		return (a : Int) > (b : Int);
	}

	@:op(A >= B) private static inline function gte(a:LogLevel, b:LogLevel):Bool
	{
		return (a : Int) >= (b : Int);
	}

	@:op(A < B) private static inline function lt(a:LogLevel, b:LogLevel):Bool
	{
		return (a : Int) < (b : Int);
	}

	@:op(A <= B) private static inline function lte(a:LogLevel, b:LogLevel):Bool
	{
		return (a : Int) <= (b : Int);
	}
}
