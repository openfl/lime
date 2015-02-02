package lime._backend.native;


import lime.graphics.ConsoleRenderContext;
import lime.graphics.GLRenderContext;
import lime.graphics.Renderer;
import lime.system.System;

@:access(lime.ui.Window)


class NativeRenderer {
	
	
	public var handle:Dynamic;
	
	private var parent:Renderer;
	
	
	public function new (parent:Renderer) {
		
		this.parent = parent;
		
	}
	
	
	public function create ():Void {
		
		handle = lime_renderer_create (parent.window.backend.handle);
		
		#if lime_console
		parent.context = CONSOLE (new ConsoleRenderContext ());
		#else
		parent.context = OPENGL (new GLRenderContext ());
		#end
		
	}
	
	
	private function dispatch ():Void {
		
		
		
	}
	
	
	public function flip ():Void {
		
		lime_renderer_flip (handle);
		
	}
	
	
	public function render ():Void {
		
		
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var lime_renderer_create = System.load ("lime", "lime_renderer_create", 1);
	private static var lime_renderer_flip = System.load ("lime", "lime_renderer_flip", 1);
	
	
}


