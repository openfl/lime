package lime.net.curl;


import haxe.io.Bytes;
import lime._backend.native.NativeCFFI;
import lime.net.curl.CURL;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)


@:deprecated class CURLEasy {
	
	
	public static function cleanup (handle:CURL):Void {
		
		handle.cleanup ();
		
	}
	
	
	public static function duphandle (handle:CURL):CURL {
		
		return handle.clone ();
		
	}
	
	
	public static function escape (handle:CURL, url:String, length:Int):String {
		
		return handle.escape (url, length);
		
	}
	
	
	public static function getinfo (handle:CURL, info:CURLInfo):Dynamic {
		
		return handle.getInfo (info);
		
	}
	
	
	public static function init ():CURL {
		
		return new CURL ();
		
	}
	
	
	public static function pause (handle:CURL, bitMask:Int):CURLCode {
		
		return handle.pause (bitMask);
		
	}
	
	
	public static function perform (handle:CURL):CURLCode {
		
		return handle.perform ();
		
	}
	
	
	/*public static function recv (handle:Dynamic):CURLCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end
		
	}*/
	
	
	public static function reset (handle:CURL):Void {
		
		return handle.reset ();
		
	}
	
	
	/*public static function send (handle:Dynamic):CURLCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_easy_perform (handle);
		#else
		return cast 0;
		#end
		
	}*/
	
	
	public static function setopt (handle:CURL, option:CURLOption, parameter:Dynamic):CURLCode {
		
		return handle.setOption (option, parameter);
		
	}
	
	
	public static function strerror (code:CURLCode):String {
		
		return CURL.strerror (code);
		
	}
	
	
	public static function unescape (handle:CURL, url:String, inLength:Int, outLength:Int):String {
		
		return handle.unescape (url, inLength, outLength);
		
	}
	
	
}