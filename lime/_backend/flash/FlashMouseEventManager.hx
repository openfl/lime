package lime._backend.flash;


import flash.events.MouseEvent;
import flash.Lib;
import lime.ui.MouseEventManager;
import lime.ui.Window;


class FlashMouseEventManager {
	
	
	public static function create ():Void {
		
		
		
	}
	
	
	private static function handleEvent (event:MouseEvent):Void {
		
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
	
	
	public static function registerWindow (_window:Window):Void {
		
		var events = [ "mouseDown", "mouseMove", "mouseUp", "mouseWheel", "middleMouseDown", "middleMouseMove", "middleMouseUp" #if ((!openfl && !disable_flash_right_click) || enable_flash_right_click) , "rightMouseDown", "rightMouseMove", "rightMouseUp" #end ];
		
		for (event in events) {
			
			Lib.current.stage.addEventListener (event, handleEvent);
			
		}
		
	}
	
	
}