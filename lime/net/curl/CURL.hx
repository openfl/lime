package lime.net.curl;


import lime.system.System;


class CURL {
	
	
	public static function easyCleanup (handle:Dynamic):Void {
		
		#if (cpp || neko)
		lime_curl_easy_cleanup (handle);
		#end
		
	}
	
	
	public static function easyDupHandle (handle:Dynamic):Float {
		
		#if (cpp || neko)
		return lime_curl_easy_duphandle (handle);
		#else
		return 0;
		#end
		
	}
	
	
	public static function easyEscape (handle:Dynamic, url:String, length:Int):String {
		
		#if (cpp || neko)
		return lime_curl_easy_escape (handle, url, length);
		#else
		return null;
		#end
		
	}
	
	
	public static function easyGetInfo (handle:Float, info:CURLInfo):Dynamic {
		
		#if (cpp || neko)
		return lime_curl_easy_getinfo (handle, cast (info, Int));
		#else
		return null;
		#end
		
	}
	
	
	public static function easyInit ():Float {
		
		#if (cpp || neko)
		return lime_curl_easy_init ();
		#else
		return null;
		#end
		
	}
	
	
	public static function easyPause (handle:Float, bitMask:Int):CURLCode {
		
		#if (cpp || neko)
		return cast lime_curl_easy_pause (handle, bitMask);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function easyPerform (handle:Float):CURLCode {
		
		#if (cpp || neko)
		return cast lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end
		
	}
	
	
	/*public static function easyRecv (handle:Dynamic):CURLCode {
		
		#if (cpp || neko)
		return cast lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end
		
	}*/
	
	
	public static function easyReset (handle:Float):CURLCode {
		
		#if (cpp || neko)
		return cast lime_curl_easy_reset (handle);
		#else
		return cast 0;
		#end
		
	}
	
	
	/*public static function easySend (handle:Dynamic):CURLCode {
		
		#if (cpp || neko)
		return cast lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end
		
	}*/
	
	
	public static function easySetOpt (handle:Float, option:CURLOption, parameter:Dynamic):CURLCode {
		
		#if (cpp || neko)
		return cast lime_curl_easy_setopt (handle, cast (option, Int), parameter);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function easyStrError (code:CURLCode):String {
		
		#if (cpp || neko)
		return lime_curl_easy_strerror (cast (code, Int));
		#else
		return null;
		#end
		
	}
	
	
	public static function easyUnescape (handle:Float, url:String, inLength:Int, outLength:Int):String {
		
		#if (cpp || neko)
		return lime_curl_easy_unescape (handle, url, inLength, outLength);
		#else
		return null;
		#end
		
	}
	
	
	public static function getDate (date:String, now:Int):Int {
		
		#if (cpp || neko)
		return lime_curl_getdate (date, now);
		#else
		return 0;
		#end
		
	}
	
	
	public static function globalCleanup ():Void {
		
		#if (cpp || neko)
		lime_curl_global_cleanup ();
		#end
		
	}
	
	
	public static function globalInit (flags:Int):CURLCode {
		
		#if (cpp || neko)
		return cast lime_curl_global_init (flags);
		#end
		
	}
	
	
	public static function version ():String {
		
		#if (cpp || neko)
		return lime_curl_version ();
		#else
		return null;
		#end
		
	}
	
	
	public static function versionInfo (type:CURLVersion):String {
		
		#if (cpp || neko)
		return lime_curl_version_info (cast (type, Int));
		#else
		return null;
		#end
		
	}
	
	
	#if (cpp || neko)
	private static var lime_curl_easy_cleanup = System.load ("lime", "lime_curl_easy_cleanup", 1);
	private static var lime_curl_easy_duphandle = System.load ("lime", "lime_curl_easy_duphandle", 1);
	private static var lime_curl_easy_escape = System.load ("lime", "lime_curl_easy_escape", 3);
	private static var lime_curl_easy_getinfo = System.load ("lime", "lime_curl_easy_getinfo", 2);
	private static var lime_curl_easy_init = System.load ("lime", "lime_curl_easy_init", 0);
	private static var lime_curl_easy_pause = System.load ("lime", "lime_curl_easy_pause", 2);
	private static var lime_curl_easy_perform = System.load ("lime", "lime_curl_easy_perform", 1);
	private static var lime_curl_easy_recv = System.load ("lime", "lime_curl_easy_recv", 4);
	private static var lime_curl_easy_reset = System.load ("lime", "lime_curl_easy_reset", 1);
	private static var lime_curl_easy_send = System.load ("lime", "lime_curl_easy_send", 4);
	private static var lime_curl_easy_setopt = System.load ("lime", "lime_curl_easy_setopt", 3);
	private static var lime_curl_easy_strerror = System.load ("lime", "lime_curl_easy_strerror", 1);
	private static var lime_curl_easy_unescape = System.load ("lime", "lime_curl_easy_unescape", 4);
	private static var lime_curl_getdate = System.load ("lime", "lime_curl_getdate", 2);
	private static var lime_curl_global_cleanup = System.load ("lime", "lime_curl_global_cleanup", 0);
	private static var lime_curl_global_init = System.load ("lime", "lime_curl_global_init", 1);
	private static var lime_curl_version = System.load ("lime", "lime_curl_version", 0);
	private static var lime_curl_version_info = System.load ("lime", "lime_curl_easy_cleanup", 1);
	#end
	
	
}