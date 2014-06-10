package lime.graphics;


import lime.app.EventManager;
import lime.system.System;
#if js
import js.Browser;
#end


@:access(lime.ui.Window)
class RenderEventManager extends EventManager<IRenderEventListener> {
	
	
	private static var instance:RenderEventManager;
	
	private var event:RenderEvent;
	
	
	public function new () {
		
		super ();
		
		instance = this;
		event = new RenderEvent ();
		
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
		
		handleFrame ();
		
		#elseif (cpp || neko)
		
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
	
	
	private function handleFrame ():Void {
		
		handleEvent (event);
		
		#if js
		Browser.window.requestAnimationFrame (cast handleFrame);
		#end
		
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