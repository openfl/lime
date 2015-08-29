package lime._backend.native;


import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoFormat;
import lime.graphics.cairo.CairoImageSurface;
import lime.graphics.cairo.CairoSurface;
import lime.graphics.CairoRenderContext;
import lime.graphics.ConsoleRenderContext;
import lime.graphics.GLRenderContext;
import lime.graphics.Renderer;
import lime.system.System;

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
		
		handle = lime_renderer_create.call (parent.window.backend.handle);
		
		#if lime_console
		
		useHardware = true;
		parent.context = CONSOLE (new ConsoleRenderContext ());
		
		#else
		
		var type = lime_renderer_get_type.call (handle);
		
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
		
	}
	
	
	private function dispatch ():Void {
		
		
		
	}
	
	
	public function flip ():Void {
		
		if (!useHardware) {
			
			#if lime_cairo
			if (cairo != null) {
				
				primarySurface.flush ();
				
			}
			#end
			lime_renderer_unlock.call (handle);
			
		}
		
		lime_renderer_flip.call (handle);
		
	}
	
	
	public function render ():Void {
		
		lime_renderer_make_current.call (handle);
		
		if (!useHardware) {
			
			#if lime_cairo
			var lock = lime_renderer_lock.call (handle);
			
			if (cacheLock == null || cacheLock.pixels != lock.pixels || cacheLock.width != lock.width || cacheLock.height != lock.height) {
				
				if (primarySurface != null) {
					
					primarySurface.destroy ();
					
				}
				
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
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var lime_renderer_create = System.loadPrime ("lime", "lime_renderer_create", "dd");
	private static var lime_renderer_flip = System.loadPrime ("lime", "lime_renderer_flip", "dv");
	private static var lime_renderer_get_context = System.loadPrime ("lime", "lime_renderer_get_context", "dd");
	private static var lime_renderer_get_type = System.loadPrime ("lime", "lime_renderer_get_type", "ds");
	private static var lime_renderer_lock = System.loadPrime ("lime", "lime_renderer_lock", "do");
	private static var lime_renderer_make_current = System.loadPrime ("lime", "lime_renderer_make_current", "dv");
	private static var lime_renderer_unlock = System.loadPrime ("lime", "lime_renderer_unlock", "dv");
	
	
}


