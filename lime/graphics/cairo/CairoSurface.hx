package lime.graphics.cairo;


import lime.system.CFFIPointer;

#if !macro
@:build(lime.system.CFFI.build())
#end


abstract CairoSurface(CFFIPointer) from CFFIPointer to CFFIPointer {
	
	
	public function flush ():Void {
		
		#if (lime_cairo && !macro)
		lime_cairo_surface_flush (this);
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (lime_cairo && !macro)
	@:cffi private static function lime_cairo_surface_flush (surface:CFFIPointer):Void;
	#end
	
	
}