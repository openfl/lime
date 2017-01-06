package lime.net.curl;


import haxe.io.Bytes;
import lime._backend.native.NativeCFFI;
import lime.net.curl.CURL;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)


class CURLEasy {
	
	
	public static function cleanup (handle:CURL):Void {
		
		#if (lime_cffi && lime_curl && !macro)
		NativeCFFI.lime_curl_easy_cleanup (handle);
		#end
		
	}
	
	
	public static function duphandle (handle:CURL):CURL {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_easy_duphandle (handle);
		#else
		return 0;
		#end
		
	}
	
	
	public static function escape (handle:CURL, url:String, length:Int):String {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_easy_escape (handle, url, length);
		#else
		return null;
		#end
		
	}
	
	
	public static function getinfo (handle:CURL, info:CURLInfo):Dynamic {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_easy_getinfo (handle, cast (info, Int));
		#else
		return null;
		#end
		
	}
	
	
	public static function init ():CURL {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_easy_init ();
		#else
		return 0;
		#end
		
	}
	
	
	public static function pause (handle:CURL, bitMask:Int):CURLCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_easy_pause (handle, bitMask);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function perform (handle:CURL):CURLCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end
		
	}
	
	
	/*public static function recv (handle:Dynamic):CURLCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end
		
	}*/
	
	
	public static function reset (handle:CURL):Void {
		
		#if (lime_cffi && lime_curl && !macro)
		NativeCFFI.lime_curl_easy_reset (handle);
		#end
		
	}
	
	
	/*public static function send (handle:Dynamic):CURLCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end
		
	}*/
	
	
	public static function setopt (handle:CURL, option:CURLOption, parameter:Dynamic):CURLCode {
		
		#if (lime_cffi && lime_curl && !macro)
		if (option == CURLOption.WRITEFUNCTION || option == CURLOption.HEADERFUNCTION) {
			
			parameter = __writeCallback.bind (parameter);
			
		}
		return cast NativeCFFI.lime_curl_easy_setopt (handle, cast (option, Int), parameter);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function strerror (code:CURLCode):String {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_easy_strerror (cast (code, Int));
		#else
		return null;
		#end
		
	}
	
	
	public static function unescape (handle:CURL, url:String, inLength:Int, outLength:Int):String {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_easy_unescape (handle, url, inLength, outLength);
		#else
		return null;
		#end
		
	}
	
	
	private static function __writeCallback (callback:Dynamic, output:Dynamic, size:Int, nmemb:Int):Int {
		
		#if (lime_cffi && lime_curl && !macro)
		var bytes:Bytes = null;
		
		if (output != null) {
			
			bytes = @:privateAccess new Bytes (output.length, output.b);
			
		}
		
		return callback (bytes, size, nmemb);
		
		#else
		
		return 0;
		
		#end
		
	}
	
	
}