package lime.ui;


import lime.app.EventManager;
import lime.system.System;

#if js
import js.html.Event;
import js.Browser;
#elseif flash
import flash.events.Event;
import flash.Lib;
#end


@:allow(lime.ui.Window)
class WindowEventManager extends EventManager<IWindowEventListener> {
	
	
	private static var instance(get, null):WindowEventManager;
	
	private var windowEvent:WindowEvent;
	
	public static inline function get_instance():WindowEventManager {
	
		return (instance == null) ? instance = new WindowEventManager() : instance;

	}


	private function new () {
		
		super ();
		
		windowEvent = new WindowEvent ();
		
		#if (cpp || neko)
		
		lime_window_event_manager_register (handleEvent, windowEvent);
		
		#end
		
	}
	
	
	public static function addEventListener (listener:IWindowEventListener, priority:Int = 0):Void {
		
		instance._addEventListener (listener, priority);
		
	}
		
	
	#if js
	private function handleDOMEvent (event:Event):Void {
		
		windowEvent.type = (event.type == "focus" ? WINDOW_ACTIVATE : WINDOW_DEACTIVATE);
		handleEvent (windowEvent);
		
	}
	#end
	
	
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
	
	
	#if flash
	private function handleFlashEvent (event:Event):Void {
		
		windowEvent.type = (event.type == Event.ACTIVATE ? WINDOW_ACTIVATE : WINDOW_DEACTIVATE);
		handleEvent (windowEvent);
		
	}
	#end
	
	
	private static function registerWindow (_):Void {
		
		#if js
		Browser.window.addEventListener ("focus", instance.handleDOMEvent, false);
		Browser.window.addEventListener ("blur", instance.handleDOMEvent, false);
		#elseif flash
		Lib.current.stage.addEventListener (Event.ACTIVATE, instance.handleFlashEvent);
		Lib.current.stage.addEventListener (Event.DEACTIVATE, instance.handleFlashEvent);
		#end
		
	}
		
	
	public static function removeEventListener (listener:IWindowEventListener):Void {
		
		instance._removeEventListener (listener);
		
	}
		
	
	#if (cpp || neko)
	private static var lime_window_event_manager_register = System.load ("lime", "lime_window_event_manager_register", 2);
	#end
	
	
}