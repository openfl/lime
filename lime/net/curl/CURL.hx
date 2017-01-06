package lime.net.curl;


import lime._backend.native.NativeCFFI;

@:access(lime._backend.native.NativeCFFI)


abstract CURL(Float) from Float to Float {
	
	
	public static inline var GLOBAL_SSL:Int = 1 << 0;
	public static inline var GLOBAL_WIN32:Int = 1 << 1;
	public static inline var GLOBAL_ALL:Int = GLOBAL_SSL | GLOBAL_WIN32;
	public static inline var GLOBAL_NOTHING:Int = 0;
	public static inline var GLOBAL_DEFAULT:Int = GLOBAL_ALL;
	public static inline var GLOBAL_ACK_EINTR:Int = 1 << 2;
	
	
	public static function getDate (date:String, now:Int):Int {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_getdate (date, cast now);
		#else
		return 0;
		#end
		
	}
	
	
	public static function globalCleanup ():Void {
		
		#if (lime_cffi && lime_curl && !macro)
		NativeCFFI.lime_curl_global_cleanup ();
		#end
		
	}
	
	
	public static function globalInit (flags:Int):CURLCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_global_init (flags);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function version ():String {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_version ();
		#else
		return null;
		#end
		
	}
	
	
	public static function versionInfo (type:CURLVersion):Dynamic {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_version_info (cast (type, Int));
		#else
		return null;
		#end
		
	}
	
	
	@:op(A > B) private static inline function intGt (a:CURL, b:Float):Bool {
		
		return (a:Float) > b;
		
	}
	
	
}