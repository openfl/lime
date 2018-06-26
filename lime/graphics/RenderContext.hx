package lime.graphics;


import lime.app.Event;
import lime.ui.Window;


class RenderContext {
	
	
	// public var cairo (default, null):CairoRenderContext;
	public var ctx (default, null):CanvasRenderContext;
	public var element (default, null):DOMRenderContext;
	// public var gl (default, null):GLRenderContext;
	// public var gles2 (default, null):GLES2RenderContext;
	// public var gles3 (default, null):GLES3RenderContext;
	public var sprite (default, null):FlashRenderContext;
	public var type (default, null):RenderContextType;
	public var version (default, null):String;
	// public var webgl (default, null):WebGLRenderContext;
	// public var webgl2 (default, null):WebGL2RenderContext;
	
	
	private function new () {
		
		
		
	}
	
	
}