package lime.graphics.cairo;


#if !macro
@:build(lime.system.CFFI.build())
#end


abstract CairoFontFace(Dynamic) from Float to Float {
	
	
	public var referenceCount (get, never):Int;
	
	
	private function new () {
		
		this = cast 0;
		
	}
	
	
	public function destroy ():Void {
		
		#if lime_cairo
		lime_cairo_font_face_destroy (this);
		#end
		
	}
	
	
	public function reference ():CairoFontFace {
		
		#if lime_cairo
		lime_cairo_font_face_reference (this);
		#end
		
		return this;
		
	}
	
	
	public function status ():CairoStatus {
		
		#if lime_cairo
		return lime_cairo_font_face_status (this);
		#else
		return 0;
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private function get_referenceCount ():Int {
		
		#if lime_cairo
		return lime_cairo_font_face_get_reference_count (this);
		#else
		return 0;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	@:cffi private static function lime_cairo_font_face_destroy (handle:Float):Void;
	@:cffi private static function lime_cairo_font_face_get_reference_count (handle:Float):Int;
	@:cffi private static function lime_cairo_font_face_reference (handle:Float):Void;
	@:cffi private static function lime_cairo_font_face_status (handle:Float):Int;
	#end
	
	
}