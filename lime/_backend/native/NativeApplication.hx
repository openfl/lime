package lime._backend.native;


import lime.app.Application;
import lime.app.Config;
import lime.audio.AudioManager;
import lime.graphics.ConsoleRenderContext;
import lime.graphics.GLRenderContext;
import lime.graphics.RenderContext;
import lime.graphics.Renderer;
import lime.system.System;
import lime.ui.Window;

@:access(lime.app.Application)
@:access(lime.graphics.Renderer)


class NativeApplication {
	
	
	private var keyEventInfo = new KeyEventInfo ();
	private var mouseEventInfo = new MouseEventInfo ();
	private var renderEventInfo = new RenderEventInfo (RENDER);
	private var touchEventInfo = new TouchEventInfo ();
	private var updateEventInfo = new UpdateEventInfo ();
	private var windowEventInfo = new WindowEventInfo ();
	
	public var handle:Dynamic;
	
	private var initialized:Bool;
	private var parent:Application;
	
	
	public function new (parent:Application):Void {
		
		this.parent = parent;
		
		AudioManager.init ();
		
	}
	
	
	public function create (config:Config):Void {
		
		parent.config = config;
		
		handle = lime_application_create (null);
		
		if (config != null) {
			
			var window = new Window (config);
			var renderer = new Renderer (window);
			parent.addWindow (window);
			parent.addRenderer (renderer);
			
		}
		
	}
	
	
	public function exec ():Int {
		
		lime_key_event_manager_register (handleKeyEvent, keyEventInfo);
		lime_mouse_event_manager_register (handleMouseEvent, mouseEventInfo);
		lime_render_event_manager_register (handleRenderEvent, renderEventInfo);
		lime_touch_event_manager_register (handleTouchEvent, touchEventInfo);
		lime_update_event_manager_register (handleUpdateEvent, updateEventInfo);
		lime_window_event_manager_register (handleWindowEvent, windowEventInfo);
		
		// TODO: add parent.init
		
		#if nodejs
		
		lime_application_init (handle);
		
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
		
		return lime_application_exec (handle);
		
		#else
		
		return 0;
		
		#end
		
	}
	
	
	private function handleKeyEvent ():Void {
		
		if (parent.window != null) {
			
			switch (keyEventInfo.type) {
				
				case KEY_DOWN:
					
					parent.window.onKeyDown.dispatch (keyEventInfo.keyCode, keyEventInfo.modifier);
				
				case KEY_UP:
					
					parent.window.onKeyUp.dispatch (keyEventInfo.keyCode, keyEventInfo.modifier);
				
			}
			
		}
		
	}
	
	
	private function handleMouseEvent ():Void {
		
		if (parent.window != null) {
			
			switch (mouseEventInfo.type) {
				
				case MOUSE_DOWN:
					
					parent.window.onMouseDown.dispatch (mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);
				
				case MOUSE_UP:
					
					parent.window.onMouseUp.dispatch (mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);
				
				case MOUSE_MOVE:
					
					parent.window.onMouseMove.dispatch (mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);
				
				case MOUSE_WHEEL:
					
					parent.window.onMouseWheel.dispatch (mouseEventInfo.x, mouseEventInfo.y);
				
				default:
				
			}
			
		}
		
	}
	
	
	private function handleRenderEvent ():Void {
		
		if (parent.renderer != null) {
			
			switch (renderEventInfo.type) {
				
				case RENDER:
					
					if (!initialized) {
						
						initialized = true;
						parent.init (parent.renderer.context);
						
					}
					
					parent.renderer.onRender.dispatch (parent.renderer.context);
					parent.renderer.flip ();
					
				case RENDER_CONTEXT_LOST:
					
					parent.renderer.context = null;
					parent.renderer.onRenderContextLost.dispatch ();
				
				case RENDER_CONTEXT_RESTORED:
					
					#if lime_console
					parent.renderer.context = CONSOLE (new ConsoleRenderContext ());
					#else
					parent.renderer.context = OPENGL (new GLRenderContext ());
					#end
					
					parent.renderer.onRenderContextRestored.dispatch (parent.renderer.context);
				
			}
			
		}
		
	}
	
	
	private function handleTouchEvent ():Void {
		
		if (parent.window != null) {
			
			switch (touchEventInfo.type) {
				
				case TOUCH_START:
					
					parent.window.onTouchStart.dispatch (touchEventInfo.x, touchEventInfo.y, touchEventInfo.id);
				
				case TOUCH_END:
					
					parent.window.onTouchEnd.dispatch (touchEventInfo.x, touchEventInfo.y, touchEventInfo.id);
				
				case TOUCH_MOVE:
					
					parent.window.onTouchMove.dispatch (touchEventInfo.x, touchEventInfo.y, touchEventInfo.id);
				
				default:
				
			}
			
		}
		
	}
	
	
	private function handleUpdateEvent ():Void {
		
		parent.onUpdate.dispatch (updateEventInfo.deltaTime);
		
	}
	
	
	private function handleWindowEvent ():Void {
		
		if (parent.window != null) {
			
			switch (windowEventInfo.type) {
				
				case WINDOW_ACTIVATE:
					
					parent.window.onWindowActivate.dispatch ();
				
				case WINDOW_CLOSE:
					
					parent.window.onWindowClose.dispatch ();
				
				case WINDOW_DEACTIVATE:
					
					parent.window.onWindowDeactivate.dispatch ();
				
				case WINDOW_FOCUS_IN:
					
					parent.window.onWindowFocusIn.dispatch ();
				
				case WINDOW_FOCUS_OUT:
					
					parent.window.onWindowFocusOut.dispatch ();
				
				case WINDOW_MOVE:
					
					parent.window.x = windowEventInfo.x;
					parent.window.y = windowEventInfo.y;
					
					parent.window.onWindowMove.dispatch (windowEventInfo.x, windowEventInfo.y);
				
				case WINDOW_RESIZE:
					
					parent.window.width = windowEventInfo.width;
					parent.window.height = windowEventInfo.height;
					
					parent.window.onWindowResize.dispatch (windowEventInfo.width, windowEventInfo.height);
				
			}
			
		}
		
	}
	
	
	private function __cleanup ():Void {
		
		AudioManager.shutdown ();
		
	}
	
	
	private static var lime_application_create = System.load ("lime", "lime_application_create", 1);
	private static var lime_application_exec = System.load ("lime", "lime_application_exec", 1);
	private static var lime_application_init = System.load ("lime", "lime_application_init", 1);
	private static var lime_application_update = System.load ("lime", "lime_application_update", 1);
	private static var lime_application_quit = System.load ("lime", "lime_application_quit", 1);
	private static var lime_application_get_ticks = System.load ("lime", "lime_application_get_ticks", 0);
	private static var lime_key_event_manager_register = System.load ("lime", "lime_key_event_manager_register", 2);
	private static var lime_mouse_event_manager_register = System.load ("lime", "lime_mouse_event_manager_register", 2);
	private static var lime_render_event_manager_register = System.load ("lime", "lime_render_event_manager_register", 2);
	private static var lime_touch_event_manager_register = System.load ("lime", "lime_touch_event_manager_register", 2);
	private static var lime_update_event_manager_register = System.load ("lime", "lime_update_event_manager_register", 2);
	private static var lime_window_event_manager_register = System.load ("lime", "lime_window_event_manager_register", 2);
	
	
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


private class RenderEventInfo {
	
	
	public var context:RenderContext;
	public var type:RenderEventType;
	
	
	public function new (type:RenderEventType = null, context:RenderContext = null) {
		
		this.type = type;
		this.context = context;
		
	}
	
	
	public function clone ():RenderEventInfo {
		
		return new RenderEventInfo (type, context);
		
	}
	
	
}


@:enum private abstract RenderEventType(Int) {
	
	var RENDER = 0;
	var RENDER_CONTEXT_LOST = 1;
	var RENDER_CONTEXT_RESTORED = 2;
	
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


private class WindowEventInfo {
	
	
	public var height:Int;
	public var type:WindowEventType;
	public var width:Int;
	public var x:Int;
	public var y:Int;
	
	
	public function new (type:WindowEventType = null, width:Int = 0, height:Int = 0, x:Int = 0, y:Int = 0) {
		
		this.type = type;
		this.width = width;
		this.height = height;
		this.x = x;
		this.y = y;
		
	}
	
	
	public function clone ():WindowEventInfo {
		
		return new WindowEventInfo (type, width, height, x, y);
		
	}
	
	
}


@:enum private abstract WindowEventType(Int) {
	
	var WINDOW_ACTIVATE = 0;
	var WINDOW_CLOSE = 1;
	var WINDOW_DEACTIVATE = 2;
	var WINDOW_FOCUS_IN = 3;
	var WINDOW_FOCUS_OUT = 4;
	var WINDOW_MOVE = 5;
	var WINDOW_RESIZE = 6;
	
}