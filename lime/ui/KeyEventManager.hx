package lime.ui;


import lime.app.EventManager;
import lime.system.System;


class KeyEventManager extends EventManager<IKeyEventListener> {
	
	
	private static var instance:KeyEventManager;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		
		#if (cpp || neko)
		lime_key_event_manager_register (handleEvent, new KeyEvent ());
		#end
		
	}
	
	
	public static function addEventListener (listener:IKeyEventListener, priority:Int = 0):Void {
		
		if (instance != null) {
			
			instance._addEventListener (listener, priority);
			
		}
		
	}
	
	
	private function handleEvent (event:KeyEvent):Void {
		
		var event = event.clone ();
		
		switch (event.type) {
			
			case KEY_DOWN:
				
				for (listener in listeners) {
					
					listener.onKeyDown (event);
					
				}
			
			case KEY_UP:
				
				for (listener in listeners) {
					
					listener.onKeyUp (event);
					
				}
			
		}
		
	}
	
	
	public static function removeEventListener (listener:IKeyEventListener):Void {
		
		if (instance != null) {
			
			instance._removeEventListener (listener);
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_key_event_manager_register = System.load ("lime", "lime_key_event_manager_register", 2);
	#end
	
	
}