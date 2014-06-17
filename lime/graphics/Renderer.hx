package lime.graphics;


import lime.graphics.opengl.GL;
import lime.graphics.GLRenderContext;
import lime.system.System;
import lime.ui.Window;

#if js
import js.html.webgl.RenderingContext;
#elseif flash
import flash.Lib;
#end


@:access(lime.graphics.opengl.GL)
class Renderer {
	
	public inline static var DEPTH_BUFFER    = 0x0200;
   	public inline static var STENCIL_BUFFER  = 0x0400;
	
	public var context:RenderContext;
	public var handle:Dynamic;
	
	private var window:Window;
	
	
	public function new (window:Window) {
		
		this.window = window;
		this.window.currentRenderer = this;
		
	}
	
	
	public function create ():Void {
		
		#if js
		
		if (window.div != null) {
			
			context = DOM (window.div);
			
		} else if (window.canvas != null) {
			
			#if canvas
			
			var webgl = null;
			
			#else
			
			var webgl:RenderingContext = cast window.canvas.getContext ("webgl");
			
			if (webgl == null) {
				
				webgl = cast window.canvas.getContext ("experimental-webgl");
				
			}
			
			#end
			
			if (webgl == null) {
				
				context = CANVAS (cast window.canvas.getContext ("2d"));
				
			} else {
				
				#if debug
				webgl = untyped WebGLDebugUtils.makeDebugContext (webgl);
				#end
				
				GL.context = webgl;
				context = OPENGL (new GLRenderContext ());
				
			}
			
		}
		
		#elseif (cpp || neko)
		
		handle = lime_renderer_create (window.handle);
		context = OPENGL (new GLRenderContext ());
		
		#elseif flash
		
		context = FLASH (Lib.current);
		
		#end
		
	}
	
	
	public function flip ():Void {
		
		#if (cpp || neko)
		lime_renderer_flip (handle);
		#end
		
	}
	
	
	#if (cpp || neko)
	private static var lime_renderer_create = System.load ("lime", "lime_renderer_create", 1);
	private static var lime_renderer_flip = System.load ("lime", "lime_renderer_flip", 1);
	#end
	
	
}