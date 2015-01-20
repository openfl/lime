package lime._backend.native;


import lime.system.System;
import lime.ui.MouseEventManager;
import lime.ui.Window;


class NativeMouseEventManager {
	
	
	private static var eventInfo:MouseEventInfo;
	
	
	public static function create ():Void {
		
		eventInfo = new MouseEventInfo ();
		
		lime_mouse_event_manager_register (handleEvent, eventInfo);
		
	}
	
	
	private static function handleEvent ():Void {
		
		switch (eventInfo.type) {
			
			case MOUSE_DOWN:
				
				MouseEventManager.onMouseDown.dispatch (eventInfo.x, eventInfo.y, eventInfo.button);
			
			case MOUSE_UP:
				
				MouseEventManager.onMouseUp.dispatch (eventInfo.x, eventInfo.y, eventInfo.button);
			
			case MOUSE_MOVE:
				
				MouseEventManager.onMouseMove.dispatch (eventInfo.x, eventInfo.y, eventInfo.button);
			
			case MOUSE_WHEEL:
				
				MouseEventManager.onMouseWheel.dispatch (eventInfo.x, eventInfo.y);
			
			default:
			
		}
		
	}
	
	
	public static function registerWindow (_window:Window):Void {
		
		
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var lime_mouse_event_manager_register = System.load ("lime", "lime_mouse_event_manager_register", 2);
	
	
}


private class MouseEventInfo {
	
	
	public var button:Int;
	public var type:MouseEventType;
	public var x:Float;
	public var y:Float;
	
	
	
	public function new (type:MouseEventType = null, x:Float = 0, y:Float = 0, button:Int = 0) {
		
		this.type = type;
		this.x = x;
		this.y = y;
		this.button = button;
		
	}
	
	
	public function clone ():MouseEventInfo {
		
		return new MouseEventInfo (type, x, y, button);
		
	}
	
	
}


@:enum private abstract MouseEventType(Int) {
	
	var MOUSE_DOWN = 0;
	var MOUSE_UP = 1;
	var MOUSE_MOVE = 2;
	var MOUSE_WHEEL = 3;
	
}