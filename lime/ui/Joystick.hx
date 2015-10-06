package lime.ui;


import lime.app.Event;

#if !macro
@:build(lime.system.CFFI.build())
#end


class Joystick {
	
	
	public static var devices = new Map<Int, Joystick> ();
	public static var onConnect = new Event<Joystick->Void> ();
	
	public var connected (default, null):Bool;
	public var guid (get, never):String;
	public var id (default, null):Int;
	public var name (get, never):String;
	public var numAxes (get, never):Int;
	public var numButtons (get, never):Int;
	public var numHats (get, never):Int;
	public var numTrackballs (get, never):Int;
	public var onAxisMove = new Event<Int->Float->Void> ();
	public var onButtonDown = new Event<Int->Void> ();
	public var onButtonUp = new Event<Int->Void> ();
	public var onDisconnect = new Event<Void->Void> ();
	public var onHatMove = new Event<Int->JoystickHatPosition->Void> ();
	public var onTrackballMove = new Event<Int->Float->Void> ();
	
	
	public function new (id:Int) {
		
		this.id = id;
		connected = true;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private inline function get_guid ():String {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_joystick_get_device_guid (this.id);
		#else
		return null;
		#end
		
	}
	
	
	@:noCompletion private inline function get_name ():String {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_joystick_get_device_name (this.id);
		#else
		return null;
		#end
		
	}
	
	
	@:noCompletion private inline function get_numAxes ():Int {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_joystick_get_num_axes (this.id);
		#else
		return 0;
		#end
		
	}
	
	
	@:noCompletion private inline function get_numButtons ():Int {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_joystick_get_num_buttons (this.id);
		#else
		return 0;
		#end
		
	}
	
	
	@:noCompletion private inline function get_numHats ():Int {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_joystick_get_num_hats (this.id);
		#else
		return 0;
		#end
		
	}
	
	
	@:noCompletion private inline function get_numTrackballs ():Int {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_joystick_get_num_trackballs (this.id);
		#else
		return 0;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_joystick_get_device_guid (id:Int):Dynamic;
	@:cffi private static function lime_joystick_get_device_name (id:Int):Dynamic;
	@:cffi private static function lime_joystick_get_num_axes (id:Int):Int;
	@:cffi private static function lime_joystick_get_num_buttons (id:Int):Int;
	@:cffi private static function lime_joystick_get_num_hats (id:Int):Int;
	@:cffi private static function lime_joystick_get_num_trackballs (id:Int):Int;
	#end
	
	
}
