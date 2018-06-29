package lime.graphics;


import lime.app.Event;
import lime.ui.Window;


class RenderContext {
	
	
	public var cairo (default, null):CairoRenderContext;
	public var canvas2D (default, null):Canvas2DRenderContext;
	public var element (default, null):DOMRenderContext;
	public var gl (default, null):OpenGLRenderContext;
	public var gles2 (default, null):OpenGLES2RenderContext;
	public var gles3 (default, null):OpenGLES3RenderContext;
	public var sprite (default, null):FlashRenderContext;
	public var type (default, null):RenderContextType;
	public var version (default, null):String;
	public var webgl (default, null):WebGLRenderContext;
	public var webgl2 (default, null):WebGL2RenderContext;
	public var window (default, null):Window;
	
	
	private function new () {
		
		
		
	}
	
	
}