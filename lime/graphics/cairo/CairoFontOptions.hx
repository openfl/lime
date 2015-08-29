package lime.graphics.cairo;


import lime.text.Font;
import lime.system.System;


abstract CairoFontOptions(Dynamic) {
	
	
	public var antialias (get, set):CairoAntialias;
	public var hintMetrics (get, set):CairoHintMetrics;
	public var hintStyle (get, set):CairoHintStyle;
	public var subpixelOrder (get, set):CairoSubpixelOrder;
	
	
	public function new () {
		
		#if lime_cairo
		this = lime_cairo_font_options_create.call ();
		#else
		this = cast 0;
		#end
		
	}
	
	
	public function destroy ():Void {
		
		#if lime_cairo
		lime_cairo_font_options_destroy.call (this);
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private function get_antialias ():CairoAntialias {
		
		#if lime_cairo
		return lime_cairo_font_options_get_antialias.call (this);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_antialias (value:CairoAntialias):CairoAntialias {
		
		#if lime_cairo
		lime_cairo_font_options_set_antialias.call (this, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_hintMetrics ():CairoHintMetrics {
		
		#if lime_cairo
		return lime_cairo_font_options_get_hint_metrics.call (this);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_hintMetrics (value:CairoHintMetrics):CairoHintMetrics {
		
		#if lime_cairo
		lime_cairo_font_options_set_hint_metrics.call (this, value);
		#end
		
		return value;
		
	}
	
	
	
	@:noCompletion private function get_hintStyle ():CairoHintStyle {
		
		#if lime_cairo
		return lime_cairo_font_options_get_hint_style.call (this);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_hintStyle (value:CairoHintStyle):CairoHintStyle {
		
		#if lime_cairo
		lime_cairo_font_options_set_hint_style.call (this, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_subpixelOrder ():CairoSubpixelOrder {
		
		#if lime_cairo
		return lime_cairo_font_options_get_subpixel_order.call (this);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_subpixelOrder (value:CairoSubpixelOrder):CairoSubpixelOrder {
		
		#if lime_cairo
		lime_cairo_font_options_set_subpixel_order.call (this, value);
		#end
		
		return value;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_cairo_font_options_create = System.loadPrime ("lime", "lime_cairo_font_options_create", "v");
	private static var lime_cairo_font_options_destroy = System.loadPrime ("lime", "lime_cairo_font_options_destroy", "dv");
	private static var lime_cairo_font_options_get_antialias = System.loadPrime ("lime", "lime_cairo_font_options_get_antialias", "di");
	private static var lime_cairo_font_options_get_hint_metrics = System.loadPrime ("lime", "lime_cairo_font_options_get_hint_metrics", "di");
	private static var lime_cairo_font_options_get_hint_style = System.loadPrime ("lime", "lime_cairo_font_options_get_hint_style", "di");
	private static var lime_cairo_font_options_get_subpixel_order = System.loadPrime ("lime", "lime_cairo_font_options_get_subpixel_order", "di");
	private static var lime_cairo_font_options_set_antialias = System.loadPrime ("lime", "lime_cairo_font_options_set_antialias", "div");
	private static var lime_cairo_font_options_set_hint_metrics = System.loadPrime ("lime", "lime_cairo_font_options_set_hint_metrics", "div");
	private static var lime_cairo_font_options_set_hint_style = System.loadPrime ("lime", "lime_cairo_font_options_set_hint_style", "div");
	private static var lime_cairo_font_options_set_subpixel_order = System.loadPrime ("lime", "lime_cairo_font_options_set_subpixel_order", "div");
	#end
	
	
}