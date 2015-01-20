package lime._backend.flash;


import flash.events.KeyboardEvent;
import flash.Lib;
import lime.ui.KeyCode;
import lime.ui.KeyEventManager;


class FlashKeyEventManager {
	
	
	private static function convertKeyCode (keyCode:Int):KeyCode {
		
		if (keyCode >= 65 && keyCode <= 90) {
			
			return keyCode + 32;
			
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
		
		return keyCode;
		
	}
	
	
	public static function create ():Void {
		
		Lib.current.stage.addEventListener (KeyboardEvent.KEY_DOWN, handleEvent);
		Lib.current.stage.addEventListener (KeyboardEvent.KEY_UP, handleEvent);
		
	}
	
	
	private static function handleEvent (event:KeyboardEvent):Void {
		
		var keyCode = convertKeyCode (event.keyCode);
		var modifier = 0;
		
		if (event.type == KeyboardEvent.KEY_DOWN) {
			
			KeyEventManager.onKeyDown.dispatch (keyCode, 0);
			
		} else {
			
			KeyEventManager.onKeyUp.dispatch (keyCode, 0);
			
		}
		
	}
	
	
}