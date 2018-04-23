package lime.net.curl;


import haxe.io.Bytes;
import lime._backend.native.NativeCFFI;
import lime.system.CFFIPointer;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)


class CURL {
	
	
	public static inline var GLOBAL_SSL:Int = 1 << 0;
	public static inline var GLOBAL_WIN32:Int = 1 << 1;
	public static inline var GLOBAL_ALL:Int = GLOBAL_SSL | GLOBAL_WIN32;
	public static inline var GLOBAL_NOTHING:Int = 0;
	public static inline var GLOBAL_DEFAULT:Int = GLOBAL_ALL;
	public static inline var GLOBAL_ACK_EINTR:Int = 1 << 2;
	
	private var handle:CFFIPointer;
	private var headerBytes:Bytes;
	private var writeBytes:Bytes;
	
	
	public function new (handle:CFFIPointer = null) {
		
		if (handle != null) {
			
			this.handle = handle;
			
		} else {
			
			#if (lime_cffi && lime_curl && !macro)
			this.handle = NativeCFFI.lime_curl_easy_init ();
			#end
			
		}
		
	}
	
	
	public function cleanup ():Void {
		
		#if (lime_cffi && lime_curl && !macro)
		NativeCFFI.lime_curl_easy_cleanup (handle);
		#end
		
	}
	
	
	public function clone ():CURL {
		
		#if (lime_cffi && lime_curl && !macro)
		return new CURL (NativeCFFI.lime_curl_easy_duphandle (handle));
		#else
		return null;
		#end
		
	}
	
	
	public function escape (url:String, length:Int):String {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_easy_escape (handle, url, length);
		#else
		return null;
		#end
		
	}
	
	
	public static function getDate (date:String, now:Int):Int {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_getdate (date, cast now);
		#else
		return 0;
		#end
		
	}
	
	
	public function getInfo (info:CURLInfo):Dynamic {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_easy_getinfo (handle, cast (info, Int));
		#else
		return null;
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
	
	
	public function pause (bitMask:Int):CURLCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_easy_pause (handle, bitMask);
		#else
		return cast 0;
		#end
		
	}
	
	
	public function perform ():CURLCode {
		
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
	
	
	public function reset ():Void {
		
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
	
	
	public function setOption (option:CURLOption, parameter:Dynamic):CURLCode {
		
		#if (lime_cffi && lime_curl && !macro)
		if (option == CURLOption.WRITEFUNCTION) {
			
			if (writeBytes == null) writeBytes = Bytes.alloc (1024);
			return cast NativeCFFI.lime_curl_easy_setopt (handle, cast (option, Int), parameter, writeBytes);
			
		} else if (option == CURLOption.HEADERFUNCTION) {
			
			if (headerBytes == null) headerBytes = Bytes.alloc (1024);
			return cast NativeCFFI.lime_curl_easy_setopt (handle, cast (option, Int), parameter, headerBytes);
			
		} else {
			
			return cast NativeCFFI.lime_curl_easy_setopt (handle, cast (option, Int), parameter, null);
			
		}
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
	
	
	public function unescape (url:String, inLength:Int, outLength:Int):String {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_easy_unescape (handle, url, inLength, outLength);
		#else
		return null;
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
	
	
}