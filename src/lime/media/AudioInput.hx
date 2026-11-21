package lime.media;

import haxe.io.Bytes;
import lime.app.Event;
import lime.system.PermissionStatus;

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

	Samples are 8 or 16 bits, in 1 or 2 channels; with another format, `start`
	returns `false`. On native targets the device is opened when the input is
	created, so the system's permission prompt can come before `start`.

	iOS and macOS end an application that opens the microphone without saying
	why. Give the reason in project.xml with
	`<config:ios microphone-usage-description="..." />` or
	`<config:mac microphone-usage-description="..." />`. Android needs
	`<android permission="android.permission.RECORD_AUDIO" />`, granted at
	runtime too. Listing any permission replaces Lime's default ones, so list
	`android.permission.INTERNET` and the others the application still needs.

	`permissionStatus` tells whether the user has allowed the microphone, and
	`requestPermission` asks for it without starting a capture. The answer comes
	through `onPermission`. HTML5, Android, iOS and macOS ask the user; Windows
	and Linux have no prompt for desktop applications and report `GRANTED`.

	`echoCancellation`, `noiseSuppression` and `autoGain` ask for the
	platform's own voice processing, set before `start`: the `getUserMedia`
	constraints on HTML5, the communications category on Windows, the voice
	processing I/O unit on macOS and iOS, the voice communication source with
	Android's audio effects on Android, and the enhanced microphone on Flash.
	Once the input is running, each one reads whether the platform applied it.
	They read `false` on Linux, which leaves voice processing to the sound
	server, on Windows before Windows 11, which cannot tell what it applied,
	and on Android before 6.0. With any of them set, native targets capture
	through the platform's mode instead of OpenAL, from the default device on
	macOS, iOS and Android. On iOS the audio session plays and records while
	capturing. macOS and iOS lower other sound while they process the voice,
	as little as they can from macOS 14 and iOS 17.

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
		Dispatched on the main thread with `true` when the microphone is allowed
		and `false` when it is refused. It is dispatched once for each call to
		`requestPermission`, when the user answers or at once if they already
		have, and also when the status changes another way: on HTML5 when the
		browser prompt from `start` is answered, or when the user changes the
		site's setting.
	**/
	public static var onPermission(default, null) = new Event<Bool->Void>();

	/**
		Whether the user has allowed the application to use the microphone.

		HTML5 reports `UNDETERMINED` until the browser answers a permission query,
		which some browsers do not support for the microphone; it learns the
		status from `requestPermission` and `start` there too. Android, iOS and
		macOS report the system's status. Windows and Linux report `GRANTED`.
		Flash reports `GRANTED` once the user has allowed it in the Flash
		Player dialog, and on AIR the runtime's status.
	**/
	public static var permissionStatus(get, never):PermissionStatus;

	/**
		Whether the platform's automatic gain control evens out the level of
		the microphone. Set it before `start`; once the input is running, it
		reads whether the platform applied it.
	**/
	public var autoGain(get, set):Bool;

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
		Whether the platform's echo cancellation takes what the device plays
		back out of what the microphone hears, so a speaker's sound does not
		come back to the other end of a call. Set it before `start`; once the
		input is running, it reads whether the platform applied it.
	**/
	public var echoCancellation(get, set):Bool;

	/**
		Whether the platform's noise suppression takes steady background noise
		out of the microphone's signal. Set it before `start`; once the input is
		running, it reads whether the platform applied it.
	**/
	public var noiseSuppression(get, set):Bool;

	/**
		Dispatched once when the input device is found disconnected, after which
		the input stops. Native targets find it while `samplesAvailable` or
		`read` is polled, where OpenAL Soft reports it; browsers when the
		device's track ends, as when it is unplugged or the permission is taken
		back. Flash does not report it.
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

	@:noCompletion private static inline var ECHO_CANCELLATION:Int = 1;
	@:noCompletion private static inline var NOISE_SUPPRESSION:Int = 2;
	@:noCompletion private static inline var AUTO_GAIN:Int = 4;

	@:noCompletion private var __backend:AudioInputBackend;
	@:noCompletion private var __disposed:Bool;
	@:noCompletion private var __processing:Int = 0;

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
		Asks the user to allow the microphone, if they have not answered yet,
		and dispatches `onPermission` with the answer. It does not start a
		capture.

		On HTML5 this opens the microphone briefly, since browsers only ask when
		a page opens it, and needs a secure context. On Android it shows the
		`RECORD_AUDIO` dialog, which needs the permission in project.xml; once
		the user refuses twice, Android stops asking and the answer is `false`.
	**/
	public static function requestPermission():Void
	{
		AudioInputBackend.requestPermission();
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

	// The processing asked for, and once running, what the backend applied
	@:noCompletion private function __getProcessing(flag:Int):Bool
	{
		var processing = running && !__disposed ? __backend.getProcessing() : __processing;
		return (processing & flag) != 0;
	}

	@:noCompletion private function __setProcessing(flag:Int, value:Bool):Bool
	{
		__processing = value ? __processing | flag : __processing & ~flag;
		return value;
	}

	@:noCompletion private function get_autoGain():Bool
	{
		return __getProcessing(AUTO_GAIN);
	}

	@:noCompletion private function set_autoGain(value:Bool):Bool
	{
		return __setProcessing(AUTO_GAIN, value);
	}

	@:noCompletion private static function get_defaultDevice():AudioInputDevice
	{
		return AudioInputBackend.getDefaultDevice();
	}

	@:noCompletion private static function get_devices():Array<AudioInputDevice>
	{
		return AudioInputBackend.getDevices();
	}

	@:noCompletion private function get_echoCancellation():Bool
	{
		return __getProcessing(ECHO_CANCELLATION);
	}

	@:noCompletion private function set_echoCancellation(value:Bool):Bool
	{
		return __setProcessing(ECHO_CANCELLATION, value);
	}

	@:noCompletion private static function get_isSupported():Bool
	{
		return AudioInputBackend.isSupported();
	}

	@:noCompletion private function get_noiseSuppression():Bool
	{
		return __getProcessing(NOISE_SUPPRESSION);
	}

	@:noCompletion private function set_noiseSuppression(value:Bool):Bool
	{
		return __setProcessing(NOISE_SUPPRESSION, value);
	}

	@:noCompletion private static function get_permissionStatus():PermissionStatus
	{
		return AudioInputBackend.getPermissionStatus();
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
