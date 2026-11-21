package lime._internal.backend.native;

import haxe.Timer;
import lime.media.CameraInput;
import lime.media.CameraInputDevice;
import lime.media.CameraPosition;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import lime.system.CFFI;
import lime.system.CFFIPointer;
import lime.system.PermissionStatus;
import lime.utils.UInt8Array;
#if android
import lime.system.JNI;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.media.CameraInput)
@:access(lime._internal.backend.native.NativeCFFI)
class NativeCameraInput
{
	private static inline var PERMISSION_POLL_MS = 100;

	// What lime_camera_capture_get_property reads
	private static inline var WIDTH = 0;
	private static inline var HEIGHT = 1;
	private static inline var FRAME_RATE = 2;
	private static inline var FRAME_WIDTH = 3;
	private static inline var FRAME_HEIGHT = 4;
	private static inline var FRAME_LENGTH = 5;
	private static inline var FRAME_COLOR_MATRIX = 6;
	private static inline var FRAME_FULL_RANGE = 7;
	private static inline var FRAME_TIME = 8;

	// ReadFrame results, as VideoDecoder's
	private static inline var READ_BUFFER_TOO_SMALL = -3;

	#if android
	private static var lime_get_permission_status:String->Int;
	private static var lime_request_permission:String->Void;
	#end
	private static var permissionRequests:Int = 0;
	private static var permissionTimer:Timer;

	private var disconnected:Bool;
	private var handle:CFFIPointer;
	private var parent:CameraInput;

	public static function getDevices():Array<CameraInputDevice>
	{
		var devices = [];

		#if (lime_cffi && !macro)
		var text:String = CFFI.stringValue(NativeCFFI.lime_camera_capture_get_devices());
		if (text == null || text == "") return devices;

		for (record in text.split("\x1E"))
		{
			var fields = record.split("\x1F");
			if (fields.length < 3) continue;

			var position:CameraPosition = switch (fields[2])
			{
				case "1": FRONT;
				case "2": BACK;
				default: UNKNOWN;
			}

			devices.push(new CameraInputDevice(fields[1], fields[0], position, devices.length == 0));
		}
		#end

		return devices;
	}

	public static function getPermissionStatus():PermissionStatus
	{
		#if android
		if (lime_get_permission_status == null)
		{
			lime_get_permission_status = JNI.createStaticMethod("org/haxe/lime/GameActivity", "getPermissionStatus", "(Ljava/lang/String;)I");
		}

		return toPermissionStatus(lime_get_permission_status("android.permission.CAMERA"));
		#elseif (lime_cffi && !macro)
		return toPermissionStatus(NativeCFFI.lime_camera_capture_get_permission_status());
		#else
		return UNDETERMINED;
		#end
	}

	public static function isSupported():Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_camera_capture_is_supported();
		#else
		return false;
		#end
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

			lime_request_permission("android.permission.CAMERA");
			#elseif (lime_cffi && !macro)
			NativeCFFI.lime_camera_capture_request_permission();
			#end
		}

		// The answer comes on another thread or activity, so it is polled here and
		// dispatched on the main thread, never before this call returns, once for
		// each request
		permissionRequests++;

		if (permissionTimer == null)
		{
			permissionTimer = new Timer(PERMISSION_POLL_MS);
			permissionTimer.run = pollPermission;
		}
	}

	public function new(parent:CameraInput)
	{
		this.parent = parent;
	}

	public function dispose():Void
	{
		#if (lime_cffi && !macro)
		if (handle != null)
		{
			NativeCFFI.lime_camera_capture_close(handle);
			handle = null;
		}
		#end
	}

	public function readFrame(frame:VideoFrame):Bool
	{
		#if (lime_cffi && !macro)
		if (handle == null || !isConnected()) return false;

		var format:Int = parent.format == TEXTURE ? RGBA : parent.format;
		var result = read(format, frame.data);

		if (result == READ_BUFFER_TOO_SMALL)
		{
			frame.data = new UInt8Array(Std.int(NativeCFFI.lime_camera_capture_get_property(handle, FRAME_LENGTH)));
			result = read(format, frame.data);
		}

		if (result <= 0) return false;

		frame.colorMatrix = Std.int(NativeCFFI.lime_camera_capture_get_property(handle, FRAME_COLOR_MATRIX));
		frame.duration = parent.frameRate > 0 ? 1 / parent.frameRate : 0;
		frame.format = format;
		frame.fullRange = NativeCFFI.lime_camera_capture_get_property(handle, FRAME_FULL_RANGE) != 0;
		frame.height = Std.int(NativeCFFI.lime_camera_capture_get_property(handle, FRAME_HEIGHT));
		frame.length = result;
		frame.src = null;
		frame.time = NativeCFFI.lime_camera_capture_get_property(handle, FRAME_TIME);
		frame.width = Std.int(NativeCFFI.lime_camera_capture_get_property(handle, FRAME_WIDTH));
		#if (lime_opengl || lime_opengles)
		frame.texture = null;
		#end
		return true;
		#else
		return false;
		#end
	}

	public function start():Bool
	{
		#if (lime_cffi && !macro)
		if (handle == null)
		{
			var id = parent.device != null && parent.device.id != null ? parent.device.id : "";
			handle = NativeCFFI.lime_camera_capture_open(id, parent.width, parent.height, parent.frameRate);

			if (handle == null)
			{
				parent.onError.dispatch(isSupported() ? "The camera could not be opened" : "Cameras are not supported on this platform");
				return false;
			}

			disconnected = false;
			parent.width = Std.int(NativeCFFI.lime_camera_capture_get_property(handle, WIDTH));
			parent.height = Std.int(NativeCFFI.lime_camera_capture_get_property(handle, HEIGHT));

			var rate = NativeCFFI.lime_camera_capture_get_property(handle, FRAME_RATE);
			if (rate > 0) parent.frameRate = rate;
		}

		return NativeCFFI.lime_camera_capture_start(handle);
		#else
		parent.onError.dispatch("Cameras are not supported on this platform");
		return false;
		#end
	}

	public function stop():Void
	{
		#if (lime_cffi && !macro)
		if (handle != null) NativeCFFI.lime_camera_capture_stop(handle);
		#end
	}

	// Polled with the frames, as the application polls for them, so onDisconnect is
	// dispatched once from readFrame
	private function isConnected():Bool
	{
		if (disconnected) return false;

		#if (lime_cffi && !macro)
		if (!NativeCFFI.lime_camera_capture_is_connected(handle))
		{
			disconnected = true;
			stop();
			parent.running = false;
			parent.onDisconnect.dispatch();
			return false;
		}
		#end

		return true;
	}

	private function read(format:Int, data:UInt8Array):Int
	{
		#if (lime_cffi && !macro)
		if (data == null)
		{
			return NativeCFFI.lime_camera_capture_read_frame(handle, format, null, 0, 0);
		}

		return NativeCFFI.lime_camera_capture_read_frame(handle, format, data.buffer, data.byteOffset, data.byteLength);
		#else
		return 0;
		#end
	}

	private static function pollPermission():Void
	{
		var status = getPermissionStatus();
		if (status == UNDETERMINED) return;

		permissionTimer.stop();
		permissionTimer = null;

		var requests = permissionRequests;
		permissionRequests = 0;

		for (i in 0...requests)
		{
			CameraInput.onPermission.dispatch(status);
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
}
