package lime._backend.native;


import haxe.Timer;
import lime.app.Application;
import lime.app.Config;
import lime.audio.AudioManager;
import lime.graphics.ConsoleRenderContext;
import lime.graphics.GLRenderContext;
import lime.graphics.RenderContext;
import lime.graphics.Renderer;
import lime.system.System;
import lime.ui.Gamepad;
import lime.ui.Window;

@:access(haxe.Timer)
@:access(lime.app.Application)
@:access(lime.graphics.Renderer)
@:access(lime.ui.Gamepad)
@:access(lime.ui.Window)


class NativeApplication {
	
	
	private var gamepadEventInfo = new GamepadEventInfo ();
	private var keyEventInfo = new KeyEventInfo ();
	private var mouseEventInfo = new MouseEventInfo ();
	private var renderEventInfo = new RenderEventInfo (RENDER);
	private var textEventInfo = new TextEventInfo ();
	private var touchEventInfo = new TouchEventInfo ();
	private var updateEventInfo = new UpdateEventInfo ();
	private var windowEventInfo = new WindowEventInfo ();
	
	public var handle:Dynamic;
	
	private var frameRate:Float;
	private var parent:Application;
	
	
	public function new (parent:Application):Void {
		
		this.parent = parent;
		frameRate = 60;
		
		AudioManager.init ();
		
	}
	
	
	public function create (config:Config):Void {
		
		parent.config = config;
		
		handle = lime_application_create (null);
		
		if (config != null) {
			
			setFrameRate (config.fps);
			var window = new Window (config);
			var renderer = new Renderer (window);
			parent.addWindow (window);
			parent.addRenderer (renderer);
			parent.init (renderer.context);
			
		}
		
	}
	
	
	public function exec ():Int {
		
		lime_gamepad_event_manager_register (handleGamepadEvent, gamepadEventInfo);
		lime_key_event_manager_register (handleKeyEvent, keyEventInfo);
		lime_mouse_event_manager_register (handleMouseEvent, mouseEventInfo);
		lime_render_event_manager_register (handleRenderEvent, renderEventInfo);
		lime_text_event_manager_register (handleTextEvent, textEventInfo);
		lime_touch_event_manager_register (handleTouchEvent, touchEventInfo);
		lime_update_event_manager_register (handleUpdateEvent, updateEventInfo);
		lime_window_event_manager_register (handleWindowEvent, windowEventInfo);
		
		#if nodejs
		
		lime_application_init (handle);
		
		var eventLoop = function () {
			
			var active = lime_application_update (handle);
			
			if (!active) {
				
				var result = lime_application_quit (handle);
				__cleanup ();
				Sys.exit (result);
				
			}
			
			untyped setImmediate (eventLoop);
			
		}
		
		untyped setImmediate (eventLoop);
		return 0;
		
		#elseif (cpp || neko)
		
		return lime_application_exec (handle);
		
		#else
		
		return 0;
		
		#end
		
	}
	
	
	public function getFrameRate ():Float {
		
		return frameRate;
		
	}
	
	
	private function handleGamepadEvent ():Void {
		
		if (parent.window != null) {
			
			switch (gamepadEventInfo.type) {
				
				case AXIS_MOVE:
					
					parent.window.onGamepadAxisMove.dispatch (Gamepad.devices.get (gamepadEventInfo.id), gamepadEventInfo.axis, gamepadEventInfo.value);
				
				case BUTTON_DOWN:
					
					parent.window.onGamepadButtonDown.dispatch (Gamepad.devices.get (gamepadEventInfo.id), gamepadEventInfo.button);
				
				case BUTTON_UP:
					
					parent.window.onGamepadButtonUp.dispatch (Gamepad.devices.get (gamepadEventInfo.id), gamepadEventInfo.button);
				
				case CONNECT:
					
					var gamepad = new Gamepad (gamepadEventInfo.id);
					Gamepad.devices.set (gamepadEventInfo.id, gamepad);
					parent.window.onGamepadConnect.dispatch (gamepad);
				
				case DISCONNECT:
					
					var gamepad = Gamepad.devices.get (gamepadEventInfo.id);
					if (gamepad != null) gamepad.connected = false;
					Gamepad.devices.remove (gamepadEventInfo.id);
					parent.window.onGamepadDisconnect.dispatch (gamepad);
				
			}
			
		}
		
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
					
					parent.window.onMouseMove.dispatch (mouseEventInfo.x, mouseEventInfo.y);
					parent.window.onMouseMoveRelative.dispatch (mouseEventInfo.movementX, mouseEventInfo.movementY);
				
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
					
					parent.renderer.render ();
					parent.renderer.onRender.dispatch (parent.renderer.context);
					parent.renderer.flip ();
					
				case RENDER_CONTEXT_LOST:
					
					parent.renderer.context = null;
					parent.renderer.onRenderContextLost.dispatch ();
				
				case RENDER_CONTEXT_RESTORED:
					
					#if lime_console
					parent.renderer.context = CONSOLE (new ConsoleRenderContext ());
					#else
					if (parent.config.hardware) {
						
						parent.renderer.context = OPENGL (new GLRenderContext ());
						
					}
					#end
					
					parent.renderer.onRenderContextRestored.dispatch (parent.renderer.context);
				
			}
			
		}
		
	}
	
	
	private function handleTextEvent ():Void {
		
		switch (textEventInfo.type) {
			
			case TEXT_INPUT:
				
				parent.window.onTextInput.dispatch (textEventInfo.text);
			
			case TEXT_EDIT:
				
				parent.window.onTextEdit.dispatch (textEventInfo.text, textEventInfo.start, textEventInfo.length);
			
			default:
			
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
		
		updateTimer ();
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
				
				case WINDOW_ENTER:
					
					parent.window.onWindowEnter.dispatch ();
				
				case WINDOW_FOCUS_IN:
					
					parent.window.onWindowFocusIn.dispatch ();
				
				case WINDOW_FOCUS_OUT:
					
					parent.window.onWindowFocusOut.dispatch ();
				
				case WINDOW_LEAVE:
					
					parent.window.onWindowLeave.dispatch ();
				
				case WINDOW_MINIMIZE:
					
					parent.window.__minimized = true;
					parent.window.onWindowMinimize.dispatch ();
				
				case WINDOW_MOVE:
					
					parent.window.__x = windowEventInfo.x;
					parent.window.__y = windowEventInfo.y;
					parent.window.onWindowMove.dispatch (windowEventInfo.x, windowEventInfo.y);
				
				case WINDOW_RESIZE:
					
					parent.window.__width = windowEventInfo.width;
					parent.window.__height = windowEventInfo.height;
					parent.window.onWindowResize.dispatch (windowEventInfo.width, windowEventInfo.height);
				
				case WINDOW_RESTORE:
					
					parent.window.__fullscreen = false;
					parent.window.__minimized = false;
					parent.window.onWindowRestore.dispatch ();
				
			}
			
		}
		
	}
	
	
	public function setFrameRate (value:Float):Float {
		
		lime_application_set_frame_rate (handle, value);
		return frameRate = value;
		
	}
	
	
	private function updateTimer ():Void {
		
		if (Timer.sRunningTimers.length > 0) {
			
			var currentTime = System.getTimer ();
			var foundNull = false;
			var timer;
			
			for (i in 0...Timer.sRunningTimers.length) {
				
				timer = Timer.sRunningTimers[i];
				
				if (timer != null) {
					
					if (currentTime >= timer.mFireAt) {
						
						timer.mFireAt += timer.mTime;
						timer.run ();
						
					}
					
				} else {
					
					foundNull = true;
					
				}
				
			}
			
			if (foundNull) {
				
				Timer.sRunningTimers = Timer.sRunningTimers.filter (function (val) { return val != null; });
				
			}
			
		}
		
	}
	
	
	private function __cleanup ():Void {
		
		AudioManager.shutdown ();
		
	}
	
	
	private static var lime_application_create = System.load ("lime", "lime_application_create", 1);
	private static var lime_application_exec = System.load ("lime", "lime_application_exec", 1);
	private static var lime_application_init = System.load ("lime", "lime_application_init", 1);
	private static var lime_application_set_frame_rate = System.load ("lime", "lime_application_set_frame_rate", 2);
	private static var lime_application_update = System.load ("lime", "lime_application_update", 1);
	private static var lime_application_quit = System.load ("lime", "lime_application_quit", 1);
	private static var lime_gamepad_event_manager_register = System.load ("lime", "lime_gamepad_event_manager_register", 2);
	private static var lime_key_event_manager_register = System.load ("lime", "lime_key_event_manager_register", 2);
	private static var lime_mouse_event_manager_register = System.load ("lime", "lime_mouse_event_manager_register", 2);
	private static var lime_render_event_manager_register = System.load ("lime", "lime_render_event_manager_register", 2);
	private static var lime_text_event_manager_register = System.load ("lime", "lime_text_event_manager_register", 2);
	private static var lime_touch_event_manager_register = System.load ("lime", "lime_touch_event_manager_register", 2);
	private static var lime_update_event_manager_register = System.load ("lime", "lime_update_event_manager_register", 2);
	private static var lime_window_event_manager_register = System.load ("lime", "lime_window_event_manager_register", 2);
	
	
}


private class GamepadEventInfo {
	
	
	public var axis:Int;
	public var button:Int;
	public var id:Int;
	public var type:GamepadEventType;
	public var value:Float;
	
	
	public function new (type:GamepadEventType = null, id:Int = 0, button:Int = 0, axis:Int = 0, value:Float = 0) {
		
		this.type = type;
		this.id = id;
		this.button = button;
		this.axis = axis;
		this.value = value;
		
	}
	
	
	public function clone ():GamepadEventInfo {
		
		return new GamepadEventInfo (type, id, button, axis, value);
		
	}
	
	
}


@:enum private abstract GamepadEventType(Int) {
	
	var AXIS_MOVE = 0;
	var BUTTON_DOWN = 1;
	var BUTTON_UP = 2;
	var CONNECT = 3;
	var DISCONNECT = 4;
	
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
	public var movementX:Float;
	public var movementY:Float;
	public var type:MouseEventType;
	public var x:Float;
	public var y:Float;
	
	
	
	public function new (type:MouseEventType = null, x:Float = 0, y:Float = 0, button:Int = 0, movementX:Float = 0, movementY:Float = 0) {
		
		this.type = type;
		this.x = x;
		this.y = y;
		this.button = button;
		this.movementX = movementX;
		this.movementY = movementY;
		
	}
	
	
	public function clone ():MouseEventInfo {
		
		return new MouseEventInfo (type, x, y, button, movementX, movementY);
		
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


private class TextEventInfo {
	
	
	public var id:Int;
	public var length:Int;
	public var start:Int;
	public var text:String;
	public var type:TextEventType;
	
	
	public function new (type:TextEventType = null, text:String = "", start:Int = 0, length:Int = 0) {
		
		this.type = type;
		this.text = text;
		this.start = start;
		this.length = length;
		
	}
	
	
	public function clone ():TextEventInfo {
		
		return new TextEventInfo (type, text, start, length);
		
	}
	
	
}


@:enum private abstract TextEventType(Int) {
	
	var TEXT_INPUT = 0;
	var TEXT_EDIT = 1;
	
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
	var WINDOW_ENTER = 3;
	var WINDOW_FOCUS_IN = 4;
	var WINDOW_FOCUS_OUT = 5;
	var WINDOW_LEAVE = 6;
	var WINDOW_MINIMIZE = 7;
	var WINDOW_MOVE = 8;
	var WINDOW_RESIZE = 9;
	var WINDOW_RESTORE = 10;
	
}