package lime.ui;


import lime.system.System;


class MouseEventManager {
	
	
	private static var instance:MouseEventManager;
	
	private var listeners:Array<IMouseEventListener>;
	
	
	public function new () {
		
		listeners = new Array ();
		instance = this;
		
		#if (cpp || neko)
		lime_mouse_event_manager_register (handleEvent, new MouseEvent ());
		#end
		
	}
	
	
	public static function addEventListener (listener:IMouseEventListener):Void {
		
		if (instance != null) {
			
			instance.listeners.push (listener);
			
		}
		
	}
	
	
	private function handleEvent (event:MouseEvent):Void {
		
		var event = event.clone ();
		
		switch (event.type) {
			
			case MOUSE_DOWN:
				
				for (listener in listeners) {
					
					listener.onMouseDown (event);
					
				}
			
			case MOUSE_UP:
				
				for (listener in listeners) {
					
					listener.onMouseUp (event);
					
				}
			
			case MOUSE_MOVE:
				
				for (listener in listeners) {
					
					listener.onMouseMove (event);
					
				}
			
			default:
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_mouse_event_manager_register = System.load ("lime", "lime_mouse_event_manager_register", 2);
	#end
	
	
}