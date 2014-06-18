package lime.ui;


import lime.app.Event;
import lime.system.System;

#if js
import js.Browser;
#elseif flash
import flash.Lib;
#end


@:allow(lime.ui.Window)
class KeyEventManager {
	
	
	public static var onKeyDown = new Event<Int->Int->Void> ();
	public static var onKeyUp = new Event<Int->Int->Void> ();
	
	private static var instance:KeyEventManager;
	private var eventInfo:KeyEventInfo;
	
	
	public function new () {
		
		instance = this;
		eventInfo = new KeyEventInfo ();
		
		#if (cpp || neko)
		lime_key_event_manager_register (dispatch, eventInfo);
		#end
		
	}
	
	
	private function dispatch ():Void {
		
		switch (eventInfo.type) {
			
			case KEY_DOWN:
				
				onKeyDown.dispatch (eventInfo.keyCode, eventInfo.modifier);
			
			case KEY_UP:
				
				onKeyUp.dispatch (eventInfo.keyCode, eventInfo.modifier);
			
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
	
	
	#if (cpp || neko)
	private static var lime_key_event_manager_register = System.load ("lime", "lime_key_event_manager_register", 2);
	#end
	
	
}


private class KeyEventInfo {
	
	
	public var keyCode:Int;
	public var modifier:Int;
	public var type:KeyEventType;
	
	
	public function new (type:KeyEventType = null, keyCode:Int = 0, modifier:Int = 0) {
		
		this.type = type;
		this.keyCode = keyCode;
		this.modifier = modifier;
		
	}
	
	
	public function clone ():KeyEventInfo {
		
		return new KeyEventInfo (type, keyCode, modifier);
		
	}
	
	
}


@:enum private abstract KeyEventType(Int) {
	
	var KEY_DOWN = 0;
	var KEY_UP = 1;
	
}