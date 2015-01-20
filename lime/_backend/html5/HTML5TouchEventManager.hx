package lime._backend.html5;


import js.html.TouchEvent;
import lime.ui.TouchEventManager;
import lime.ui.Window;


class HTML5TouchEventManager {
	
	
	private static var window:Window;
	
	
	public static function create ():Void {
		
		
		
	}
	
	
	private static function handleEvent (event:TouchEvent):Void {
		
		event.preventDefault ();
		
		var touch = event.changedTouches[0];
		var id = touch.identifier;
		var x = 0.0;
		var y = 0.0;
		
		if (window != null && window.backend.element != null) {
			
			if (window.backend.canvas != null) {
				
				var rect = window.backend.canvas.getBoundingClientRect ();
				x = (touch.clientX - rect.left) * (window.width / rect.width);
				y = (touch.clientY - rect.top) * (window.height / rect.height);
				
			} else if (window.backend.div != null) {
				
				var rect = window.backend.div.getBoundingClientRect ();
				//eventInfo.x = (event.clientX - rect.left) * (window.div.style.width / rect.width);
				x = (touch.clientX - rect.left);
				//eventInfo.y = (event.clientY - rect.top) * (window.div.style.height / rect.height);
				y = (touch.clientY - rect.top);
				
			} else {
				
				var rect = window.backend.element.getBoundingClientRect ();
				x = (touch.clientX - rect.left) * (window.width / rect.width);
				y = (touch.clientY - rect.top) * (window.height / rect.height);
				
			}
			
		} else {
			
			x = touch.clientX;
			y = touch.clientY;
			
		}
		
		switch (event.type) {
			
			case "touchstart":
				
				TouchEventManager.onTouchStart.dispatch (x, y, id);
			
			case "touchmove":
				
				TouchEventManager.onTouchMove.dispatch (x, y, id);
			
			case "touchend":
				
				TouchEventManager.onTouchEnd.dispatch (x, y, id);
			
			default:
			
		}
		
	}
	
	
	public static function registerWindow (window:Window):Void {
		
		window.backend.element.addEventListener ("touchstart", handleEvent, true);
		window.backend.element.addEventListener ("touchmove", handleEvent, true);
		window.backend.element.addEventListener ("touchend", handleEvent, true);
		
		HTML5TouchEventManager.window = window;
		
	}
	
	
}