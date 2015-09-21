package lime.net.curl;


#if !macro
@:build(lime.system.CFFI.build())
#end


abstract CURL(Float) from Float to Float {
	
	
	public static inline var GLOBAL_SSL:Int = 1 << 0;
	public static inline var GLOBAL_WIN32:Int = 1 << 1;
	public static inline var GLOBAL_ALL:Int = GLOBAL_SSL | GLOBAL_WIN32;
	public static inline var GLOBAL_NOTHING:Int = 0;
	public static inline var GLOBAL_DEFAULT:Int = GLOBAL_ALL;
	public static inline var GLOBAL_ACK_EINTR:Int = 1 << 2;
	
	
	public static function getDate (date:String, now:Int):Int {
		
		#if ((cpp || neko || nodejs) && lime_curl && !macro)
		return cast lime_curl_getdate (date, cast now);
		#else
		return 0;
		#end
		
	}
	
	
	public static function globalCleanup ():Void {
		
		#if ((cpp || neko || nodejs) && lime_curl && !macro)
		lime_curl_global_cleanup ();
		#end
		
	}
	
	
	public static function globalInit (flags:Int):CURLCode {
		
		#if ((cpp || neko || nodejs) && lime_curl && !macro)
		return cast lime_curl_global_init (flags);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function version ():String {
		
		#if ((cpp || neko || nodejs) && lime_curl && !macro)
		return lime_curl_version ();
		#else
		return null;
		#end
		
	}
	
	
	public static function versionInfo (type:CURLVersion):Dynamic {
		
		#if ((cpp || neko || nodejs) && lime_curl && !macro)
		return lime_curl_version_info (cast (type, Int));
		#else
		return null;
		#end
		
	}
	
	
	@:op(A > B) private static inline function intGt (a:CURL, b:Float):Bool {
		
		return (a:Float) > b;
		
	}
	
	
	#if ((cpp || neko || nodejs) && lime_curl && !macro)
	@:cffi private static function lime_curl_getdate (date:String, now:Float):Float;
	@:cffi private static function lime_curl_global_cleanup ():Void;
	@:cffi private static function lime_curl_global_init (flags:Int):Int;
	@:cffi private static function lime_curl_version ():Dynamic;
	@:cffi private static function lime_curl_version_info (type:Int):Dynamic;
	#end
	
	
}