package lime.media;

import haxe.Timer;
import lime._internal.backend.native.NativeCFFI;
import lime.media.openal.AL;
import lime.media.openal.ALC;
import lime.media.openal.ALContext;
import lime.media.openal.ALDevice;
#if (js && html5)
import js.Browser;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class AudioManager
{
	public static var context:AudioContext;

	public static function init(context:AudioContext = null)
	{
		if (AudioManager.context == null)
		{
			if (context == null)
			{
				AudioManager.context = new AudioContext();
				context = AudioManager.context;

				#if !lime_doc_gen
				if (context.type == OPENAL)
				{
					var alc = context.openal;

					var device = alc.openDevice();
					var ctx = alc.createContext(device);
					alc.makeContextCurrent(ctx);
					alc.processContext(ctx);
					trace(device);

					// AL_STOP_SOURCES_ON_DISCONNECT_SOFT
					alc.disable(AL.STOP_SOURCES_ON_DISCONNECT_SOFT);

					// todo: check if alcExtension ALC_SOFT_system_events is present
					// alc.eventCallbackSOFT(device, () ->
					// {
					// 	Sys.println("what the !");
					// });

					// var timer = new Timer(100);
					// timer.run = function()
					// {
					// 	// ALC_CONNECTED = 0x313
					// 	// Checks if device connected
					// 	var a = alc.getIntegerv(0x313, 1, device);
					// 	trace(a);
					// 	if (a[0] == 0)
					// 	{
					// 		timer.stop();
					// 		trace(device);
					// 		var m = new sys.thread.Mutex();
					// 		m.acquire();
					// 		var p = alc.reopenDeviceSOFT(device, null, 0);
					// 		m.release();
					// 		trace(device);
					// 		trace(p);
					// 	}
					// }

					// new Timer(1000).run = () ->
					// {
					// 	trace("AL: " + alc.getError() + " , " + alc.getErrorString());
					// 	trace("ALC: " + alc.getError(device) + " , " + alc.getErrorString(device));
					// }

					ALC.eventControlSOFT(3, [
						ALC.EVENT_TYPE_DEFAULT_DEVICE_CHANGED_SOFT,
						ALC.EVENT_TYPE_DEVICE_ADDED_SOFT,
						ALC.EVENT_TYPE_DEVICE_REMOVED_SOFT
					], true);
					ALC.eventCallbackSOFT((device), __temp__SoftCallback);
				}
				#end
			}

			AudioManager.context = context;

			#if (lime_cffi && !macro && lime_openal && (ios || tvos || mac))
			var timer = new Timer(100);
			timer.run = function()
			{
				NativeCFFI.lime_al_cleanup();
			};
			#end
		}
	}

	static function __temp__SoftCallback():Void
	{
		trace("Hello from Haxe !!!");
	}

	static var delayTimer:Float;
	static var auxDirty:Bool = false;
	public static function update():Void
	{
		if (!auxDirty)
		{

			var alc = AudioManager.context.openal;
			var device = alc.getContextsDevice(alc.getCurrentContext());
			var connected = alc.getIntegerv(0x313, 1, device)[0];
			if (connected == 0)
			{
				trace("Disconnected!");
				auxDirty = true;
			}

		}
		else
		{
			delayTimer += 0.016;
			trace(delayTimer);

			if (delayTimer >= 3.0)
			{
				var alc = AudioManager.context.openal;
				var device = alc.getContextsDevice(alc.getCurrentContext());

				auxDirty = false;
				delayTimer = 0.0;
				var p = alc.reopenDeviceSOFT(device, null, 0);
				trace(p);
			}
		}
	}

	public static function resume():Void
	{
		#if !lime_doc_gen
		if (context != null && context.type == OPENAL)
		{
			var alc = context.openal;
			var currentContext = alc.getCurrentContext();

			if (currentContext != null)
			{
				var device = alc.getContextsDevice(currentContext);
				alc.resumeDevice(device);
				alc.processContext(currentContext);
			}
		}
		#end
	}

	public static function shutdown():Void
	{
		trace("shutdown");

		#if !lime_doc_gen
		if (context != null && context.type == OPENAL)
		{
			var alc = context.openal;
			var currentContext = alc.getCurrentContext();

			if (currentContext != null)
			{
				var device = alc.getContextsDevice(currentContext);
				alc.makeContextCurrent(null);
				alc.destroyContext(currentContext);

				if (device != null)
				{
					alc.closeDevice(device);
				}
			}
		}
		#end

		context = null;
	}

	public static function suspend():Void
	{
		trace("suspend");

		#if !lime_doc_gen
		if (context != null && context.type == OPENAL)
		{
			var alc = context.openal;
			var currentContext = alc.getCurrentContext();

			if (currentContext != null)
			{
				alc.suspendContext(currentContext);
				var device = alc.getContextsDevice(currentContext);

				if (device != null)
				{
					alc.pauseDevice(device);
				}
			}
		}
		#end
	}
}
