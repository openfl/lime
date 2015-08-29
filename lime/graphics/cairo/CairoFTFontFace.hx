package lime.graphics.cairo;


import lime.system.System;
import lime.text.Font;


abstract CairoFTFontFace(CairoFontFace) from CairoFontFace to CairoFontFace {
	
	
	public static inline var FT_LOAD_FORCE_AUTOHINT = (1 << 5);
	
	
	private function new () {
		
		this = cast 0;
		
	}
	
	
	public static function create (face:Font, loadFlags:Int):CairoFTFontFace {
		
		#if lime_cairo
		return lime_cairo_ft_font_face_create.call (face.src, loadFlags);
		#else
		return cast 0;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_cairo_ft_font_face_create = System.loadPrime ("lime", "lime_cairo_ft_font_face_create", "did");
	#end
	
	
}