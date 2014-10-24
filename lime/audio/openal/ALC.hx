package lime.audio.openal;


import lime.system.System;


class ALC {
	
	
	public static inline var FALSE:Int = 0;
	public static inline var TRUE:Int = 1;
	public static inline var FREQUENCY:Int = 0x1007;
	public static inline var REFRESH:Int = 0x1008;
	public static inline var SYNC:Int = 0x1009;
	public static inline var MONO_SOURCES:Int = 0x1010;
	public static inline var STEREO_SOURCES:Int = 0x1011;
	public static inline var NO_ERROR:Int = 0;
	public static inline var INVALID_DEVICE:Int = 0xA001;
	public static inline var INVALID_CONTEXT:Int = 0xA002;
	public static inline var INVALID_ENUM:Int = 0xA003;
	public static inline var INVALID_VALUE:Int = 0xA004;
	public static inline var OUT_OF_MEMORY:Int = 0xA005;
	public static inline var ATTRIBUTES_SIZE:Int = 0x1002;
	public static inline var ALL_ATTRIBUTES:Int = 0x1003;
	public static inline var DEFAULT_DEVICE_SPECIFIER:Int = 0x1004;
	public static inline var DEVICE_SPECIFIER:Int = 0x1005;
	public static inline var EXTENSIONS:Int = 0x1006;
	public static inline var ENUMERATE_ALL_EXT:Int = 1;
	public static inline var DEFAULT_ALL_DEVICES_SPECIFIER:Int = 0x1012;
	public static inline var ALL_DEVICES_SPECIFIER:Int = 0x1013;
	
	
	public static function closeDevice (device:ALDevice):Bool {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		return lime_alc_close_device (device);
		#else
		return false;
		#end
		
	}
	
	
	public static function createContext (device:ALDevice, attrlist:Array<Int> = null):ALContext {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		var handle:Float = lime_alc_create_context (device, attrlist);
		
		if (handle != 0) {
			
			return new ALContext (handle);
			
		}
		#end
		
		return null;
		
	}
	
	
	public static function destroyContext (context:ALContext):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		lime_alc_destroy_context (context);
		#end
		
	}
	
	
	public static function getContextsDevice (context:ALContext):ALDevice {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		var handle:Float = lime_alc_get_contexts_device (context);
		
		if (handle != 0) {
			
			return new ALDevice (handle);
			
		}
		#end
		
		return null;
		
	}
	
	
	public static function getCurrentContext ():ALContext {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		var handle:Float = lime_alc_get_current_context ();
		
		if (handle != 0) {
			
			return new ALContext (handle);
			
		}
		#end
		
		return null;
		
	}
	
	
	public static function getError (device:ALDevice):Int {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		return lime_alc_get_error (device);
		#else
		return 0;
		#end
		
	}
	
	
	public static function getErrorString (device:ALDevice):String {
		
		return switch (getError (device)) {
			
			case INVALID_DEVICE: "INVALID_DEVICE: Invalid device (or no device?)";
			case INVALID_CONTEXT: "INVALID_CONTEXT: Invalid context (or no context?)";
			case INVALID_ENUM: "INVALID_ENUM: Invalid enum value";
			case INVALID_VALUE: "INVALID_VALUE: Invalid param value";
			case OUT_OF_MEMORY: "OUT_OF_MEMORY: OpenAL has run out of memory";
			default: "";
			
		}
		
	}
	
	
	public static function getIntegerv (device:ALDevice, param:Int, size:Int):Array<Int> {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		return lime_alc_get_integerv (device, param, size);
		#else
		return null;
		#end
		
	}
	
	
	public static function getString (device:ALDevice, param:Int):String {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		return lime_alc_get_string (device, param);
		#else
		return null;
		#end
		
	}
	
	
	public static function makeContextCurrent (context:ALContext):Bool {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		return lime_alc_make_context_current (context);
		#else
		return false;
		#end
		
	}
	
	
	public static function openDevice (deviceName:String = null):ALDevice {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		var handle:Float = lime_alc_open_device (deviceName);
		
		if (handle != 0) {
			
			return new ALDevice (handle);
			
		}
		#end
		
		return null;
		
	}
	
	
	public static function processContext (context:ALContext):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		lime_alc_process_context (context);
		#end
		
	}
	
	
	public static function suspendContext (context:ALContext):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal)
		lime_alc_suspend_context (context);
		#end
		
	}
	
	
	#if ((cpp || neko || nodejs) && lime_openal)
	private static var lime_alc_close_device = System.load ("lime", "lime_alc_close_device", 1);
	private static var lime_alc_create_context = System.load ("lime", "lime_alc_create_context", 2);
	private static var lime_alc_destroy_context = System.load ("lime", "lime_alc_destroy_context", 1);
	private static var lime_alc_get_contexts_device = System.load ("lime", "lime_alc_get_contexts_device", 1);
	private static var lime_alc_get_current_context = System.load ("lime", "lime_alc_get_current_context", 0);
	private static var lime_alc_get_error = System.load ("lime", "lime_alc_get_error", 1);
	private static var lime_alc_get_integerv = System.load ("lime", "lime_alc_get_integerv", 3);
	private static var lime_alc_get_string = System.load ("lime", "lime_alc_get_string", 2);
	private static var lime_alc_make_context_current = System.load ("lime", "lime_alc_make_context_current", 1);
	private static var lime_alc_open_device = System.load ("lime", "lime_alc_open_device", 1);
	private static var lime_alc_process_context = System.load ("lime", "lime_alc_process_context", 1);
	private static var lime_alc_suspend_context = System.load ("lime", "lime_alc_suspend_context", 1);
	#end
	
	
}