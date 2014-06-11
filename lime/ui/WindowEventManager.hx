package lime.ui;


import lime.app.EventManager;
import lime.system.System;

#if js
import js.Browser;
#end


@:allow(lime.ui.Window)
class WindowEventManager extends EventManager<IWindowEventListener> {
	
	
	private static var instance:WindowEventManager;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		
		#if (cpp || neko)
		
		lime_window_event_manager_register (handleEvent, new WindowEvent ());
		
		#end
		
	}
	
	
	public static function addEventListener (listener:IWindowEventListener, priority:Int = 0):Void {
		
		if (instance != null) {
			
			instance._addEventListener (listener, priority);
			
		}
		
	}
	
	
	private function handleEvent (event:WindowEvent):Void {
		
		var event = event.clone ();
		
		switch (event.type) {
			
			case WINDOW_ACTIVATE:
				
				for (listener in listeners) {
					
					listener.onWindowActivate (event);
					
				}
			
			case WINDOW_DEACTIVATE:
				
				for (listener in listeners) {
					
					listener.onWindowDeactivate (event);
					
				}
			
		}
		
	}
	
	
	private static function registerWindow (_):Void {
		
		if (instance != null) {
			
			#if js
			
			Browser.window.addEventListener ("focus", function (event) {
				
				instance.handleEvent (new WindowEvent (WINDOW_ACTIVATE));
				
			}, false);
			
			Browser.window.addEventListener ("blur", function (event) {
				
				instance.handleEvent (new WindowEvent (WINDOW_DEACTIVATE));
				
			}, false);
			
			#end
			
		}
		
	}
	
	
	public static function removeEventListener (listener:IWindowEventListener):Void {
		
		if (instance != null) {
			
			instance._removeEventListener (listener);
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_window_event_manager_register = System.load ("lime", "lime_window_event_manager_register", 2);
	#end
	
	
}