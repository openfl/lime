package lime.app;


import lime.graphics.RenderEventManager;
import lime.system.System;
import lime.ui.Window;

#if js
import js.Browser;
#elseif flash
import flash.events.Event;
import flash.Lib;
#end


@:allow(lime.ui.Window) @:access(lime.graphics.RenderEventManager)
class UpdateEventManager extends EventManager<IUpdateEventListener> {
	
	
	private static var instance(get, null):UpdateEventManager;
	
	private var event:UpdateEvent;
	
	public static inline function get_instance():UpdateEventManager {
	
		return (instance == null) ? instance = new UpdateEventManager() : instance;

	}


	private function new () {
		
		super ();
		
		event = new UpdateEvent ();
		
		#if (cpp || neko)
		lime_update_event_manager_register (handleEvent, event);
		#end
		
	}
	
	
	public static function addEventListener (listener:IUpdateEventListener, priority:Int = 0):Void {
		
		instance._addEventListener (listener, priority);
		
	}
		
	
	private function handleEvent (event:UpdateEvent):Void {
		
		var event = event.clone ();
		
		for (listener in listeners) {
			
			listener.onUpdate (event);
			
		}
		
	}
	
	
	private static function registerWindow (window:Window):Void {
		
		#if js
		
		untyped __js__ ("
			var lastTime = 0;
			var vendors = ['ms', 'moz', 'webkit', 'o'];
			for(var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
				window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
				window.cancelAnimationFrame = window[vendors[x]+'CancelAnimationFrame'] 
										   || window[vendors[x]+'CancelRequestAnimationFrame'];
			}
			
			if (!window.requestAnimationFrame)
				window.requestAnimationFrame = function(callback, element) {
					var currTime = new Date().getTime();
					var timeToCall = Math.max(0, 16 - (currTime - lastTime));
					var id = window.setTimeout(function() { callback(currTime + timeToCall); }, 
					  timeToCall);
					lastTime = currTime + timeToCall;
					return id;
				};
			
			if (!window.cancelAnimationFrame)
				window.cancelAnimationFrame = function(id) {
					clearTimeout(id);
				};
			
			window.requestAnimFrame = window.requestAnimationFrame;
		");
		
		instance.triggerFrame ();
		
		#elseif flash
		
		Lib.current.stage.addEventListener (Event.ENTER_FRAME, instance.triggerFrame);
		
		#end
		
	}
		
	
	public function triggerFrame (?_):Void {
		
		handleEvent (event);
		
		RenderEventManager.instance.render ();
			
		#if js
		Browser.window.requestAnimationFrame (cast triggerFrame);
		#end
		
	}
	
	
	public static function removeEventListener (listener:IUpdateEventListener):Void {
		
		instance._removeEventListener (listener);
		
	}
		
	
	#if (cpp || neko)
	private static var lime_update_event_manager_register = System.load ("lime", "lime_update_event_manager_register", 2);
	#end
	
	
}