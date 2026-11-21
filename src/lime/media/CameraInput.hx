package lime.media;

import lime.app.Event;
import lime.system.PermissionStatus;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

/**
	Captures video from a camera, a frame at a time, into the same
	`VideoFrame` that `VideoSource` fills, so camera and video are drawn the
	same way.

	Create an input for a device, `start` it, and call `readFrame` as often as
	frames are wanted, such as once per render. It returns `true` when a new
	frame has come since the last read, and only the newest frame is kept.

	The camera gives the size and rate nearest those asked for, which `width`,
	`height` and `frameRate` hold once the camera is open.

	Available on Windows (Media Foundation), macOS and iOS (AVFoundation),
	Android 5.0 and later (Camera2), Linux (GStreamer, through PipeWire or
	Video4Linux) and HTML5 (`getUserMedia`, which needs a secure context). On
	HTML5, frames carry the `<video>` element in `VideoFrame.src`, as
	`VideoSource` does there, and `data` is `null`. Native frames are in
	system memory, so the `TEXTURE` format is read as `RGBA`. On iOS and
	Android, frames come in the camera sensor's orientation, which is usually
	landscape whichever way the device is held. Flash is not supported.

	iOS and macOS end an application that opens the camera without saying
	why. Give the reason in project.xml with
	`<config:ios camera-usage-description="..." />` or
	`<config:mac camera-usage-description="..." />`. Android needs
	`<android permission="android.permission.CAMERA" />`, granted at runtime
	too. Listing any permission replaces Lime's default ones, so list
	`android.permission.INTERNET` and the others the application still needs.

	`permissionStatus` tells whether the user has allowed the camera, and
	`requestPermission` asks for it. The answer comes through `onPermission`.
	HTML5, Android, iOS and macOS ask the user. Windows asks nothing of desktop
	applications, but reports `DENIED` when camera access for them is off in
	its privacy settings. Linux reports `GRANTED`.

	@see lime.media.CameraInputDevice
	@see lime.media.VideoFrame
**/
class CameraInput
{
	/**
		The system's default camera, or `null` if there is none.
	**/
	public static var defaultDevice(get, never):CameraInputDevice;

	/**
		The cameras connected now, the default one first.
	**/
	public static var devices(get, never):Array<CameraInputDevice>;

	/**
		Whether cameras can be captured from on this platform.
	**/
	public static var isSupported(get, never):Bool;

	/**
		Dispatched on the main thread with `GRANTED` when the camera is allowed
		and `DENIED` when it is refused, once for each call to `requestPermission`,
		and on HTML5 also when the browser prompt from `start` is answered.
	**/
	public static var onPermission(default, null) = new Event<PermissionStatus->Void>();

	/**
		Whether the user has allowed the application to use the camera.
	**/
	public static var permissionStatus(get, never):PermissionStatus;

	/**
		The camera captured from.
	**/
	public var device(default, null):CameraInputDevice;

	/**
		The layout frames are read in.
	**/
	public var format(default, null):VideoFrameFormat;

	/**
		The rate the camera gives frames at, in frames per second, once it is
		open, or the rate asked for before.
	**/
	public var frameRate(default, null):Float;

	/**
		The height of the frames, once the camera is open, or the height asked
		for before.
	**/
	public var height(default, null):Int;

	/**
		Dispatched once when the camera is found disconnected, as when it is
		unplugged or another application takes it, after which the input stops.
	**/
	public var onDisconnect = new Event<Void->Void>();

	/**
		Dispatched with a message when the camera cannot be opened, as when it is
		missing, refused or in use.
	**/
	public var onError = new Event<String->Void>();

	/**
		Whether the camera is capturing. On HTML5 it becomes `true` once the
		browser has allowed the camera, after `start` returns.
	**/
	public var running(default, null):Bool;

	/**
		The width of the frames, once the camera is open, or the width asked for
		before.
	**/
	public var width(default, null):Int;

	@:noCompletion private var __backend:CameraInputBackend;
	@:noCompletion private var __disposed:Bool;

	/**
		Creates a new `CameraInput`. The camera is opened by `start`.

		@param device The camera to use. If `null`, the default camera is used.
		@param width The frame width to ask for, in pixels.
		@param height The frame height to ask for, in pixels.
		@param frameRate The frame rate to ask for, in frames per second.
		@param format The layout to read frames in.
	**/
	public function new(device:CameraInputDevice = null, width:Int = 640, height:Int = 480, frameRate:Float = 30, format:VideoFrameFormat = NV12)
	{
		this.device = device != null ? device : defaultDevice;
		this.width = width > 0 ? width : 640;
		this.height = height > 0 ? height : 480;
		this.frameRate = frameRate > 0 ? frameRate : 30;
		this.format = format;
		running = false;

		__backend = new CameraInputBackend(this);
	}

	/**
		Asks the user to allow the camera, if they have not answered yet, and
		dispatches `onPermission` with the answer. It does not open the camera,
		except on HTML5, where browsers only ask when a page opens it.
	**/
	public static function requestPermission():Void
	{
		CameraInputBackend.requestPermission();
	}

	/**
		Stops capturing and lets the camera go.
	**/
	public function dispose():Void
	{
		if (__disposed) return;

		stop();
		__backend.dispose();
		__disposed = true;
	}

	/**
		Reads the newest frame into `frame`, if one has come since the last read.

		@param frame The frame to fill. Its `data` is reallocated when it is too
		small.
		@return Whether `frame` holds a new frame.
	**/
	public function readFrame(frame:VideoFrame):Bool
	{
		if (__disposed || !running || frame == null) return false;

		return __backend.readFrame(frame);
	}

	/**
		Opens the camera, if it is not open, and starts capturing. When the
		camera cannot be opened, `onError` is dispatched and `running` stays
		`false`.
	**/
	public function start():Void
	{
		if (__disposed || running) return;

		running = __backend.start();
	}

	/**
		Stops capturing. The camera stays open until `dispose`, so `start` can
		carry on quickly.
	**/
	public function stop():Void
	{
		if (__disposed) return;

		__backend.stop();
		running = false;
	}

	@:noCompletion private static function get_defaultDevice():CameraInputDevice
	{
		var devices = get_devices();
		return devices.length > 0 ? devices[0] : null;
	}

	@:noCompletion private static function get_devices():Array<CameraInputDevice>
	{
		return CameraInputBackend.getDevices();
	}

	@:noCompletion private static function get_isSupported():Bool
	{
		return CameraInputBackend.isSupported();
	}

	@:noCompletion private static function get_permissionStatus():PermissionStatus
	{
		return CameraInputBackend.getPermissionStatus();
	}
}

#if flash
@:noCompletion private typedef CameraInputBackend = lime._internal.backend.flash.FlashCameraInput;
#elseif (js && html5)
@:noCompletion private typedef CameraInputBackend = lime._internal.backend.html5.HTML5CameraInput;
#else
@:noCompletion private typedef CameraInputBackend = lime._internal.backend.native.NativeCameraInput;
#end
