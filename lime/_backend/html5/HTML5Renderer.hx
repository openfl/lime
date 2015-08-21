package lime._backend.html5;


import js.html.webgl.RenderingContext;
import lime.app.Application;
import lime.graphics.opengl.GL;
import lime.graphics.GLRenderContext;
import lime.graphics.Renderer;

@:access(lime.app.Application)
@:access(lime.graphics.opengl.GL)
@:access(lime.graphics.Renderer)
@:access(lime.ui.Window)


class HTML5Renderer {
	
	
	private var parent:Renderer;
	
	
	public function new (parent:Renderer) {
		
		this.parent = parent;
		
	}
	
	
	public function create ():Void {
		
		createContext ();
		
		switch (parent.context) {
			
			case OPENGL (_):
				
				parent.window.backend.canvas.addEventListener ("webglcontextlost", handleEvent, false);
				parent.window.backend.canvas.addEventListener ("webglcontextrestored", handleEvent, false);
			
			default:
			
		}
		
	}
	
	
	private function createContext ():Void {
		
		if (parent.window.backend.div != null) {
			
			parent.context = DOM (cast parent.window.backend.div);
			parent.type = DOM;
			
		} else if (parent.window.backend.canvas != null) {
			
			#if (canvas || munit)
			
			var webgl = null;
			
			#else
			
			var options = {
				alpha: true,
				antialias: Reflect.hasField (parent.window.config, "antialiasing") ? parent.window.config.antialiasing > 0 : false,
				depth: Reflect.hasField (parent.window.config, "depthBuffer") ? parent.window.config.depthBuffer : true,
				premultipliedAlpha: true,
				stencil: Reflect.hasField (parent.window.config, "stencilBuffer") ? parent.window.config.stencilBuffer : true,
				preserveDrawingBuffer: false
			};
			
			var webgl:RenderingContext = cast parent.window.backend.canvas.getContextWebGL (options);
			
			#end
			
			if (webgl == null) {
				
				parent.context = CANVAS (cast parent.window.backend.canvas.getContext ("2d"));
				parent.type = CANVAS;
				
			} else {
				
				#if debug
				webgl = untyped WebGLDebugUtils.makeDebugContext (webgl);
				#end
				
				GL.context = webgl;
				#if (js && html5)
				parent.context = OPENGL (cast GL.context);
				#else
				parent.context = OPENGL (new GLRenderContext ());
				#end
				parent.type = OPENGL;
				
			}
			
		}
		
	}
	
	
	public function flip ():Void {
		
		
		
	}
	
	
	private function handleEvent (event:js.html.Event):Void {
		
		switch (event.type) {
			
			case "webglcontextlost":
				
				event.preventDefault ();
				parent.context = null;
				
				parent.onContextLost.dispatch ();
				
			case "webglcontextrestored":
				
				createContext ();
				
				parent.onContextRestored.dispatch (parent.context);
			
			default:
			
		}
		
	}
	
	
	public function render ():Void {
		
		
		
	}
	
	
}