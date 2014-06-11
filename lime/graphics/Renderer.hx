package lime.graphics;


import lime.system.System;
import lime.ui.Window;


class Renderer {
	
	
	public var handle:Dynamic;
	
	private var window:Window;
	
	
	public function new (window:Window) {
		
		this.window = window;
		this.window.currentRenderer = this;
		
	}
	
	
	public function create ():Void {
		
		#if (cpp || neko)
		handle = lime_renderer_create (window.handle);
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