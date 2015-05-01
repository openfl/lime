package lime.graphics.cairo;


import lime.math.Matrix3;
import lime.system.System;


abstract CairoPattern(Dynamic) {
	
	
	public var extend (get, set):CairoExtend;
	public var filter (get, set):CairoFilter;
	public var matrix (get, set):Matrix3;
	
	
	public function new (handle) {
		
		this = handle;
		
	}
	
	
	public static function createForSurface (surface:CairoSurface):CairoPattern {
		
		#if lime_cairo
		return lime_cairo_pattern_create_for_surface (surface);
		#else
		return cast 0;
		#end
		
	}
	
	
	public function destroy ():Void {
		
		#if lime_cairo
		lime_cairo_pattern_destroy (this);
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	public function get_extend ():CairoExtend {
		
		#if lime_cairo
		return lime_cairo_pattern_get_extend (this);
		#else
		return 0;
		#end
		
	}
	
	
	public function set_extend (value:CairoExtend):CairoExtend {
		
		#if lime_cairo
		lime_cairo_pattern_set_extend (this, value);
		#end
		
		return value;
		
	}
	
	
	public function get_filter ():CairoFilter {
		
		#if lime_cairo
		return lime_cairo_pattern_get_filter (this);
		#else
		return 0;
		#end
		
	}
	
	
	public function set_filter (value:CairoFilter):CairoFilter {
		
		#if lime_cairo
		lime_cairo_pattern_set_filter (this, value);
		#end
		
		return value;
		
	}
	
	
	public function get_matrix ():Matrix3 {
		
		#if lime_cairo
		var m = lime_cairo_pattern_get_matrix (this);
		return new Matrix3 (m.a, m.b, m.c, m.d, m.tx, m.ty);
		#else
		return null;
		#end
		
	}
	
	
	public function set_matrix (value:Matrix3):Matrix3 {
		
		#if lime_cairo
		lime_cairo_pattern_set_matrix (this, value);
		#end
		
		return value;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if lime_cairo
	private static var lime_cairo_pattern_create_for_surface = System.load ("lime", "lime_cairo_pattern_create_for_surface", 1);
	private static var lime_cairo_pattern_destroy = System.load ("lime", "lime_cairo_pattern_destroy", 1);
	private static var lime_cairo_pattern_get_extend = System.load ("lime", "lime_cairo_pattern_get_extend", 1);
	private static var lime_cairo_pattern_get_filter = System.load ("lime", "lime_cairo_pattern_get_filter", 1);
	private static var lime_cairo_pattern_get_matrix = System.load ("lime", "lime_cairo_pattern_get_matrix", 1);
	private static var lime_cairo_pattern_set_extend = System.load ("lime", "lime_cairo_pattern_set_extend", 2);
	private static var lime_cairo_pattern_set_filter = System.load ("lime", "lime_cairo_pattern_set_filter", 2);
	private static var lime_cairo_pattern_set_matrix = System.load ("lime", "lime_cairo_pattern_set_matrix", 2);
	#end
	
	
}