package lime._backend.native;


import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoFormat;
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
		
		handle = lime_renderer_create (parent.window.backend.handle);
		
		useHardware = parent.window.config.hardware;
		
		#if lime_console
		parent.context = CONSOLE (new ConsoleRenderContext ());
		#else
		if (useHardware) {
			
			parent.context = OPENGL (new GLRenderContext ());
			
		} else {
			
			render ();
			
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
			lime_renderer_unlock (handle);
			
		}
		
		lime_renderer_flip (handle);
		
	}
	
	
	public function render ():Void {
		
		if (!useHardware) {
			
			#if lime_cairo
			var lock = lime_renderer_lock (handle);
			
			if (cacheLock == null || cacheLock.pixels != lock.pixels || cacheLock.width != lock.width || cacheLock.height != lock.height) {
				
				if (cairo != null) {
					
					cairo.destroy ();
					primarySurface.destroy ();
					
				}
				
				primarySurface = CairoSurface.createForData (lock.pixels, CairoFormat.ARGB32, lock.width, lock.height, lock.pitch);
				cairo = new Cairo (primarySurface);
				parent.context = CAIRO (cairo);
				
			}
			
			cacheLock = lock;
			#else
			parent.context = NONE;
			#end
			
		}
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var lime_renderer_create = System.load ("lime", "lime_renderer_create", 1);
	private static var lime_renderer_flip = System.load ("lime", "lime_renderer_flip", 1);
	private static var lime_renderer_lock = System.load ("lime", "lime_renderer_lock", 1);
	private static var lime_renderer_unlock = System.load ("lime", "lime_renderer_unlock", 1);
	
	
}


