package lime.ui;


import lime.app.EventManager;
import lime.system.System;


@:allow(lime.ui.Window)
class MouseEventManager extends EventManager<IMouseEventListener> {
	
	
	private static var instance:MouseEventManager;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		
		#if (cpp || neko)
		
		lime_mouse_event_manager_register (handleEvent, new MouseEvent ());
		
		#end
		
	}
	
	
	public static function addEventListener (listener:IMouseEventListener, priority:Int = 0):Void {
		
		if (instance != null) {
			
			instance._addEventListener (listener, priority);
			
		}
		
	}
	
	
	private function handleEvent (event:MouseEvent):Void {
		
		var event = event.clone ();
		
		switch (event.type) {
			
			case MOUSE_DOWN:
				
				for (listener in listeners) {
					
					listener.onMouseDown (event);
					
				}
			
			case MOUSE_UP:
				
				for (listener in listeners) {
					
					listener.onMouseUp (event);
					
				}
			
			case MOUSE_MOVE:
				
				for (listener in listeners) {
					
					listener.onMouseMove (event);
					
				}
			
			default:
			
		}
		
	}
	
	
	private static function registerWindow (window:Window):Void {
		
		if (instance != null) {
			
			#if js
			
			window.element.addEventListener ("mousedown", function (event) {
				
				instance.handleEvent (new MouseEvent (MOUSE_DOWN, 0, 0));
				
			}, true);
			
			window.element.addEventListener ("mousemove", function (event) {
				
				instance.handleEvent (new MouseEvent (MOUSE_MOVE, 0, 0));
				
			}, true);
			
			window.element.addEventListener ("mouseup", function (event) {
				
				instance.handleEvent (new MouseEvent (MOUSE_UP, 0, 0));
				
			}, true);
			
			window.element.addEventListener ("mousewheel", function (event) {
				
				//instance.handleEvent (new MouseEvent (MOUSE_DOWN, 0, 0));
				
			}, true);
			
			#end
			
		}
		
	}
	
	
	public static function removeEventListener (listener:IMouseEventListener):Void {
		
		if (instance != null) {
			
			instance._removeEventListener (listener);
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_mouse_event_manager_register = System.load ("lime", "lime_mouse_event_manager_register", 2);
	#end
	
	
}