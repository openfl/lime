package lime.app;


import lime.system.System;


class UpdateEventManager extends EventManager<IUpdateEventListener> {
	
	
	private static var instance:UpdateEventManager;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		
		#if (cpp || neko)
		lime_update_event_manager_register (handleEvent, new UpdateEvent ());
		#end
		
	}
	
	
	public static function addEventListener (listener:IUpdateEventListener, priority:Int = 0):Void {
		
		if (instance != null) {
			
			instance._addEventListener (listener, priority);
			
		}
		
	}
	
	
	private function handleEvent (event:UpdateEvent):Void {
		
		var event = event.clone ();
		
		for (listener in listeners) {
			
			listener.onUpdate (event);
			
		}
		
	}
	
	
	public static function removeEventListener (listener:IUpdateEventListener):Void {
		
		if (instance != null) {
			
			instance._removeEventListener (listener);
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_update_event_manager_register = System.load ("lime", "lime_update_event_manager_register", 2);
	#end
	
	
}