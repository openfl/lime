package lime.graphics;


import lime.app.Event;
import lime.ui.Window;


class RenderContext {
	
	
	public var attributes (default, null):RenderContextAttributes;
	
	#if (!lime_doc_gen || native) 
	public var cairo (default, null):CairoRenderContext;
	#end
	
	#if (!lime_doc_gen || (js && html5)) 
	public var canvas2D (default, null):Canvas2DRenderContext;
	#end
	
	#if (!lime_doc_gen || (js && html5)) 
	public var dom (default, null):DOMRenderContext;
	#end
	
	#if (!lime_doc_gen || flash) 
	public var flash (default, null):FlashRenderContext;
	#end
	
	#if (!lime_doc_gen || (native && desktop)) 
	public var gl (default, null):OpenGLRenderContext;
	#end
	
	#if (!lime_doc_gen || native) 
	public var gles2 (default, null):OpenGLES2RenderContext;
	#end
	
	#if (!lime_doc_gen || native) 
	public var gles3 (default, null):OpenGLES3RenderContext;
	#end
	
	public var type (default, null):RenderContextType;
	public var version (default, null):String;
	
	#if (!lime_doc_gen || native || (js && html5)) 
	public var webgl (default, null):WebGLRenderContext;
	#end
	
	#if (!lime_doc_gen || native || (js && html5)) 
	public var webgl2 (default, null):WebGL2RenderContext;
	#end
	
	public var window (default, null):Window;
	
	
	private function new () {}
	
	
}