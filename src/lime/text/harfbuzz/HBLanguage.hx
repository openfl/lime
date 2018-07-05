package lime.text.harfbuzz;


import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;

@:access(lime._internal.backend.native.NativeCFFI)


abstract HBLanguage(CFFIPointer) from CFFIPointer to CFFIPointer {
	
	
	public function new (language:String = null) {
		
		#if (lime_cffi && lime_harfbuzz && !macro)
		if (language != null) {
			
			this = NativeCFFI.lime_hb_language_from_string (language);
			
		} else {
			
			this = NativeCFFI.lime_hb_language_get_default ();
			
		}
		#else
		this = null;
		#end
		
	}
	
	
	public function toString ():String {
		
		#if (lime_cffi && lime_harfbuzz && !macro)
		if (this != null) {
			
			return NativeCFFI.lime_hb_language_to_string (this);
			
		}
		#end
		return null;
		
	}
	
	
}