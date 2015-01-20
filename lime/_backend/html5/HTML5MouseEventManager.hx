package lime._backend.html5;


import js.html.MouseEvent;
import js.Browser;
import lime.ui.MouseEventManager;
import lime.ui.Window;


class HTML5MouseEventManager {
	
	
	private static var window:Window;
	
	
	public static function create ():Void {
		
		
		
	}
	
	
	private static function handleEvent (event:MouseEvent):Void {
		
		var x = 0.0;
		var y = 0.0;
		
		if (event.type != "wheel") {
			
			if (window != null && window.backend.element != null) {
				
				if (window.backend.canvas != null) {
					
					var rect = window.backend.canvas.getBoundingClientRect ();
					x = (event.clientX - rect.left) * (window.width / rect.width);
					y = (event.clientY - rect.top) * (window.height / rect.height);
					
				} else if (window.backend.div != null) {
					
					var rect = window.backend.div.getBoundingClientRect ();
					//x = (event.clientX - rect.left) * (window.backend.div.style.width / rect.width);
					x = (event.clientX - rect.left);
					//y = (event.clientY - rect.top) * (window.backend.div.style.height / rect.height);
					y = (event.clientY - rect.top);
					
				} else {
					
					var rect = window.backend.element.getBoundingClientRect ();
					x = (event.clientX - rect.left) * (window.width / rect.width);
					y = (event.clientY - rect.top) * (window.height / rect.height);
					
				}
				
			} else {
				
				x = event.clientX;
				y = event.clientY;
				
			}
			
			switch (event.type) {
				
				case "mousedown":
					
					MouseEventManager.onMouseDown.dispatch (x, y, event.button);
				
				case "mouseup":
					
					MouseEventManager.onMouseUp.dispatch (x, y, event.button);
				
				case "mousemove":
					
					MouseEventManager.onMouseMove.dispatch (x, y, event.button);
				
				default:
				
			}
			
		} else {
			
			MouseEventManager.onMouseWheel.dispatch (untyped event.deltaX, untyped event.deltaY);
			
		}
		
	}
	
	
	public static function registerWindow (_window:Window):Void {
		
		var events = [ "mousedown", "mousemove", "mouseup", "wheel" ];
		
		for (event in events) {
			
			_window.backend.element.addEventListener (event, handleEvent, true);
			
		}
		
		HTML5MouseEventManager.window = _window;
		
		// Disable image drag on Firefox
		Browser.document.addEventListener ("dragstart", function (e) {
			if (e.target.nodeName.toLowerCase () == "img") {
				e.preventDefault ();
				return false;
			}
			return true;
		}, false);
		
	}
	
	
}