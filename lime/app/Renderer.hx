package lime.app;


import lime.system.System;


class Renderer {
	
	
	public var handle:Dynamic;
	
	
	public function new (window:Window) {
		
		#if (cpp || neko)
		handle = lime_renderer_create (window.handle);
		#end
		
	}
	
	
	#if (cpp || neko)
	private static var lime_renderer_create = System.load ("lime", "lime_renderer_create", 1);
	#end
	
	
}