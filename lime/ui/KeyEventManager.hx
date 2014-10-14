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
	
	
	private static function convertKeyCode (keyCode:Int):KeyCode {
		
		#if js
		if (keyCode >= 65 && keyCode <= 90) {
			
			return cast keyCode + 32;
			
		}
		
		switch (keyCode) {
			
			case 16: return KeyCode.LEFT_SHIFT;
			case 17: return KeyCode.LEFT_CTRL;
			case 18: return KeyCode.LEFT_ALT;
			case 20: return KeyCode.CAPS_LOCK;
			case 144: return KeyCode.NUM_LOCK;
			case 37: return KeyCode.LEFT;
			case 38: return KeyCode.UP;
			case 39: return KeyCode.RIGHT;
			case 40: return KeyCode.DOWN;
			case 45: return KeyCode.INSERT;
			case 46: return KeyCode.DELETE;
			case 36: return KeyCode.HOME;
			case 35: return KeyCode.END;
			case 33: return KeyCode.PAGE_UP;
			case 34: return KeyCode.PAGE_DOWN;
			case 112: return KeyCode.F1;
			case 113: return KeyCode.F2;
			case 114: return KeyCode.F3;
			case 115: return KeyCode.F4;
			case 116: return KeyCode.F5;
			case 117: return KeyCode.F6;
			case 118: return KeyCode.F7;
			case 119: return KeyCode.F8;
			case 120: return KeyCode.F9;
			case 121: return KeyCode.F10;
			case 122: return KeyCode.F11;
			case 123: return KeyCode.F12;
			
		}
		#elseif flash
		if (keyCode >= 65 && keyCode <= 90) {
			
			return cast keyCode + 32;
			
		}
		
		switch (keyCode) {
			
			case 16: return KeyCode.LEFT_SHIFT;
			case 17: return KeyCode.LEFT_CTRL;
			case 18: return KeyCode.LEFT_ALT;
			case 20: return KeyCode.CAPS_LOCK;
			case 33: return KeyCode.PAGE_UP;
			case 34: return KeyCode.PAGE_DOWN;
			case 35: return KeyCode.END;
			case 36: return KeyCode.HOME;
			case 37: return KeyCode.LEFT;
			case 38: return KeyCode.UP;
			case 39: return KeyCode.RIGHT;
			case 40: return KeyCode.DOWN;
			case 45: return KeyCode.INSERT;
			case 46: return KeyCode.DELETE;
			case 96: return KeyCode.NUMPAD_0;
			case 97: return KeyCode.NUMPAD_1;
			case 98: return KeyCode.NUMPAD_2;
			case 99: return KeyCode.NUMPAD_3;
			case 100: return KeyCode.NUMPAD_4;
			case 101: return KeyCode.NUMPAD_5;
			case 102: return KeyCode.NUMPAD_6;
			case 103: return KeyCode.NUMPAD_7;
			case 104: return KeyCode.NUMPAD_8;
			case 105: return KeyCode.NUMPAD_9;
			case 106: return KeyCode.NUMPAD_MULTIPLY;
			case 107: return KeyCode.NUMPAD_PLUS;
			case 109: return KeyCode.NUMPAD_MINUS;
			case 110: return KeyCode.NUMPAD_PERIOD;
			case 111: return KeyCode.NUMPAD_DIVIDE;
			case 112: return KeyCode.F1;
			case 113: return KeyCode.F2;
			case 114: return KeyCode.F3;
			case 115: return KeyCode.F4;
			case 116: return KeyCode.F5;
			case 117: return KeyCode.F6;
			case 118: return KeyCode.F7;
			case 119: return KeyCode.F8;
			case 120: return KeyCode.F9;
			case 121: return KeyCode.F10;
			case 122: return KeyCode.F11;
			case 123: return KeyCode.F12;
			case 144: return KeyCode.NUM_LOCK;
			case 219: return KeyCode.LEFT_BRACKET;
			case 221: return KeyCode.RIGHT_BRACKET;
			
		}
		#end
		
		return cast keyCode;
		
	}
	
	
	private static function handleEvent (#if js event:js.html.KeyboardEvent #elseif flash event:flash.events.KeyboardEvent #end):Void {
		
		#if js
		
		// space and arrow keys
		switch (event.keyCode) {
			
			case 32, 37, 38, 39, 40: event.preventDefault ();
			
		}
		
		//keyEvent.code = event.code;
		eventInfo.keyCode = cast convertKeyCode (event.keyCode != null ? event.keyCode : event.which);
		//keyEvent.key = keyEvent.code;
		//keyEvent.code = Keyboard.__convertMozillaCode (keyEvent.code);
		
		//keyEvent.location = untyped (event).location != null ? untyped (event).location : event.keyLocation;
		
		//keyEvent.ctrlKey = event.ctrlKey;
		//keyEvent.altKey = event.altKey;
		//keyEvent.shiftKey = event.shiftKey;
		//keyEvent.metaKey = event.metaKey;
		
		eventInfo.type = (event.type == "keydown" ? KEY_DOWN : KEY_UP);
		
		#elseif flash
		
		eventInfo.keyCode = cast convertKeyCode (event.keyCode);
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
