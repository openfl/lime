package lime.net.curl;


import lime.net.curl.CURL;
import lime.system.System;


class CURLEasy {
	
	
	public static function cleanup (handle:CURL):Void {
		
		#if ((cpp || neko) && lime_curl)
		lime_curl_easy_cleanup (handle);
		#end
		
	}
	
	
	public static function duphandle (handle:CURL):CURL {
		
		#if ((cpp || neko) && lime_curl)
		return lime_curl_easy_duphandle (handle);
		#else
		return 0;
		#end
		
	}
	
	
	public static function escape (handle:CURL, url:String, length:Int):String {
		
		#if ((cpp || neko) && lime_curl)
		return lime_curl_easy_escape (handle, url, length);
		#else
		return null;
		#end
		
	}
	
	
	public static function getinfo (handle:CURL, info:CURLInfo):Dynamic {
		
		#if ((cpp || neko) && lime_curl)
		return lime_curl_easy_getinfo (handle, cast (info, Int));
		#else
		return null;
		#end
		
	}
	
	
	public static function init ():CURL {
		
		#if ((cpp || neko) && lime_curl)
		return lime_curl_easy_init ();
		#else
		return 0;
		#end
		
	}
	
	
	public static function pause (handle:CURL, bitMask:Int):CURLCode {
		
		#if ((cpp || neko) && lime_curl)
		return cast lime_curl_easy_pause (handle, bitMask);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function perform (handle:CURL):CURLCode {
		
		#if ((cpp || neko) && lime_curl)
		return cast lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end
		
	}
	
	
	/*public static function recv (handle:Dynamic):CURLCode {
		
		#if ((cpp || neko) && lime_curl)
		return cast lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end
		
	}*/
	
	
	public static function reset (handle:CURL):CURLCode {
		
		#if ((cpp || neko) && lime_curl)
		return cast lime_curl_easy_reset (handle);
		#else
		return cast 0;
		#end
		
	}
	
	
	/*public static function send (handle:Dynamic):CURLCode {
		
		#if ((cpp || neko) && lime_curl)
		return cast lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end
		
	}*/
	
	
	public static function setopt (handle:CURL, option:CURLOption, parameter:Dynamic):CURLCode {
		
		#if ((cpp || neko) && lime_curl)
		return cast lime_curl_easy_setopt (handle, cast (option, Int), parameter);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function strerror (code:CURLCode):String {
		
		#if ((cpp || neko) && lime_curl)
		return lime_curl_easy_strerror (cast (code, Int));
		#else
		return null;
		#end
		
	}
	
	
	public static function unescape (handle:CURL, url:String, inLength:Int, outLength:Int):String {
		
		#if ((cpp || neko) && lime_curl)
		return lime_curl_easy_unescape (handle, url, inLength, outLength);
		#else
		return null;
		#end
		
	}
	
	
	#if ((cpp || neko) && lime_curl)
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