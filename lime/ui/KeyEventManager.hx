package lime.ui;


import lime.app.EventManager;
import lime.system.System;

#if js
import js.Browser;
#end


@:allow(lime.ui.Window)
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
	
	
	private static function registerWindow (_):Void {
		
		if (instance != null) {
			
			#if js
			
			Browser.window.addEventListener ("keydown", function (event) {
				
				instance.handleEvent (new KeyEvent (KEY_DOWN, 0));
				
			}, false);
			
			Browser.window.addEventListener ("keyup", function (event) {
				
				instance.handleEvent (new KeyEvent (KEY_UP, 0));
				
			}, false);
			
			#end
			
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