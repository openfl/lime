package lime.app;


import lime.graphics.*;
import lime.media.AudioManager;
import lime.system.*;
import lime.ui.*;

#if js
import js.Browser;
#elseif flash
import flash.Lib;
#end


class Application extends Module {
	
	
	public static var onUpdate = new Event<Int->Void> ();
	
	private static var __eventInfo = new UpdateEventInfo ();
	private static var __initialized:Bool;
	private static var __instance:Application;
	private static var __registered:Bool;
	
	public var config (default, null):Config;
	public var window (get, null):Window;
	public var windows (default, null):Array<Window>;
	
	@:noCompletion private var __handle:Dynamic;
	
	
	public function new () {
		
		super ();
		
		__instance = this;
		
		windows = new Array ();
		
		if (!__registered) {
			
			__registered = true;
			
			AudioManager.init ();
			
			#if (cpp || neko)
			lime_update_event_manager_register (__dispatch, __eventInfo);
			#end
			
		}
		
	}
	
	
	public function addWindow (window:Window):Void {
		
		windows.push (window);
		window.create (this);
		
	}
	
	
	public function create (config:Config):Void {
		
		this.config = config;
		
		#if (cpp || neko)
		__handle = lime_application_create (null);
		#end
		
		KeyEventManager.create ();
		MouseEventManager.create ();
		TouchEventManager.create ();
		
		KeyEventManager.onKeyDown.add (onKeyDown);
		KeyEventManager.onKeyUp.add (onKeyUp);
		
		MouseEventManager.onMouseDown.add (onMouseDown);
		MouseEventManager.onMouseMove.add (onMouseMove);
		MouseEventManager.onMouseUp.add (onMouseUp);
		MouseEventManager.onMouseWheel.add (onMouseWheel);
		
		TouchEventManager.onTouchStart.add (onTouchStart);
		TouchEventManager.onTouchMove.add (onTouchMove);
		TouchEventManager.onTouchEnd.add (onTouchEnd);
		
		Window.onWindowActivate.add (onWindowActivate);
		Window.onWindowClose.add (onWindowClose);
		Window.onWindowDeactivate.add (onWindowDeactivate);
		Window.onWindowFocusIn.add (onWindowFocusIn);
		Window.onWindowFocusOut.add (onWindowFocusOut);
		Window.onWindowMove.add (onWindowMove);
		Window.onWindowResize.add (onWindowResize);
		
		var window = new Window (config);
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
		
		var result = lime_application_exec (__handle);
		
		AudioManager.shutdown ();
		
		return result;
		
		#elseif js
		
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
		
		return 0;
		
	}
	
	
	public function init (context:RenderContext):Void {
		
		
		
	}
	
	
	public function onKeyDown (keyCode:Int, modifier:Int):Void {}
	public function onKeyUp (keyCode:Int, modifier:Int):Void {}
	public function onMouseDown (x:Float, y:Float, button:Int):Void {}
	public function onMouseMove (x:Float, y:Float, button:Int):Void {}
	public function onMouseUp (x:Float, y:Float, button:Int):Void {}
	public function onMouseWheel (deltaX:Float, deltaY:Float):Void {}
	public function onTouchEnd (x:Float, y:Float, id:Int):Void {}
	public function onTouchMove (x:Float, y:Float, id:Int):Void {}
	public function onTouchStart (x:Float, y:Float, id:Int):Void {}
	public function onWindowActivate ():Void {}
	public function onWindowClose ():Void {}
	public function onWindowDeactivate ():Void {}
	public function onWindowFocusIn ():Void {}
	public function onWindowFocusOut ():Void {}
	public function onWindowMove (x:Float, y:Float):Void {}
	public function onWindowResize (width:Int, height:Int):Void {}
	
	
	public function render (context:RenderContext):Void {
		
		
		
	}
	
	
	public function update (deltaTime:Int):Void {
		
		
		
	}
	
	
	@:noCompletion private static function __dispatch ():Void {
		
		#if (js && stats)
		__instance.window.stats.begin ();
		#end
		
		__instance.update (__eventInfo.deltaTime);
		onUpdate.dispatch (__eventInfo.deltaTime);
		
	}
	
	
	@:noCompletion private function __triggerFrame (?_):Void {
		
		__eventInfo.deltaTime = 16; //TODO
		__dispatch ();
		
		Renderer.dispatch ();
		
		#if js
		Browser.window.requestAnimationFrame (cast __triggerFrame);
		#end
		
	}
	
	
	@:noCompletion private inline function get_window ():Window {
		
		return windows[0];
		
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