package lime.ui;

import lime._internal.backend.native.NativeCFFI;
import lime.app.Event;
import lime.system.CFFI;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.ui.Joystick)
class Gamepad
{
	public static var devices = new Map<Int, Gamepad>();
	public static var onConnect = new Event<Gamepad->Void>();

	public var connected(default, null):Bool;
	public var guid(get, never):String;
	public var id(default, null):Int;
	public var name(get, never):String;
	public var onAxisMove = new Event<GamepadAxis->Float->Void>();
	public var onButtonDown = new Event<GamepadButton->Void>();
	public var onButtonUp = new Event<GamepadButton->Void>();
	public var onDisconnect = new Event<Void->Void>();

	/**
		Dispatched with a motion sensor's readings along the x, y and z axes, while
		it is enabled with `setSensorEnabled()`.
	**/
	public var onSensorUpdate = new Event<GamepadSensorType->Float->Float->Float->Void>();

	/**
		Dispatched when a finger touches the touchpad, as on PlayStation
		controllers, with the finger and where it is, from 0 to 1 across and down.
	**/
	public var onTouchpadDown = new Event<Int->Float->Float->Void>();

	/**
		Dispatched when a finger moves on the touchpad, with the finger and where it
		is, from 0 to 1 across and down.
	**/
	public var onTouchpadMove = new Event<Int->Float->Float->Void>();

	/**
		Dispatched when a finger leaves the touchpad, with the finger and where it
		was, from 0 to 1 across and down.
	**/
	public var onTouchpadUp = new Event<Int->Float->Float->Void>();

	/**
		The kind of controller this is, as for showing the right button prompts.
	**/
	public var type(get, never):GamepadType;

	#if (js && html5)
	private var __jsGamepad:js.html.Gamepad;
	#end

	public function new(id:Int)
	{
		this.id = id;
		connected = true;

		#if (js && html5)
		var devices = Joystick.__getDeviceData();
		__jsGamepad = devices[this.id];
		#end
	}

	public static function addMappings(mappings:Array<String>):Void
	{
		#if (lime_cffi && !macro)
		#if hl
		var _mappings = new hl.NativeArray<String>(mappings.length);
		for (i in 0...mappings.length)
			_mappings[i] = mappings[i];
		var mappings = _mappings;
		#end
		NativeCFFI.lime_gamepad_add_mappings(mappings);
		#end
	}

	/**
		@param	lowFrequencyRumble	The intensity of the low frequency (strong)
		rumble motor, from 0 to 1.
		@param	highFrequencyRumble	The intensity of the high frequency (weak)
		rumble motor, from 0 to 1. Will be ignored in situations where only one
		motor is available.
		@param	duration	The duration of the rumble effect, in milliseconds.
	**/
	public inline function rumble(lowFrequencyRumble:Float, highFrequencyRumble:Float, duration:Int):Void
	{
		#if (lime_cffi && !macro)
		NativeCFFI.lime_gamepad_rumble(this.id, lowFrequencyRumble, highFrequencyRumble, duration);
		#elseif (js && html5)
		var actuator:Dynamic = (untyped __jsGamepad.vibrationActuator) ? untyped __jsGamepad.vibrationActuator : (untyped __jsGamepad.hapticActuators) ? untyped __jsGamepad.hapticActuators[0] : null;
		if (actuator == null) return;

		if (untyped actuator.playEffect)
		{
			untyped actuator.playEffect("dual-rumble",
				{
					duration: duration,
					strongMagnitude: lowFrequencyRumble,
					weakMagnitude: highFrequencyRumble
				});
		}
		else if (untyped actuator.pulse)
		{
			untyped actuator.pulse(lowFrequencyRumble, duration);
		}
		#else
		return;
		#end
	}

	/**
		Whether the gamepad has a light whose color can be set with `setLED()`.
	**/
	public function hasLED():Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_gamepad_has_led(this.id);
		#else
		return false;
		#end
	}

	/**
		Whether the gamepad has the motion sensor given.
	**/
	public function hasSensor(sensor:GamepadSensorType):Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_gamepad_has_sensor(this.id, sensor);
		#else
		return false;
		#end
	}

	/**
		Whether the gamepad has rumble motors in its triggers, for
		`rumbleTriggers()`, as Xbox One controllers do.
	**/
	public function hasTriggerRumble():Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_gamepad_has_rumble_triggers(this.id);
		#else
		return false;
		#end
	}

	/**
		Rumbles the motors in the gamepad's triggers.
		@param	leftRumble	The intensity of the left trigger's motor, from 0 to 1.
		@param	rightRumble	The intensity of the right trigger's motor, from 0 to 1.
		@param	duration	How long to rumble, in milliseconds.
		@return	Whether the triggers could rumble.
	**/
	public function rumbleTriggers(leftRumble:Float, rightRumble:Float, duration:Int):Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_gamepad_rumble_triggers(this.id, leftRumble, rightRumble, duration);
		#elseif (js && html5)
		var actuator:Dynamic = untyped __jsGamepad.vibrationActuator;
		if (actuator == null || untyped !actuator.playEffect) return false;
		if (untyped actuator.effects != null && actuator.effects.indexOf("trigger-rumble") == -1) return false;

		untyped actuator.playEffect("trigger-rumble",
			{
				duration: duration,
				leftTrigger: leftRumble,
				rightTrigger: rightRumble
			});
		return true;
		#else
		return false;
		#end
	}

	/**
		Sets the color of the gamepad's light, as on PlayStation controllers.
		@param	color	The color, as `0xRRGGBB`.
		@return	Whether the light could be set.
	**/
	public function setLED(color:Int):Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_gamepad_set_led(this.id, (color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF);
		#else
		return false;
		#end
	}

	/**
		Turns a motion sensor on or off. While it is on, its readings are
		dispatched with `onSensorUpdate`.
		@return	Whether the sensor could be turned on or off.
	**/
	public function setSensorEnabled(sensor:GamepadSensorType, enabled:Bool):Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_gamepad_set_sensor_enabled(this.id, sensor, enabled);
		#else
		return false;
		#end
	}

	@:noCompletion private static function __connect(id:Int):Void
	{
		if (!devices.exists(id))
		{
			var gamepad = new Gamepad(id);
			devices.set(id, gamepad);
			onConnect.dispatch(gamepad);
		}
	}

	@:noCompletion private static function __disconnect(id:Int):Void
	{
		var gamepad = devices.get(id);
		if (gamepad != null) gamepad.connected = false;
		devices.remove(id);
		if (gamepad != null) gamepad.onDisconnect.dispatch();
	}

	// Get & Set Methods
	@:noCompletion private inline function get_guid():String
	{
		#if (lime_cffi && !macro)
		return CFFI.stringValue(NativeCFFI.lime_gamepad_get_device_guid(this.id));
		#elseif (js && html5)
		return __jsGamepad.id;
		#else
		return null;
		#end
	}

	@:noCompletion private function get_type():GamepadType
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_gamepad_get_type(this.id);
		#else
		return UNKNOWN;
		#end
	}

	@:noCompletion private inline function get_name():String
	{
		#if (lime_cffi && !macro)
		return CFFI.stringValue(NativeCFFI.lime_gamepad_get_device_name(this.id));
		#elseif (js && html5)
		return __jsGamepad.id;
		#else
		return null;
		#end
	}
}
