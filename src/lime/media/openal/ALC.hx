package lime.media.openal;

#if (!lime_doc_gen || lime_openal)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class ALC
{
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

	public static function closeDevice(device:ALDevice):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_alc_close_device(device);
		#else
		return false;
		#end
	}

	public static function createContext(device:ALDevice, attrlist:Array<Int> = null):ALContext
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _attrlist = null;
		if (attrlist != null)
		{
			_attrlist = new hl.NativeArray<Int>(attrlist.length);
			for (i in 0...attrlist.length)
				_attrlist[i] = attrlist[i];
		}
		var attrlist = _attrlist;
		#end
		var handle = NativeCFFI.lime_alc_create_context(device, attrlist);

		if (handle != null)
		{
			return new ALContext(handle);
		}
		#end

		return null;
	}

	public static function destroyContext(context:ALContext):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_alc_destroy_context(context);
		#end
	}

	public static function getContextsDevice(context:ALContext):ALDevice
	{
		#if (lime_cffi && lime_openal && !macro) #if !hl var handle:Dynamic = NativeCFFI.lime_alc_get_contexts_device(context);

		if (handle != null)
		{
			return new ALDevice(handle);
		} #else #end
		#end

		return null;
	}

	public static function getCurrentContext():ALContext
	{
		#if (lime_cffi && lime_openal && !macro)
		var handle:Dynamic = NativeCFFI.lime_alc_get_current_context();

		if (handle != null)
		{
			return new ALContext(handle);
		}
		#end

		return null;
	}

	public static function getError(device:ALDevice):Int
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_alc_get_error(device);
		#else
		return 0;
		#end
	}

	public static function getErrorString(device:ALDevice):String
	{
		return switch (getError(device))
		{
			case INVALID_DEVICE: "INVALID_DEVICE: Invalid device (or no device?)";
			case INVALID_CONTEXT: "INVALID_CONTEXT: Invalid context (or no context?)";
			case INVALID_ENUM: "INVALID_ENUM: Invalid enum value";
			case INVALID_VALUE: "INVALID_VALUE: Invalid param value";
			case OUT_OF_MEMORY: "OUT_OF_MEMORY: OpenAL has run out of memory";
			default: "";
		}
	}

	public static function getIntegerv(device:ALDevice, param:Int, size:Int):Array<Int>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_alc_get_integerv(device, param, size);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getString(device:ALDevice, param:Int):String
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_alc_get_string(device, param);
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public static function makeContextCurrent(context:ALContext):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_alc_make_context_current(context);
		#else
		return false;
		#end
	}

	public static function openDevice(deviceName:String = null):ALDevice
	{
		#if (lime_cffi && lime_openal && !macro)
		var handle = NativeCFFI.lime_alc_open_device(deviceName);

		if (handle != null)
		{
			return new ALDevice(handle);
		}
		#end

		return null;
	}

	public static function pauseDevice(device:ALDevice):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_alc_pause_device(device);
		#end
	}

	public static function processContext(context:ALContext):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_alc_process_context(context);
		#end
	}

	public static function resumeDevice(device:ALDevice):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_alc_resume_device(device);
		#end
	}

	public static function suspendContext(context:ALContext):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_alc_suspend_context(context);
		#end
	}
}
#end
