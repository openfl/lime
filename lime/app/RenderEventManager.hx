package lime.app;


import lime.system.System;


class RenderEventManager {
	
	
	private static var instance:RenderEventManager;
	
	private var listeners:Array<IRenderEventListener>;
	
	
	public function new () {
		
		listeners = new Array ();
		instance = this;
		
		#if (cpp || neko)
		lime_render_event_manager_register (handleEvent, new RenderEvent ());
		#end
		
	}
	
	
	public static function addEventListener (listener:IRenderEventListener):Void {
		
		if (instance != null) {
			
			instance.listeners.push (listener);
			
		}
		
	}
	
	
	private function handleEvent (event:RenderEvent):Void {
		
		var event = event.clone ();
		
		for (listener in listeners) {
			
			listener.onRender (event);
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_render_event_manager_register = System.load ("lime", "lime_render_event_manager_register", 2);
	#end
	
	
}