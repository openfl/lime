package lime.graphics.cairo; #if !macro


import lime.graphics.Image;
import lime.system.System;
import lime.utils.ByteArray;

@:access(haxe.io.Bytes)


abstract CairoSurface(Dynamic) {
	
	
	public var height (get, never):Int;
	public var width (get, never):Int;
	
	
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
		return cast 0;
		#end
		
	}
	
	
	public function destroy ():Void {
		
		#if lime_cairo
		lime_cairo_surface_destroy (this);
		#end
		
	}
	
	
	public function flush ():Void {
		
		#if lime_cairo
		lime_cairo_surface_flush (this);
		#end
		
	}
	
	
	public static function fromImage (image:Image):CairoSurface {
		
		#if lime_cairo
		return createForData (lime_bytes_get_data_pointer (#if nodejs image.data #else image.data.buffer #end), CairoFormat.ARGB32, image.width, image.height, image.buffer.stride);
		#else
		return null;
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private function get_height ():Int {
		
		#if lime_cairo
		return lime_cairo_image_surface_get_height (this);
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
	private static var lime_cairo_image_surface_get_height = System.load ("lime", "lime_cairo_image_surface_get_height", 1);
	private static var lime_cairo_image_surface_get_width = System.load ("lime", "lime_cairo_image_surface_get_width", 1);
	private static var lime_cairo_surface_destroy = System.load ("lime", "lime_cairo_surface_destroy", 1);
	private static var lime_cairo_surface_flush = System.load ("lime", "lime_cairo_surface_flush", 1);
	#end
	
	
}


#end