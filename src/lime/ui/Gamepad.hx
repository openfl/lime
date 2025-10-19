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
		var actuator:Dynamic = (untyped __jsGamepad.vibrationActuator) ? untyped __jsGamepad.vibrationActuator
			: (untyped __jsGamepad.hapticActuators) ? untyped __jsGamepad.hapticActuators[0]
			: null;
		if (actuator == null) return;

		if (untyped actuator.playEffect)
		{
			untyped actuator.playEffect("dual-rumble", {
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
