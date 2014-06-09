package lime.ui;


import lime.system.System;


class KeyEventManager {
	
	
	private static var instance:KeyEventManager;
	
	private var listeners:Array<IKeyEventListener>;
	
	
	public function new () {
		
		listeners = new Array ();
		instance = this;
		
		#if (cpp || neko)
		lime_key_event_manager_register (handleEvent, new KeyEvent ());
		#end
		
	}
	
	
	public static function addEventListener (listener:IKeyEventListener):Void {
		
		if (instance != null) {
			
			instance.listeners.push (listener);
			
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
	
	
	#if (cpp || neko)
	private static var lime_key_event_manager_register = System.load ("lime", "lime_key_event_manager_register", 2);
	#end
	
	
}