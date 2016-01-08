package lime._backend.html5;


import haxe.macro.Compiler;
import js.html.webgl.RenderingContext;
import js.html.CanvasElement;
import js.Browser;
import lime.app.Application;
import lime.graphics.Image;
import lime.graphics.opengl.GL;
import lime.graphics.GLRenderContext;
import lime.graphics.Renderer;
import lime.math.Rectangle;

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
			
			var webgl:RenderingContext = null;
			
			if (#if (canvas || munit) false #elseif webgl true #else !Reflect.hasField (parent.window.config, "hardware") || parent.window.config.hardware #end) {
				
				var options = {
					
					alpha: false,
					antialias: Reflect.hasField (parent.window.config, "antialiasing") ? parent.window.config.antialiasing > 0 : false,
					depth: Reflect.hasField (parent.window.config, "depthBuffer") ? parent.window.config.depthBuffer : true,
					premultipliedAlpha: false,
					stencil: Reflect.hasField (parent.window.config, "stencilBuffer") ? parent.window.config.stencilBuffer : false,
					preserveDrawingBuffer: false
					
				};
				
				webgl = cast parent.window.backend.canvas.getContextWebGL (options);
				
			}
			
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
	
	
	public function readPixels (rect:Rectangle):Image {
		
		// TODO: Handle DIV, improve 3D canvas support
		
		if (parent.window.backend.canvas != null) {
			
			if (rect == null) {
				
				rect = new Rectangle (0, 0, parent.window.backend.canvas.width, parent.window.backend.canvas.height);
				
			} else {
				
				rect.__contract (0, 0, parent.window.backend.canvas.width, parent.window.backend.canvas.height);
				
			}
			
			if (rect.width > 0 && rect.height > 0) {
				
				var canvas:CanvasElement = cast Browser.document.createElement ("canvas");
				canvas.width = Std.int (rect.width);
				canvas.height = Std.int (rect.height);
				
				var context = canvas.getContext ("2d");
				context.drawImage (parent.window.backend.canvas, -rect.x, -rect.y);
				
				return Image.fromCanvas (canvas);
				
			}
			
		}
		
		return null;
		
	}
	
	
	public function render ():Void {
		
		
		
	}
	
	
}