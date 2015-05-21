package lime.graphics.cairo;
import lime.graphics.cairo.CairoSubpixelOrder;
import lime.graphics.cairo.CairoSubpixelOrder;
import lime.graphics.cairo.CairoSubpixelOrder;
import lime.text.Font;
import lime.system.System;

class CairoFontOptions
{
	public var antialias (get, set):CairoAntialias;
	public var subpixelOrder (get, set):CairoSubpixelOrder;
	public var hintStyle (get, set):CairoHintStyle;
	public var hintMetrics (get, set):CairoHintMetrics;
	
	@:noCompletion public var handle:Dynamic;

	public function new( handle : Dynamic = null  ) {
		
		#if lime_cairo
		if ( handle == null ) 
			handle = lime_cairo_font_options_create();
		#end
			
		this.handle = handle;
	}
		
	@:noCompletion private function get_antialias ():CairoAntialias {
		
		#if lime_cairo
		return lime_cairo_font_options_get_antialias (handle);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_antialias (value:CairoAntialias):CairoAntialias {
		
		#if lime_cairo
		lime_cairo_font_options_set_antialias (handle, value);
		#end
		
		return value;
		
	}
	
	@:noCompletion private function get_subpixelOrder ():CairoSubpixelOrder {
		
		#if lime_cairo
		return lime_cairo_font_options_get_subpixel_order (handle);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_subpixelOrder (value:CairoSubpixelOrder):CairoSubpixelOrder {
		
		#if lime_cairo
		lime_cairo_font_options_set_subpixel_order (handle, value);
		#end
		
		return value;
		
	}
	
	@:noCompletion private function get_hintStyle ():CairoHintStyle {
		
		#if lime_cairo
		return lime_cairo_font_options_get_hint_style (handle);
		#end
		
		return cast 0;
	}
	
	
	@:noCompletion private function set_hintStyle (value:CairoHintStyle):CairoHintStyle {
		
		#if lime_cairo
		lime_cairo_font_options_set_hint_style (handle, value);
		#end
		
		return value;
	}
		
	@:noCompletion private function get_hintMetrics ():CairoHintMetrics {
		
		#if lime_cairo
		return lime_cairo_font_options_get_hint_metrics (handle);
		#end
		
		return cast 0;
	}

	@:noCompletion private function set_hintMetrics (value:CairoHintMetrics):CairoHintMetrics {
		
		#if lime_cairo
		lime_cairo_font_options_set_hint_metrics (handle, value);
		#end
		
		return value;
	}
	
	#if (cpp || neko || nodejs)
	private static var lime_cairo_font_options_create = System.load ("lime", "lime_cairo_font_options_create", 0);
	private static var lime_cairo_font_options_get_antialias = System.load ("lime", "lime_cairo_font_options_get_antialias", 1);
	private static var lime_cairo_font_options_get_subpixel_order = System.load ("lime", "lime_cairo_font_options_get_subpixel_order", 1);
	private static var lime_cairo_font_options_get_hint_style = System.load ("lime", "lime_cairo_font_options_get_hint_style", 1);
	private static var lime_cairo_font_options_get_hint_metrics = System.load ("lime", "lime_cairo_font_options_get_hint_metrics", 1);
	private static var lime_cairo_font_options_set_antialias = System.load ("lime", "lime_cairo_font_options_set_antialias", 2);
	private static var lime_cairo_font_options_set_subpixel_order = System.load ("lime", "lime_cairo_font_options_set_subpixel_order", 2);
	private static var lime_cairo_font_options_set_hint_style = System.load ("lime", "lime_cairo_font_options_set_hint_style", 2);
	private static var lime_cairo_font_options_set_hint_metrics = System.load ("lime", "lime_cairo_font_options_set_hint_metrics", 2);
	#end
	
}