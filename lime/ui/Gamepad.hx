package lime.ui;


import lime.system.System;


class Gamepad {
	
	
	public static function getDeviceName (id:Int):String {
		
		#if (cpp || neko || nodejs)
		return lime_gamepad_get_device_name (id);
		#else
		return null;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_gamepad_get_device_name = System.load ("lime", "lime_gamepad_get_device_name", 1);
	#end
	
	
}