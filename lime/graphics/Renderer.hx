package lime.graphics;


import lime.app.Event;
import lime.math.Rectangle;
import lime.ui.Window;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class Renderer {
	
	
	public var context:RenderContext;
	public var onContextLost = new Event<Void->Void> ();
	public var onContextRestored = new Event<RenderContext->Void> ();
	public var onRender = new Event<Void->Void> ();
	public var type:RendererType;
	public var window:Window;
	
	@:noCompletion private var backend:RendererBackend;
	
	
	public function new (window:Window) {
		
		this.window = window;
		
		backend = new RendererBackend (this);
		
		this.window.renderer = this;
		
	}
	
	
	public function create ():Void {
		
		backend.create ();
		
	}
	
	
	public function flip ():Void {
		
		backend.flip ();
		
	}
	
	
	public function readPixels (rect:Rectangle = null):Image {
		
		return backend.readPixels (rect);
		
	}
	
	
	private function render ():Void {
		
		backend.render ();
		
	}
	
	
}


#if kha
@:noCompletion private typedef RendererBackend = lime._backend.kha.KhaRenderer;
#elseif flash
@:noCompletion private typedef RendererBackend = lime._backend.flash.FlashRenderer;
#elseif (js && html5)
@:noCompletion private typedef RendererBackend = lime._backend.html5.HTML5Renderer;
#else
@:noCompletion private typedef RendererBackend = lime._backend.native.NativeRenderer;
#end