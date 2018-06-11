package lime.net.curl;


import haxe.io.Bytes;
import lime._backend.native.NativeCFFI;
import lime.system.CFFIPointer;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)


class CURLMulti {
	
	
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
	
	
}