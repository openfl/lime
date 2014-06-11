package lime.graphics;


import lime.app.EventManager;
import lime.system.System;
import lime.ui.Window;


@:allow(lime.ui.Window)
class RenderEventManager extends EventManager<IRenderEventListener> {
	
	
	private static var instance:RenderEventManager;
	
	private var event:RenderEvent;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		event = new RenderEvent ();
		
		#if (cpp || neko)
		
		lime_render_event_manager_register (handleEvent, event);
		
		#end
		
	}
	
	
	public static function addEventListener (listener:IRenderEventListener, priority:Int = 0):Void {
		
		if (instance != null) {
			
			instance._addEventListener (listener, priority);
			
		}
		
	}
	
	
	private function handleEvent (event:RenderEvent):Void {
		
		var event = event.clone ();
		
		for (listener in listeners) {
			
			listener.onRender (event);
			
		}
		
	}
	
	
	private static function registerWindow (window:Window):Void {
		
		
		
	}
	
	
	private function render ():Void {
		
		handleEvent (event);
		
	}
	
	
	public static function removeEventListener (listener:IRenderEventListener) {
		
		if (instance != null) {
			
			instance._removeEventListener (listener);
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_render_event_manager_register = System.load ("lime", "lime_render_event_manager_register", 2);
	#end
	
	
}