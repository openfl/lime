package lime._backend.flash;


import flash.events.Event;
import flash.events.FocusEvent;
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
import lime.ui.Window;

@:access(lime.app.Application)
@:access(lime.graphics.Renderer)


class FlashApplication {
	
	
	private var cacheTime:Int;
	private var initialized:Bool;
	private var parent:Application;
	
	
	public function new (parent:Application):Void {
		
		this.parent = parent;
		
		AudioManager.init ();
		
	}
	
	
	private function convertKeyCode (keyCode:Int):KeyCode {
		
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
		
		if (config != null) {
			
			var window = new Window (config);
			var renderer = new Renderer (window);
			parent.addWindow (window);
			parent.addRenderer (renderer);
			
		}
		
	}
	
	
	public function exec ():Int {
		
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
		Lib.current.stage.addEventListener (Event.ACTIVATE, handleWindowEvent);
		Lib.current.stage.addEventListener (Event.DEACTIVATE, handleWindowEvent);
		Lib.current.stage.addEventListener (FocusEvent.FOCUS_IN, handleWindowEvent);
		Lib.current.stage.addEventListener (FocusEvent.FOCUS_OUT, handleWindowEvent);
		Lib.current.stage.addEventListener (Event.RESIZE, handleWindowEvent);
		
		cacheTime = Lib.getTimer ();
		handleUpdateEvent (null);
		
		Lib.current.stage.addEventListener (Event.ENTER_FRAME, handleUpdateEvent);
		
		return 0;
		
	}
	
	
	private function handleKeyEvent (event:KeyboardEvent):Void {
		
		if (parent.window != null) {
			
			var keyCode = convertKeyCode (event.keyCode);
			var modifier = 0;
			
			if (event.type == KeyboardEvent.KEY_DOWN) {
				
				parent.window.onKeyDown.dispatch (keyCode, 0);
				
			} else {
				
				parent.window.onKeyUp.dispatch (keyCode, 0);
				
			}
			
		}
		
	}
	
	
	private function handleMouseEvent (event:MouseEvent):Void {
		
		if (parent.window != null) {
			
			var button = switch (event.type) {
				
				case "middleMouseDown", "middleMouseMove", "middleMouseUp": 1;
				case "rightMouseDown", "rightMouseMove", "rightMouseUp": 2;
				default: 0;
				
			}
			
			switch (event.type) {
				
				case "mouseDown", "middleMouseDown", "rightMouseDown":
					
					parent.window.onMouseDown.dispatch (event.stageX, event.stageY, button);
				
				case "mouseMove", "middleMouseMove", "rightMouseMove":
					
					parent.window.onMouseMove.dispatch (event.stageX, event.stageY, button);
				
				case "mouseUp", "middleMouseUp", "rightMouseUp":
					
					parent.window.onMouseUp.dispatch (event.stageX, event.stageY, button);
				
				case "mouseWheel":
					
					parent.window.onMouseWheel.dispatch (0, event.delta);
				
				default:
				
			}
			
		}
		
	}
	
	
	private function handleTouchEvent (event:TouchEvent):Void {
		
		if (parent.window != null) {
			
			var id = 0;
			var x = event.stageX;
			var y = event.stageY;
			
			switch (event.type) {
				
				case TouchEvent.TOUCH_BEGIN:
					
					parent.window.onTouchStart.dispatch (x, y, id);
				
				case TouchEvent.TOUCH_MOVE:
					
					parent.window.onTouchMove.dispatch (x, y, id);
				
				case TouchEvent.TOUCH_END:
					
					parent.window.onTouchEnd.dispatch (x, y, id);
				
			}
			
		}
		
	}
	
	
	private function handleUpdateEvent (event:Event):Void {
		
		var currentTime = Lib.getTimer ();
		var deltaTime = currentTime - cacheTime;
		cacheTime = currentTime;
		
		parent.onUpdate.dispatch (deltaTime);
		
		if (parent.renderer != null) {
			
			if (!initialized) {
				
				initialized = true;
				parent.init (parent.renderer.context);
				
			}
			
			parent.renderer.onRender.dispatch (parent.renderer.context);
			parent.renderer.flip ();
			
		}
		
	}
	
	
	private function handleWindowEvent (event:Event):Void {
		
		if (parent.window != null) {
			
			switch (event.type) {
				
				case Event.ACTIVATE:
					
					parent.window.onWindowActivate.dispatch ();
				
				case Event.DEACTIVATE:
					
					parent.window.onWindowDeactivate.dispatch ();
				
				case FocusEvent.FOCUS_IN:
					
					parent.window.onWindowFocusIn.dispatch ();
				
				case FocusEvent.FOCUS_OUT:
					
					parent.window.onWindowFocusOut.dispatch ();
				
				default:
					
					parent.window.width = Lib.current.stage.stageWidth;
					parent.window.height = Lib.current.stage.stageHeight;
					
					parent.window.onWindowResize.dispatch (parent.window.width, parent.window.height);
				
			}
			
		}
		
	}
	
	
}