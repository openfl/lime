package lime._internal.backend.html5;

import js.html.DeviceMotionEvent;
import js.html.KeyboardEvent;
import js.Browser;
import lime.app.Application;
import lime.media.AudioManager;
import lime.system.Sensor;
import lime.system.SensorType;
import lime.ui.GamepadAxis;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Gamepad;
import lime.ui.GamepadButton;
import lime.ui.Joystick;
import lime.ui.Window;

@:access(lime._internal.backend.html5.HTML5Window)
@:access(lime.app.Application)
@:access(lime.system.Sensor)
@:access(lime.ui.Gamepad)
@:access(lime.ui.Joystick)
@:access(lime.ui.Window)
class HTML5Application
{
	private var accelerometer:Sensor;
	private var currentUpdate:Float;
	private var deltaTime:Float;
	private var framePeriod:Float;
	private var gameDeviceCache = new Map<Int, GameDeviceData>();
	private var hidden:Bool;
	private var lastUpdate:Float;
	private var nextUpdate:Float;
	private var parent:Application;
	#if stats
	private var stats:Dynamic;
	#end

	public inline function new(parent:Application)
	{
		this.parent = parent;

		currentUpdate = 0;
		lastUpdate = 0;
		nextUpdate = 0;
		framePeriod = -1;

		AudioManager.init();
		accelerometer = Sensor.registerSensor(SensorType.ACCELEROMETER, 0);
	}

	private function convertKeyCode(keyCode:Int):KeyCode
	{
		if (keyCode >= 65 && keyCode <= 90)
		{
			return keyCode + 32;
		}

		switch (keyCode)
		{
			case 12:
				return KeyCode.CLEAR;
			case 16:
				return KeyCode.LEFT_SHIFT;
			case 17:
				return KeyCode.LEFT_CTRL;
			case 18:
				return KeyCode.LEFT_ALT;
			case 19:
				return KeyCode.PAUSE;
			case 20:
				return KeyCode.CAPS_LOCK;
			case 33:
				return KeyCode.PAGE_UP;
			case 34:
				return KeyCode.PAGE_DOWN;
			case 35:
				return KeyCode.END;
			case 36:
				return KeyCode.HOME;
			case 37:
				return KeyCode.LEFT;
			case 38:
				return KeyCode.UP;
			case 39:
				return KeyCode.RIGHT;
			case 40:
				return KeyCode.DOWN;
			case 41:
				return KeyCode.SELECT;
			case 43:
				return KeyCode.EXECUTE;
			case 44:
				return KeyCode.PRINT_SCREEN;
			case 45:
				return KeyCode.INSERT;
			case 46:
				return KeyCode.DELETE;
			case 91:
				return KeyCode.LEFT_META;
			case 92:
				return KeyCode.RIGHT_META;
			case 93:
				return KeyCode.RIGHT_META; // this maybe should be APPLICATION if on Windows
			case 95:
				return KeyCode.SLEEP;
			case 96:
				return KeyCode.NUMPAD_0;
			case 97:
				return KeyCode.NUMPAD_1;
			case 98:
				return KeyCode.NUMPAD_2;
			case 99:
				return KeyCode.NUMPAD_3;
			case 100:
				return KeyCode.NUMPAD_4;
			case 101:
				return KeyCode.NUMPAD_5;
			case 102:
				return KeyCode.NUMPAD_6;
			case 103:
				return KeyCode.NUMPAD_7;
			case 104:
				return KeyCode.NUMPAD_8;
			case 105:
				return KeyCode.NUMPAD_9;
			case 106:
				return KeyCode.NUMPAD_MULTIPLY;
			case 107:
				return KeyCode.NUMPAD_PLUS;
			case 108:
				return KeyCode.NUMPAD_PERIOD;
			case 109:
				return KeyCode.NUMPAD_MINUS;
			case 110:
				return KeyCode.NUMPAD_PERIOD;
			case 111:
				return KeyCode.NUMPAD_DIVIDE;
			case 112:
				return KeyCode.F1;
			case 113:
				return KeyCode.F2;
			case 114:
				return KeyCode.F3;
			case 115:
				return KeyCode.F4;
			case 116:
				return KeyCode.F5;
			case 117:
				return KeyCode.F6;
			case 118:
				return KeyCode.F7;
			case 119:
				return KeyCode.F8;
			case 120:
				return KeyCode.F9;
			case 121:
				return KeyCode.F10;
			case 122:
				return KeyCode.F11;
			case 123:
				return KeyCode.F12;
			case 124:
				return KeyCode.F13;
			case 125:
				return KeyCode.F14;
			case 126:
				return KeyCode.F15;
			case 127:
				return KeyCode.F16;
			case 128:
				return KeyCode.F17;
			case 129:
				return KeyCode.F18;
			case 130:
				return KeyCode.F19;
			case 131:
				return KeyCode.F20;
			case 132:
				return KeyCode.F21;
			case 133:
				return KeyCode.F22;
			case 134:
				return KeyCode.F23;
			case 135:
				return KeyCode.F24;
			case 144:
				return KeyCode.NUM_LOCK;
			case 145:
				return KeyCode.SCROLL_LOCK;
			case 160:
				return KeyCode.CARET;
			case 161:
				return KeyCode.EXCLAMATION;
			case 163:
				return KeyCode.HASH;
			case 164:
				return KeyCode.DOLLAR;
			case 166:
				return KeyCode.APP_CONTROL_BACK;
			case 167:
				return KeyCode.APP_CONTROL_FORWARD;
			case 168:
				return KeyCode.APP_CONTROL_REFRESH;
			case 169:
				return KeyCode.RIGHT_PARENTHESIS; // is this correct?
			case 170:
				return KeyCode.ASTERISK;
			case 171:
				return KeyCode.GRAVE;
			case 172:
				return KeyCode.HOME;
			case 173:
				return KeyCode.MINUS; // or mute/unmute?
			case 174:
				return KeyCode.VOLUME_DOWN;
			case 175:
				return KeyCode.VOLUME_UP;
			case 176:
				return KeyCode.AUDIO_NEXT;
			case 177:
				return KeyCode.AUDIO_PREVIOUS;
			case 178:
				return KeyCode.AUDIO_STOP;
			case 179:
				return KeyCode.AUDIO_PLAY;
			case 180:
				return KeyCode.MAIL;
			case 181:
				return KeyCode.AUDIO_MUTE;
			case 182:
				return KeyCode.VOLUME_DOWN;
			case 183:
				return KeyCode.VOLUME_UP;
			case 186:
				return KeyCode.SEMICOLON; // or ñ?
			case 187:
				return KeyCode.EQUALS;
			case 188:
				return KeyCode.COMMA;
			case 189:
				return KeyCode.MINUS;
			case 190:
				return KeyCode.PERIOD;
			case 191:
				return KeyCode.SLASH;
			case 192:
				return KeyCode.GRAVE;
			case 193:
				return KeyCode.QUESTION;
			case 194:
				return KeyCode.NUMPAD_PERIOD;
			case 219:
				return KeyCode.LEFT_BRACKET;
			case 220:
				return KeyCode.BACKSLASH;
			case 221:
				return KeyCode.RIGHT_BRACKET;
			case 222:
				return KeyCode.SINGLE_QUOTE;
			case 223:
				return KeyCode.GRAVE;
			case 224:
				return KeyCode.LEFT_META;
			case 226:
				return KeyCode.BACKSLASH;
		}

		return keyCode;
	}

	public function exec():Int
	{
		Browser.window.addEventListener("keydown", handleKeyEvent, false);
		Browser.window.addEventListener("keyup", handleKeyEvent, false);
		Browser.window.addEventListener("focus", handleWindowEvent, false);
		Browser.window.addEventListener("blur", handleWindowEvent, false);
		Browser.window.addEventListener("resize", handleWindowEvent, false);
		Browser.window.addEventListener("beforeunload", handleWindowEvent, false);
		Browser.window.addEventListener("devicemotion", handleSensorEvent, false);

		#if stats
		stats = untyped #if haxe4 js.Syntax.code #else __js__ #end ("new Stats ()");
		stats.domElement.style.position = "absolute";
		stats.domElement.style.top = "0px";
		Browser.document.body.appendChild(stats.domElement);
		#end

		untyped #if haxe4 js.Syntax.code #else __js__ #end ("
			if (!CanvasRenderingContext2D.prototype.isPointInStroke) {
				CanvasRenderingContext2D.prototype.isPointInStroke = function (path, x, y) {
					return false;
				};
			}
			if (!CanvasRenderingContext2D.prototype.isPointInPath) {
				CanvasRenderingContext2D.prototype.isPointInPath = function (path, x, y) {
					return false;
				};
			}

			if ('performance' in window == false) {
				window.performance = {};
			}

			if ('now' in window.performance == false) {
				var offset = Date.now();
				if (performance.timing && performance.timing.navigationStart) {
					offset = performance.timing.navigationStart
				}
				window.performance.now = function now() {
					return Date.now() - offset;
				}
			}

			var lastTime = 0;
			var vendors = ['ms', 'moz', 'webkit', 'o'];
			for (var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
				window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
				window.cancelAnimationFrame = window[vendors[x]+'CancelAnimationFrame'] || window[vendors[x]+'CancelRequestAnimationFrame'];
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

		lastUpdate = Date.now().getTime();

		handleApplicationEvent();

		return 0;
	}

	public function exit():Void {}

	private function handleApplicationEvent(?__):Void
	{
		// TODO: Support independent window frame rates

		for (window in parent.__windows)
		{
			window.__backend.updateSize();
		}

		updateGameDevices();

		currentUpdate = Date.now().getTime();

		if (currentUpdate >= nextUpdate)
		{
			#if stats
			stats.begin();
			#end

			deltaTime = currentUpdate - lastUpdate;

			for (window in parent.__windows)
			{
				parent.onUpdate.dispatch(Std.int(deltaTime));
				if (window.context != null) window.onRender.dispatch(window.context);
			}

			#if stats
			stats.end();
			#end

			if (framePeriod < 0)
			{
				nextUpdate = currentUpdate;
			}
			else
			{
				nextUpdate = currentUpdate - (currentUpdate % framePeriod) + framePeriod;
			}

			lastUpdate = currentUpdate;
		}

		Browser.window.requestAnimationFrame(cast handleApplicationEvent);
	}

	private function handleKeyEvent(event:KeyboardEvent):Void
	{
		if (parent.window != null)
		{
			// space and arrow keys

			// switch (event.keyCode) {

			// 	case 32, 37, 38, 39, 40: event.preventDefault ();

			// }

			// TODO: Use event.key instead where supported

			var keyCode = cast convertKeyCode(event.keyCode != null ? event.keyCode : event.which);
			var modifier = (event.shiftKey ? (KeyModifier.SHIFT) : 0) | (event.ctrlKey ? (KeyModifier.CTRL) : 0) | (event.altKey ? (KeyModifier.ALT) : 0) | (event.metaKey ? (KeyModifier.META) : 0);

			if (event.type == "keydown")
			{
				parent.window.onKeyDown.dispatch(keyCode, modifier);

				if (parent.window.onKeyDown.canceled && event.cancelable)
				{
					event.preventDefault();
				}
			}
			else
			{
				parent.window.onKeyUp.dispatch(keyCode, modifier);

				if (parent.window.onKeyUp.canceled && event.cancelable)
				{
					event.preventDefault();
				}
			}
		}
	}

	private function handleSensorEvent(event:DeviceMotionEvent):Void
	{
		accelerometer.onUpdate.dispatch(event.accelerationIncludingGravity.x, event.accelerationIncludingGravity.y, event.accelerationIncludingGravity.z);
	}

	private function handleWindowEvent(event:js.html.Event):Void
	{
		if (parent.window != null)
		{
			switch (event.type)
			{
				case "focus":
					if (hidden)
					{
						parent.window.onFocusIn.dispatch();
						parent.window.onActivate.dispatch();
						hidden = false;
					}

				case "blur":
					if (!hidden)
					{
						parent.window.onFocusOut.dispatch();
						parent.window.onDeactivate.dispatch();
						hidden = true;
					}

				case "visibilitychange":
					if (Browser.document.hidden)
					{
						if (!hidden)
						{
							parent.window.onFocusOut.dispatch();
							parent.window.onDeactivate.dispatch();
							hidden = true;
						}
					}
					else
					{
						if (hidden)
						{
							parent.window.onFocusIn.dispatch();
							parent.window.onActivate.dispatch();
							hidden = false;
						}
					}

				case "resize":
					parent.window.__backend.handleResizeEvent(event);

				case "beforeunload":
					// Mobile Chrome dispatches 'beforeunload' after device sleep,
					// but returns later without reloading the page. This triggers
					// a window.onClose(), without us creating the window again.
					//
					// For now, let focus in/out and activate/deactivate trigger
					// on blur and focus, and do not dispatch a closed window event
					// since it may actually never close.

					// if (!event.defaultPrevented) {

					// 		parent.window.onClose.dispatch ();

					// 		if (parent.window != null && parent.window.onClose.canceled && event.cancelable) {

					// 			event.preventDefault ();

					// 		}

					// 	}
			}
		}
	}

	private function updateGameDevices():Void
	{
		var devices = Joystick.__getDeviceData();
		if (devices == null) return;

		var id, gamepad, joystick, data:Dynamic, cache;

		for (i in 0...devices.length)
		{
			id = i;
			data = devices[id];

			if (data == null) continue;

			if (!gameDeviceCache.exists(id))
			{
				cache = new GameDeviceData();
				cache.id = id;
				cache.connected = data.connected;

				for (i in 0...data.buttons.length)
				{
					cache.buttons.push(data.buttons[i].value);
				}

				for (i in 0...data.axes.length)
				{
					cache.axes.push(data.axes[i]);
				}

				if (data.mapping == "standard")
				{
					cache.isGamepad = true;
				}

				gameDeviceCache.set(id, cache);

				if (data.connected)
				{
					Joystick.__connect(id);

					if (cache.isGamepad)
					{
						Gamepad.__connect(id);
					}
				}
			}

			cache = gameDeviceCache.get(id);

			joystick = Joystick.devices.get(id);
			gamepad = Gamepad.devices.get(id);

			if (data.connected)
			{
				var button:GamepadButton;
				var value:Float;

				for (i in 0...data.buttons.length)
				{
					value = data.buttons[i].value;

					if (value != cache.buttons[i])
					{
						if (i == 6)
						{
							joystick.onAxisMove.dispatch(data.axes.length, value);
							if (gamepad != null) gamepad.onAxisMove.dispatch(GamepadAxis.TRIGGER_LEFT, value);
						}
						else if (i == 7)
						{
							joystick.onAxisMove.dispatch(data.axes.length + 1, value);
							if (gamepad != null) gamepad.onAxisMove.dispatch(GamepadAxis.TRIGGER_RIGHT, value);
						}
						else
						{
							if (value > 0)
							{
								joystick.onButtonDown.dispatch(i);
							}
							else
							{
								joystick.onButtonUp.dispatch(i);
							}

							if (gamepad != null)
							{
								button = switch (i)
								{
									case 0: GamepadButton.A;
									case 1: GamepadButton.B;
									case 2: GamepadButton.X;
									case 3: GamepadButton.Y;
									case 4: GamepadButton.LEFT_SHOULDER;
									case 5: GamepadButton.RIGHT_SHOULDER;
									case 8: GamepadButton.BACK;
									case 9: GamepadButton.START;
									case 10: GamepadButton.LEFT_STICK;
									case 11: GamepadButton.RIGHT_STICK;
									case 12: GamepadButton.DPAD_UP;
									case 13: GamepadButton.DPAD_DOWN;
									case 14: GamepadButton.DPAD_LEFT;
									case 15: GamepadButton.DPAD_RIGHT;
									case 16: GamepadButton.GUIDE;
									default: continue;
								}

								if (value > 0)
								{
									gamepad.onButtonDown.dispatch(button);
								}
								else
								{
									gamepad.onButtonUp.dispatch(button);
								}
							}
						}

						cache.buttons[i] = value;
					}
				}

				for (i in 0...data.axes.length)
				{
					if (data.axes[i] != cache.axes[i])
					{
						joystick.onAxisMove.dispatch(i, data.axes[i]);
						if (gamepad != null) gamepad.onAxisMove.dispatch(i, data.axes[i]);
						cache.axes[i] = data.axes[i];
					}
				}
			}
			else if (cache.connected)
			{
				cache.connected = false;

				Joystick.__disconnect(id);
				Gamepad.__disconnect(id);
			}
		}
	}
}

class GameDeviceData
{
	public var connected:Bool;
	public var id:Int;
	public var isGamepad:Bool;
	public var buttons:Array<Float>;
	public var axes:Array<Float>;

	public function new()
	{
		connected = true;
		buttons = [];
		axes = [];
	}
}
