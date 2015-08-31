package lime.graphics.cairo;


import lime.math.Matrix3;
import lime.system.CFFI;


abstract CairoPattern(Dynamic) from Float to Float {
	
	
	public var colorStopCount (get, never):Int;
	public var extend (get, set):CairoExtend;
	public var filter (get, set):CairoFilter;
	public var matrix (get, set):Matrix3;
	
	
	public function new (handle) {
		
		this = handle;
		
	}
	
	
	public function addColorStopRGB (offset:Float, r:Float, g:Float, b:Float):Void {
		
		#if lime_cairo
		lime_cairo_pattern_add_color_stop_rgb.call (this, offset, r, g, b);
		#end
		
	}
	
	
	public function addColorStopRGBA (offset:Float, r:Float, g:Float, b:Float, a:Float):Void {
		
		#if lime_cairo
		lime_cairo_pattern_add_color_stop_rgba.call (this, offset, r, g, b, a);
		#end
		
	}
	
	
	public static function createForSurface (surface:CairoSurface):CairoPattern {
		
		#if lime_cairo
		return lime_cairo_pattern_create_for_surface.call (surface);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function createLinear (x0:Float, y0:Float, x1:Float, y1:Float):CairoPattern {
		
		#if lime_cairo
		return lime_cairo_pattern_create_linear.call (x0, y0, x1, y1);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function createRadial (cx0:Float, cy0:Float, radius0:Float, cx1:Float, cy1:Float, radius1:Float):CairoPattern {
		
		#if lime_cairo
		return lime_cairo_pattern_create_radial.call (cx0, cy0, radius0, cx1, cy1, radius1);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function createRGB (r:Float, g:Float, b:Float):CairoPattern {
		
		#if lime_cairo
		return lime_cairo_pattern_create_rgb.call (r, g, b);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function createRGBA (r:Float, g:Float, b:Float, a:Float):CairoPattern {
		
		#if lime_cairo
		return lime_cairo_pattern_create_rgba.call (r, g, b, a);
		#else
		return cast 0;
		#end
		
	}
	
	
	public function destroy ():Void {
		
		#if lime_cairo
		lime_cairo_pattern_destroy.call (this);
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private function get_colorStopCount ():Int {
		
		#if lime_cairo
		return lime_cairo_pattern_get_color_stop_count.call (this);
		#else
		return 0;
		#end
		
	}
	
	
	@:noCompletion private function get_extend ():CairoExtend {
		
		#if lime_cairo
		return lime_cairo_pattern_get_extend.call (this);
		#else
		return 0;
		#end
		
	}
	
	
	@:noCompletion private function set_extend (value:CairoExtend):CairoExtend {
		
		#if lime_cairo
		lime_cairo_pattern_set_extend.call (this, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_filter ():CairoFilter {
		
		#if lime_cairo
		return lime_cairo_pattern_get_filter.call (this);
		#else
		return 0;
		#end
		
	}
	
	
	@:noCompletion private function set_filter (value:CairoFilter):CairoFilter {
		
		#if lime_cairo
		lime_cairo_pattern_set_filter.call (this, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_matrix ():Matrix3 {
		
		#if lime_cairo
		var m:Dynamic = lime_cairo_pattern_get_matrix.call (this);
		return new Matrix3 (m.a, m.b, m.c, m.d, m.tx, m.ty);
		#else
		return null;
		#end
		
	}
	
	
	@:noCompletion private function set_matrix (value:Matrix3):Matrix3 {
		
		#if lime_cairo
		lime_cairo_pattern_set_matrix.call (this, value);
		#end
		
		return value;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if lime_cairo
	private static var lime_cairo_pattern_add_color_stop_rgb = new CFFI<Float->Float->Float->Float->Float->Void> ("lime", "lime_cairo_pattern_add_color_stop_rgb");
	private static var lime_cairo_pattern_add_color_stop_rgba = new CFFI<Float->Float->Float->Float->Float->Float->Void> ("lime", "lime_cairo_pattern_add_color_stop_rgba");
	private static var lime_cairo_pattern_create_for_surface = new CFFI<Float->Float> ("lime", "lime_cairo_pattern_create_for_surface");
	private static var lime_cairo_pattern_create_linear = new CFFI<Float->Float->Float->Float->Float> ("lime", "lime_cairo_pattern_create_linear");
	private static var lime_cairo_pattern_create_radial = new CFFI<Float->Float->Float->Float->Float->Float->Float> ("lime", "lime_cairo_pattern_create_radial");
	private static var lime_cairo_pattern_create_rgb = new CFFI<Float->Float->Float->Float> ("lime", "lime_cairo_pattern_create_rgb");
	private static var lime_cairo_pattern_create_rgba = new CFFI<Float->Float->Float->Float->Float> ("lime", "lime_cairo_pattern_create_rgba");
	private static var lime_cairo_pattern_destroy = new CFFI<Float->Void> ("lime", "lime_cairo_pattern_destroy");
	private static var lime_cairo_pattern_get_color_stop_count = new CFFI<Float->Int> ("lime", "lime_cairo_pattern_get_color_stop_count");
	private static var lime_cairo_pattern_get_extend = new CFFI<Float->Int> ("lime", "lime_cairo_pattern_get_extend");
	private static var lime_cairo_pattern_get_filter = new CFFI<Float->Int> ("lime", "lime_cairo_pattern_get_filter");
	private static var lime_cairo_pattern_get_matrix = new CFFI<Float->Dynamic> ("lime", "lime_cairo_pattern_get_matrix");
	private static var lime_cairo_pattern_set_extend = new CFFI<Float->Int->Void> ("lime", "lime_cairo_pattern_set_extend");
	private static var lime_cairo_pattern_set_filter = new CFFI<Float->Int->Void> ("lime", "lime_cairo_pattern_set_filter");
	private static var lime_cairo_pattern_set_matrix = new CFFI<Float->Dynamic->Void> ("lime", "lime_cairo_pattern_set_matrix");
	#end
	
	
}