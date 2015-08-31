package lime.graphics.cairo; #if !macro


import lime.system.CFFI;


abstract CairoSurface(Dynamic) from Float to Float {
	
	
	public function destroy ():Void {
		
		#if lime_cairo
		lime_cairo_surface_destroy.call (this);
		#end
		
	}
	
	
	public function flush ():Void {
		
		#if lime_cairo
		lime_cairo_surface_flush.call (this);
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if lime_cairo
	private static var lime_cairo_surface_destroy = new CFFI<Float->Void> ("lime", "lime_cairo_surface_destroy");
	private static var lime_cairo_surface_flush = new CFFI<Float->Void> ("lime", "lime_cairo_surface_flush");
	#end
	
	
}


#end