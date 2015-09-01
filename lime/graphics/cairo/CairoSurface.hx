package lime.graphics.cairo;


#if !macro
@:build(lime.system.CFFI.build())
#end


abstract CairoSurface(Dynamic) from Float to Float {
	
	
	public function destroy ():Void {
		
		#if (lime_cairo && !macro)
		lime_cairo_surface_destroy (this);
		#end
		
	}
	
	
	public function flush ():Void {
		
		#if (lime_cairo && !macro)
		lime_cairo_surface_flush (this);
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (lime_cairo && !macro)
	@:cffi private static function lime_cairo_surface_destroy (surface:Float):Void;
	@:cffi private static function lime_cairo_surface_flush (surface:Float):Void;
	#end
	
	
}