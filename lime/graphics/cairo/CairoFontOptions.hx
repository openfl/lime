package lime.graphics.cairo;


import lime.text.Font;

#if !macro
@:build(lime.system.CFFI.build())
#end


abstract CairoFontOptions(Dynamic) from Float to Float {
	
	
	public var antialias (get, set):CairoAntialias;
	public var hintMetrics (get, set):CairoHintMetrics;
	public var hintStyle (get, set):CairoHintStyle;
	public var subpixelOrder (get, set):CairoSubpixelOrder;
	
	
	public function new () {
		
		#if lime_cairo
		this = lime_cairo_font_options_create ();
		#else
		this = cast 0;
		#end
		
	}
	
	
	public function destroy ():Void {
		
		#if lime_cairo
		lime_cairo_font_options_destroy (this);
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private function get_antialias ():CairoAntialias {
		
		#if lime_cairo
		return lime_cairo_font_options_get_antialias (this);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_antialias (value:CairoAntialias):CairoAntialias {
		
		#if lime_cairo
		lime_cairo_font_options_set_antialias (this, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_hintMetrics ():CairoHintMetrics {
		
		#if lime_cairo
		return lime_cairo_font_options_get_hint_metrics (this);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_hintMetrics (value:CairoHintMetrics):CairoHintMetrics {
		
		#if lime_cairo
		lime_cairo_font_options_set_hint_metrics (this, value);
		#end
		
		return value;
		
	}
	
	
	
	@:noCompletion private function get_hintStyle ():CairoHintStyle {
		
		#if lime_cairo
		return lime_cairo_font_options_get_hint_style (this);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_hintStyle (value:CairoHintStyle):CairoHintStyle {
		
		#if lime_cairo
		lime_cairo_font_options_set_hint_style (this, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_subpixelOrder ():CairoSubpixelOrder {
		
		#if lime_cairo
		return lime_cairo_font_options_get_subpixel_order (this);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_subpixelOrder (value:CairoSubpixelOrder):CairoSubpixelOrder {
		
		#if lime_cairo
		lime_cairo_font_options_set_subpixel_order (this, value);
		#end
		
		return value;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	@:cffi private static function lime_cairo_font_options_create ():Float;
	@:cffi private static function lime_cairo_font_options_destroy (handle:Float):Void;
	@:cffi private static function lime_cairo_font_options_get_antialias (handle:Float):Int;
	@:cffi private static function lime_cairo_font_options_get_hint_metrics (handle:Float):Int;
	@:cffi private static function lime_cairo_font_options_get_hint_style (handle:Float):Int;
	@:cffi private static function lime_cairo_font_options_get_subpixel_order (handle:Float):Int;
	@:cffi private static function lime_cairo_font_options_set_antialias (handle:Float, v:Int):Void;
	@:cffi private static function lime_cairo_font_options_set_hint_metrics (handle:Float, v:Int):Void;
	@:cffi private static function lime_cairo_font_options_set_hint_style (handle:Float, v:Int):Void;
	@:cffi private static function lime_cairo_font_options_set_subpixel_order (handle:Float, v:Int):Void;
	#end
	
	
}