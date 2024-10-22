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

	public function new(id:Int)
	{
		this.id = id;
		connected = true;
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
		var devices = Joystick.__getDeviceData();
		return devices[this.id].id;
		#else
		return null;
		#end
	}

	@:noCompletion private inline function get_name():String
	{
		#if (lime_cffi && !macro)
		return CFFI.stringValue(NativeCFFI.lime_gamepad_get_device_name(this.id));
		#elseif (js && html5)
		var devices = Joystick.__getDeviceData();
		return devices[this.id].id;
		#else
		return null;
		#end
	}
	
	// Rumble
	public inline function rumble(duration:Int, largeStrength:Float, smallStrength:Float):Void
	{
		#if (lime_cffi && !macro)
		NativeCFFI.lime_gamepad_rumble(this.id, duration, largeStrength, smallStrength);
		#elseif (js && html5)
		// TODO: HTML5 Rumble
		return;
		#else
		return;
		#end
	}
}
