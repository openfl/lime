package lime.graphics;


import lime.app.Application;
import lime.app.Event;
import lime.graphics.opengl.GL;
import lime.graphics.GLRenderContext;
import lime.system.System;
import lime.ui.Window;

#if (js && html5)
import js.html.webgl.RenderingContext;
#elseif flash
import flash.Lib;
#elseif java
import org.lwjgl.opengl.GLContext;
import org.lwjgl.system.glfw.GLFW;
#end


@:access(lime.graphics.opengl.GL)
@:access(lime.app.Application)
@:allow(lime.app.Application)


class Renderer {
	
	
	public static var onRenderContextLost = new Event<Void->Void> ();
	public static var onRenderContextRestored = new Event<RenderContext->Void> ();
	public static var onRender = new Event<RenderContext->Void> ();
	
	private static var eventInfo = new RenderEventInfo (RENDER);
	private static var registered:Bool;
	
	public var context:RenderContext;
	public var handle:Dynamic;
	
	private var window:Window;
	
	
	public function new (window:Window) {
		
		this.window = window;
		this.window.currentRenderer = this;
		
	}
	
	
	public function create ():Void {
		
		#if (cpp || neko || nodejs)
			
			handle = lime_renderer_create (window.handle);
			
		#elseif java
			
			GLFW.glfwMakeContextCurrent (window.handle);
			GLContext.createFromCurrent ();
			
		#end
		
		createContext ();
		
		#if (js && html5)
			
			switch (context) {
				
				case OPENGL (_):
					
					window.canvas.addEventListener ("webglcontextlost", handleCanvasEvent, false);
					window.canvas.addEventListener ("webglcontextrestored", handleCanvasEvent, false);
				
				default:
				
			}
			
		#end
		
		if (!registered) {
			
			registered = true;
			
			#if (cpp || neko || nodejs)
			lime_render_event_manager_register (dispatch, eventInfo);
			#end
			
		}
		
	}
	
	
	private function createContext ():Void {
		
		#if (js && html5)
			
			if (window.div != null) {
				
				context = DOM (window.div);
				
			} else if (window.canvas != null) {
				
				#if canvas
				
				var webgl = null;
				
				#else
				
				var options = {
					alpha: true,
					antialias: window.config.antialiasing > 0,
					depth: window.config.depthBuffer,
					premultipliedAlpha: true,
					stencil: window.config.stencilBuffer,
					preserveDrawingBuffer: false
				};
				
				var webgl:RenderingContext = cast window.canvas.getContextWebGL(options);
				
				#end
				
				if (webgl == null) {
					
					context = CANVAS (cast window.canvas.getContext ("2d"));
					
				} else {
					
					#if debug
					webgl = untyped WebGLDebugUtils.makeDebugContext (webgl);
					#end
					
					GL.context = webgl;
					#if (js && html5)
					context = OPENGL (cast GL.context);
					#else
					context = OPENGL (new GLRenderContext ());
					#end
					
				}
				
			}
			
		#elseif (cpp || neko || nodejs || java)
			
			context = OPENGL (new GLRenderContext ());
			
		#elseif flash
			
			context = FLASH (Lib.current);
			
		#end
		
	}
	
	
	private function dispatch ():Void {
		
		switch (eventInfo.type) {
			
			case RENDER:
				
				if (!Application.__initialized) {
					
					Application.__initialized = true;
					Application.__instance.init (context);
					
				}
				
				Application.__instance.render (context);
				onRender.dispatch (context);
				
				flip ();
				
			case RENDER_CONTEXT_LOST:
				
				context = null;
				
				onRenderContextLost.dispatch ();
			
			case RENDER_CONTEXT_RESTORED:
				
				createContext ();
				
				onRenderContextRestored.dispatch (context);
			
		}
		
	}
	
	
	public function flip ():Void {
		
		#if (cpp || neko || nodejs)
		lime_renderer_flip (handle);
		#end
		
	}
	
	
	#if (js && html5)
	private function handleCanvasEvent (event:js.html.Event):Void {
		
		switch (event.type) {
			
			case "webglcontextlost":
				
				event.preventDefault ();
				eventInfo.type = RENDER_CONTEXT_LOST;
				dispatch ();
				
			case "webglcontextrestored":
				
				createContext ();
				
				eventInfo.type = RENDER_CONTEXT_RESTORED;
				dispatch ();
			
			default:
			
		}
		
	}
	#end
	
	
	private static function render ():Void {
		
		eventInfo.type = RENDER;
		
		for (window in Application.__instance.windows) {
			
			if (window.currentRenderer != null) {
				
				window.currentRenderer.dispatch ();
				
			}
			
		}
		
		#if (js && stats)
		Application.__instance.windows[0].stats.end ();
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_render_event_manager_register = System.load ("lime", "lime_render_event_manager_register", 2);
	private static var lime_renderer_create = System.load ("lime", "lime_renderer_create", 1);
	private static var lime_renderer_flip = System.load ("lime", "lime_renderer_flip", 1);
	#end
	
	
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