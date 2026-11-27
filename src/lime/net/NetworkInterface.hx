package lime.net;

import haxe.Timer;
import lime._internal.backend.native.NativeCFFI;
import lime.app.Event;
import lime.app.Future;
import lime.system.CFFI;
#if (js && html5)
import js.Browser;
#end

/**
	A network adapter on this device, with its addresses, and an event for
	the network changing.

	Once `onChange` is first used, the interfaces are compared once a second,
	on a background thread where there is one, and `onChange` is dispatched on
	the main thread when an interface comes or goes, goes up or down, or gains
	or loses an address.

	Available on Windows, macOS, Linux, iOS and Android 7.0 and later. On
	HTML5 the interfaces cannot be listed, and `onChange` is dispatched when
	the browser goes online or offline. iOS, and Android 11 and later, hide
	hardware addresses from apps.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.net.InterfaceAddress)
class NetworkInterface
{
	private static inline var POLL_MS:Int = 1000;

	/**
		Whether the interfaces can be listed on this platform.
	**/
	public static var isSupported(get, never):Bool;

	/**
		Dispatched when the network changes.
	**/
	public static var onChange(get, never):Event<Void->Void>;

	/**
		Whether the interface is up and connected.
	**/
	public var active(default, null):Bool;

	/**
		The interface's addresses.
	**/
	public var addresses(default, null):Array<InterfaceAddress>;

	/**
		The name the system shows for the interface, as `"Wi-Fi"` on Windows.
		Elsewhere it is the same as `name`.
	**/
	public var displayName(default, null):String;

	/**
		The interface's hardware (MAC) address, as `"00-1A-2B-3C-4D-5E"`, or
		`null` when it has none or the system does not give it out.
	**/
	public var hardwareAddress(default, null):String;

	/**
		The largest packet the interface sends, in bytes, or -1 when it is not
		known.
	**/
	public var mtu(default, null):Int;

	/**
		The system's name for the interface, as `"en0"` or `"eth0"`, or the
		adapter's GUID on Windows.
	**/
	public var name(default, null):String;

	@:noCompletion private static var __change:Event<Void->Void>;
	@:noCompletion private static var __known:String;
	@:noCompletion private static var __polling:Bool = false;
	@:noCompletion private static var __timer:Timer;

	@:noCompletion private function new() {}

	/**
		The interfaces on this device now, or an empty array where they cannot
		be listed.
	**/
	public static function getInterfaces():Array<NetworkInterface>
	{
		var interfaces = [];
		var text = __read();
		if (text == null || text == "") return interfaces;

		for (record in text.split("\x1E"))
		{
			var fields = record.split("\x1F");
			if (fields.length < 5) continue;

			var networkInterface = new NetworkInterface();
			networkInterface.name = fields[0];
			networkInterface.displayName = fields[1];
			networkInterface.hardwareAddress = fields[2] != "" ? fields[2] : null;
			networkInterface.active = fields[3] == "1";
			networkInterface.mtu = Std.parseInt(fields[4]);
			networkInterface.addresses = [];

			var i = 5;
			while (i + 3 < fields.length)
			{
				networkInterface.addresses.push(new InterfaceAddress(fields[i], fields[i + 1] != "" ? fields[i + 1] : null, fields[i + 2],
					Std.parseInt(fields[i + 3])));
				i += 4;
			}

			interfaces.push(networkInterface);
		}

		return interfaces;
	}

	@:noCompletion private static function __read():String
	{
		#if (lime_cffi && !macro)
		return CFFI.stringValue(NativeCFFI.lime_network_interface_get_interfaces());
		#else
		return null;
		#end
	}

	@:noCompletion private static function __compare(text:String):Void
	{
		if (text == null) return;

		var previous = __known;
		__known = text;

		// The first list is how the network was already
		if (previous != null && previous != text) __change.dispatch();
	}

	@:noCompletion private static function __poll():Void
	{
		if (__polling) return;
		__polling = true;

		#if (lime_threads && !html5)
		new Future<String>(__read, true).onComplete(function(text)
		{
			__polling = false;
			__compare(text);
		}).onError(function(_) __polling = false);
		#else
		__compare(__read());
		__polling = false;
		#end
	}

	@:noCompletion private static function __watch():Void
	{
		if (__change != null) return;

		__change = new Event<Void->Void>();

		#if (js && html5)
		var dispatch = function(_) __change.dispatch();
		Browser.window.addEventListener("online", dispatch);
		Browser.window.addEventListener("offline", dispatch);
		#else
		if (get_isSupported())
		{
			__poll();
			__timer = new Timer(POLL_MS);
			__timer.run = __poll;
		}
		#end
	}

	// Get & Set Methods
	@:noCompletion private static function get_isSupported():Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_network_interface_is_supported();
		#else
		return false;
		#end
	}

	@:noCompletion private static function get_onChange():Event<Void->Void>
	{
		__watch();
		return __change;
	}
}
