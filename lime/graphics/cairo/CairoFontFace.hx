package lime.graphics.cairo;


import lime.system.CFFIPointer;

#if !macro
@:build(lime.system.CFFI.build())
#end


abstract CairoFontFace(CFFIPointer) from CFFIPointer to CFFIPointer {
	
	
	private function new () {
		
		this = null;
		
	}
	
	
	public function status ():CairoStatus {
		
		#if (lime_cairo && !macro)
		return lime_cairo_font_face_status (this);
		#else
		return 0;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_cairo_font_face_status (handle:CFFIPointer):Int;
	#end
	
	
}