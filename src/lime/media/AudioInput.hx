package lime.media;

import haxe.io.Bytes;
import lime.app.Event;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

/**
	The `AudioInput` class provides polling-based access to microphone or other
	audio capture input.

	`AudioInput` reads raw PCM sample frames into a `Bytes` buffer. Use
	`samplesAvailable` to determine how many sample frames can be read without
	blocking, then call `read`.

	@see lime.media.AudioInputDevice
	@see lime.media.AudioBuffer
**/
class AudioInput
{
	/**
		The backend's default audio input device, or `null` if capture is not
		available.
	**/
	public static var defaultDevice(get, never):AudioInputDevice;

	/**
		The available audio input devices reported by the backend.
	**/
	public static var devices(get, never):Array<AudioInputDevice>;

	/**
		Whether audio input capture is supported by the current backend.
	**/
	public static var isSupported(get, never):Bool;

	/**
		The number of bits per sample used by this input.
	**/
	public var bitsPerSample(default, null):Int;

	/**
		The capture buffer size, in sample frames.
	**/
	public var bufferSize(default, null):Int;

	/**
		The number of capture channels.
	**/
	public var channels(default, null):Int;

	/**
		The audio input device used by this input.
	**/
	public var device(default, null):AudioInputDevice;

	/**
		An event that is dispatched if the backend reports that the input device
		has disconnected.
	**/
	public var onDisconnect = new Event<Void->Void>();

	/**
		Whether this input is currently capturing.
	**/
	public var running(default, null):Bool;

	/**
		The capture sample rate, in Hz.
	**/
	public var sampleRate(default, null):Int;

	/**
		The number of sample frames currently available to read.
	**/
	public var samplesAvailable(get, never):Int;

	@:noCompletion private var __backend:AudioInputBackend;
	@:noCompletion private var __disposed:Bool;

	/**
		Creates a new `AudioInput` instance.

		@param device The input device to use. If `null`, the backend default is used.
		@param sampleRate The requested capture sample rate, in Hz.
		@param channels The requested channel count.
		@param bitsPerSample The requested bits per sample.
		@param bufferSize The capture buffer size, in sample frames.
	**/
	public function new(device:AudioInputDevice = null, sampleRate:Int = 44100, channels:Int = 1, bitsPerSample:Int = 16, bufferSize:Int = 4096)
	{
		this.device = device != null ? device : defaultDevice;
		this.sampleRate = sampleRate > 0 ? sampleRate : 44100;
		this.channels = channels;
		this.bitsPerSample = bitsPerSample;
		this.bufferSize = bufferSize > 0 ? bufferSize : 4096;
		running = false;

		__backend = new AudioInputBackend(this);
	}

	/**
		Releases any resources used by this `AudioInput`.
	**/
	public function dispose():Void
	{
		if (__disposed)
		{
			return;
		}

		stop();
		__backend.dispose();
		__disposed = true;
	}

	/**
		Reads captured PCM sample frames into `buffer`.

		@param buffer The destination buffer.
		@param samples The maximum number of sample frames to read.
		@return The number of sample frames actually read.
	**/
	public function read(buffer:Bytes, samples:Int):Int
	{
		if (__disposed)
		{
			return 0;
		}

		return __backend.read(buffer, samples);
	}

	/**
		Starts audio capture.

		On backends that require asynchronous permission, such as HTML5,
		`running` may become true after this method returns.
	**/
	public function start():Void
	{
		if (__disposed || running)
		{
			return;
		}

		running = __backend.start();
	}

	/**
		Stops audio capture.
	**/
	public function stop():Void
	{
		if (__disposed)
		{
			return;
		}

		__backend.stop();
		running = false;
	}

	@:noCompletion private static function get_defaultDevice():AudioInputDevice
	{
		return AudioInputBackend.getDefaultDevice();
	}

	@:noCompletion private static function get_devices():Array<AudioInputDevice>
	{
		return AudioInputBackend.getDevices();
	}

	@:noCompletion private static function get_isSupported():Bool
	{
		return AudioInputBackend.isSupported();
	}

	@:noCompletion private function get_samplesAvailable():Int
	{
		if (__disposed)
		{
			return 0;
		}

		return __backend.getSamplesAvailable();
	}
}

#if flash
@:noCompletion private typedef AudioInputBackend = lime._internal.backend.flash.FlashAudioInput;
#elseif (js && html5)
@:noCompletion private typedef AudioInputBackend = lime._internal.backend.html5.HTML5AudioInput;
#else
@:noCompletion private typedef AudioInputBackend = lime._internal.backend.native.NativeAudioInput;
#end
