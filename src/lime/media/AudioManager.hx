package lime.media;

import lime.system.CFFI;
import lime.app.Application;
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

					var version:String = alc.getString(AL.VERSION);
					var alSoft:Bool = StringTools.contains(version, "ALSOFT");

					// These things are only valid on OpenAL Soft.
					if (alSoft)
					{
						// TODO: Do we need to check if the extension is present?
						// If so, this needs to be merged beforehand: https://github.com/openfl/lime/pull/1832
						alc.disable(AL.STOP_SOURCES_ON_DISCONNECT_SOFT);

						Application.current.onUpdate.add((_) -> {
							AudioManager.update();
						});

						alc.eventControlSOFT(3, [
							ALC.EVENT_TYPE_DEFAULT_DEVICE_CHANGED_SOFT,
							ALC.EVENT_TYPE_DEVICE_ADDED_SOFT,
							ALC.EVENT_TYPE_DEVICE_REMOVED_SOFT
						], true);
						alc.eventCallbackSOFT(device, __deviceEventCallback);
					}
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

	public static function update():Void
	{
		#if !lime_doc_gen
		if (context != null && context.type == OPENAL)
		{
			if (__audioDeviceChanged)
			{
				var alc = context.openal;
				var context = alc.getCurrentContext();
				if (context != null)
				{
					var device = alc.getContextsDevice(context);
					var reopened = alc.reopenDeviceSOFT(device, null, null);
					if (reopened)
					{
						__audioDeviceChanged = false;
					}
				}
			}
		}
		#end
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

	@:noCompletion static var __audioDeviceChanged:Bool = false;
	@:noCompletion static function __deviceEventCallback(eventType:Int, deviceType:Int, device:Dynamic,#if hl message:hl.Bytes #else message:String #end, userParam:Dynamic):Void
	{
		#if !lime_doc_gen
		#if hl
		var message = CFFI.stringValue(message);
		#end

		if (eventType == ALC.EVENT_TYPE_DEFAULT_DEVICE_CHANGED_SOFT && deviceType == ALC.PLAYBACK_DEVICE_SOFT)
		{
			// We can't make any calls to OpenAL here.
			// Let's set a flag and then reopen the device in the update() function that gets
			// called on the main thread.
			__audioDeviceChanged = true;
		}
		#end
	}
}
