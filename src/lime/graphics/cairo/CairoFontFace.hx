package lime.graphics.cairo;


import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;

@:access(lime._internal.backend.native.NativeCFFI)


abstract CairoFontFace(CFFIPointer) from CFFIPointer to CFFIPointer {
	
	
	private function new () {
		
		this = null;
		
	}
	
	
	public function status ():CairoStatus {
		
		#if (lime_cffi && lime_cairo && !macro)
		return NativeCFFI.lime_cairo_font_face_status (this);
		#else
		return 0;
		#end
		
	}
	
	
}