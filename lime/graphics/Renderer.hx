package lime.graphics;


import lime.system.System;
import lime.ui.Window;


class Renderer implements IRenderEventListener {
	
	
	public var handle:Dynamic;
	
	
	public function new (window:Window) {
		
		#if (cpp || neko)
		handle = lime_renderer_create (window.handle);
		RenderEventManager.addEventListener (this, -99999999);
		#end
		
	}
	
	
	public function onRender (event:RenderEvent):Void {
		
		#if (cpp || neko)
		lime_renderer_flip (handle);
		#end
		
	}
	
	
	#if (cpp || neko)
	private static var lime_renderer_create = System.load ("lime", "lime_renderer_create", 1);
	private static var lime_renderer_flip = System.load ("lime", "lime_renderer_flip", 1);
	#end
	
	
}