package lime.graphics.cairo;


import lime.text.Font;

#if !macro
@:build(lime.system.CFFI.build())
#end


abstract CairoFTFontFace(CairoFontFace) from CairoFontFace to CairoFontFace {
	
	
	public static inline var FT_LOAD_FORCE_AUTOHINT = (1 << 5);
	
	
	private function new () {
		
		this = cast 0;
		
	}
	
	
	public static function create (face:Font, loadFlags:Int):CairoFTFontFace {
		
		#if lime_cairo
		return lime_cairo_ft_font_face_create (face.src, loadFlags);
		#else
		return cast 0;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	@:cffi private static function lime_cairo_ft_font_face_create (face:Float, flags:Int):Float;
	#end
	
	
}