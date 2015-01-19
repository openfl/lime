package lime._backend.html5;


import js.html.webgl.RenderingContext;
import lime.app.Application;
import lime.graphics.opengl.GL;
import lime.graphics.GLRenderContext;
import lime.graphics.Renderer;

@:access(lime.app.Application)
@:access(lime.graphics.opengl.GL)
@:access(lime.graphics.Renderer)


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
			
			parent.context = DOM (parent.window.backend.div);
			
		} else if (parent.window.backend.canvas != null) {
			
			#if canvas
			
			var webgl = null;
			
			#else
			
			var options = {
				alpha: true,
				antialias: parent.window.config.antialiasing > 0,
				depth: parent.window.config.depthBuffer,
				premultipliedAlpha: true,
				stencil: parent.window.config.stencilBuffer,
				preserveDrawingBuffer: false
			};
			
			var webgl:RenderingContext = cast parent.window.backend.canvas.getContextWebGL (options);
			
			#end
			
			if (webgl == null) {
				
				parent.context = CANVAS (cast parent.window.backend.canvas.getContext ("2d"));
				
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
				
				Renderer.onRenderContextLost.dispatch ();
				
			case "webglcontextrestored":
				
				createContext ();
				
				Renderer.onRenderContextRestored.dispatch (parent.context);
			
			default:
			
		}
		
	}
	
	
	public static function render ():Void {
		
		for (window in Application.__instance.windows) {
			
			if (window.currentRenderer != null) {
				
				window.currentRenderer.backend.renderEvent ();
				
			}
			
		}
		
		#if stats
		Application.__instance.windows[0].stats.end ();
		#end
		
	}
	
	
	private function renderEvent ():Void {
		
		if (!Application.__initialized) {
			
			Application.__initialized = true;
			Application.__instance.init (parent.context);
			
		}
		
		Application.__instance.render (parent.context);
		Renderer.onRender.dispatch (parent.context);
		
		flip ();
		
	}
	
	
}