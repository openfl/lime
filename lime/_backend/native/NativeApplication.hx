package lime._backend.native;


import lime.app.Application;
import lime.app.Config;
import lime.audio.AudioManager;
import lime.graphics.Renderer;
import lime.system.System;
import lime.ui.KeyEventManager;
import lime.ui.MouseEventManager;
import lime.ui.TouchEventManager;
import lime.ui.Window;

@:access(lime.app.Application)
@:access(lime.graphics.Renderer)


class NativeApplication {
	
	
	private static var __eventInfo = new UpdateEventInfo ();
	private static var __registered:Bool;
	
	public var handle:Dynamic;
	
	private var parent:Application;
	
	
	public function new (parent:Application):Void {
		
		this.parent = parent;
		
		Application.__instance = parent;
		
		if (!__registered) {
			
			__registered = true;
			
			AudioManager.init ();
			
			lime_update_event_manager_register (__dispatch, __eventInfo);
			
		}
		
	}
	
	
	public function create (config:Config):Void {
		
		parent.config = config;
		
		handle = lime_application_create (null);
		
		KeyEventManager.create ();
		MouseEventManager.create ();
		TouchEventManager.create ();
		
		KeyEventManager.onKeyDown.add (parent.onKeyDown);
		KeyEventManager.onKeyUp.add (parent.onKeyUp);
		
		MouseEventManager.onMouseDown.add (parent.onMouseDown);
		MouseEventManager.onMouseMove.add (parent.onMouseMove);
		MouseEventManager.onMouseUp.add (parent.onMouseUp);
		MouseEventManager.onMouseWheel.add (parent.onMouseWheel);
		
		TouchEventManager.onTouchStart.add (parent.onTouchStart);
		TouchEventManager.onTouchMove.add (parent.onTouchMove);
		TouchEventManager.onTouchEnd.add (parent.onTouchEnd);
		
		Renderer.onRenderContextLost.add (parent.onRenderContextLost);
		Renderer.onRenderContextRestored.add (parent.onRenderContextRestored);
		
		Window.onWindowActivate.add (parent.onWindowActivate);
		Window.onWindowClose.add (parent.onWindowClose);
		Window.onWindowDeactivate.add (parent.onWindowDeactivate);
		Window.onWindowFocusIn.add (parent.onWindowFocusIn);
		Window.onWindowFocusOut.add (parent.onWindowFocusOut);
		Window.onWindowMove.add (parent.onWindowMove);
		Window.onWindowResize.add (parent.onWindowResize);
		
		var window = new Window (config);
		var renderer = new Renderer (window);
		
		window.width = config.width;
		window.height = config.height;
		
		parent.addWindow (window);
		
	}
	
	
	public function exec ():Int {
		
		lime_application_init (handle);
		
		#if nodejs
		
		var prevTime = untyped __js__ ('Date.now ()');
		var eventLoop = function () {
			
			var active = lime_application_update (handle);
			
			if (!active) {
				
				var result = lime_application_quit (handle);
				__cleanup ();
				Sys.exit (result);
				
			}
			
			var time =  untyped __js__ ('Date.now ()');
			if (time - prevTime <= 16) {
				
				untyped setTimeout (eventLoop, 0);
				
			}
			else {
				
				untyped setImmediate (eventLoop);
				
			}
			
			prevTime = time;
			
		}
		
		untyped setImmediate (eventLoop);
		
		#elseif (cpp || neko)
		
		while (lime_application_update (handle)) {}
		
		var result = lime_application_quit (handle);
		__cleanup ();
		
		return result;
		
		#else
		
		return 0;
		
		#end
		
	}
	
	
	private static function __cleanup ():Void {
		
		AudioManager.shutdown ();
		
	}
	
	
	private static function __dispatch ():Void {
		
		Application.__instance.update (__eventInfo.deltaTime);
		Application.onUpdate.dispatch (__eventInfo.deltaTime);
		
	}
	
	
	private function __triggerFrame (?__):Void {
		
		__eventInfo.deltaTime = 16; //TODO
		__dispatch ();
		
		Renderer.render ();
		
	}
	
	
	private static var lime_application_create = System.load ("lime", "lime_application_create", 1);
	private static var lime_application_init = System.load ("lime", "lime_application_init", 1);
	private static var lime_application_update = System.load ("lime", "lime_application_update", 1);
	private static var lime_application_quit = System.load ("lime", "lime_application_quit", 1);
	private static var lime_application_get_ticks = System.load ("lime", "lime_application_get_ticks", 0);
	private static var lime_update_event_manager_register = System.load ("lime", "lime_update_event_manager_register", 2);
	
	
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