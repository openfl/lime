package lime.ui;


import lime.app.Application;
import lime.system.System;


class Window {
	
	
	public var handle:Dynamic;
	
	
	public function new (application:Application) {
		
		#if (cpp || neko)
		handle = lime_window_create (application.handle);
		#end
		
	}
	
	
	#if (cpp || neko)
	private static var lime_window_create = System.load ("lime", "lime_window_create", 1);
	#end
	
	
}