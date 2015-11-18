package lime._backend.native;


import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoFormat;
import lime.graphics.cairo.CairoImageSurface;
import lime.graphics.cairo.CairoSurface;
import lime.graphics.CairoRenderContext;
import lime.graphics.ConsoleRenderContext;
import lime.graphics.GLRenderContext;
import lime.graphics.Renderer;

#if !macro
@:build(lime.system.CFFI.build())
#end

@:access(lime.graphics.cairo.Cairo)
@:access(lime.ui.Window)


class NativeRenderer {
	
	
	public var handle:Dynamic;
	
	private var parent:Renderer;
	private var useHardware:Bool;
	
	#if lime_cairo
	private var cacheLock:Dynamic;
	private var cairo:Cairo;
	private var primarySurface:CairoSurface;
	#end
	
	
	public function new (parent:Renderer) {
		
		this.parent = parent;
		
	}
	
	
	public function create ():Void {
		
		#if !macro
		handle = lime_renderer_create (parent.window.backend.handle);
		
		parent.window.__scale = lime_renderer_get_scale (handle);
		
		#if lime_console
		
		useHardware = true;
		parent.context = CONSOLE (new ConsoleRenderContext ());
		
		#else
		
		var type:String = lime_renderer_get_type (handle);
		
		switch (type) {
			
			case "opengl":
				
				useHardware = true;
				parent.context = OPENGL (new GLRenderContext ());
				parent.type = OPENGL;
			
			default:
				
				useHardware = false;
				
				#if lime_cairo
				render ();
				parent.context = CAIRO (cairo);
				#end
				parent.type = CAIRO;
			
		}
		
		#end
		#end
		
	}
	
	
	private function dispatch ():Void {
		
		
		
	}
	
	
	public function flip ():Void {
		
		#if !macro
		if (!useHardware) {
			
			#if lime_cairo
			if (cairo != null) {
				
				primarySurface.flush ();
				
			}
			#end
			lime_renderer_unlock (handle);
			
		}
		
		lime_renderer_flip (handle);
		#end
		
	}
	
	
	public function render ():Void {
		
		#if !macro
		lime_renderer_make_current (handle);
		
		if (!useHardware) {
			
			#if lime_cairo
			var lock:Dynamic = lime_renderer_lock (handle);
			
			if (cacheLock == null || cacheLock.pixels != lock.pixels || cacheLock.width != lock.width || cacheLock.height != lock.height) {
				
				primarySurface = CairoImageSurface.create (lock.pixels, CairoFormat.ARGB32, lock.width, lock.height, lock.pitch);
				
				if (cairo != null) {
					
					cairo.recreate (primarySurface);
					
				} else {
					
					cairo = new Cairo (primarySurface);
					
				}
				
			}
			
			cacheLock = lock;
			#else
			parent.context = NONE;
			#end
			
		}
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if !macro
	@:cffi private static function lime_renderer_create (window:Dynamic):Dynamic;
	@:cffi private static function lime_renderer_flip (handle:Dynamic):Void;
	@:cffi private static function lime_renderer_get_context (handle:Dynamic):Float;
	@:cffi private static function lime_renderer_get_scale (handle:Dynamic):Float;
	@:cffi private static function lime_renderer_get_type (handle:Dynamic):Dynamic;
	@:cffi private static function lime_renderer_lock (handle:Dynamic):Dynamic;
	@:cffi private static function lime_renderer_make_current (handle:Dynamic):Void;
	@:cffi private static function lime_renderer_unlock (handle:Dynamic):Void;
	#end
	
	
}


