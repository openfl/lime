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
	
	
	private static var keyEventInfo = new KeyEventInfo ();
	private static var mouseEventInfo = new MouseEventInfo ();
	private static var registeredEvents:Bool;
	private static var touchEventInfo = new TouchEventInfo ();
	private static var updateEventInfo = new UpdateEventInfo ();
	
	public var handle:Dynamic;
	
	private var parent:Application;
	
	
	public function new (parent:Application):Void {
		
		this.parent = parent;
		
		Application.__instance = parent;
		
		if (!registeredEvents) {
			
			registeredEvents = true;
			
			AudioManager.init ();
			
			lime_key_event_manager_register (handleKeyEvent, keyEventInfo);
			lime_mouse_event_manager_register (handleMouseEvent, mouseEventInfo);
			lime_touch_event_manager_register (handleTouchEvent, touchEventInfo);
			lime_update_event_manager_register (handleUpdateEvent, updateEventInfo);
			
		}
		
	}
	
	
	public function create (config:Config):Void {
		
		parent.config = config;
		
		handle = lime_application_create (null);
		
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
	
	
	private static function handleKeyEvent ():Void {
		
		switch (keyEventInfo.type) {
			
			case KEY_DOWN:
				
				KeyEventManager.onKeyDown.dispatch (keyEventInfo.keyCode, keyEventInfo.modifier);
			
			case KEY_UP:
				
				KeyEventManager.onKeyUp.dispatch (keyEventInfo.keyCode, keyEventInfo.modifier);
			
		}
		
	}
	
	
	private static function handleMouseEvent ():Void {
		
		switch (mouseEventInfo.type) {
			
			case MOUSE_DOWN:
				
				MouseEventManager.onMouseDown.dispatch (mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);
			
			case MOUSE_UP:
				
				MouseEventManager.onMouseUp.dispatch (mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);
			
			case MOUSE_MOVE:
				
				MouseEventManager.onMouseMove.dispatch (mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);
			
			case MOUSE_WHEEL:
				
				MouseEventManager.onMouseWheel.dispatch (mouseEventInfo.x, mouseEventInfo.y);
			
			default:
			
		}
		
	}
	
	
	private static function handleTouchEvent ():Void {
		
		switch (touchEventInfo.type) {
			
			case TOUCH_START:
				
				TouchEventManager.onTouchStart.dispatch (touchEventInfo.x, touchEventInfo.y, touchEventInfo.id);
			
			case TOUCH_END:
				
				TouchEventManager.onTouchEnd.dispatch (touchEventInfo.x, touchEventInfo.y, touchEventInfo.id);
			
			case TOUCH_MOVE:
				
				TouchEventManager.onTouchMove.dispatch (touchEventInfo.x, touchEventInfo.y, touchEventInfo.id);
			
			default:
			
		}
		
	}
	
	
	private static function __cleanup ():Void {
		
		AudioManager.shutdown ();
		
	}
	
	
	private static function handleUpdateEvent ():Void {
		
		Application.__instance.update (updateEventInfo.deltaTime);
		Application.onUpdate.dispatch (updateEventInfo.deltaTime);
		
	}
	
	
	private static var lime_application_create = System.load ("lime", "lime_application_create", 1);
	private static var lime_application_init = System.load ("lime", "lime_application_init", 1);
	private static var lime_application_update = System.load ("lime", "lime_application_update", 1);
	private static var lime_application_quit = System.load ("lime", "lime_application_quit", 1);
	private static var lime_application_get_ticks = System.load ("lime", "lime_application_get_ticks", 0);
	private static var lime_key_event_manager_register = System.load ("lime", "lime_key_event_manager_register", 2);
	private static var lime_mouse_event_manager_register = System.load ("lime", "lime_mouse_event_manager_register", 2);
	private static var lime_touch_event_manager_register = System.load ("lime", "lime_touch_event_manager_register", 2);
	private static var lime_update_event_manager_register = System.load ("lime", "lime_update_event_manager_register", 2);
	
	
}


private class KeyEventInfo {
	
	
	public var keyCode:Int;
	public var modifier:Int;
	public var type:KeyEventType;
	
	
	public function new (type:KeyEventType = null, keyCode:Int = 0, modifier:Int = 0) {
		
		this.type = type;
		this.keyCode = keyCode;
		this.modifier = modifier;
		
	}
	
	
	public function clone ():KeyEventInfo {
		
		return new KeyEventInfo (type, keyCode, modifier);
		
	}
	
	
}


@:enum private abstract KeyEventType(Int) {
	
	var KEY_DOWN = 0;
	var KEY_UP = 1;
	
}


private class MouseEventInfo {
	
	
	public var button:Int;
	public var type:MouseEventType;
	public var x:Float;
	public var y:Float;
	
	
	
	public function new (type:MouseEventType = null, x:Float = 0, y:Float = 0, button:Int = 0) {
		
		this.type = type;
		this.x = x;
		this.y = y;
		this.button = button;
		
	}
	
	
	public function clone ():MouseEventInfo {
		
		return new MouseEventInfo (type, x, y, button);
		
	}
	
	
}


@:enum private abstract MouseEventType(Int) {
	
	var MOUSE_DOWN = 0;
	var MOUSE_UP = 1;
	var MOUSE_MOVE = 2;
	var MOUSE_WHEEL = 3;
	
}


private class TouchEventInfo {
	
	
	public var id:Int;
	public var type:TouchEventType;
	public var x:Float;
	public var y:Float;
	
	
	public function new (type:TouchEventType = null, x:Float = 0, y:Float = 0, id:Int = 0) {
		
		this.type = type;
		this.x = x;
		this.y = y;
		this.id = id;
		
	}
	
	
	public function clone ():TouchEventInfo {
		
		return new TouchEventInfo (type, x, y, id);
		
	}
	
	
}


@:enum private abstract TouchEventType(Int) {
	
	var TOUCH_START = 0;
	var TOUCH_END = 1;
	var TOUCH_MOVE = 2;
	
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