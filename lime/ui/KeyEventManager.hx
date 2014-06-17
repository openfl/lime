package lime.ui;


import lime.app.EventManager;
import lime.system.System;

#if js
import js.Browser;
#elseif flash
import flash.Lib;
#end


@:allow(lime.ui.Window)
class KeyEventManager extends EventManager<IKeyEventListener> {
	
	
	private static var instance:KeyEventManager;
	
	private var eventInfo:KeyEventInfo;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		eventInfo = new KeyEventInfo ();
		
		#if (cpp || neko)
		lime_key_event_manager_register (dispatch, eventInfo);
		#end
		
	}
	
	
	public static function addEventListener (listener:IKeyEventListener, priority:Int = 0):Void {
		
		if (instance != null) {
			
			instance._addEventListener (listener, priority);
			
		}
		
	}
	
	
	private function dispatch ():Void {
		
		var keyCode = eventInfo.keyCode;
		var modifier = eventInfo.modifier;
		
		switch (eventInfo.type) {
			
			case KEY_DOWN:
				
				for (listener in listeners) {
					
					listener.onKeyDown (keyCode, modifier);
					
				}
			
			case KEY_UP:
				
				for (listener in listeners) {
					
					listener.onKeyUp (keyCode, modifier);
					
				}
			
		}
		
	}
	
	
	#if js
	private function handleDOMEvent (event:js.html.KeyboardEvent):Void {
		
		//keyEvent.code = event.code;
		eventInfo.keyCode = (event.keyCode != null ? event.keyCode : event.which);
		//keyEvent.key = keyEvent.code;
		//keyEvent.code = Keyboard.__convertMozillaCode (keyEvent.code);
		
		//keyEvent.location = untyped (event).location != null ? untyped (event).location : event.keyLocation;
		
		//keyEvent.ctrlKey = event.ctrlKey;
		//keyEvent.altKey = event.altKey;
		//keyEvent.shiftKey = event.shiftKey;
		//keyEvent.metaKey = event.metaKey;
		
		eventInfo.type = (event.type == "keydown" ? KEY_DOWN : KEY_UP);
		dispatch ();
		
	}
	#end
	
	
	#if flash
	private function handleFlashEvent (event:flash.events.KeyboardEvent):Void {
		
		eventInfo.keyCode = event.keyCode;
		//keyEvent.key = event.charCode;
		
		//keyEvent.ctrlKey = event.ctrlKey;
		//keyEvent.altKey = event.altKey;
		//keyEvent.shiftKey = event.shiftKey;
		//keyEvent.metaKey = event.commandKey;
		
		eventInfo.type = (event.type == flash.events.KeyboardEvent.KEY_DOWN ? KEY_DOWN : KEY_UP);
		dispatch ();
		
	}
	#end
	
	
	private static function registerWindow (_):Void {
		
		if (instance != null) {
			
			#if js
			Browser.window.addEventListener ("keydown", instance.handleDOMEvent, false);
			Browser.window.addEventListener ("keyup", instance.handleDOMEvent, false);
			#elseif flash
			Lib.current.stage.addEventListener (flash.events.KeyboardEvent.KEY_DOWN, instance.handleFlashEvent);
			Lib.current.stage.addEventListener (flash.events.KeyboardEvent.KEY_UP, instance.handleFlashEvent);
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