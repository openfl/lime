package lime.ui;


import lime.system.System;


class WindowEventManager {
	
	
	private static var instance:WindowEventManager;
	
	private var listeners:Array<IWindowEventListener>;
	
	
	public function new () {
		
		listeners = new Array ();
		instance = this;
		
		#if (cpp || neko)
		lime_window_event_manager_register (handleEvent, new WindowEvent ());
		#end
		
	}
	
	
	public static function addEventListener (listener:IWindowEventListener):Void {
		
		if (instance != null) {
			
			instance.listeners.push (listener);
			
		}
		
	}
	
	
	private function handleEvent (event:WindowEvent):Void {
		
		var event = event.clone ();
		
		switch (event.type) {
			
			case WINDOW_ACTIVATE:
				
				for (listener in listeners) {
					
					listener.onWindowActivate (event);
					
				}
			
			case WINDOW_DEACTIVATE:
				
				for (listener in listeners) {
					
					listener.onWindowDeactivate (event);
					
				}
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_window_event_manager_register = System.load ("lime", "lime_window_event_manager_register", 2);
	#end
	
	
}