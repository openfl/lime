package lime.graphics.cairo;


import lime.system.System;


@:forward abstract CairoImageSurface(CairoSurface) from CairoSurface to CairoSurface {
	
	
	public var data (get, never):Dynamic;
	public var format (get, never):CairoFormat;
	public var height (get, never):Int;
	public var stride (get, never):Int;
	public var width (get, never):Int;
	
	
	public function new (format:CairoFormat, width:Int, height:Int):CairoSurface {
		
		#if lime_cairo
		this = lime_cairo_image_surface_create (format, width, height);
		#else
		this = cast 0;
		#end
		
	}
	
	
	public static function create (data:Dynamic, format:CairoFormat, width:Int, height:Int, stride:Int):CairoSurface {
		
		#if lime_cairo
		return lime_cairo_image_surface_create_for_data (data, format, width, height, stride);
		#else
		return cast 0;
		#end
		
	}
	
	
	public static function fromImage (image:Image):CairoSurface {
		
		#if lime_cairo
		return create (lime_bytes_get_data_pointer (#if nodejs image.data #else image.data.buffer #end), CairoFormat.ARGB32, image.width, image.height, image.buffer.stride);
		#else
		return null;
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private function get_data ():Dynamic {
		
		#if lime_cairo
		return lime_cairo_image_surface_get_data (this);
		#else
		return null;
		#end
		
	}
	
	
	@:noCompletion private function get_format ():CairoFormat {
		
		#if lime_cairo
		return lime_cairo_image_surface_get_format (this);
		#else
		return 0;
		#end
		
	}
	
	
	@:noCompletion private function get_height ():Int {
		
		#if lime_cairo
		return lime_cairo_image_surface_get_height (this);
		#else
		return 0;
		#end
		
	}
	
	
	@:noCompletion private function get_stride ():Int {
		
		#if lime_cairo
		return lime_cairo_image_surface_get_stride (this);
		#else
		return 0;
		#end
		
	}
	
	
	@:noCompletion private function get_width ():Int {
		
		#if lime_cairo
		return lime_cairo_image_surface_get_width (this);
		#else
		return 0;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if lime_cairo
	private static var lime_bytes_get_data_pointer = System.load ("lime", "lime_bytes_get_data_pointer", 1);
	private static var lime_cairo_image_surface_create = System.load ("lime", "lime_cairo_image_surface_create", 3);
	private static var lime_cairo_image_surface_create_for_data = System.load ("lime", "lime_cairo_image_surface_create_for_data", 5);
	private static var lime_cairo_image_surface_get_data = System.load ("lime", "lime_cairo_image_surface_get_data", 1);
	private static var lime_cairo_image_surface_get_format = System.load ("lime", "lime_cairo_image_surface_get_format", 1);
	private static var lime_cairo_image_surface_get_height = System.load ("lime", "lime_cairo_image_surface_get_height", 1);
	private static var lime_cairo_image_surface_get_stride = System.load ("lime", "lime_cairo_image_surface_get_stride", 1);
	private static var lime_cairo_image_surface_get_width = System.load ("lime", "lime_cairo_image_surface_get_width", 1);
	#end
	
	
}