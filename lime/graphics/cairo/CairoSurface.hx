package lime.graphics.cairo;


import lime.system.System;


abstract CairoSurface(Dynamic) {
	
	
	public function new (format:CairoFormat, width:Int, height:Int):CairoSurface {
		
		#if lime_cairo
		this = lime_cairo_image_surface_create (format, width, height);
		#else
		this = 0;
		#end
		
	}
	
	
	public static function createForData (data:Dynamic, format:CairoFormat, width:Int, height:Int, stride:Int):CairoSurface {
		
		#if lime_cairo
		return lime_cairo_image_surface_create_for_data (data, format, width, height, stride);
		#else
		return 0;
		#end
		
	}
	
	
	public function destroy ():Void {
		
		#if lime_cairo
		lime_cairo_surface_destroy (this);
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if lime_cairo
	private static var lime_cairo_image_surface_create = System.load ("lime", "lime_cairo_image_surface_create", 3);
	private static var lime_cairo_image_surface_create_for_data = System.load ("lime", "lime_cairo_image_surface_create_for_data", 5);
	private static var lime_cairo_surface_destroy = System.load ("lime", "lime_cairo_surface_destroy", 1);
	#end
	
	
}