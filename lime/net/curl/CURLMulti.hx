package lime.net.curl;


import lime._backend.native.NativeCFFI;
import lime.system.CFFIPointer;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)
@:access(lime.net.curl.CURL)
@:access(lime.net.curl.CURLMsg)


class CURLMulti {
	
	
	public var runningHandles (get, never):Int;
	
	private var handle:CFFIPointer;
	
	
	public function new (handle:CFFIPointer = null) {
		
		if (handle != null) {
			
			this.handle = handle;
			
		} else {
			
			#if (lime_cffi && lime_curl && !macro)
			this.handle = NativeCFFI.lime_curl_multi_init ();
			#end
			
		}
		
	}
	
	
	public function addHandle (curl:CURL):CURLMultiCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_multi_add_handle (handle, curl.handle);
		#else
		return cast 0;
		#end
		
	}
	
	
	public function infoRead ():CURLMsg {
		
		#if (lime_cffi && lime_curl && !macro)
		#if hl
		var object:{ easy_handle:CFFIPointer, result:Int } = { easy_handle: null, result: 0 };
		#end
		var msg:Dynamic = NativeCFFI.lime_curl_multi_info_read (handle #if hl , object #end);
		var result = null;
		
		if (msg != null) {
			result = new CURLMsg (msg.easy_handle, msg.result);
		}
		
		return result;
		#else
		return null;
		#end
		
	}
	
	
	public function perform ():CURLMultiCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_multi_perform (handle);
		#else
		return cast 0;
		#end
		
	}
	
	
	public function removeHandle (curl:CURL):CURLMultiCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_multi_remove_handle (handle, curl.handle);
		#else
		return cast 0;
		#end
		
	}
	
	
	public function setOption (option:CURLMultiOption, parameter:Dynamic):CURLMultiCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_multi_setopt (handle, option, parameter);
		#else
		return cast 0;
		#end
		
	}
	
	
	public function wait (timeoutMS:Int):CURLMultiCode {
		
		#if (lime_cffi && lime_curl && !macro)
		return cast NativeCFFI.lime_curl_multi_wait (handle, timeoutMS);
		#else
		return cast 0;
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_runningHandles ():Int {
		
		#if (lime_cffi && lime_curl && !macro)
		return NativeCFFI.lime_curl_multi_get_running_handles (handle);
		#else
		return 0;
		#end
		
	}
	
	
}