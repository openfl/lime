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
	
	
	private static var instance:WindowEventManager;
	
	private var eventInfo:WindowEventInfo;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		eventInfo = new WindowEventInfo ();
		
		#if (cpp || neko)
		lime_window_event_manager_register (dispatch, eventInfo);
		#end
		
	}
	
	
	public static function addEventListener (listener:IWindowEventListener, priority:Int = 0):Void {
		
		if (instance != null) {
			
			instance._addEventListener (listener, priority);
			
		}
		
	}
	
	
	private function dispatch ():Void {
		
		switch (eventInfo.type) {
			
			case WINDOW_ACTIVATE:
				
				for (listener in listeners) {
					
					listener.onWindowActivate ();
					
				}
			
			case WINDOW_DEACTIVATE:
				
				for (listener in listeners) {
					
					listener.onWindowDeactivate ();
					
				}
			
		}
		
	}
	
	
	#if js
	private function handleDOMEvent (event:Event):Void {
		
		eventInfo.type = (event.type == "focus" ? WINDOW_ACTIVATE : WINDOW_DEACTIVATE);
		dispatch ();
		
	}
	#end
	
	
	#if flash
	private function handleFlashEvent (event:Event):Void {
		
		eventInfo.type = (event.type == Event.ACTIVATE ? WINDOW_ACTIVATE : WINDOW_DEACTIVATE);
		dispatch ();
		
	}
	#end
	
	
	private static function registerWindow (_):Void {
		
		if (instance != null) {
			
			#if js
			Browser.window.addEventListener ("focus", instance.handleDOMEvent, false);
			Browser.window.addEventListener ("blur", instance.handleDOMEvent, false);
			#elseif flash
			Lib.current.stage.addEventListener (Event.ACTIVATE, instance.handleFlashEvent);
			Lib.current.stage.addEventListener (Event.DEACTIVATE, instance.handleFlashEvent);
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