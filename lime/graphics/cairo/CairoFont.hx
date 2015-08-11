package lime.graphics.cairo;


import lime.text.Font;
import lime.system.System;


class CairoFont {
	
	
	private static inline var FT_LOAD_FORCE_AUTOHINT = (1 << 5);
	
	public var font (default, null):Font;
	
	@:noCompletion public var handle:Dynamic;
	
	
	public function new (font:Font) {
		
		#if lime_cairo
		
		this.font = font;
		
		if (font != null && font.src != null) {
			
			handle = lime_cairo_ft_font_face_create_for_ft_face (font.src, FT_LOAD_FORCE_AUTOHINT);
			
		}
		
		#end
		
	}
	
	
	public function destroy () {
		
		#if lime_cairo
		
		if (handle != null) {
			
			lime_cairo_font_face_destroy (handle);
			
		}
		
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_cairo_ft_font_face_create_for_ft_face = System.load ("lime", "lime_cairo_ft_font_face_create_for_ft_face", 2);
	private static var lime_cairo_font_face_destroy = System.load ("lime", "lime_cairo_font_face_destroy", 1);
	#end
	
	
}