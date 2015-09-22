package lime.graphics.cairo;


#if !macro
@:build(lime.system.CFFI.build())
#end


abstract CairoSurface(Dynamic) {
	
	
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
	
	
	public function reference ():Void {
		
		#if (lime_cairo && !macro)
		lime_cairo_surface_reference (this);
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (lime_cairo && !macro)
	@:cffi private static function lime_cairo_surface_destroy (surface:Dynamic):Void;
	@:cffi private static function lime_cairo_surface_flush (surface:Dynamic):Void;
	@:cffi private static function lime_cairo_surface_reference (surface:Dynamic):Void;
	#end
	
	
}