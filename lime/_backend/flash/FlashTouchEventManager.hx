package lime._backend.flash;


import flash.events.TouchEvent;
import flash.ui.MultitouchInputMode;
import flash.ui.Multitouch;
import flash.Lib;
import lime.ui.TouchEventManager;
import lime.ui.Window;


class FlashTouchEventManager {
	
	
	public static function create ():Void {
		
		
		
	}
	
	
	private static function handleEvent (event:TouchEvent):Void {
		
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
	
	
	public static function registerWindow (window:Window):Void {
		
		Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
		Lib.current.stage.addEventListener (TouchEvent.TOUCH_BEGIN, handleEvent);
		Lib.current.stage.addEventListener (TouchEvent.TOUCH_MOVE, handleEvent);
		Lib.current.stage.addEventListener (TouchEvent.TOUCH_END, handleEvent);
		
	}
	
	
}