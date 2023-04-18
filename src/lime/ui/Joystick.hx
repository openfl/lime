package lime.ui;

import lime._internal.backend.native.NativeCFFI;
import lime.app.Event;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class Joystick
{
	public static var devices = new Map<Int, Joystick>();
	public static var onConnect = new Event<Joystick->Void>();

	public var connected(default, null):Bool;
	public var guid(get, never):String;
	public var id(default, null):Int;
	public var name(get, never):String;
	public var numAxes(get, never):Int;
	public var numButtons(get, never):Int;
	public var numHats(get, never):Int;
	public var numTrackballs(get, never):Int;
	public var onAxisMove = new Event<Int->Float->Void>();
	public var onButtonDown = new Event<Int->Void>();
	public var onButtonUp = new Event<Int->Void>();
	public var onDisconnect = new Event<Void->Void>();
	public var onHatMove = new Event<Int->JoystickHatPosition->Void>();
	public var onTrackballMove = new Event<Int->Float->Float->Void>();

	public function new(id:Int)
	{
		this.id = id;
		connected = true;
	}

	@:noCompletion private static function __connect(id:Int):Void
	{
		if (!devices.exists(id))
		{
			var joystick = new Joystick(id);
			devices.set(id, joystick);
			onConnect.dispatch(joystick);
		}
	}

	@:noCompletion private static function __disconnect(id:Int):Void
	{
		var joystick = devices.get(id);
		if (joystick != null) joystick.connected = false;
		devices.remove(id);
		if (joystick != null) joystick.onDisconnect.dispatch();
	}

	#if (js && html5)
	@:noCompletion private static function __getDeviceData():Array<Dynamic>
	{
		return
			(untyped navigator.getGamepads) ? untyped navigator.getGamepads() : (untyped navigator.webkitGetGamepads) ? untyped navigator.webkitGetGamepads() : null;
	}
	#end

	// Get & Set Methods
	@:noCompletion private inline function get_guid():String
	{
		#if (lime_cffi && !macro)
		#if hl
		return @:privateAccess String.fromUTF8(NativeCFFI.lime_joystick_get_device_guid(this.id));
		#else
		return NativeCFFI.lime_joystick_get_device_guid(this.id);
		#end
		#elseif (js && html5)
		var devices = __getDeviceData();
		return devices[this.id].id;
		#else
		return null;
		#end
	}

	@:noCompletion private inline function get_name():String
	{
		#if (lime_cffi && !macro)
		#if hl
		return @:privateAccess String.fromUTF8(NativeCFFI.lime_joystick_get_device_name(this.id));
		#else
		return NativeCFFI.lime_joystick_get_device_name(this.id);
		#end
		#elseif (js && html5)
		var devices = __getDeviceData();
		return devices[this.id].id;
		#else
		return null;
		#end
	}

	@:noCompletion private inline function get_numAxes():Int
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_joystick_get_num_axes(this.id);
		#elseif (js && html5)
		var devices = __getDeviceData();
		return devices[this.id].axes.length;
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function get_numButtons():Int
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_joystick_get_num_buttons(this.id);
		#elseif (js && html5)
		var devices = __getDeviceData();
		return devices[this.id].buttons.length;
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function get_numHats():Int
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_joystick_get_num_hats(this.id);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function get_numTrackballs():Int
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_joystick_get_num_trackballs(this.id);
		#else
		return 0;
		#end
	}
}
