package lime.app;


import lime.graphics.*;
import lime.system.*;
import lime.ui.*;

#if js
import js.Browser;
#elseif flash
import flash.Lib;
#end


class Application {
	
	
	public static var onUpdate = new Event<Int->Void> ();
	
	private static var eventInfo = new UpdateEventInfo ();
	private static var instance:Application;
	private static var registered:Bool;
	
	public var handle:Dynamic;
	
	private var config:Config;
	private var lastUpdate:Int;
	private var windows:Array<Window>;
	
	
	public function new () {
		
		instance = this;
		
		lastUpdate = 0;
		windows = new Array ();
		
		if (!registered) {
			
			registered = true;
			
			#if (cpp || neko)
			lime_update_event_manager_register (__dispatch, eventInfo);
			#end
			
		}
		
	}
	
	
	public function addWindow (window:Window):Void {
		
		windows.push (window);
		window.create ();
		
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
		
		__triggerFrame ();
		
		#elseif flash
		
		Lib.current.stage.addEventListener (flash.events.Event.ENTER_FRAME, __triggerFrame);
		
		#end
		
	}
	
	
	public function create (config:Config):Void {
		
		this.config = config;
		
		#if (cpp || neko)
		handle = lime_application_create (null);
		#end
		
		KeyEventManager.create ();
		MouseEventManager.create ();
		TouchEventManager.create ();
		
		KeyEventManager.onKeyDown.add (onKeyDown);
		KeyEventManager.onKeyUp.add (onKeyUp);
		
		MouseEventManager.onMouseDown.add (onMouseDown);
		MouseEventManager.onMouseMove.add (onMouseMove);
		MouseEventManager.onMouseUp.add (onMouseUp);
		
		TouchEventManager.onTouchStart.add (onTouchStart);
		TouchEventManager.onTouchMove.add (onTouchMove);
		TouchEventManager.onTouchEnd.add (onTouchEnd);
		
		Window.onWindowActivate.add (onWindowActivate);
		Window.onWindowDeactivate.add (onWindowDeactivate);
		
		var window = new Window (this, config);
		var renderer = new Renderer (window);
		
		window.width = config.width;
		window.height = config.height;
		
		#if js
		window.element = config.element;
		#end
		
		addWindow (window);
		
	}
	
	
	public function exec ():Int {
		
		#if (cpp || neko)
		return lime_application_exec (handle);
		#else
		return 0;
		#end
		
	}
	
	
	public function onKeyDown (keyCode:Int, modifier:Int):Void {}
	public function onKeyUp (keyCode:Int, modifier:Int):Void {}
	public function onMouseDown (x:Float, y:Float, button:Int):Void {}
	public function onMouseMove (x:Float, y:Float, button:Int):Void {}
	public function onMouseUp (x:Float, y:Float, button:Int):Void {}
	public function onTouchEnd (x:Float, y:Float, id:Int):Void {}
	public function onTouchMove (x:Float, y:Float, id:Int):Void {}
	public function onTouchStart (x:Float, y:Float, id:Int):Void {}
	public function onWindowActivate ():Void {}
	public function onWindowDeactivate ():Void { }
	
	
	public function render (context:RenderContext):Void {
		
		
		
	}
	
	
	public function update (deltaTime:Int):Void {
		
		
		
	}
	
	
	@:noCompletion private static function __dispatch ():Void {
		
		#if (js && stats)
		windows[0].stats.begin ();
		#end
		
		instance.update (eventInfo.deltaTime);
		
		onUpdate.dispatch (eventInfo.deltaTime);
		
	}
	
	
	@:noCompletion private function __triggerFrame (?_):Void {
		
		eventInfo.deltaTime = 16; //TODO
		__dispatch ();
		
		Renderer.dispatch ();
		
		#if js
		Browser.window.requestAnimationFrame (cast __triggerFrame);
		#end
		
	}
	
	
	#if (cpp || neko)
	private static var lime_application_create = System.load ("lime", "lime_application_create", 1);
	private static var lime_application_exec = System.load ("lime", "lime_application_exec", 1);
	private static var lime_application_get_ticks = System.load ("lime", "lime_application_get_ticks", 0);
	private static var lime_update_event_manager_register = System.load ("lime", "lime_update_event_manager_register", 2);
	#end
	
	
}


private class UpdateEventInfo {
	
	
	public var deltaTime:Int;
	public var type:UpdateEventType;
	
	
	public function new (type:UpdateEventType = null, deltaTime:Int = 0) {
		
		this.type = type;
		this.deltaTime = deltaTime;
		
	}
	
	
	public function clone ():UpdateEventInfo {
		
		return new UpdateEventInfo (type, deltaTime);
		
	}
	
	
}


@:enum private abstract UpdateEventType(Int) {
	
	var UPDATE = 0;
	
}