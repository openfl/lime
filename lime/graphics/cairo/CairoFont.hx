package lime.graphics.cairo;
import lime.text.Font;
import lime.system.System;

class CairoFont
{
	@:noCompletion public var handle:Dynamic;

	public var font(default,null):Font;
	
	public function new( font : Font ) {
		
		#if lime_cairo
		this.font = font;
		handle = lime_cairo_ft_font_face_create_for_ft_face( font.src, 0 );
		#end
	}
	
	public function destroy() {
		#if lime_cairo
		lime_cairo_font_face_destroy (handle);
		#end
	}
		
	#if (cpp || neko || nodejs)
	private static var lime_cairo_ft_font_face_create_for_ft_face = System.load ("lime", "lime_cairo_ft_font_face_create_for_ft_face", 2);
	private static var lime_cairo_font_face_destroy = System.load ("lime", "lime_cairo_font_face_destroy", 1);
	#end
	
}