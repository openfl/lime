package lime.app;


import lime.system.System;


class UpdateEventManager {
	
	
	private static var instance:UpdateEventManager;
	
	private var listeners:Array<IUpdateEventListener>;
	
	
	public function new () {
		
		listeners = new Array ();
		instance = this;
		
		#if (cpp || neko)
		lime_update_event_manager_register (handleEvent, new UpdateEvent ());
		#end
		
	}
	
	
	public static function addEventListener (listener:IUpdateEventListener):Void {
		
		if (instance != null) {
			
			instance.listeners.push (listener);
			
		}
		
	}
	
	
	private function handleEvent (event:UpdateEvent):Void {
		
		var event = event.clone ();
		
		for (listener in listeners) {
			
			listener.onUpdate (event);
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_update_event_manager_register = System.load ("lime", "lime_update_event_manager_register", 2);
	#end
	
	
}