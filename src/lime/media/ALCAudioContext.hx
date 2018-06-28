package lime.media;


import lime.media.openal.ALC;
import lime.media.openal.ALContext;
import lime.media.openal.ALDevice;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


class ALCAudioContext {
	
	
	public var FALSE:Int = 0;
	public var TRUE:Int = 1;
	public var FREQUENCY:Int = 0x1007;
	public var REFRESH:Int = 0x1008;
	public var SYNC:Int = 0x1009;
	public var MONO_SOURCES:Int = 0x1010;
	public var STEREO_SOURCES:Int = 0x1011;
	public var NO_ERROR:Int = 0;
	public var INVALID_DEVICE:Int = 0xA001;
	public var INVALID_CONTEXT:Int = 0xA002;
	public var INVALID_ENUM:Int = 0xA003;
	public var INVALID_VALUE:Int = 0xA004;
	public var OUT_OF_MEMORY:Int = 0xA005;
	public var ATTRIBUTES_SIZE:Int = 0x1002;
	public var ALL_ATTRIBUTES:Int = 0x1003;
	public var DEFAULT_DEVICE_SPECIFIER:Int = 0x1004;
	public var DEVICE_SPECIFIER:Int = 0x1005;
	public var EXTENSIONS:Int = 0x1006;
	public var ENUMERATE_ALL_EXT:Int = 1;
	public var DEFAULT_ALL_DEVICES_SPECIFIER:Int = 0x1012;
	public var ALL_DEVICES_SPECIFIER:Int = 0x1013;
	
	
	public function new () {
		
		
		
	}
	
	
	public function closeDevice (device:ALDevice):Bool {
		
		return ALC.closeDevice (device);
		
	}
	
	
	public function createContext (device:ALDevice, attrlist:Array<Int> = null):ALContext {
		
		return ALC.createContext (device, attrlist);
		
	}
	
	
	public function destroyContext (context:ALContext):Void {
		
		if (context == null) return;
		ALC.destroyContext (context);
		
	}
	
	
	public function getContextsDevice (context:ALContext):ALDevice {
		
		if (context == null) return null;
		return ALC.getContextsDevice (context);
		
	}
	
	
	public function getCurrentContext ():ALContext {
		
		return ALC.getCurrentContext ();
		
	}
	
	
	public function getError (device:ALDevice):Int {
		
		return ALC.getError (device);
		
	}
	
	
	public function getErrorString (device:ALDevice):String {
		
		return ALC.getErrorString (device);
		
	}
	
	
	public function getIntegerv (device:ALDevice, param:Int, count:Int = 1):Array<Int> {
		
		return ALC.getIntegerv (device, param, count);
		
	}
	
	
	public function getString (device:ALDevice, param:Int):String {
		
		return ALC.getString (device, param);
		
	}
	
	
	public function makeContextCurrent (context:ALContext):Bool {
		
		return ALC.makeContextCurrent (context);
		
	}
	
	
	public function openDevice (deviceName:String = null):ALDevice {
		
		return ALC.openDevice (deviceName);
		
	}
	
	
	public function pauseDevice (device:ALDevice):Void {
		
		ALC.pauseDevice (device);
		
	}
	
	
	public function processContext (context:ALContext):Void {
		
		ALC.processContext (context);
		
	}
	
	
	public function resumeDevice (device:ALDevice):Void {
		
		ALC.resumeDevice (device);
		
	}
	
	
	public function suspendContext (context:ALContext):Void {
		
		ALC.suspendContext (context);
		
	}
	
	
}