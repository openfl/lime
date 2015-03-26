package lime.ui;


import lime.system.System;


class Gamepad {
	
	
	public static var devices = new Map<Int, Gamepad> ();
	
	public var connected (default, null):Bool;
	public var guid (get, never):String;
	public var id (default, null):Int;
	public var name (get, never):String;
	
	
	public function new (id:Int) {
		
		this.id = id;
		connected = true;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private inline function get_guid ():String {
		
		#if (cpp || neko || nodejs)
		return lime_gamepad_get_device_guid (this.id);
		#else
		return null;
		#end
		
	}
	
	
	@:noCompletion private inline function get_name ():String {
		
		#if (cpp || neko || nodejs)
		return lime_gamepad_get_device_name (this.id);
		#else
		return null;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_gamepad_get_device_guid = System.load ("lime", "lime_gamepad_get_device_guid", 1);
	private static var lime_gamepad_get_device_name = System.load ("lime", "lime_gamepad_get_device_name", 1);
	#end
	
	
}
