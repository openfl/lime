package lime.ui;


import lime.system.System;


class TouchEventManager {
	
	
	private static var instance:TouchEventManager;
	
	private var listeners:Array<ITouchEventListener>;
	
	
	public function new () {
		
		listeners = new Array ();
		instance = this;
		
		#if (cpp || neko)
		lime_touch_event_manager_register (handleEvent, new TouchEvent ());
		#end
		
	}
	
	
	public static function addEventListener (listener:ITouchEventListener):Void {
		
		if (instance != null) {
			
			instance.listeners.push (listener);
			
		}
		
	}
	
	
	private function handleEvent (event:TouchEvent):Void {
		
		var event = event.clone ();
		
		switch (event.type) {
			
			case TOUCH_START:
				
				for (listener in listeners) {
					
					listener.onTouchStart (event);
					
				}
			
			case TOUCH_END:
				
				for (listener in listeners) {
					
					listener.onTouchEnd (event);
					
				}
			
			case TOUCH_MOVE:
				
				for (listener in listeners) {
					
					listener.onTouchMove (event);
					
				}
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_touch_event_manager_register = System.load ("lime", "lime_touch_event_manager_register", 2);
	#end
	
	
}