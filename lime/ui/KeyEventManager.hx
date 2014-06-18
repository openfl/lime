package lime.ui;


import lime.app.Event;
import lime.system.System;

#if js
import js.Browser;
#elseif flash
import flash.Lib;
#end


class KeyEventManager {
	
	
	public static var onKeyDown = new Event<Int->Int->Void> ();
	public static var onKeyUp = new Event<Int->Int->Void> ();
	
	private static var eventInfo:KeyEventInfo;
	
	
	public static function create ():Void {
		
		eventInfo = new KeyEventInfo ();
		
		#if js
		
		Browser.window.addEventListener ("keydown", handleEvent, false);
		Browser.window.addEventListener ("keyup", handleEvent, false);
		
		#elseif flash
		
		Lib.current.stage.addEventListener (flash.events.KeyboardEvent.KEY_DOWN, handleEvent);
		Lib.current.stage.addEventListener (flash.events.KeyboardEvent.KEY_UP, handleEvent);
		
		#elseif (cpp || neko)
		
		lime_key_event_manager_register (handleEvent, eventInfo);
		
		#end
		
	}
	
	
	private static function handleEvent (#if js event:js.html.KeyboardEvent #elseif flash event:flash.events.KeyboardEvent #end):Void {
		
		#if js
		
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
		
		#elseif flash
		
		eventInfo.keyCode = event.keyCode;
		//keyEvent.key = event.charCode;
		
		//keyEvent.ctrlKey = event.ctrlKey;
		//keyEvent.altKey = event.altKey;
		//keyEvent.shiftKey = event.shiftKey;
		//keyEvent.metaKey = event.commandKey;
		
		eventInfo.type = (event.type == flash.events.KeyboardEvent.KEY_DOWN ? KEY_DOWN : KEY_UP);
		
		#end
		
		switch (eventInfo.type) {
			
			case KEY_DOWN:
				
				onKeyDown.dispatch (eventInfo.keyCode, eventInfo.modifier);
			
			case KEY_UP:
				
				onKeyUp.dispatch (eventInfo.keyCode, eventInfo.modifier);
			
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