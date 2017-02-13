package lime._backend.html5;


import js.html.KeyboardEvent;
import js.Browser;
import lime.app.Application;
import lime.app.Config;
import lime.audio.AudioManager;
import lime.graphics.Renderer;
import lime.ui.GamepadAxis;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Gamepad;
import lime.ui.GamepadButton;
import lime.ui.Joystick;
import lime.ui.Window;

@:access(lime._backend.html5.HTML5Window)
@:access(lime.app.Application)
@:access(lime.graphics.Renderer)
@:access(lime.ui.Gamepad)
@:access(lime.ui.Joystick)
@:access(lime.ui.Window)


class HTML5Application {


	private var gameDeviceCache = new Map<Int, GameDeviceData> ();

	private var currentUpdate:Float;
	private var deltaTime:Float;
	private var framePeriod:Float;
	private var lastUpdate:Float;
	private var nextUpdate:Float;
	private var parent:Application;
	public static var stopUpdating:Bool = false;
	private static var instance:HTML5Application;
	private var requestAnimFrameFunc:Dynamic;
	#if stats
	private var stats:Dynamic;
	#end


	public inline function new (parent:Application) {

		this.parent = parent;

		currentUpdate = 0;
		lastUpdate = 0;
		nextUpdate = 0;
		framePeriod = -1;

		AudioManager.init ();

		instance = this;
	}


	private function convertKeyCode (keyCode:Int):KeyCode {

		if (keyCode >= 65 && keyCode <= 90) {

			return keyCode + 32;

		}

		switch (keyCode) {

			case 16: return KeyCode.LEFT_SHIFT;
			case 17: return KeyCode.LEFT_CTRL;
			case 18: return KeyCode.LEFT_ALT;
			case 20: return KeyCode.CAPS_LOCK;
			case 144: return KeyCode.NUM_LOCK;
			case 37: return KeyCode.LEFT;
			case 38: return KeyCode.UP;
			case 39: return KeyCode.RIGHT;
			case 40: return KeyCode.DOWN;
			case 45: return KeyCode.INSERT;
			case 46: return KeyCode.DELETE;
			case 36: return KeyCode.HOME;
			case 35: return KeyCode.END;
			case 33: return KeyCode.PAGE_UP;
			case 34: return KeyCode.PAGE_DOWN;
			case 112: return KeyCode.F1;
			case 113: return KeyCode.F2;
			case 114: return KeyCode.F3;
			case 115: return KeyCode.F4;
			case 116: return KeyCode.F5;
			case 117: return KeyCode.F6;
			case 118: return KeyCode.F7;
			case 119: return KeyCode.F8;
			case 120: return KeyCode.F9;
			case 121: return KeyCode.F10;
			case 122: return KeyCode.F11;
			case 123: return KeyCode.F12;
			case 124: return KeyCode.F13;
			case 125: return KeyCode.F14;
			case 126: return KeyCode.F15;
			case 186: return KeyCode.SEMICOLON;
			case 187: return KeyCode.EQUALS;
			case 188: return KeyCode.COMMA;
			case 189: return KeyCode.MINUS;
			case 190: return KeyCode.PERIOD;
			case 191: return KeyCode.SLASH;
			case 192: return KeyCode.GRAVE;
			case 219: return KeyCode.LEFT_BRACKET;
			case 220: return KeyCode.BACKSLASH;
			case 221: return KeyCode.RIGHT_BRACKET;
			case 222: return KeyCode.SINGLE_QUOTE;

		}

		return keyCode;

	}


	public function create (config:Config):Void {



	}


	public function exec ():Int {

		Browser.window.addEventListener ("keydown", handleKeyEvent, false);
		Browser.window.addEventListener ("keyup", handleKeyEvent, false);
		Browser.window.addEventListener ("focus", handleWindowEvent, false);
		Browser.window.addEventListener ("blur", handleWindowEvent, false);
		Browser.window.addEventListener ("resize", handleWindowEvent, false);
		Browser.window.addEventListener ("beforeunload", handleWindowEvent, false);

		#if stats
		stats = untyped __js__("new Stats ()");
		stats.domElement.style.position = "absolute";
		stats.domElement.style.top = "0px";
		Browser.document.body.appendChild (stats.domElement);
		#end

		untyped __js__ ("
			if (!CanvasRenderingContext2D.prototype.isPointInStroke) {
				CanvasRenderingContext2D.prototype.isPointInStroke = function (path, x, y) {
					return false;
				};
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

		lastUpdate = Date.now ().getTime ();

		requestAnimFrameFunc = untyped __js__("window.requestAnimationFrame");

		handleApplicationEvent ();

		#if profile
		untyped __js__("window.frameIndex = 0;");
		untyped __js__("window.updateCalls = 0;");
		#end

		return 0;

	}


	public function exit ():Void {

		AudioManager.shutdown ();

	}


	public function getFrameRate ():Float {

		if (framePeriod < 0) {

			return 60;

		} else if (framePeriod == 1000) {

			return 0;

		} else {

			return 1000 / framePeriod;

		}

	}


	private function handleApplicationEvent (?__):Void {

		#if supports_devices
			updateGameDevices ();
		#end

		currentUpdate = lime.system.System.getTimer();

		if (currentUpdate >= nextUpdate) {

			#if stats
			stats.begin ();
			#end

			deltaTime = currentUpdate - lastUpdate;

			parent.onUpdate.dispatch (Std.int (deltaTime));

			if (parent.renderer != null) {

				//parent.renderer.onRender.dispatch ();
				parent.render(parent.renderer);
				parent.renderer.flip ();

			}

			#if stats
			stats.end ();
			#end

			if (framePeriod < 0) {

				nextUpdate = currentUpdate;
				nextUpdate = currentUpdate;

			} else {

				nextUpdate = currentUpdate + framePeriod;

				//while (nextUpdate <= currentUpdate) {
					//
					//nextUpdate += framePeriod;
					//
				//}


			}

			lastUpdate = currentUpdate;

		}

		if( !stopUpdating ){
			#if profile
			untyped __js__("
				if(window.countUpdate) {
					++window.frameIndex;
					if(window.frameIndex == 150) {
						var cpf = window.updateCalls / 150;
						console.log('__update/frame: ' + cpf);
						window.frameIndex = 0;
						window.updateCalls = 0;
					}
				}
			");
			#end
			requestAnimFrameFunc.call(untyped __js__("window"), staticHandleApplicationEvent);
		}
	}

	private static function staticHandleApplicationEvent()
	{
		instance.handleApplicationEvent();
	}

	private function handleKeyEvent (event:KeyboardEvent):Void {

		if (parent.window != null) {

			// space and arrow keys

			// switch (event.keyCode) {

			// 	case 32, 37, 38, 39, 40: event.preventDefault ();

			// }

			var keyCode = cast convertKeyCode (event.keyCode != null ? event.keyCode : event.which);
			var modifier = (event.shiftKey ? (KeyModifier.SHIFT) : 0) | (event.ctrlKey ? (KeyModifier.CTRL) : 0) | (event.altKey ? (KeyModifier.ALT) : 0) | (event.metaKey ? (KeyModifier.META) : 0);

			if (event.type == "keydown") {

				parent.window.onKeyDown.dispatch (keyCode, modifier);

				if (parent.window.onKeyDown.canceled) {

					event.preventDefault ();

				}

			} else {

				parent.window.onKeyUp.dispatch (keyCode, modifier);

				if (parent.window.onKeyUp.canceled) {

					event.preventDefault ();

				}

			}

		}

	}


	private function handleWindowEvent (event:js.html.Event):Void {

		if (parent.window != null) {

			switch (event.type) {

				case "focus":

					parent.window.onFocusIn.dispatch ();
					parent.window.onActivate.dispatch ();

				case "blur":

					parent.window.onFocusOut.dispatch ();
					parent.window.onDeactivate.dispatch ();

				case "resize":

					parent.window.resize (parent.window.width, parent.window.height);

				case "beforeunload":

					parent.window.onClose.dispatch ();

			}

		}

	}


	public function setFrameRate (value:Float):Float {

		if (value >= 60) {

			framePeriod = -1;

		} else if (value > 0) {

			framePeriod = 1000 / value;

		} else {

			framePeriod = 1000;

		}

		return value;

	}


	private function updateGameDevices ():Void {

		var devices = Joystick.__getDeviceData ();
		if (devices == null) return;

		var id, gamepad, joystick, data:Dynamic, cache;

		for (i in 0...devices.length) {

			id = i;
			data = devices[id];

			if (data == null) continue;

			if (!gameDeviceCache.exists (id)) {

				cache = new GameDeviceData ();
				cache.id = id;
				cache.connected = data.connected;

				for (i in 0...data.buttons.length) {

					cache.buttons.push (data.buttons[i].value);

				}

				for (i in 0...data.axes.length) {

					cache.axes.push (data.axes[i]);

				}

				if (data.mapping == "standard") {

					cache.isGamepad = true;

				}

				gameDeviceCache.set (id, cache);

				if (data.connected) {

					Joystick.__connect (id);

					if (cache.isGamepad) {

						Gamepad.__connect (id);

					}

				}

			}

			cache = gameDeviceCache.get (id);

			joystick = Joystick.devices.get (id);
			gamepad = Gamepad.devices.get (id);

			if (data.connected) {

				var button:GamepadButton;
				var value:Float;

				for (i in 0...data.buttons.length) {

					value = data.buttons[i].value;

					if (value != cache.buttons[i]) {

						if (i == 6) {

							joystick.onAxisMove.dispatch (data.axes.length, value);
							if (gamepad != null) gamepad.onAxisMove.dispatch (GamepadAxis.TRIGGER_LEFT, value);

						} else if (i == 7) {

							joystick.onAxisMove.dispatch (data.axes.length + 1, value);
							if (gamepad != null) gamepad.onAxisMove.dispatch (GamepadAxis.TRIGGER_RIGHT, value);

						} else {

							if (value > 0) {

								joystick.onButtonDown.dispatch (i);

							} else {

								joystick.onButtonUp.dispatch (i);

							}

							if (gamepad != null) {

								button = switch (i) {

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

								if (value > 0) {

									gamepad.onButtonDown.dispatch (button);

								} else {

									gamepad.onButtonUp.dispatch (button);

								}

							}

						}

						cache.buttons[i] = value;

					}

				}

				for (i in 0...data.axes.length) {

					if (data.axes[i] != cache.axes[i]) {

						joystick.onAxisMove.dispatch (i, data.axes[i]);
						if (gamepad != null) gamepad.onAxisMove.dispatch (i, data.axes[i]);
						cache.axes[i] = data.axes[i];

					}

				}

			} else if (cache.connected) {

				cache.connected = false;

				Joystick.__disconnect (id);
				Gamepad.__disconnect (id);

			}

		}

	}


}


class GameDeviceData {


	public var connected:Bool;
	public var id:Int;
	public var isGamepad:Bool;
	public var buttons:Array<Float>;
	public var axes:Array<Float>;


	public function new () {

		connected = true;
		buttons = [];
		axes = [];

	}


}
