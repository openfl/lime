package lime.ui;


import lime.app.EventManager;
import lime.system.System;


@:allow(lime.ui.Window)
class TouchEventManager extends EventManager<ITouchEventListener> {
	
	
	private static var instance:TouchEventManager;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		
		#if (cpp || neko)
		
		lime_touch_event_manager_register (handleEvent, new TouchEvent ());
		
		#end
		
	}
	
	
	public static function addEventListener (listener:ITouchEventListener, priority:Int = 0):Void {
		
		if (instance != null) {
			
			instance._addEventListener (listener, priority);
			
		}
		
	}
	
	
	private function handleEvent (event:TouchEvent):Void {
		
		var event = event.clone ();
		
		switch (event.type) {
			
			case TOUCH_START:
				
				for (listener in listeners) {
					
					listener.onTouchStart (event);
					
				}
			
			case TOUCH_END:
				
				for (listener in listeners) {
					
					listener.onTouchEnd (event);
					
				}
			
			case TOUCH_MOVE:
				
				for (listener in listeners) {
					
					listener.onTouchMove (event);
					
				}
			
		}
		
	}
	
	
	private static function registerWindow (window:Window):Void {
		
		if (instance != null) {
			
			#if js
			
			window.element.addEventListener ("touchstart", function (event) {
				
				instance.handleEvent (new TouchEvent (TOUCH_START, 0, 0, 0));
				
			}, true);
			
			window.element.addEventListener ("touchmove", function (event) {
				
				instance.handleEvent (new TouchEvent (TOUCH_MOVE, 0, 0, 0));
				
			}, true);
			
			window.element.addEventListener ("touchend", function (event) {
				
				instance.handleEvent (new TouchEvent (TOUCH_END, 0, 0, 0));
				
			}, true);
			
			#end
			
		}
		
	}
	
	
	public static function removeEventListener (listener:ITouchEventListener):Void {
		
		if (instance != null) {
			
			instance._removeEventListener (listener);
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_touch_event_manager_register = System.load ("lime", "lime_touch_event_manager_register", 2);
	#end
	
	
}