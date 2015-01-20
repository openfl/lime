package lime._backend.flash;


import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.ui.MultitouchInputMode;
import flash.ui.Multitouch;
import flash.Lib;
import lime.app.Application;
import lime.app.Config;
import lime.audio.AudioManager;
import lime.graphics.Renderer;
import lime.ui.KeyCode;
import lime.ui.KeyEventManager;
import lime.ui.MouseEventManager;
import lime.ui.TouchEventManager;
import lime.ui.Window;

@:access(lime.app.Application)
@:access(lime.graphics.Renderer)


class FlashApplication {
	
	
	private static var registeredEvents:Bool;
	
	private var parent:Application;
	
	
	public function new (parent:Application):Void {
		
		this.parent = parent;
		
		Application.__instance = parent;
		
		if (!registeredEvents) {
			
			registeredEvents = true;
			
			AudioManager.init ();
			
			Lib.current.stage.addEventListener (KeyboardEvent.KEY_DOWN, handleKeyEvent);
			Lib.current.stage.addEventListener (KeyboardEvent.KEY_UP, handleKeyEvent);
			
			var events = [ "mouseDown", "mouseMove", "mouseUp", "mouseWheel", "middleMouseDown", "middleMouseMove", "middleMouseUp" #if ((!openfl && !disable_flash_right_click) || enable_flash_right_click) , "rightMouseDown", "rightMouseMove", "rightMouseUp" #end ];
			
			for (event in events) {
				
				Lib.current.stage.addEventListener (event, handleMouseEvent);
				
			}
			
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			
			Lib.current.stage.addEventListener (TouchEvent.TOUCH_BEGIN, handleTouchEvent);
			Lib.current.stage.addEventListener (TouchEvent.TOUCH_MOVE, handleTouchEvent);
			Lib.current.stage.addEventListener (TouchEvent.TOUCH_END, handleTouchEvent);
			
		}
		
	}
	
	
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
	
	
	public function create (config:Config):Void {
		
		parent.config = config;
		
		KeyEventManager.onKeyDown.add (parent.onKeyDown);
		KeyEventManager.onKeyUp.add (parent.onKeyUp);
		
		MouseEventManager.onMouseDown.add (parent.onMouseDown);
		MouseEventManager.onMouseMove.add (parent.onMouseMove);
		MouseEventManager.onMouseUp.add (parent.onMouseUp);
		MouseEventManager.onMouseWheel.add (parent.onMouseWheel);
		
		TouchEventManager.onTouchStart.add (parent.onTouchStart);
		TouchEventManager.onTouchMove.add (parent.onTouchMove);
		TouchEventManager.onTouchEnd.add (parent.onTouchEnd);
		
		Renderer.onRenderContextLost.add (parent.onRenderContextLost);
		Renderer.onRenderContextRestored.add (parent.onRenderContextRestored);
		
		Window.onWindowActivate.add (parent.onWindowActivate);
		Window.onWindowClose.add (parent.onWindowClose);
		Window.onWindowDeactivate.add (parent.onWindowDeactivate);
		Window.onWindowFocusIn.add (parent.onWindowFocusIn);
		Window.onWindowFocusOut.add (parent.onWindowFocusOut);
		Window.onWindowMove.add (parent.onWindowMove);
		Window.onWindowResize.add (parent.onWindowResize);
		
		var window = new Window (config);
		var renderer = new Renderer (window);
		
		window.width = config.width;
		window.height = config.height;
		
		parent.addWindow (window);
		
	}
	
	
	public function exec ():Int {
		
		Lib.current.stage.addEventListener (Event.ENTER_FRAME, handleUpdateEvent);
		
		return 0;
		
	}
	
	
	private static function handleKeyEvent (event:KeyboardEvent):Void {
		
		var keyCode = convertKeyCode (event.keyCode);
		var modifier = 0;
		
		if (event.type == KeyboardEvent.KEY_DOWN) {
			
			KeyEventManager.onKeyDown.dispatch (keyCode, 0);
			
		} else {
			
			KeyEventManager.onKeyUp.dispatch (keyCode, 0);
			
		}
		
	}
	
	
	private static function handleMouseEvent (event:MouseEvent):Void {
		
		var button = switch (event.type) {
			
			case "middleMouseDown", "middleMouseMove", "middleMouseUp": 1;
			case "rightMouseDown", "rightMouseMove", "rightMouseUp": 2;
			default: 0;
			
		}
		
		switch (event.type) {
			
			case "mouseDown", "middleMouseDown", "rightMouseDown":
				
				MouseEventManager.onMouseDown.dispatch (event.stageX, event.stageY, button);
			
			case "mouseMove", "middleMouseMove", "rightMouseMove":
				
				MouseEventManager.onMouseMove.dispatch (event.stageX, event.stageY, button);
			
			case "mouseUp", "middleMouseUp", "rightMouseUp":
				
				MouseEventManager.onMouseUp.dispatch (event.stageX, event.stageY, button);
			
			case "mouseWheel":
				
				MouseEventManager.onMouseWheel.dispatch (0, event.delta);
			
			default:
			
		}
		
	}
	
	
	private static function handleTouchEvent (event:TouchEvent):Void {
		
		var id = 0;
		var x = event.stageX;
		var y = event.stageY;
		
		switch (event.type) {
			
			case TouchEvent.TOUCH_BEGIN:
				
				TouchEventManager.onTouchStart.dispatch (x, y, id);
			
			case TouchEvent.TOUCH_MOVE:
				
				TouchEventManager.onTouchMove.dispatch (x, y, id);
			
			case TouchEvent.TOUCH_END:
				
				TouchEventManager.onTouchEnd.dispatch (x, y, id);
			
		}
		
	}
	
	
	private static function handleUpdateEvent (event:Event):Void {
		
		// TODO: deltaTime
		
		Application.__instance.update (16);
		Application.onUpdate.dispatch (16);
		
		Renderer.render ();
		
	}
	
	
}