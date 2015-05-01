package lime.graphics.cairo;


import lime.system.System;


class Cairo {
	
	
	public static var version (get, null):Int;
	public static var versionString (get, null):String;
	
	
	public static function imageSurfaceCreate (format:CairoFormat, width:Int, height:Int):CairoSurface {
		
		#if lime_cairo
		return lime_cairo_image_surface_create (format, width, height);
		#else
		return null;
		#end
		
	}
	
	
	// Get & Set Methods
	
	
	
	
	private static function get_version ():Int {
		
		#if lime_cairo
		return lime_cairo_version ();
		#else
		return 0;
		#end
		
	}
	
	
	private static function get_versionString ():String {
		
		#if lime_cairo
		return lime_cairo_version_string ();
		#else
		return "";
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if lime_cairo
	private static var lime_cairo_image_surface_create = System.load ("lime", "lime_cairo_image_surface_create", 3);
	private static var lime_cairo_version = System.load ("lime", "lime_cairo_version", 0);
	private static var lime_cairo_version_string = System.load ("lime", "lime_cairo_version_string", 0);
	#end
	
	
}