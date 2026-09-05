package lime._internal.backend.native;

import haxe.io.Bytes;
import lime.media.AudioInput;
import lime.media.AudioInputDevice;
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
class NativeAudioInput
{
	private var disposed:Bool;
	private var handle:#if (!lime_doc_gen || lime_openal) ALDevice #else Dynamic #end;
	private var parent:AudioInput;
	private var started:Bool;

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
		var devices = parseDeviceList(ALC.getString(null, ALC.CAPTURE_DEVICE_SPECIFIER), defaultName);

		if (devices.length == 0 && defaultDevice != null)
		{
			devices.push(defaultDevice);
		}

		return devices;
		#else
		return [];
		#end
	}

	public static function isSupported():Bool
	{
		return getDefaultDevice() != null || getDevices().length > 0;
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

		#if (!lime_doc_gen || lime_openal)
		if (handle != null)
		{
			ALC.captureCloseDevice(handle);
			handle = null;
		}
		#end

		disposed = true;
	}

	public function getSamplesAvailable():Int
	{
		#if (!lime_doc_gen || lime_openal)
		if (handle == null)
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
		if (!started || handle == null || buffer == null || samples <= 0)
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
		#if (!lime_doc_gen || lime_openal)
		if (started && handle != null)
		{
			ALC.captureStop(handle);
		}
		#end

		started = false;
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
		#end
	}

	private static function parseDeviceList(value:String, defaultName:String):Array<AudioInputDevice>
	{
		var devices = [];

		if (value == null || value == "")
		{
			return devices;
		}

		var hasDefault = false;
		var names = value.split(String.fromCharCode(0));

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
