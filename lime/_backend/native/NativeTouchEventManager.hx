package lime._backend.native;


import lime.system.System;
import lime.ui.TouchEventManager;
import lime.ui.Window;


class NativeTouchEventManager {
	
	
	private static var eventInfo:TouchEventInfo;
	
	
	public static function create ():Void {
		
		eventInfo = new TouchEventInfo ();
		
		lime_touch_event_manager_register (handleEvent, eventInfo);
		
	}
	
	
	private static function handleEvent ():Void {
		
		switch (eventInfo.type) {
			
			case TOUCH_START:
				
				TouchEventManager.onTouchStart.dispatch (eventInfo.x, eventInfo.y, eventInfo.id);
			
			case TOUCH_END:
				
				TouchEventManager.onTouchEnd.dispatch (eventInfo.x, eventInfo.y, eventInfo.id);
			
			case TOUCH_MOVE:
				
				TouchEventManager.onTouchMove.dispatch (eventInfo.x, eventInfo.y, eventInfo.id);
			
			default:
			
		}
		
	}
	
	
	public static function registerWindow (window:Window):Void {
		
		
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var lime_touch_event_manager_register = System.load ("lime", "lime_touch_event_manager_register", 2);
	
	
}


private class TouchEventInfo {
	
	
	public var id:Int;
	public var type:TouchEventType;
	public var x:Float;
	public var y:Float;
	
	
	public function new (type:TouchEventType = null, x:Float = 0, y:Float = 0, id:Int = 0) {
		
		this.type = type;
		this.x = x;
		this.y = y;
		this.id = id;
		
	}
	
	
	public function clone ():TouchEventInfo {
		
		return new TouchEventInfo (type, x, y, id);
		
	}
	
	
}


@:enum private abstract TouchEventType(Int) {
	
	var TOUCH_START = 0;
	var TOUCH_END = 1;
	var TOUCH_MOVE = 2;
	
}