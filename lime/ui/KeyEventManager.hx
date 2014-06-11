package lime.ui;


import lime.app.EventManager;
import lime.system.System;

#if js
import js.Browser;
#end


@:allow(lime.ui.Window)
class KeyEventManager extends EventManager<IKeyEventListener> {
	
	
	private static var instance:KeyEventManager;
	
	private var keyEvent:KeyEvent;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		keyEvent = new KeyEvent ();
		
		#if (cpp || neko)
		
		lime_key_event_manager_register (handleEvent, keyEvent);
		
		#end
		
	}
	
	
	public static function addEventListener (listener:IKeyEventListener, priority:Int = 0):Void {
		
		if (instance != null) {
			
			instance._addEventListener (listener, priority);
			
		}
		
	}
	
	
	#if js
	private function handleDOMEvent (event:js.html.KeyboardEvent):Void {
		
		//keyEvent.code = event.code;
		keyEvent.code = (event.keyCode != null ? event.keyCode : event.which);
		keyEvent.key = keyEvent.code;
		//keyEvent.code = Keyboard.__convertMozillaCode (keyEvent.code);
		
		//keyEvent.location = untyped (event).location != null ? untyped (event).location : event.keyLocation;
		
		keyEvent.ctrlKey = event.ctrlKey;
		keyEvent.altKey = event.altKey;
		keyEvent.shiftKey = event.shiftKey;
		keyEvent.metaKey = event.metaKey;
		
		keyEvent.type = (event.type == "keydown" ? KEY_DOWN : KEY_UP);
		
		handleEvent (keyEvent);
		
	}
	#end
	
	
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
			Browser.window.addEventListener ("keydown", instance.handleDOMEvent, false);
			Browser.window.addEventListener ("keyup", instance.handleDOMEvent, false);
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