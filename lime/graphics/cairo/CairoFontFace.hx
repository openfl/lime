package lime.graphics.cairo;


#if !macro
@:build(lime.system.CFFI.build())
#end


abstract CairoFontFace(Dynamic) {
	
	
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
	@:cffi private static function lime_cairo_font_face_status (handle:Dynamic):Int;
	#end
	
	
}