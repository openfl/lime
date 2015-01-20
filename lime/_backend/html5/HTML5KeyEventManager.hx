package lime._backend.html5;


import js.html.KeyboardEvent;
import js.Browser;
import lime.ui.KeyCode;
import lime.ui.KeyEventManager;


class HTML5KeyEventManager {
	
	
	private static function convertKeyCode (keyCode:Int):KeyCode {
		
		if (keyCode >= 65 && keyCode <= 90) {
			
			return keyCode + 32;
			
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
		
		return keyCode;
		
	}
	
	
	public static function create ():Void {
		
		Browser.window.addEventListener ("keydown", handleEvent, false);
		Browser.window.addEventListener ("keyup", handleEvent, false);
		
	}
	
	
	private static function handleEvent (event:KeyboardEvent):Void {
		
		// space and arrow keys
		
		switch (event.keyCode) {
			
			case 32, 37, 38, 39, 40: event.preventDefault ();
			
		}
		
		var keyCode = cast convertKeyCode (event.keyCode != null ? event.keyCode : event.which);
		var modifier = 0;
		
		if (event.type == "keydown") {
			
			KeyEventManager.onKeyDown.dispatch (keyCode, modifier);
			
		} else {
			
			KeyEventManager.onKeyUp.dispatch (keyCode, modifier);
			
		}
		
	}
	
	
}