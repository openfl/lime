package lime.utils;


import haxe.PosInfos;


class Log {
	
	
	public static var level:LogLevel;
	
	
	public static function debug (message:String, ?info:PosInfos):Void {
		
		if (level >= LogLevel.DEBUG) {
			
			println ("[" + info.className + "] " + message);
			
		}
		
	}
	
	
	public static function error (message:String, ?info:PosInfos):Void {
		
		if (level >= LogLevel.ERROR) {
			
			println ("[" + info.className + "] ERROR: " + message);
			
		}
		
	}
	
	
	public static function info (message:String, ?info:PosInfos):Void {
		
		if (level >= LogLevel.INFO) {
			
			println ("[" + info.className + "] " + message);
			
		}
		
	}
	
	
	public static inline function print (message:String):Void {
		
		#if sys
		Sys.print (message);
		#elseif flash
		untyped __global__["trace"] (message);
		#elseif js
		untyped __js__("console").log (message);
		#else
		trace (message);
		#end
		
	}
	
	
	public static inline function println (message:String):Void {
		
		#if sys
		Sys.println (message);
		#elseif flash
		untyped __global__["trace"] (message);
		#elseif js
		untyped __js__("console").log (message);
		#else
		trace (message);
		#end
		
	}
	
	
	public static function verbose (message:String, ?info:PosInfos):Void {
		
		if (level >= LogLevel.VERBOSE) {
			
			println ("[" + info.className + "] " + message);
			
		}
		
	}
	
	
	public static function warn (message:String, ?info:PosInfos):Void {
		
		if (level >= LogLevel.WARN) {
			
			println ("[" + info.className + "] WARNING: " + message);
			
		}
		
	}
	
	
	private static function __init__ ():Void {
		
		#if no_traces
		level = NONE;
		#elseif verbose
		level = VERBOSE;
		#else
		#if sys
		var args = Sys.args ();
		if (args.indexOf ("-v") > -1 || args.indexOf ("-verbose") > -1) {
			level = VERBOSE;
		} else
		#end
		{
			#if debug
			level = DEBUG;
			#else
			level = INFO;
			#end
		}
		#end
		
		#if js
		if (untyped __js__("typeof console") == "undefined") {
			untyped __js__("console = {}");
		}
		if (untyped __js__("console").log == null) {
			untyped __js__("console").log = function () {};
		}
		#end
		
	}
	
	
}


@:enum abstract LogLevel(Int) from Int to Int from UInt to UInt {
	
	var NONE = 0;
	var ERROR = 1;
	var WARN = 2;
	var INFO = 3;
	var DEBUG = 4;
	var VERBOSE = 5;
	
	@:op(A > B) private static inline function gt (a:LogLevel, b:LogLevel):Bool { return (a:Int) > (b:Int); }
	@:op(A >= B) private static inline function gte (a:LogLevel, b:LogLevel):Bool { return (a:Int) >= (b:Int); }
	@:op(A < B) private static inline function lt (a:LogLevel, b:LogLevel):Bool { return (a:Int) < (b:Int); }
	@:op(A <= B) private static inline function lte (a:LogLevel, b:LogLevel):Bool { return (a:Int) <= (b:Int); }
	
}