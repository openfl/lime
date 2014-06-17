package lime.graphics;


import lime.app.EventManager;
import lime.system.System;
import lime.ui.Window;


@:allow(lime.ui.Window)
class RenderEventManager extends EventManager<IRenderEventListener> {
	
	
	private static var instance:RenderEventManager;
	
	private var eventInfo:RenderEventInfo;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		eventInfo = new RenderEventInfo ();
		
		#if (cpp || neko)
		
		lime_render_event_manager_register (dispatch, eventInfo);
		
		#end
		
	}
	
	
	public static function addEventListener (listener:IRenderEventListener, priority:Int = 0):Void {
		
		if (instance != null) {
			
			instance._addEventListener (listener, priority);
			
		}
		
	}
	
	
	private function dispatch ():Void {
		
		var context = eventInfo.context;
		
		for (listener in listeners) {
			
			listener.onRender (context);
			
		}
		
	}
	
	
	private static function registerWindow (window:Window):Void {
		
		
		
	}
	
	
	private function render ():Void {
		
		dispatch ();
		
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