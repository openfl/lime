package lime.net.curl;


import lime.system.System;


abstract CURL(Int) from Int to Int {
	
	
	public static inline var GLOBAL_SSL:Int = 1 << 0;
	public static inline var GLOBAL_WIN32:Int = 1 << 1;
	public static inline var GLOBAL_ALL:Int = GLOBAL_SSL | GLOBAL_WIN32;
	public static inline var GLOBAL_NOTHING:Int = 0;
	public static inline var GLOBAL_DEFAULT:Int = GLOBAL_ALL;
	public static inline var GLOBAL_ACK_EINTR:Int = 1 << 2;
	
	
	public static function getDate (date:String, now:Int):Int {
		
		#if ((cpp || neko || nodejs) && lime_curl)
		return lime_curl_getdate (date, now);
		#else
		return 0;
		#end
		
	}
	
	
	public static function globalCleanup ():Void {
		
		#if ((cpp || neko || nodejs) && lime_curl)
		lime_curl_global_cleanup ();
		#end
		
	}
	
	
	public static function globalInit (flags:Int):CURLCode {
		
		#if ((cpp || neko || nodejs) && lime_curl)
		return cast lime_curl_global_init (flags);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function version ():String {
		
		#if ((cpp || neko || nodejs) && lime_curl)
		return lime_curl_version ();
		#else
		return null;
		#end
		
	}
	
	
	public static function versionInfo (type:CURLVersion):String {
		
		#if ((cpp || neko || nodejs) && lime_curl)
		return lime_curl_version_info (cast (type, Int));
		#else
		return null;
		#end
		
	}
	
	
	@:op(A > B) private static inline function intGt (a:CURL, b:Int):Bool {
		
		return (a:Int) > b;
		
	}
	
	
	#if ((cpp || neko || nodejs) && lime_curl)
	private static var lime_curl_getdate = System.load ("lime", "lime_curl_getdate", 2);
	private static var lime_curl_global_cleanup = System.load ("lime", "lime_curl_global_cleanup", 0);
	private static var lime_curl_global_init = System.load ("lime", "lime_curl_global_init", 1);
	private static var lime_curl_version = System.load ("lime", "lime_curl_version", 0);
	private static var lime_curl_version_info = System.load ("lime", "lime_curl_easy_cleanup", 1);
	#end
	
	
}