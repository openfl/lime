package lime.ui;


import lime.app.Event;

#if !macro
@:build(lime.system.CFFI.build())
#end


class Gamepad {
	
	
	public static var devices = new Map<Int, Gamepad> ();
	public static var onConnect = new Event<Gamepad->Void> ();
	
	public var connected (default, null):Bool;
	public var guid (get, never):String;
	public var id (default, null):Int;
	public var name (get, never):String;
	public var onAxisMove = new Event<GamepadAxis->Float->Void> ();
	public var onButtonDown = new Event<GamepadButton->Void> ();
	public var onButtonUp = new Event<GamepadButton->Void> ();
	public var onDisconnect = new Event<Void->Void> ();
	
	
	public function new (id:Int) {
		
		this.id = id;
		connected = true;
		
	}
	
	
	public static function addMappings (mappings:Array<String>):Void {
		
		#if ((cpp || neko || nodejs) && !macro)
		lime_gamepad_add_mappings (mappings);
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private inline function get_guid ():String {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_gamepad_get_device_guid (this.id);
		#else
		return null;
		#end
		
	}
	
	
	@:noCompletion private inline function get_name ():String {
		
		#if ((cpp || neko || nodejs) && !macro)
		return lime_gamepad_get_device_name (this.id);
		#else
		return null;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_gamepad_add_mappings (mappings:Dynamic):Void;
	@:cffi private static function lime_gamepad_get_device_guid (id:Int):Dynamic;
	@:cffi private static function lime_gamepad_get_device_name (id:Int):Dynamic;
	#end
	
	
}
