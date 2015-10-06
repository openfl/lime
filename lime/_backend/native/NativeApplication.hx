package lime._backend.native;


import haxe.Timer;
import lime.app.Application;
import lime.app.Config;
import lime.audio.AudioManager;
import lime.graphics.ConsoleRenderContext;
import lime.graphics.GLRenderContext;
import lime.graphics.RenderContext;
import lime.graphics.Renderer;
import lime.math.Rectangle;
import lime.system.Display;
import lime.system.DisplayMode;
import lime.system.Sensor;
import lime.system.SensorType;
import lime.system.System;
import lime.ui.Gamepad;
import lime.ui.Joystick;
import lime.ui.JoystickHatPosition;
import lime.ui.Touch;
import lime.ui.Window;

#if !macro
@:build(lime.system.CFFI.build())
#end

@:access(haxe.Timer)
@:access(lime._backend.native.NativeRenderer)
@:access(lime.app.Application)
@:access(lime.graphics.Renderer)
@:access(lime.system.Sensor)
@:access(lime.ui.Gamepad)
@:access(lime.ui.Joystick)
@:access(lime.ui.Window)


class NativeApplication {
	
	
	private var applicationEventInfo = new ApplicationEventInfo (UPDATE);
	private var currentTouches = new Map<Int, Touch> ();
	private var gamepadEventInfo = new GamepadEventInfo ();
	private var joystickEventInfo = new JoystickEventInfo ();
	private var keyEventInfo = new KeyEventInfo ();
	private var mouseEventInfo = new MouseEventInfo ();
	private var renderEventInfo = new RenderEventInfo (RENDER);
	private var sensorEventInfo = new SensorEventInfo ();
	private var textEventInfo = new TextEventInfo ();
	private var touchEventInfo = new TouchEventInfo ();
	private var unusedTouchesPool = new List<Touch> ();
	private var windowEventInfo = new WindowEventInfo ();
	
	public var handle:Dynamic;
	
	private var frameRate:Float;
	private var parent:Application;
	
	
	public function new (parent:Application):Void {
		
		this.parent = parent;
		frameRate = 60;
		
		AudioManager.init ();
		
		#if (ios || android || tvos)
		Sensor.registerSensor (SensorType.ACCELEROMETER, 0);
		#end
		
	}
	
	
	public function create (config:Config):Void {
		
		#if !macro
		handle = lime_application_create ( { } );
		#end
		
	}
	
	
	public function exec ():Int {
		
		#if !macro
		
		lime_application_event_manager_register (handleApplicationEvent, applicationEventInfo);
		lime_gamepad_event_manager_register (handleGamepadEvent, gamepadEventInfo);
		lime_joystick_event_manager_register (handleJoystickEvent, joystickEventInfo);
		lime_key_event_manager_register (handleKeyEvent, keyEventInfo);
		lime_mouse_event_manager_register (handleMouseEvent, mouseEventInfo);
		lime_render_event_manager_register (handleRenderEvent, renderEventInfo);
		lime_text_event_manager_register (handleTextEvent, textEventInfo);
		lime_touch_event_manager_register (handleTouchEvent, touchEventInfo);
		lime_window_event_manager_register (handleWindowEvent, windowEventInfo);
		
		#if (ios || android || tvos)
		lime_sensor_event_manager_register (handleSensorEvent, sensorEventInfo);
		#end
		
		#if nodejs
		
		lime_application_init (handle);
		
		var eventLoop = function () {
			
			var active = lime_application_update (handle);
			
			if (!active) {
				
				var result = lime_application_quit (handle);
				System.exit (result);
				
			}
			
			untyped setImmediate (eventLoop);
			
		}
		
		untyped setImmediate (eventLoop);
		return 0;
		
		#elseif (cpp || neko)
		
		var result = lime_application_exec (handle);
		parent.onExit.dispatch (result);
		
		return result;
		
		#end
		#end
		
		return 0;
		
	}
	
	
	public function exit ():Void {
		
		AudioManager.shutdown ();
		
	}
	
	
	public function getFrameRate ():Float {
		
		return frameRate;
		
	}
	
	
	private function handleApplicationEvent ():Void {
		
		switch (applicationEventInfo.type) {
			
			case UPDATE:
				
				updateTimer ();
				parent.onUpdate.dispatch (applicationEventInfo.deltaTime);
			
			case EXIT:
				
				//parent.onExit.dispatch (0);
			
		}
		
	}
	
	
	private function handleGamepadEvent ():Void {
		
		switch (gamepadEventInfo.type) {
			
			case AXIS_MOVE:
				
				var gamepad = Gamepad.devices.get (gamepadEventInfo.id);
				if (gamepad != null) gamepad.onAxisMove.dispatch (gamepadEventInfo.axis, gamepadEventInfo.value);
			
			case BUTTON_DOWN:
				
				var gamepad = Gamepad.devices.get (gamepadEventInfo.id);
				if (gamepad != null) gamepad.onButtonDown.dispatch (gamepadEventInfo.button);
			
			case BUTTON_UP:
				
				var gamepad = Gamepad.devices.get (gamepadEventInfo.id);
				if (gamepad != null) gamepad.onButtonUp.dispatch (gamepadEventInfo.button);
			
			case CONNECT:
				
				if (!Gamepad.devices.exists (gamepadEventInfo.id)) {
					
					var gamepad = new Gamepad (gamepadEventInfo.id);
					Gamepad.devices.set (gamepadEventInfo.id, gamepad);
					Gamepad.onConnect.dispatch (gamepad);
					
				}
			
			case DISCONNECT:
				
				var gamepad = Gamepad.devices.get (gamepadEventInfo.id);
				if (gamepad != null) gamepad.connected = false;
				Gamepad.devices.remove (gamepadEventInfo.id);
				if (gamepad != null) gamepad.onDisconnect.dispatch ();
			
		}
		
	}
	
	
	private function handleJoystickEvent ():Void {
		
		switch (joystickEventInfo.type) {
			
			case AXIS_MOVE:
				
				var joystick = Joystick.devices.get (joystickEventInfo.id);
				if (joystick != null) joystick.onAxisMove.dispatch (joystickEventInfo.index, joystickEventInfo.value);
			
			case HAT_MOVE:
				
				var joystick = Joystick.devices.get (joystickEventInfo.id);
				if (joystick != null) joystick.onHatMove.dispatch (joystickEventInfo.index, joystickEventInfo.x);
			
			case TRACKBALL_MOVE:
				
				var joystick = Joystick.devices.get (joystickEventInfo.id);
				if (joystick != null) joystick.onTrackballMove.dispatch (joystickEventInfo.index, joystickEventInfo.value);
			
			case BUTTON_DOWN:
				
				var joystick = Joystick.devices.get (joystickEventInfo.id);
				if (joystick != null) joystick.onButtonDown.dispatch (joystickEventInfo.index);
			
			case BUTTON_UP:
				
				var joystick = Joystick.devices.get (joystickEventInfo.id);
				if (joystick != null) joystick.onButtonUp.dispatch (joystickEventInfo.index);
			
			case CONNECT:
				
				if (!Joystick.devices.exists (joystickEventInfo.id)) {
					
					var joystick = new Joystick (joystickEventInfo.id);
					Joystick.devices.set (joystickEventInfo.id, joystick);
					Joystick.onConnect.dispatch (joystick);
					
				}
			
			case DISCONNECT:
				
				var joystick = Joystick.devices.get (joystickEventInfo.id);
				if (joystick != null) joystick.connected = false;
				Joystick.devices.remove (joystickEventInfo.id);
				if (joystick != null) joystick.onDisconnect.dispatch ();
			
		}
		
	}
	
	
	private function handleKeyEvent ():Void {
		
		var window = parent.windowByID.get (keyEventInfo.windowID);
		
		if (window != null) {
			
			switch (keyEventInfo.type) {
				
				case KEY_DOWN:
					
					window.onKeyDown.dispatch (keyEventInfo.keyCode, keyEventInfo.modifier);
				
				case KEY_UP:
					
					window.onKeyUp.dispatch (keyEventInfo.keyCode, keyEventInfo.modifier);
				
			}
			
		}
		
	}
	
	
	private function handleMouseEvent ():Void {
		
		var window = parent.windowByID.get (mouseEventInfo.windowID);
		
		if (window != null) {
			
			switch (mouseEventInfo.type) {
				
				case MOUSE_DOWN:
					
					window.onMouseDown.dispatch (mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);
				
				case MOUSE_UP:
					
					window.onMouseUp.dispatch (mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);
				
				case MOUSE_MOVE:
					
					window.onMouseMove.dispatch (mouseEventInfo.x, mouseEventInfo.y);
					window.onMouseMoveRelative.dispatch (mouseEventInfo.movementX, mouseEventInfo.movementY);
				
				case MOUSE_WHEEL:
					
					window.onMouseWheel.dispatch (mouseEventInfo.x, mouseEventInfo.y);
				
				default:
				
			}
			
		}
		
	}
	
	
	private function handleRenderEvent ():Void {
		
		for (renderer in parent.renderers) {
			
			parent.renderer = renderer;
			
			switch (renderEventInfo.type) {
				
				case RENDER:
					
					renderer.render ();
					renderer.onRender.dispatch ();
					renderer.flip ();
					
				case RENDER_CONTEXT_LOST:
					
					if (renderer.backend.useHardware) {
						
						renderer.context = null;
						renderer.onContextLost.dispatch ();
						
					}
				
				case RENDER_CONTEXT_RESTORED:
					
					if (renderer.backend.useHardware) {
						
						#if lime_console
						renderer.context = CONSOLE (new ConsoleRenderContext ());
						#else
						renderer.context = OPENGL (new GLRenderContext ());
						#end
						
						renderer.onContextRestored.dispatch (renderer.context);
						
					}
				
			}
			
		}
		
	}
	
	
	private function handleSensorEvent ():Void {
		
		var sensor = Sensor.sensorByID.get (sensorEventInfo.id);
		
		if (sensor != null) {
			
			sensor.onUpdate.dispatch (sensorEventInfo.x, sensorEventInfo.y, sensorEventInfo.z);
			
		}
		
	}
	
	
	private function handleTextEvent ():Void {
		
		var window = parent.windowByID.get (textEventInfo.windowID);
		
		if (window != null) {
			
			switch (textEventInfo.type) {
				
				case TEXT_INPUT:
					
					window.onTextInput.dispatch (textEventInfo.text);
				
				case TEXT_EDIT:
					
					window.onTextEdit.dispatch (textEventInfo.text, textEventInfo.start, textEventInfo.length);
				
				default:
				
			}
			
		}
		
	}
	
	
	private function handleTouchEvent ():Void {
		
		switch (touchEventInfo.type) {
			
			case TOUCH_START:
				
				var touch = unusedTouchesPool.pop ();
				
				if (touch == null) {
					
					touch = new Touch (touchEventInfo.x, touchEventInfo.y, touchEventInfo.id, touchEventInfo.dx, touchEventInfo.dy, touchEventInfo.pressure, touchEventInfo.device);
					
				} else {
					
					touch.x = touchEventInfo.x;
					touch.y = touchEventInfo.y;
					touch.id = touchEventInfo.id;
					touch.dx = touchEventInfo.dx;
					touch.dy = touchEventInfo.dy;
					touch.pressure = touchEventInfo.pressure;
					touch.device = touchEventInfo.device;
					
				}
				
				currentTouches.set (touch.id, touch);
				
				Touch.onStart.dispatch (touch);
			
			case TOUCH_END:
				
				var touch = currentTouches.get (touchEventInfo.id);
				
				if (touch != null) {
					
					touch.x = touchEventInfo.x;
					touch.y = touchEventInfo.y;
					touch.dx = touchEventInfo.dx;
					touch.dy = touchEventInfo.dy;
					touch.pressure = touchEventInfo.pressure;
					
					Touch.onEnd.dispatch (touch);
					
					currentTouches.remove (touchEventInfo.id);
					unusedTouchesPool.add (touch);
					
				}
			
			case TOUCH_MOVE:
				
				var touch = currentTouches.get (touchEventInfo.id);
				
				if (touch != null) {
					
					touch.x = touchEventInfo.x;
					touch.y = touchEventInfo.y;
					touch.dx = touchEventInfo.dx;
					touch.dy = touchEventInfo.dy;
					touch.pressure = touchEventInfo.pressure;
					
					Touch.onMove.dispatch (touch);
					
				}
			
			default:
			
		}
		
	}
	
	
	private function handleWindowEvent ():Void {
		
		var window = parent.windowByID.get (windowEventInfo.windowID);
		
		if (window != null) {
			
			switch (windowEventInfo.type) {
				
				case WINDOW_ACTIVATE:
					
					window.onActivate.dispatch ();
				
				case WINDOW_CLOSE:
					
					window.onClose.dispatch ();
					window.close ();
				
				case WINDOW_DEACTIVATE:
					
					window.onDeactivate.dispatch ();
				
				case WINDOW_ENTER:
					
					window.onEnter.dispatch ();
				
				case WINDOW_FOCUS_IN:
					
					window.onFocusIn.dispatch ();
				
				case WINDOW_FOCUS_OUT:
					
					window.onFocusOut.dispatch ();
				
				case WINDOW_LEAVE:
					
					window.onLeave.dispatch ();
				
				case WINDOW_MINIMIZE:
					
					window.__minimized = true;
					window.onMinimize.dispatch ();
				
				case WINDOW_MOVE:
					
					window.__x = windowEventInfo.x;
					window.__y = windowEventInfo.y;
					window.onMove.dispatch (windowEventInfo.x, windowEventInfo.y);
				
				case WINDOW_RESIZE:
					
					window.__width = windowEventInfo.width;
					window.__height = windowEventInfo.height;
					window.onResize.dispatch (windowEventInfo.width, windowEventInfo.height);
				
				case WINDOW_RESTORE:
					
					window.__fullscreen = false;
					window.__minimized = false;
					window.onRestore.dispatch ();
				
			}
			
		}
		
	}
	
	
	public function setFrameRate (value:Float):Float {
		
		#if !macro
		lime_application_set_frame_rate (handle, value);
		#end
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
	
	
	#if !macro
	@:cffi private static function lime_application_create (config:Dynamic):Dynamic;
	@:cffi private static function lime_application_event_manager_register (callback:Dynamic, eventObject:Dynamic):Void;
	@:cffi private static function lime_application_exec (handle:Dynamic):Int;
	@:cffi private static function lime_application_init (handle:Dynamic):Void;
	@:cffi private static function lime_application_quit (handle:Dynamic):Int;
	@:cffi private static function lime_application_set_frame_rate (handle:Dynamic, value:Float):Void;
	@:cffi private static function lime_application_update (handle:Dynamic):Bool;
	@:cffi private static function lime_gamepad_event_manager_register (callback:Dynamic, eventObject:Dynamic):Void;
	@:cffi private static function lime_joystick_event_manager_register (callback:Dynamic, eventObject:Dynamic):Void;
	@:cffi private static function lime_key_event_manager_register (callback:Dynamic, eventObject:Dynamic):Void;
	@:cffi private static function lime_mouse_event_manager_register (callback:Dynamic, eventObject:Dynamic):Void;
	@:cffi private static function lime_render_event_manager_register (callback:Dynamic, eventObject:Dynamic):Void;
	@:cffi private static function lime_sensor_event_manager_register (callback:Dynamic, eventObject:Dynamic):Void;
	@:cffi private static function lime_text_event_manager_register (callback:Dynamic, eventObject:Dynamic):Void;
	@:cffi private static function lime_touch_event_manager_register (callback:Dynamic, eventObject:Dynamic):Void;
	@:cffi private static function lime_window_event_manager_register (callback:Dynamic, eventObject:Dynamic):Void;
	#end
	
	
}


private class ApplicationEventInfo {
	
	
	public var deltaTime:Int;
	public var type:ApplicationEventType;
	
	
	public function new (type:ApplicationEventType = null, deltaTime:Int = 0) {
		
		this.type = type;
		this.deltaTime = deltaTime;
		
	}
	
	
	public function clone ():ApplicationEventInfo {
		
		return new ApplicationEventInfo (type, deltaTime);
		
	}
	
	
}


@:enum private abstract ApplicationEventType(Int) {
	
	var UPDATE = 0;
	var EXIT = 1;
	
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


private class JoystickEventInfo {
	
	
	public var id:Int;
	public var index:Int;
	public var type:JoystickEventType;
	public var value:Float;
	public var x:Int;
	public var y:Int;
	
	
	public function new (type:JoystickEventType = null, id:Int = 0, index:Int = 0, value:Float = 0, x:Int = 0, y:Int = 0) {
		
		this.type = type;
		this.id = id;
		this.index = index;
		this.value = value;
		this.x = x;
		this.y = y;
		
	}
	
	
	public function clone ():JoystickEventInfo {
		
		return new JoystickEventInfo (type, id, index, value, x, y);
		
	}
	
	
}


@:enum private abstract JoystickEventType(Int) {
	
	var AXIS_MOVE = 0;
	var HAT_MOVE = 1;
	var TRACKBALL_MOVE = 2;
	var BUTTON_DOWN = 3;
	var BUTTON_UP = 4;
	var CONNECT = 5;
	var DISCONNECT = 6;
	
}


private class KeyEventInfo {
	
	
	public var keyCode:Int;
	public var modifier:Int;
	public var type:KeyEventType;
	public var windowID:Int;
	
	
	public function new (type:KeyEventType = null, windowID:Int = 0, keyCode:Int = 0, modifier:Int = 0) {
		
		this.type = type;
		this.windowID = windowID;
		this.keyCode = keyCode;
		this.modifier = modifier;
		
	}
	
	
	public function clone ():KeyEventInfo {
		
		return new KeyEventInfo (type, windowID, keyCode, modifier);
		
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
	public var windowID:Int;
	public var x:Float;
	public var y:Float;
	
	
	
	public function new (type:MouseEventType = null, windowID:Int = 0, x:Float = 0, y:Float = 0, button:Int = 0, movementX:Float = 0, movementY:Float = 0) {
		
		this.type = type;
		this.windowID = 0;
		this.x = x;
		this.y = y;
		this.button = button;
		this.movementX = movementX;
		this.movementY = movementY;
		
	}
	
	
	public function clone ():MouseEventInfo {
		
		return new MouseEventInfo (type, windowID, x, y, button, movementX, movementY);
		
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


private class SensorEventInfo {
	
	
	public var id:Int;
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var type:SensorEventType;
	
	
	public function new (type:SensorEventType = null, id:Int = 0, x:Float = 0, y:Float = 0, z:Float = 0) {
		
		this.type = type;
		this.id = id;
		this.x = x;
		this.y = y;
		this.z = z;
		
	}
	
	
	public function clone ():SensorEventInfo {
		
		return new SensorEventInfo (type, id, x, y, z);
		
	}
	
	
}


@:enum private abstract SensorEventType(Int) {
	
	var ACCELEROMETER = 0;
	
}


private class TextEventInfo {
	
	
	public var id:Int;
	public var length:Int;
	public var start:Int;
	public var text:String;
	public var type:TextEventType;
	public var windowID:Int;
	
	
	public function new (type:TextEventType = null, windowID:Int = 0, text:String = "", start:Int = 0, length:Int = 0) {
		
		this.type = type;
		this.windowID = windowID;
		this.text = text;
		this.start = start;
		this.length = length;
		
	}
	
	
	public function clone ():TextEventInfo {
		
		return new TextEventInfo (type, windowID, text, start, length);
		
	}
	
	
}


@:enum private abstract TextEventType(Int) {
	
	var TEXT_INPUT = 0;
	var TEXT_EDIT = 1;
	
}


private class TouchEventInfo {
	
	
	public var device:Int;
	public var dx:Float;
	public var dy:Float;
	public var id:Int;
	public var pressure:Float;
	public var type:TouchEventType;
	public var x:Float;
	public var y:Float;
	
	
	public function new (type:TouchEventType = null, x:Float = 0, y:Float = 0, id:Int = 0, dx:Float = 0, dy:Float = 0, pressure:Float = 0, device:Int = 0) {
		
		this.type = type;
		this.x = x;
		this.y = y;
		this.id = id;
		this.dx = dx;
		this.dy = dy;
		this.pressure = pressure;
		this.device = device;
		
	}
	
	
	public function clone ():TouchEventInfo {
		
		return new TouchEventInfo (type, x, y, id, dx, dy, pressure, device);
		
	}
	
	
}


@:enum private abstract TouchEventType(Int) {
	
	var TOUCH_START = 0;
	var TOUCH_END = 1;
	var TOUCH_MOVE = 2;
	
}


private class WindowEventInfo {
	
	
	public var height:Int;
	public var type:WindowEventType;
	public var width:Int;
	public var windowID:Int;
	public var x:Int;
	public var y:Int;
	
	
	public function new (type:WindowEventType = null, windowID:Int = 0, width:Int = 0, height:Int = 0, x:Int = 0, y:Int = 0) {
		
		this.type = type;
		this.windowID = windowID;
		this.width = width;
		this.height = height;
		this.x = x;
		this.y = y;
		
	}
	
	
	public function clone ():WindowEventInfo {
		
		return new WindowEventInfo (type, windowID, width, height, x, y);
		
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
