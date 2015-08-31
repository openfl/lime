package lime.graphics.cairo;


import lime.system.CFFI;


abstract CairoFontFace(Dynamic) from Float to Float {
	
	
	public var referenceCount (get, never):Int;
	
	
	private function new () {
		
		this = cast 0;
		
	}
	
	
	public function destroy ():Void {
		
		#if lime_cairo
		lime_cairo_font_face_destroy.call (this);
		#end
		
	}
	
	
	public function reference ():CairoFontFace {
		
		#if lime_cairo
		lime_cairo_font_face_reference.call (this);
		#end
		
		return this;
		
	}
	
	
	public function status ():CairoStatus {
		
		#if lime_cairo
		return lime_cairo_font_face_status.call (this);
		#else
		return 0;
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private function get_referenceCount ():Int {
		
		#if lime_cairo
		return lime_cairo_font_face_get_reference_count.call (this);
		#else
		return 0;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_cairo_font_face_destroy = new CFFI<Float->Void> ("lime", "lime_cairo_font_face_destroy");
	private static var lime_cairo_font_face_get_reference_count = new CFFI<Float->Int> ("lime", "lime_cairo_font_face_get_reference_count");
	private static var lime_cairo_font_face_reference = new CFFI<Float->Void> ("lime", "lime_cairo_font_face_reference");
	private static var lime_cairo_font_face_status = new CFFI<Float->Int> ("lime", "lime_cairo_font_face_status");
	#end
	
	
}