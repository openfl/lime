package lime._internal.backend.html5;

import haxe.Timer;
import js.Browser;
import lime.media.CameraInput;
import lime.media.CameraInputDevice;
import lime.media.CameraPosition;
import lime.media.VideoFrame;
import lime.system.PermissionStatus;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.media.CameraInput)
class HTML5CameraInput
{
	private static var cachedDevices:Array<CameraInputDevice>;
	private static var enumeratingDevices:Bool;
	private static var permissionQueried:Bool;
	private static var permissionRequests:Int = 0;
	private static var permissionState:PermissionStatus = UNDETERMINED;

	private var disposed:Bool;
	private var element:Dynamic;
	private var frameTime:Float = -1;
	private var mediaStream:Dynamic;
	private var parent:CameraInput;
	private var presentedTime:Float = -1;
	private var starting:Bool;

	public static function getDevices():Array<CameraInputDevice>
	{
		refreshDevices();

		if (cachedDevices != null) return cachedDevices.copy();

		// Browsers list cameras once they have one, so before that the default
		// camera stands for them
		return isSupported() ? [new CameraInputDevice("Default Camera", "", UNKNOWN, true)] : [];
	}

	public static function getPermissionStatus():PermissionStatus
	{
		queryPermission();
		return permissionState;
	}

	public static function isSupported():Bool
	{
		var navigator:Dynamic = Browser.navigator;
		return navigator != null && navigator.mediaDevices != null && navigator.mediaDevices.getUserMedia != null;
	}

	public static function requestPermission():Void
	{
		if (!isSupported())
		{
			// Without a secure context there is no getUserMedia to ask with
			Timer.delay(CameraInput.onPermission.dispatch.bind(false), 0);
			return;
		}

		queryPermission();
		permissionRequests++;

		var navigator:Dynamic = Browser.navigator;
		var promise:Dynamic = navigator.mediaDevices.getUserMedia({video: true});

		promise.then(function(stream)
		{
			// Browsers only ask when a page opens the camera, so it is closed again at once
			stopMediaStream(stream);
			permissionRequests--;
			permissionState = GRANTED;
			refreshDevices();
			CameraInput.onPermission.dispatch(true);
		}, function(error)
		{
			permissionRequests--;
			if (isPermissionError(error)) permissionState = DENIED;
			CameraInput.onPermission.dispatch(false);
		});
	}

	public function new(parent:CameraInput)
	{
		this.parent = parent;
	}

	public function dispose():Void
	{
		stop();
		disposed = true;
	}

	public function readFrame(frame:VideoFrame):Bool
	{
		// HAVE_CURRENT_DATA, so the element has a picture to upload
		if (element == null || element.readyState < 2) return false;

		// Where the browser says when each frame is presented, a frame is only read
		// once; elsewhere the media clock stands for it
		var time:Float = presentedTime >= 0 ? presentedTime : element.currentTime;
		if (time == frameTime) return false;

		frameTime = time;

		frame.data = null;
		frame.duration = parent.frameRate > 0 ? 1 / parent.frameRate : 0;
		frame.format = RGBA;
		frame.fullRange = true;
		frame.height = element.videoHeight;
		frame.length = 0;
		frame.src = element;
		frame.time = time;
		frame.width = element.videoWidth;
		return true;
	}

	public function start():Bool
	{
		if (!isSupported())
		{
			parent.onError.dispatch("Cameras are not supported here, as getUserMedia needs a secure context");
			return false;
		}

		if (starting) return false;
		starting = true;

		var video:Dynamic = {
			width: {ideal: parent.width},
			height: {ideal: parent.height},
			frameRate: {ideal: parent.frameRate}
		};

		if (parent.device != null && !parent.device.isDefault && parent.device.id != null && parent.device.id != "")
		{
			video.deviceId = {exact: parent.device.id};
		}

		var navigator:Dynamic = Browser.navigator;
		var promise:Dynamic = navigator.mediaDevices.getUserMedia({video: video});

		queryPermission();
		permissionRequests++;

		promise.then(function(stream)
		{
			permissionRequests--;
			starting = false;
			setPermissionState(GRANTED, true);

			if (disposed)
			{
				stopMediaStream(stream);
				return;
			}

			open(stream);
		}, function(error)
		{
			permissionRequests--;
			starting = false;

			if (isPermissionError(error)) setPermissionState(DENIED, true);

			var message:String = error != null && error.message != null && error.message != "" ? error.message : "The camera could not be opened";
			parent.onError.dispatch(message);
		});

		// running becomes true once the browser hands over the camera
		return false;
	}

	public function stop():Void
	{
		starting = false;
		stopMediaStream(mediaStream);
		mediaStream = null;

		if (element != null)
		{
			element.pause();
			element.srcObject = null;
			element = null;
		}

		frameTime = -1;
		presentedTime = -1;
	}

	private function open(stream:Dynamic):Void
	{
		mediaStream = stream;

		var tracks:Dynamic = stream.getVideoTracks();
		var track:Dynamic = tracks.length > 0 ? tracks[0] : null;

		if (track != null && track.getSettings != null)
		{
			var settings:Dynamic = track.getSettings();
			if (settings.width != null) parent.width = settings.width;
			if (settings.height != null) parent.height = settings.height;
			if (settings.frameRate != null) parent.frameRate = settings.frameRate;
		}

		if (track != null)
		{
			// A track ends when its camera is unplugged or the permission is taken back, not when it is stopped
			track.onended = function(event)
			{
				if (disposed || mediaStream != stream) return;
				stop();
				parent.running = false;
				parent.onDisconnect.dispatch();
			};
		}

		element = Browser.document.createElement("video");
		element.muted = true;
		element.playsInline = true;
		element.setAttribute("playsinline", "");
		element.srcObject = stream;
		element.play();

		watchFrames(element);
		refreshDevices();
		parent.running = true;
	}

	private function watchFrames(video:Dynamic):Void
	{
		if (video.requestVideoFrameCallback == null) return;

		video.requestVideoFrameCallback(function(now:Float, metadata:Dynamic)
		{
			if (element != video) return;
			presentedTime = metadata != null && metadata.mediaTime != null ? metadata.mediaTime : video.currentTime;
			watchFrames(video);
		});
	}

	private static function isPermissionError(error:Dynamic):Bool
	{
		var name:String = error != null ? error.name : null;

		// PermissionDeniedError is what older Chrome versions used
		return name == "NotAllowedError" || name == "SecurityError" || name == "PermissionDeniedError";
	}

	private static function queryPermission():Void
	{
		if (permissionQueried) return;
		permissionQueried = true;

		var navigator:Dynamic = Browser.navigator;
		if (navigator == null || navigator.permissions == null || navigator.permissions.query == null) return;

		try
		{
			var promise:Dynamic = navigator.permissions.query({name: "camera"});

			promise.then(function(status:Dynamic)
			{
				if (permissionState == UNDETERMINED) permissionState = toPermissionStatus(status.state);

				status.onchange = function(event)
				{
					// A pending request dispatches the answer itself
					setPermissionState(toPermissionStatus(status.state), permissionRequests == 0);
				};
			}, function(error) {});
		}
		catch (e:Dynamic)
		{
			// Some browsers throw for a permission name they do not know
		}
	}

	private static function refreshDevices():Void
	{
		if (enumeratingDevices || !isSupported()) return;
		enumeratingDevices = true;

		var navigator:Dynamic = Browser.navigator;
		var promise:Dynamic = navigator.mediaDevices.enumerateDevices();

		promise.then(function(devices)
		{
			var result:Array<CameraInputDevice> = [];
			var length:Int = devices.length;

			for (i in 0...length)
			{
				var device:Dynamic = devices[i];
				if (device.kind != "videoinput") continue;

				var label:String = device.label != null && device.label != "" ? device.label : "Camera";
				result.push(new CameraInputDevice(label, device.deviceId, getPosition(device), result.length == 0));
			}

			if (result.length > 0) cachedDevices = result;
			enumeratingDevices = false;
		}, function(error)
		{
			enumeratingDevices = false;
		});
	}

	// Mobile browsers tell which way a camera faces through its capabilities
	private static function getPosition(device:Dynamic):CameraPosition
	{
		if (device.getCapabilities == null) return UNKNOWN;

		var capabilities:Dynamic = device.getCapabilities();
		var facing:Array<String> = capabilities != null ? capabilities.facingMode : null;
		if (facing == null || facing.length == 0) return UNKNOWN;

		return switch (facing[0])
		{
			case "user": FRONT;
			case "environment": BACK;
			default: UNKNOWN;
		}
	}

	private static function setPermissionState(status:PermissionStatus, dispatch:Bool):Void
	{
		if (status == permissionState) return;

		permissionState = status;

		if (dispatch && status != UNDETERMINED)
		{
			CameraInput.onPermission.dispatch(status == GRANTED);
		}
	}

	private static function stopMediaStream(stream:Dynamic):Void
	{
		if (stream == null || stream.getTracks == null) return;

		var tracks:Dynamic = stream.getTracks();
		var length:Int = tracks.length;

		for (i in 0...length)
		{
			tracks[i].stop();
		}
	}

	private static function toPermissionStatus(state:String):PermissionStatus
	{
		return switch (state)
		{
			case "granted": GRANTED;
			case "denied": DENIED;
			default: UNDETERMINED;
		}
	}
}
