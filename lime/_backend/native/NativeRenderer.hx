package lime._backend.native;


import lime.app.Application;
import lime.graphics.opengl.GL;
import lime.graphics.ConsoleRenderContext;
import lime.graphics.GLRenderContext;
import lime.graphics.RenderContext;
import lime.graphics.Renderer;
import lime.system.System;
import lime.ui.Window;

@:access(lime.graphics.opengl.GL)
@:access(lime.app.Application)
@:access(lime.graphics.Renderer)


class NativeRenderer {
	
	
	private static var eventInfo = new RenderEventInfo (RENDER);
	private static var registered:Bool;
	
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
		
		if (!registered) {
			
			registered = true;
			lime_render_event_manager_register (dispatch, eventInfo);
			
		}
		
		
	}
	
	
	private function dispatch ():Void {
		
		switch (eventInfo.type) {
			
			case RENDER:
				
				if (!Application.__initialized) {
					
					Application.__initialized = true;
					Application.__instance.init (parent.context);
					
				}
				
				Application.__instance.render (parent.context);
				Renderer.onRender.dispatch (parent.context);
				
				flip ();
				
			case RENDER_CONTEXT_LOST:
				
				parent.context = null;
				
				Renderer.onRenderContextLost.dispatch ();
			
			case RENDER_CONTEXT_RESTORED:
				
				#if lime_console
					parent.context = CONSOLE (new ConsoleRenderContext ());
				#else
					parent.context = OPENGL (new GLRenderContext ());
				#end
				
				Renderer.onRenderContextRestored.dispatch (parent.context);
			
		}
		
	}
	
	
	public function flip ():Void {
		
		lime_renderer_flip (handle);
		
	}
	
	
	public static function render ():Void {
		
		eventInfo.type = RENDER;
		
		for (window in Application.__instance.windows) {
			
			if (window.currentRenderer != null) {
				
				window.currentRenderer.backend.dispatch ();
				
			}
			
		}
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var lime_render_event_manager_register = System.load ("lime", "lime_render_event_manager_register", 2);
	private static var lime_renderer_create = System.load ("lime", "lime_renderer_create", 1);
	private static var lime_renderer_flip = System.load ("lime", "lime_renderer_flip", 1);
	
	
}


private class RenderEventInfo {
	
	
	public var context:RenderContext;
	public var type:RenderEventType;
	
	
	public function new (type:RenderEventType = null, context:RenderContext = null) {
		
		this.type = type;
		this.context = context;
		
	}
	
	
	public function clone ():RenderEventInfo {
		
		return new RenderEventInfo (type, context);
		
	}
	
	
}


@:enum private abstract RenderEventType(Int) {
	
	var RENDER = 0;
	var RENDER_CONTEXT_LOST = 1;
	var RENDER_CONTEXT_RESTORED = 2;
	
}
