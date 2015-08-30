package lime.graphics.cairo;


import lime.system.System;


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
	private static var lime_cairo_font_face_destroy = System.loadPrime ("lime", "lime_cairo_font_face_destroy", "dv");
	private static var lime_cairo_font_face_get_reference_count = System.loadPrime ("lime", "lime_cairo_font_face_get_reference_count", "di");
	private static var lime_cairo_font_face_reference  = System.loadPrime ("lime", "lime_cairo_font_face_reference", "dv");
	private static var lime_cairo_font_face_status  = System.loadPrime ("lime", "lime_cairo_font_face_status", "di");
	#end
	
	
}