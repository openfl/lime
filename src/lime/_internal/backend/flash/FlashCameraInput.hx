package lime._internal.backend.flash;

import lime.media.CameraInput;
import lime.media.CameraInputDevice;
import lime.media.VideoFrame;
import lime.system.PermissionStatus;

// Flash's Camera draws into a Video display object rather than handing over
// frames, so CameraInput is not supported there
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.media.CameraInput)
class FlashCameraInput
{
	private var parent:CameraInput;

	public static function getDevices():Array<CameraInputDevice>
	{
		return [];
	}

	public static function getPermissionStatus():PermissionStatus
	{
		return UNDETERMINED;
	}

	public static function isSupported():Bool
	{
		return false;
	}

	public static function requestPermission():Void
	{
		haxe.Timer.delay(CameraInput.onPermission.dispatch.bind(false), 0);
	}

	public function new(parent:CameraInput)
	{
		this.parent = parent;
	}

	public function dispose():Void {}

	public function readFrame(frame:VideoFrame):Bool
	{
		return false;
	}

	public function start():Bool
	{
		parent.onError.dispatch("Cameras are not supported on Flash");
		return false;
	}

	public function stop():Void {}
}
