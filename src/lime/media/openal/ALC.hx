package lime.media.openal;

#if (!lime_doc_gen || lime_openal)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFI;
import lime.system.CFFIPointer;
import haxe.io.Bytes;

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
	public static inline var CAPTURE_DEVICE_SPECIFIER:Int = 0x310;
	public static inline var CAPTURE_DEFAULT_DEVICE_SPECIFIER:Int = 0x311;
	public static inline var CAPTURE_SAMPLES:Int = 0x312;
	public static inline var CONNECTED:Int = 0x313;
	public static inline var PLAYBACK_DEVICE_SOFT:Int = 0x19D4;
	public static inline var CAPTURE_DEVICE_SOFT:Int = 0x19D5;
	public static inline var EVENT_TYPE_DEFAULT_DEVICE_CHANGED_SOFT:Int = 0x19D6;
	public static inline var EVENT_TYPE_DEVICE_ADDED_SOFT:Int = 0x19D7;
	public static inline var EVENT_TYPE_DEVICE_REMOVED_SOFT:Int = 0x19D8;
	public static inline var EVENT_SUPPORTED_SOFT:Int = 0x19D9;
	public static inline var EVENT_NOT_SUPPORTED_SOFT:Int = 0x19DA;

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

	/**
		Returns `EVENT_SUPPORTED_SOFT` if OpenAL can report `eventType`, one of the
		`EVENT_TYPE_*_SOFT` values, for `deviceType`, which is `PLAYBACK_DEVICE_SOFT`
		or `CAPTURE_DEVICE_SOFT`, on this system. Returns `EVENT_NOT_SUPPORTED_SOFT`
		otherwise, and without the `ALC_SOFT_system_events` extension of OpenAL Soft.
	**/
	public static function eventIsSupported(eventType:Int, deviceType:Int):Int
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_alc_event_is_supported(eventType, deviceType);
		#else
		return EVENT_NOT_SUPPORTED_SOFT;
		#end
	}

	public static function getContextsDevice(context:ALContext):ALDevice
	{
		#if (lime_cffi && lime_openal && !macro)
		var handle:Dynamic = NativeCFFI.lime_alc_get_contexts_device(context);

		if (handle != null)
		{
			return new ALDevice(handle);
		}
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
		return CFFI.stringValue(result);
		#else
		return null;
		#end
	}

	/**
		Returns the strings OpenAL gives for `param`, one for each device when `device`
		is `null` and `param` is `DEVICE_SPECIFIER`, `CAPTURE_DEVICE_SPECIFIER` or
		`ALL_DEVICES_SPECIFIER`. `getString()` returns only the first of those.
	**/
	public static function getStringList(device:ALDevice, param:Int):Array<String>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_alc_get_string_list(device, param);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = CFFI.stringValue(result[i]);
		return _result;
		#else
		return result;
		#end
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

	/**
		Moves the playback `device` to the output named `deviceName`, or to the
		default output when `deviceName` is `null`, keeping its contexts, sources and
		buffers. Sources that were playing carry on from where they were.

		`attributes` are the same as for `createContext()`, ending with `0`, or
		`null` for the defaults. Needs the `ALC_SOFT_reopen_device` extension of
		OpenAL Soft. Returns `false` if the output could not be opened, and the
		device then keeps the output it had.
	**/
	public static function reopenDevice(device:ALDevice, deviceName:String = null, attributes:Array<Int> = null):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		if (device == null) return false;
		#if hl
		var _attributes = null;
		if (attributes != null)
		{
			_attributes = new hl.NativeArray<Int>(attributes.length);
			for (i in 0...attributes.length)
				_attributes[i] = attributes[i];
		}
		var attributes = _attributes;
		#end
		return NativeCFFI.lime_alc_reopen_device(device, deviceName, attributes);
		#else
		return false;
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

	public static function isExtensionPresent(device:ALDevice, extname:String):Bool
	{
		if (extname == null)
		{
			return false;
		}

		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_alc_is_extension_present(device, extname);
		#else
		return false;
		#end
	}

	public static function captureOpenDevice(deviceName:String = null, frequency:Int, format:Int, bufferSize:Int):ALDevice
	{
		#if (lime_cffi && lime_openal && !macro)
		var handle = NativeCFFI.lime_alc_capture_open_device(deviceName, frequency, format, bufferSize);

		if (handle != null)
		{
			return new ALDevice(handle);
		}
		#end

		return null;
	}

	public static function captureCloseDevice(device:ALDevice):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_alc_capture_close_device(device);
		#end

		return false;
	}

	public static function captureStart(device:ALDevice):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_alc_capture_start(device);
		#end
	}

	public static function captureStop(device:ALDevice):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_alc_capture_stop(device);
		#end
	}

	public static function captureSamples(device:ALDevice, buffer:Bytes, samples:Int):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_alc_capture_samples(device, buffer, samples);
		#end
	}

	// OpenAL Soft takes one event callback for the whole process. Lime keeps it and
	// queues the events, since they arrive on OpenAL's threads, and AudioManager
	// reads them on the main thread.
	@:allow(lime.media.AudioManager)
	private static function __eventControl(events:Array<Int>, enable:Bool):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _events = new hl.NativeArray<Int>(events.length);
		for (i in 0...events.length)
			_events[i] = events[i];
		return NativeCFFI.lime_alc_event_control(_events, enable);
		#else
		return NativeCFFI.lime_alc_event_control(events, enable);
		#end
		#else
		return false;
		#end
	}

	// Returns the queued events as pairs of event type and device type
	@:allow(lime.media.AudioManager)
	private static function __pollEvents():Array<Int>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_alc_poll_events();
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
		return [];
		#end
	}
}
#end
