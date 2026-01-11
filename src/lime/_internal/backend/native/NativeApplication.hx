package lime._internal.backend.native;

import haxe.Timer;
import lime._internal.backend.native.NativeCFFI;
import lime.app.Application;
import lime.graphics.opengl.GL;
import lime.graphics.OpenGLRenderContext;
import lime.graphics.RenderContext;
import lime.math.Rectangle;
import lime.media.AudioManager;
import lime.system.CFFI;
import lime.system.Clipboard;
import lime.system.Display;
import lime.system.DisplayMode;
import lime.system.JNI;
import lime.system.Orientation;
import lime.system.Sensor;
import lime.system.SensorType;
import lime.system.System;
import lime.ui.Gamepad;
import lime.ui.Joystick;
import lime.ui.JoystickHatPosition;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Touch;
import lime.ui.Window;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(haxe.Timer)
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime._internal.backend.native.NativeOpenGLRenderContext)
@:access(lime._internal.backend.native.NativeWindow)
@:access(lime.app.Application)
@:access(lime.graphics.opengl.GL)
@:access(lime.graphics.OpenGLRenderContext)
@:access(lime.graphics.Renderer)
@:access(lime.system.Clipboard)
@:access(lime.system.Sensor)
@:access(lime.ui.Gamepad)
@:access(lime.ui.Joystick)
@:access(lime.ui.Window)
class NativeApplication
{
	private var applicationEventInfo = new ApplicationEventInfo(UPDATE);
	private var clipboardEventInfo = new ClipboardEventInfo();
	private var currentTouches = new Map<Int, Touch>();
	private var dropEventInfo = new DropEventInfo();
	private var gamepadEventInfo = new GamepadEventInfo();
	private var joystickEventInfo = new JoystickEventInfo();
	private var keyEventInfo = new KeyEventInfo();
	private var orientationEventInfo = new OrientationEventInfo();
	private var mouseEventInfo = new MouseEventInfo();
	private var renderEventInfo = new RenderEventInfo(RENDER);
	private var sensorEventInfo = new SensorEventInfo();
	private var textEventInfo = new TextEventInfo();
	private var touchEventInfo = new TouchEventInfo();
	private var unusedTouchesPool = new List<Touch>();
	private var windowEventInfo = new WindowEventInfo();

	public var handle:Dynamic;

	#if android
	private var deviceOrientationListener:OrientationChangeListener;
	#end

	private var pauseTimer:Int;
	private var parent:Application;
	private var toggleFullscreen:Bool;

	private static function __init__()
	{
		#if (lime_cffi && !macro)
		var init = NativeCFFI;
		#end
	}

	public function new(parent:Application):Void
	{
		this.parent = parent;
		pauseTimer = -1;
		toggleFullscreen = true;

		AudioManager.init();

		#if (ios || android || tvos)
		Sensor.registerSensor(SensorType.ACCELEROMETER, 0);
		#end

		#if android
		var setDeviceOrientationListener = JNI.createStaticMethod("org/haxe/lime/GameActivity", "setDeviceOrientationListener",
			"(Lorg/haxe/lime/HaxeObject;)V");
		deviceOrientationListener = new OrientationChangeListener(handleJNIOrientationEvent);
		setDeviceOrientationListener(deviceOrientationListener);
		#end

		#if (!macro && lime_cffi)
		handle = NativeCFFI.lime_application_create();
		#end
	}

	private function advanceTimer():Void
	{
		#if (lime_cffi && !macro)
		if (pauseTimer > -1)
		{
			var offset = System.getTimer() - pauseTimer;
			for (timer in Timer.sRunningTimers)
			{
				if (timer.mRunning) timer.mFireAt += offset;
			}
			pauseTimer = -1;
		}
		#end
	}

	public function exec():Int
	{
		#if !macro
		#if lime_cffi
		NativeCFFI.lime_application_event_manager_register(handleApplicationEvent, applicationEventInfo);
		NativeCFFI.lime_clipboard_event_manager_register(handleClipboardEvent, clipboardEventInfo);
		NativeCFFI.lime_drop_event_manager_register(handleDropEvent, dropEventInfo);
		NativeCFFI.lime_gamepad_event_manager_register(handleGamepadEvent, gamepadEventInfo);
		NativeCFFI.lime_joystick_event_manager_register(handleJoystickEvent, joystickEventInfo);
		NativeCFFI.lime_key_event_manager_register(handleKeyEvent, keyEventInfo);
		NativeCFFI.lime_mouse_event_manager_register(handleMouseEvent, mouseEventInfo);
		NativeCFFI.lime_render_event_manager_register(handleRenderEvent, renderEventInfo);
		NativeCFFI.lime_text_event_manager_register(handleTextEvent, textEventInfo);
		NativeCFFI.lime_touch_event_manager_register(handleTouchEvent, touchEventInfo);
		NativeCFFI.lime_window_event_manager_register(handleWindowEvent, windowEventInfo);
		#if (ios || android)
		NativeCFFI.lime_orientation_event_manager_register(handleOrientationEvent, orientationEventInfo);
		#end
		#if (ios || android || tvos)
		NativeCFFI.lime_sensor_event_manager_register(handleSensorEvent, sensorEventInfo);
		#end
		#end

		#if (nodejs && lime_cffi)
		NativeCFFI.lime_application_init(handle);

		var eventLoop = function()
		{
			var active = NativeCFFI.lime_application_update(handle);

			if (!active)
			{
				untyped process.exitCode = NativeCFFI.lime_application_quit(handle);
				parent.onExit.dispatch(untyped process.exitCode);
			}
			else
			{
				untyped setImmediate(eventLoop);
			}
		}

		untyped setImmediate(eventLoop);
		return 0;
		#elseif lime_cffi
		var result = NativeCFFI.lime_application_exec(handle);

		#if (!webassembly && !ios && !nodejs)
		parent.onExit.dispatch(result);
		#end

		return result;
		#end
		#end

		return 0;
	}

	public function exit():Void
	{
		AudioManager.shutdown();

		#if (!macro && lime_cffi)
		NativeCFFI.lime_application_quit(handle);
		#end
	}

	public function getDeviceOrientation():Orientation
	{
		#if (!macro && lime_cffi)
		return cast NativeCFFI.lime_system_get_device_orientation();
		#else
		return UNKNOWN;
		#end
	}

	private function handleApplicationEvent():Void
	{
		switch (applicationEventInfo.type)
		{
			case UPDATE:
				updateTimer();

				parent.onUpdate.dispatch(applicationEventInfo.deltaTime);

			default:
		}
	}

	private function handleClipboardEvent():Void
	{
		Clipboard.__update();
	}

	private function handleDropEvent():Void
	{
		for (window in parent.windows)
		{
			window.onDropFile.dispatch(CFFI.stringValue(dropEventInfo.file));
		}
	}

	private function handleGamepadEvent():Void
	{
		switch (gamepadEventInfo.type)
		{
			case AXIS_MOVE:
				var gamepad = Gamepad.devices.get(gamepadEventInfo.id);
				if (gamepad != null) gamepad.onAxisMove.dispatch(gamepadEventInfo.axis, gamepadEventInfo.axisValue);

			case BUTTON_DOWN:
				var gamepad = Gamepad.devices.get(gamepadEventInfo.id);
				if (gamepad != null) gamepad.onButtonDown.dispatch(gamepadEventInfo.button);

			case BUTTON_UP:
				var gamepad = Gamepad.devices.get(gamepadEventInfo.id);
				if (gamepad != null) gamepad.onButtonUp.dispatch(gamepadEventInfo.button);

			case CONNECT:
				Gamepad.__connect(gamepadEventInfo.id);

			case DISCONNECT:
				Gamepad.__disconnect(gamepadEventInfo.id);
		}
	}

	private function handleJoystickEvent():Void
	{
		switch (joystickEventInfo.type)
		{
			case AXIS_MOVE:
				var joystick = Joystick.devices.get(joystickEventInfo.id);
				if (joystick != null) joystick.onAxisMove.dispatch(joystickEventInfo.index, joystickEventInfo.x);

			case HAT_MOVE:
				var joystick = Joystick.devices.get(joystickEventInfo.id);
				if (joystick != null) joystick.onHatMove.dispatch(joystickEventInfo.index, joystickEventInfo.eventValue);

			case BUTTON_DOWN:
				var joystick = Joystick.devices.get(joystickEventInfo.id);
				if (joystick != null) joystick.onButtonDown.dispatch(joystickEventInfo.index);

			case BUTTON_UP:
				var joystick = Joystick.devices.get(joystickEventInfo.id);
				if (joystick != null) joystick.onButtonUp.dispatch(joystickEventInfo.index);

			case CONNECT:
				Joystick.__connect(joystickEventInfo.id);

			case DISCONNECT:
				Joystick.__disconnect(joystickEventInfo.id);
		}
	}

	private function handleKeyEvent():Void
	{
		var window = parent.__windowByID.get(keyEventInfo.windowID);

		if (window != null)
		{
			var type:KeyEventType = keyEventInfo.type;
			var int32:Float = keyEventInfo.keyCode;
			var keyCode:KeyCode = Std.int(int32);
			var modifier:KeyModifier = keyEventInfo.modifier;

			switch (type)
			{
				case KEY_DOWN:
					window.onKeyDown.dispatch(keyCode, modifier);

				case KEY_UP:
					window.onKeyUp.dispatch(keyCode, modifier);
			}

			#if (windows || linux)
			if (keyCode == RETURN)
			{
				if (type == KEY_DOWN)
				{
					if (toggleFullscreen && modifier.altKey && (!modifier.ctrlKey && !modifier.shiftKey && !modifier.metaKey))
					{
						toggleFullscreen = false;

						if (!window.onKeyDown.canceled)
						{
							window.fullscreen = !window.fullscreen;
						}
					}
				}
				else
				{
					toggleFullscreen = true;
				}
			}

			#if rpi
			if (keyCode == ESCAPE && modifier.ctrlKey && type == KEY_DOWN)
			{
				System.exit(0);
			}
			#end
			#elseif mac
			if (keyCode == F)
			{
				if (type == KEY_DOWN)
				{
					if (toggleFullscreen && (modifier.ctrlKey && modifier.metaKey) && (!modifier.altKey && !modifier.shiftKey))
					{
						toggleFullscreen = false;

						if (!window.onKeyDown.canceled)
						{
							window.fullscreen = !window.fullscreen;
						}
					}
				}
				else
				{
					toggleFullscreen = true;
				}
			}
			#elseif android
			if (keyCode == APP_CONTROL_BACK && modifier == KeyModifier.NONE && type == KEY_UP && !window.onKeyUp.canceled)
			{
				var mainActivity = JNI.createStaticField("org/haxe/extension/Extension", "mainActivity", "Landroid/app/Activity;");
				var moveTaskToBack = JNI.createMemberMethod("android/app/Activity", "moveTaskToBack", "(Z)Z");

				moveTaskToBack(mainActivity.get(), true);
			}
			#end
		}
	}

	private function handleMouseEvent():Void
	{
		var window = parent.__windowByID.get(mouseEventInfo.windowID);

		if (window != null)
		{
			switch (mouseEventInfo.type)
			{
				case MOUSE_DOWN:
					window.clickCount = mouseEventInfo.clickCount;
					window.onMouseDown.dispatch(mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);
					window.clickCount = 0;

				case MOUSE_UP:
					window.clickCount = mouseEventInfo.clickCount;
					window.onMouseUp.dispatch(mouseEventInfo.x, mouseEventInfo.y, mouseEventInfo.button);
					window.clickCount = 0;

				case MOUSE_MOVE:
					window.onMouseMove.dispatch(mouseEventInfo.x, mouseEventInfo.y);
					window.onMouseMoveRelative.dispatch(mouseEventInfo.movementX, mouseEventInfo.movementY);

				case MOUSE_WHEEL:
					window.onMouseWheel.dispatch(mouseEventInfo.x, mouseEventInfo.y, UNKNOWN);

				default:
			}
		}
	}

	private function handleOrientationEvent():Void
	{
		var orientation:Orientation = cast orientationEventInfo.orientation;
		var display = orientationEventInfo.display;
		switch (orientationEventInfo.type)
		{
			case DISPLAY_ORIENTATION_CHANGE:
				parent.onDisplayOrientationChange.dispatch(display, orientation);
			case DEVICE_ORIENTATION_CHANGE:
				parent.onDeviceOrientationChange.dispatch(orientation);
		}
	}

	#if android
	private function handleJNIOrientationEvent(newOrientation:Int):Void
	{
		var orientation:Orientation = cast newOrientation;
		parent.onDeviceOrientationChange.dispatch(orientation);
	}
	#end

	private function handleRenderEvent():Void
	{
		// TODO: Allow windows to render independently

		for (window in parent.__windows)
		{
			if (window == null) continue;

			// parent.renderer = renderer;

			switch (renderEventInfo.type)
			{
				case RENDER:
					if (window.context != null)
					{
						window.__backend.render();
						window.onRender.dispatch(window.context);

						if (!window.onRender.canceled)
						{
							window.__backend.contextFlip();
						}
					}

				case RENDER_CONTEXT_LOST:
					if (window.__backend.useHardware && window.context != null)
					{
						switch (window.context.type)
						{
							case OPENGL, OPENGLES, WEBGL:
								#if (lime_cffi && (lime_opengl || lime_opengles) && !display)
								var gl = window.context.gl;
								(gl : NativeOpenGLRenderContext).__contextLost();
								if (GL.context == gl) GL.context = null;
								#end

							default:
						}

						window.context = null;
						window.onRenderContextLost.dispatch();
					}

				case RENDER_CONTEXT_RESTORED:
					if (window.__backend.useHardware)
					{
						// GL.context = new OpenGLRenderContext ();
						// window.context.gl = GL.context;

						window.onRenderContextRestored.dispatch(window.context);
					}
			}
		}
	}

	private function handleSensorEvent():Void
	{
		var sensor = Sensor.sensorByID.get(sensorEventInfo.id);

		if (sensor != null)
		{
			sensor.onUpdate.dispatch(sensorEventInfo.x, sensorEventInfo.y, sensorEventInfo.z);
		}
	}

	private function handleTextEvent():Void
	{
		var window = parent.__windowByID.get(textEventInfo.windowID);

		if (window != null)
		{
			switch (textEventInfo.type)
			{
				case TEXT_INPUT:
					window.onTextInput.dispatch(CFFI.stringValue(textEventInfo.text));

				case TEXT_EDIT:
					window.onTextEdit.dispatch(CFFI.stringValue(textEventInfo.text), textEventInfo.start, textEventInfo.length);

				default:
			}
		}
	}

	private function handleTouchEvent():Void
	{
		switch (touchEventInfo.type)
		{
			case TOUCH_START:
				var touch = unusedTouchesPool.pop();

				if (touch == null)
				{
					touch = new Touch(touchEventInfo.x, touchEventInfo.y, touchEventInfo.id, touchEventInfo.dx, touchEventInfo.dy, touchEventInfo.pressure,
						touchEventInfo.device);
				}
				else
				{
					touch.x = touchEventInfo.x;
					touch.y = touchEventInfo.y;
					touch.id = touchEventInfo.id;
					touch.dx = touchEventInfo.dx;
					touch.dy = touchEventInfo.dy;
					touch.pressure = touchEventInfo.pressure;
					touch.device = touchEventInfo.device;
				}

				currentTouches.set(touch.id, touch);

				Touch.onStart.dispatch(touch);

			case TOUCH_END:
				var touch = currentTouches.get(touchEventInfo.id);

				if (touch != null)
				{
					touch.x = touchEventInfo.x;
					touch.y = touchEventInfo.y;
					touch.dx = touchEventInfo.dx;
					touch.dy = touchEventInfo.dy;
					touch.pressure = touchEventInfo.pressure;

					Touch.onEnd.dispatch(touch);

					currentTouches.remove(touchEventInfo.id);
					unusedTouchesPool.add(touch);
				}

			case TOUCH_MOVE:
				var touch = currentTouches.get(touchEventInfo.id);

				if (touch != null)
				{
					touch.x = touchEventInfo.x;
					touch.y = touchEventInfo.y;
					touch.dx = touchEventInfo.dx;
					touch.dy = touchEventInfo.dy;
					touch.pressure = touchEventInfo.pressure;

					Touch.onMove.dispatch(touch);
				}

			default:
		}
	}

	private function handleWindowEvent():Void
	{
		var window = parent.__windowByID.get(windowEventInfo.windowID);

		if (window != null)
		{
			switch (windowEventInfo.type)
			{
				case WINDOW_ACTIVATE:
					advanceTimer();
					window.onActivate.dispatch();
					AudioManager.resume();

				case WINDOW_CLOSE:
					window.close();

				case WINDOW_DEACTIVATE:
					window.onDeactivate.dispatch();
					AudioManager.suspend();
					pauseTimer = System.getTimer();

				case WINDOW_ENTER:
					window.onEnter.dispatch();

				case WINDOW_EXPOSE:
					window.onExpose.dispatch();

				case WINDOW_FOCUS_IN:
					window.onFocusIn.dispatch();

				case WINDOW_FOCUS_OUT:
					window.onFocusOut.dispatch();

				case WINDOW_LEAVE:
					window.onLeave.dispatch();

				case WINDOW_MAXIMIZE:
					window.__maximized = true;
					window.__fullscreen = false;
					window.__minimized = false;
					window.onMaximize.dispatch();

				case WINDOW_MINIMIZE:
					window.__minimized = true;
					window.__maximized = false;
					window.__fullscreen = false;
					window.onMinimize.dispatch();

				case WINDOW_MOVE:
					window.__x = windowEventInfo.x;
					window.__y = windowEventInfo.y;
					window.onMove.dispatch(windowEventInfo.x, windowEventInfo.y);

				case WINDOW_RESIZE:
					window.__width = windowEventInfo.width;
					window.__height = windowEventInfo.height;
					window.onResize.dispatch(windowEventInfo.width, windowEventInfo.height);

				case WINDOW_RESTORE:
					window.__fullscreen = false;
					window.__minimized = false;
					window.onRestore.dispatch();

				case WINDOW_SHOW:
					window.onShow.dispatch();

				case WINDOW_HIDE:
					window.onHide.dispatch();
			}
		}
	}

	private function updateTimer():Void
	{
		#if (lime_cffi && !macro)
		if (Timer.sRunningTimers.length > 0)
		{
			var currentTime = System.getTimer();
			var foundStopped = false;

			for (timer in Timer.sRunningTimers)
			{
				if (timer.mRunning)
				{
					if (currentTime >= timer.mFireAt)
					{
						timer.mFireAt += timer.mTime;
						timer.run();
					}
				}
				else
				{
					foundStopped = true;
				}
			}

			if (foundStopped)
			{
				Timer.sRunningTimers = Timer.sRunningTimers.filter(function(val)
				{
					return val.mRunning;
				});
			}
		}

		#if (haxe_ver >= 4.2)
		#if target.threaded
		sys.thread.Thread.current().events.progress();
		#else
		// Duplicate code required because Haxe 3 can't handle
		// #if (haxe_ver >= 4.2 && target.threaded)
		@:privateAccess haxe.EntryPoint.processEvents();
		#end
		#else
		@:privateAccess haxe.EntryPoint.processEvents();
		#end
		#end
	}
}

@:keep /*private*/ class ApplicationEventInfo
{
	public var deltaTime:Int;
	public var type:ApplicationEventType;

	public function new(type:ApplicationEventType = null, deltaTime:Int = 0)
	{
		this.type = type;
		this.deltaTime = deltaTime;
	}

	public function clone():ApplicationEventInfo
	{
		return new ApplicationEventInfo(type, deltaTime);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract ApplicationEventType(Int)
{
	var UPDATE = 0;
	var EXIT = 1;
}

@:keep /*private*/ class ClipboardEventInfo
{
	public var type:ClipboardEventType;

	public function new(type:ClipboardEventType = null)
	{
		this.type = type;
	}

	public function clone():ClipboardEventInfo
	{
		return new ClipboardEventInfo(type);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract ClipboardEventType(Int)
{
	var UPDATE = 0;
}

@:keep /*private*/ class DropEventInfo
{
	public var file:#if hl hl.Bytes #else String #end;
	public var type:DropEventType;

	public function new(type:DropEventType = null, file = null)
	{
		this.type = type;
		this.file = file;
	}

	public function clone():DropEventInfo
	{
		return new DropEventInfo(type, file);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract DropEventType(Int)
{
	var DROP_FILE = 0;
}

@:keep /*private*/ class GamepadEventInfo
{
	public var axis:Int;
	public var button:Int;
	public var id:Int;
	public var type:GamepadEventType;
	public var axisValue:Float;

	public function new(type:GamepadEventType = null, id:Int = 0, button:Int = 0, axis:Int = 0, value:Float = 0)
	{
		this.type = type;
		this.id = id;
		this.button = button;
		this.axis = axis;
		this.axisValue = value;
	}

	public function clone():GamepadEventInfo
	{
		return new GamepadEventInfo(type, id, button, axis, axisValue);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract GamepadEventType(Int)
{
	var AXIS_MOVE = 0;
	var BUTTON_DOWN = 1;
	var BUTTON_UP = 2;
	var CONNECT = 3;
	var DISCONNECT = 4;
}

@:keep /*private*/ class JoystickEventInfo
{
	public var id:Int;
	public var index:Int;
	public var type:JoystickEventType;
	public var eventValue:Int;
	public var x:Float;
	public var y:Float;

	public function new(type:JoystickEventType = null, id:Int = 0, index:Int = 0, value:Int = 0, x:Float = 0, y:Float = 0)
	{
		this.type = type;
		this.id = id;
		this.index = index;
		this.eventValue = value;
		this.x = x;
		this.y = y;
	}

	public function clone():JoystickEventInfo
	{
		return new JoystickEventInfo(type, id, index, eventValue, x, y);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract JoystickEventType(Int)
{
	var AXIS_MOVE = 0;
	var HAT_MOVE = 1;
	var BUTTON_DOWN = 3;
	var BUTTON_UP = 4;
	var CONNECT = 5;
	var DISCONNECT = 6;
}

@:keep /*private*/ class KeyEventInfo
{
	public var keyCode:Float;
	public var modifier:Int;
	public var type:KeyEventType;
	public var windowID:Int;

	public function new(type:KeyEventType = null, windowID:Int = 0, keyCode:Float = 0, modifier:Int = 0)
	{
		this.type = type;
		this.windowID = windowID;
		this.keyCode = keyCode;
		this.modifier = modifier;
	}

	public function clone():KeyEventInfo
	{
		return new KeyEventInfo(type, windowID, keyCode, modifier);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract KeyEventType(Int)
{
	var KEY_DOWN = 0;
	var KEY_UP = 1;
}

@:keep /*private*/ class MouseEventInfo
{
	public var button:Int;
	public var movementX:Float;
	public var movementY:Float;
	public var type:MouseEventType;
	public var windowID:Int;
	public var x:Float;
	public var y:Float;
	public var clickCount:Int;

	public function new(type:MouseEventType = null, windowID:Int = 0, x:Float = 0, y:Float = 0, button:Int = 0, movementX:Float = 0, movementY:Float = 0,
			clickCount:Int = 0)
	{
		this.type = type;
		this.windowID = 0;
		this.x = x;
		this.y = y;
		this.button = button;
		this.movementX = movementX;
		this.movementY = movementY;
		this.clickCount = clickCount;
	}

	public function clone():MouseEventInfo
	{
		return new MouseEventInfo(type, windowID, x, y, button, movementX, movementY, clickCount);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract MouseEventType(Int)
{
	var MOUSE_DOWN = 0;
	var MOUSE_UP = 1;
	var MOUSE_MOVE = 2;
	var MOUSE_WHEEL = 3;
}

@:keep /*private*/ class RenderEventInfo
{
	public var type:RenderEventType;

	public function new(type:RenderEventType = null)
	{
		this.type = type;
	}

	public function clone():RenderEventInfo
	{
		return new RenderEventInfo(type);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract RenderEventType(Int)
{
	var RENDER = 0;
	var RENDER_CONTEXT_LOST = 1;
	var RENDER_CONTEXT_RESTORED = 2;
}

@:keep /*private*/ class SensorEventInfo
{
	public var id:Int;
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var type:SensorEventType;

	public function new(type:SensorEventType = null, id:Int = 0, x:Float = 0, y:Float = 0, z:Float = 0)
	{
		this.type = type;
		this.id = id;
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public function clone():SensorEventInfo
	{
		return new SensorEventInfo(type, id, x, y, z);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract SensorEventType(Int)
{
	var ACCELEROMETER = 0;
}

@:keep /*private*/ class TextEventInfo
{
	public var id:Int;
	public var length:Int;
	public var start:Int;
	public var text:#if hl hl.Bytes #else String #end;
	public var type:TextEventType;
	public var windowID:Int;

	public function new(type:TextEventType = null, windowID:Int = 0, text = null, start:Int = 0, length:Int = 0)
	{
		this.type = type;
		this.windowID = windowID;
		this.text = text;
		this.start = start;
		this.length = length;
	}

	public function clone():TextEventInfo
	{
		return new TextEventInfo(type, windowID, text, start, length);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract TextEventType(Int)
{
	var TEXT_INPUT = 0;
	var TEXT_EDIT = 1;
}

@:keep /*private*/ class TouchEventInfo
{
	public var device:Int;
	public var dx:Float;
	public var dy:Float;
	public var id:Int;
	public var pressure:Float;
	public var type:TouchEventType;
	public var x:Float;
	public var y:Float;

	public function new(type:TouchEventType = null, x:Float = 0, y:Float = 0, id:Int = 0, dx:Float = 0, dy:Float = 0, pressure:Float = 0, device:Int = 0)
	{
		this.type = type;
		this.x = x;
		this.y = y;
		this.id = id;
		this.dx = dx;
		this.dy = dy;
		this.pressure = pressure;
		this.device = device;
	}

	public function clone():TouchEventInfo
	{
		return new TouchEventInfo(type, x, y, id, dx, dy, pressure, device);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract TouchEventType(Int)
{
	var TOUCH_START = 0;
	var TOUCH_END = 1;
	var TOUCH_MOVE = 2;
}

@:keep /*private*/ class WindowEventInfo
{
	public var height:Int;
	public var type:WindowEventType;
	public var width:Int;
	public var windowID:Int;
	public var x:Int;
	public var y:Int;

	public function new(type:WindowEventType = null, windowID:Int = 0, width:Int = 0, height:Int = 0, x:Int = 0, y:Int = 0)
	{
		this.type = type;
		this.windowID = windowID;
		this.width = width;
		this.height = height;
		this.x = x;
		this.y = y;
	}

	public function clone():WindowEventInfo
	{
		return new WindowEventInfo(type, windowID, width, height, x, y);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract WindowEventType(Int)
{
	var WINDOW_ACTIVATE = 0;
	var WINDOW_CLOSE = 1;
	var WINDOW_DEACTIVATE = 2;
	var WINDOW_ENTER = 3;
	var WINDOW_EXPOSE = 4;
	var WINDOW_FOCUS_IN = 5;
	var WINDOW_FOCUS_OUT = 6;
	var WINDOW_LEAVE = 7;
	var WINDOW_MAXIMIZE = 8;
	var WINDOW_MINIMIZE = 9;
	var WINDOW_MOVE = 10;
	var WINDOW_RESIZE = 11;
	var WINDOW_RESTORE = 12;
	var WINDOW_SHOW = 13;
	var WINDOW_HIDE = 14;
}

@:keep /*private*/ class OrientationEventInfo
{
	public var orientation:Int;
	public var display:Int;
	public var type:OrientationEventType;

	public function new(type:OrientationEventType = null, orientation:Int = 0, display:Int = -1)
	{
		this.type = type;
		this.orientation = orientation;
		this.display = display;
	}

	public function clone():OrientationEventInfo
	{
		return new OrientationEventInfo(type, orientation, display);
	}
}

#if (haxe_ver >= 4.0) private enum #else @:enum private #end abstract OrientationEventType(Int)
{
	var DISPLAY_ORIENTATION_CHANGE = 0;
	var DEVICE_ORIENTATION_CHANGE = 1;
}

#if android
@:keep
private class OrientationChangeListener implements JNISafety
{
	private var callback:Int->Void;

	public function new(callback:Int->Void)
	{
		this.callback = callback;
	}

	@:runOnMainThread
	public function onOrientationChanged(orientation:Int):Void
	{
		callback(orientation);
	}
}
#end
