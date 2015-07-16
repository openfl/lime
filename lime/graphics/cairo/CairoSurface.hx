package lime.graphics.cairo; #if !macro


import lime.graphics.Image;
import lime.system.System;
import lime.utils.ByteArray;

@:access(haxe.io.Bytes)


abstract CairoSurface(Dynamic) {
	
	
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
	
	
	
	
	// Native Methods
	
	
	
	
	#if lime_cairo
	private static var lime_cairo_surface_destroy = System.load ("lime", "lime_cairo_surface_destroy", 1);
	private static var lime_cairo_surface_flush = System.load ("lime", "lime_cairo_surface_flush", 1);
	#end
	
	
}


#end