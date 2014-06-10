package lime.graphics;


import lime.system.System;
import lime.ui.Window;


class Renderer {
	
	
	public var handle:Dynamic;
	
	private static var instance:Renderer;
	
	
	public function new (window:Window) {
		
		#if (cpp || neko)
		handle = lime_renderer_create (window.handle);
		#end
		
		instance = this;
		
	}
	
	
	public static function flip ():Void {
		
		lime_renderer_flip (instance.handle);
		
	}
	
	
	#if (cpp || neko)
	private static var lime_renderer_create = System.load ("lime", "lime_renderer_create", 1);
	private static var lime_renderer_flip = System.load ("lime", "lime_renderer_flip", 1);
	#end
	
	
}
