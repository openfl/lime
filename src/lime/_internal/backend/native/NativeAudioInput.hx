package lime._internal.backend.native;

import haxe.io.Bytes;
import haxe.Timer;
import lime.media.AudioInput;
import lime.media.AudioInputDevice;
import lime.system.CFFIPointer;
import lime.system.PermissionStatus;
#if android
import lime.system.JNI;
#end
#if (!lime_doc_gen || lime_openal)
import lime.media.openal.AL;
import lime.media.openal.ALC;
import lime.media.openal.ALDevice;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.media.AudioInput)
@:access(lime._internal.backend.native.NativeCFFI)
class NativeAudioInput
{
	private static inline var PERMISSION_POLL_MS = 100;

	#if android
	private static var lime_get_permission_status:String->Int;
	private static var lime_request_permission:String->Void;
	#end
	private static var permissionRequests:Int = 0;
	private static var permissionTimer:Timer;

	private var canReportDisconnect:Bool;
	private var disconnected:Bool;
	private var disposed:Bool;
	private var handle:#if (!lime_doc_gen || lime_openal) ALDevice #else Dynamic #end;
	private var parent:AudioInput;
	private var started:Bool;
	// The platform's voice processing capture, used instead of OpenAL while
	// processing is asked for
	private var voice:CFFIPointer;

	public static function getDefaultDevice():AudioInputDevice
	{
		#if (!lime_doc_gen || lime_openal)
		var name = ALC.getString(null, ALC.CAPTURE_DEFAULT_DEVICE_SPECIFIER);

		if (name == null || name == "")
		{
			return null;
		}

		return new AudioInputDevice(name, name, true);
		#else
		return null;
		#end
	}

	public static function getDevices():Array<AudioInputDevice>
	{
		#if (!lime_doc_gen || lime_openal)
		var defaultDevice = getDefaultDevice();
		var defaultName = defaultDevice != null ? defaultDevice.name : null;

		// The names come in one string, each ending in a null character, which getString() stops at
		return createDevices(ALC.getStringList(null, ALC.CAPTURE_DEVICE_SPECIFIER), defaultName);
		#else
		return [];
		#end
	}

	public static function getPermissionStatus():PermissionStatus
	{
		#if android
		if (lime_get_permission_status == null)
		{
			lime_get_permission_status = JNI.createStaticMethod("org/haxe/lime/GameActivity", "getPermissionStatus", "(Ljava/lang/String;)I");
		}

		return toPermissionStatus(lime_get_permission_status("android.permission.RECORD_AUDIO"));
		#elseif ((mac || ios) && (lime_cffi && !macro))
		return toPermissionStatus(NativeCFFI.lime_audio_input_get_permission_status());
		#else
		// Desktop applications on Windows and Linux are not asked
		return GRANTED;
		#end
	}

	public static function isSupported():Bool
	{
		return getDefaultDevice() != null || getDevices().length > 0;
	}

	public static function requestPermission():Void
	{
		if (getPermissionStatus() == UNDETERMINED)
		{
			#if android
			if (lime_request_permission == null)
			{
				lime_request_permission = JNI.createStaticMethod("org/haxe/lime/GameActivity", "requestPermission", "(Ljava/lang/String;)V");
			}

			lime_request_permission("android.permission.RECORD_AUDIO");
			#elseif ((mac || ios) && (lime_cffi && !macro))
			NativeCFFI.lime_audio_input_request_permission();
			#end
		}

		// The answer comes on another thread or activity, so it is polled here
		// and dispatched on the main thread, never before this call returns,
		// once for each request
		permissionRequests++;

		if (permissionTimer == null)
		{
			permissionTimer = new Timer(PERMISSION_POLL_MS);
			permissionTimer.run = pollPermission;
		}
	}

	public function new(parent:AudioInput)
	{
		this.parent = parent;

		open();
	}

	public function dispose():Void
	{
		if (disposed)
		{
			return;
		}

		stop();
		closeVoice();

		#if (!lime_doc_gen || lime_openal)
		if (handle != null)
		{
			ALC.captureCloseDevice(handle);
			handle = null;
		}
		#end

		disposed = true;
	}

	public function getProcessing():Int
	{
		#if (lime_cffi && !macro)
		if (voice != null)
		{
			return NativeCFFI.lime_voice_capture_get_processing(voice);
		}
		#end

		return 0;
	}

	public function getSamplesAvailable():Int
	{
		#if (lime_cffi && !macro)
		if (voice != null)
		{
			return isConnected() ? NativeCFFI.lime_voice_capture_get_available(voice) : 0;
		}
		#end

		#if (!lime_doc_gen || lime_openal)
		if (handle == null || !isConnected())
		{
			return 0;
		}

		var values = ALC.getIntegerv(handle, ALC.CAPTURE_SAMPLES, 1);

		if (values != null && values.length > 0)
		{
			return values[0];
		}
		#end

		return 0;
	}

	public function read(buffer:Bytes, samples:Int):Int
	{
		#if (!lime_doc_gen || lime_openal)
		if (!started || (handle == null && voice == null) || buffer == null || samples <= 0)
		{
			return 0;
		}

		var available = getSamplesAvailable();

		if (available <= 0)
		{
			return 0;
		}

		var samplesToRead = samples < available ? samples : available;
		var frameSize = getFrameSize();

		if (frameSize <= 0)
		{
			return 0;
		}

		var maxSamples = Std.int(buffer.length / frameSize);

		if (samplesToRead > maxSamples)
		{
			samplesToRead = maxSamples;
		}

		if (samplesToRead <= 0)
		{
			return 0;
		}

		#if (lime_cffi && !macro)
		if (voice != null)
		{
			return NativeCFFI.lime_voice_capture_read(voice, buffer, samplesToRead);
		}
		#end

		ALC.captureSamples(handle, buffer, samplesToRead);
		return samplesToRead;
		#end

		return 0;
	}

	public function start():Bool
	{
		#if (!lime_doc_gen || lime_openal)
		if (disposed)
		{
			return false;
		}

		if (parent.__processing != 0)
		{
			if (openVoice())
			{
				return started = true;
			}
		}
		else
		{
			closeVoice();
		}

		if (handle == null)
		{
			open();
		}

		if (handle == null)
		{
			return false;
		}

		ALC.captureStart(handle);
		started = true;
		return true;
		#else
		return false;
		#end
	}

	public function stop():Void
	{
		#if (lime_cffi && !macro)
		if (started && voice != null)
		{
			NativeCFFI.lime_voice_capture_stop(voice);
		}
		#end

		#if (!lime_doc_gen || lime_openal)
		if (started && handle != null)
		{
			ALC.captureStop(handle);
		}
		#end

		started = false;
	}

	private function closeVoice():Void
	{
		#if (lime_cffi && !macro)
		if (voice != null)
		{
			NativeCFFI.lime_voice_capture_close(voice);
			voice = null;
			disconnected = false;
		}
		#end
	}

	private function getFormat():Int
	{
		#if (!lime_doc_gen || lime_openal)
		if (parent.channels == 1)
		{
			if (parent.bitsPerSample == 8)
			{
				return AL.FORMAT_MONO8;
			}
			else if (parent.bitsPerSample == 16)
			{
				return AL.FORMAT_MONO16;
			}
		}
		else if (parent.channels == 2)
		{
			if (parent.bitsPerSample == 8)
			{
				return AL.FORMAT_STEREO8;
			}
			else if (parent.bitsPerSample == 16)
			{
				return AL.FORMAT_STEREO16;
			}
		}
		#end

		return 0;
	}

	private function getFrameSize():Int
	{
		return Std.int((parent.channels * parent.bitsPerSample) / 8);
	}

	private function open():Void
	{
		#if (!lime_doc_gen || lime_openal)
		if (handle != null)
		{
			return;
		}

		var format = getFormat();

		if (format == 0)
		{
			return;
		}

		var deviceName = parent.device != null && !parent.device.isDefault ? parent.device.id : null;
		handle = ALC.captureOpenDevice(deviceName, parent.sampleRate, format, parent.bufferSize);
		canReportDisconnect = handle != null && ALC.isExtensionPresent(handle, "ALC_EXT_disconnect");
		#end
	}

	// Opens the platform's voice processing capture, letting OpenAL's device go so the
	// two do not hold the microphone together. Where the platform has none, OpenAL
	// captures without processing.
	private function openVoice():Bool
	{
		#if (lime_cffi && !macro)
		if (voice == null)
		{
			if (parent.channels < 1 || parent.channels > 2 || (parent.bitsPerSample != 8 && parent.bitsPerSample != 16))
			{
				return false;
			}

			var deviceName = parent.device != null && !parent.device.isDefault ? parent.device.id : "";
			voice = NativeCFFI.lime_voice_capture_open(deviceName, parent.sampleRate, parent.channels, parent.bitsPerSample, parent.bufferSize,
				parent.__processing);

			if (voice == null)
			{
				return false;
			}

			disconnected = false;

			#if (!lime_doc_gen || lime_openal)
			if (handle != null)
			{
				ALC.captureCloseDevice(handle);
				handle = null;
			}
			#end
		}

		if (NativeCFFI.lime_voice_capture_start(voice))
		{
			return true;
		}

		closeVoice();
		#end

		return false;
	}

	// Polled with the samples, as the application polls for them, so onDisconnect is dispatched once
	// from samplesAvailable or read
	private function isConnected():Bool
	{
		if (disconnected)
		{
			return false;
		}

		#if (lime_cffi && !macro)
		if (voice != null)
		{
			if (!NativeCFFI.lime_voice_capture_is_connected(voice))
			{
				setDisconnected();
				return false;
			}

			return true;
		}
		#end

		#if (!lime_doc_gen || lime_openal)
		if (!canReportDisconnect)
		{
			return true;
		}

		var values = ALC.getIntegerv(handle, ALC.CONNECTED, 1);

		if (values != null && values.length > 0 && values[0] == ALC.FALSE)
		{
			setDisconnected();
			return false;
		}
		#end

		return true;
	}

	private function setDisconnected():Void
	{
		disconnected = true;
		stop();
		parent.running = false;
		parent.onDisconnect.dispatch();
	}

	private static function pollPermission():Void
	{
		var status = getPermissionStatus();

		if (status == UNDETERMINED)
		{
			return;
		}

		permissionTimer.stop();
		permissionTimer = null;

		var requests = permissionRequests;
		permissionRequests = 0;

		for (i in 0...requests)
		{
			AudioInput.onPermission.dispatch(status == GRANTED);
		}
	}

	// 0 is undetermined, 1 granted and 2 denied, from both the JNI and the CFFI calls
	private static function toPermissionStatus(value:Int):PermissionStatus
	{
		return switch (value)
		{
			case 1: GRANTED;
			case 2: DENIED;
			default: UNDETERMINED;
		}
	}

	private static function createDevices(names:Array<String>, defaultName:String):Array<AudioInputDevice>
	{
		var devices = [];
		var hasDefault = false;

		if (names == null)
		{
			names = [];
		}

		for (name in names)
		{
			if (name == null || name == "")
			{
				continue;
			}

			var isDefault = name == defaultName;
			hasDefault = hasDefault || isDefault;
			devices.push(new AudioInputDevice(name, name, isDefault));
		}

		if (!hasDefault && defaultName != null && defaultName != "")
		{
			devices.unshift(new AudioInputDevice(defaultName, defaultName, true));
		}

		return devices;
	}
}
