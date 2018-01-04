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

@:access(lime._backend.html5.HTML5GLRenderContext)
@:access(lime._backend.html5.HTML5Window)
@:access(lime.app.Application)
@:access(lime.graphics.opengl.GL)
@:access(lime.graphics.GLRenderContext)
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
			
			var renderType = parent.window.backend.renderType;
			var forceCanvas = #if (canvas || munit) true #else (renderType == "canvas") #end;
			var forceWebGL = #if webgl true #else (renderType == "opengl" || renderType == "webgl" || renderType == "webgl1" || renderType == "webgl2") #end;
			var allowWebGL2 = #if webgl1 false #else (renderType != "webgl1") #end;
			
			if (forceWebGL || (!forceCanvas && (!Reflect.hasField (parent.window.config, "hardware") || parent.window.config.hardware))) {
				
				var transparentBackground = Reflect.hasField (parent.window.config, "background") && parent.window.config.background == null;
				var colorDepth = Reflect.hasField (parent.window.config, "colorDepth") ? parent.window.config.colorDepth : 16;
				
				var options = {
					
					alpha: (transparentBackground || colorDepth > 16) ? true : false,
					antialias: Reflect.hasField (parent.window.config, "antialiasing") ? parent.window.config.antialiasing > 0 : false,
					depth: Reflect.hasField (parent.window.config, "depthBuffer") ? parent.window.config.depthBuffer : true,
					premultipliedAlpha: true,
					stencil: Reflect.hasField (parent.window.config, "stencilBuffer") ? parent.window.config.stencilBuffer : false,
					preserveDrawingBuffer: false
					
				};
				
				var glContextType = [ "webgl", "experimental-webgl" ];
				
				if (allowWebGL2) {
					
					glContextType.unshift ("webgl2");
					
				}
				
				for (name in glContextType) {
					
					webgl = cast parent.window.backend.canvas.getContext (name, options);
					if (webgl != null) break;
					
				}
				
			}
			
			if (webgl == null) {
				
				parent.context = CANVAS (cast parent.window.backend.canvas.getContext ("2d"));
				parent.type = CANVAS;
				
			} else {
				
				#if webgl_debug
				webgl = untyped WebGLDebugUtils.makeDebugContext (webgl);
				#end
				
				#if ((js && html5) && !display)
				GL.context = new GLRenderContext (cast webgl);
				parent.context = OPENGL (GL.context);
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
				
				#if !display
				if (GL.context != null) {
					
					GL.context.__contextLost = true;
					
				}
				#end
				
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