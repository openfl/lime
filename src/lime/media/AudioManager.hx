package lime.media;

import haxe.Timer;
#if (lime_cffi && !macro && lime_openal)
import lime._internal.backend.native.NativeCFFI;
import lime._internal.backend.native.NativeAudioSource;
#end
#if (!lime_doc_gen || lime_openal)
import lime.media.openal.AL;
import lime.media.openal.ALC;
import lime.media.openal.ALContext;
import lime.media.openal.ALDevice;
#end
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
	@:noCompletion public static var __contextGeneration(default, null):Int = 0;
	private static inline var OUTPUT_DEVICE_POLL_TIME:Int = 1000;
	#if (!lime_doc_gen || lime_openal)
	private static var outputDevice:ALDevice;
	#else
	private static var outputDevice:Dynamic;
	#end
	private static var outputDeviceHasDisconnectExt:Bool;
	private static var outputDeviceName:String;
	private static var outputDevicePreferredName:String;
	private static var outputDeviceRecovering:Bool;
	private static var outputDeviceTimer:Timer;

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
					if (device != null)
					{
						var ctx = alc.createContext(device);
						alc.makeContextCurrent(ctx);
						alc.processContext(ctx);
						__contextGeneration++;
					}
				}
				#end
			}

			AudioManager.context = context;
			setupOutputDeviceRecovery();

			#if (lime_cffi && !macro && lime_openal && (ios || tvos || mac))
			var timer = new Timer(100);
			timer.run = function()
			{
				NativeCFFI.lime_al_cleanup();
			};
			#end
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
		#if !lime_doc_gen
		stopOutputDeviceRecovery();

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

	private static function closeOpenALContext():Void
	{
		#if !lime_doc_gen
		if (context == null || context.type != OPENAL)
		{
			return;
		}

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
		#end
	}

	private static function getCurrentOutputDeviceName():String
	{
		#if (lime_cffi && !macro && lime_openal)
		var name = ALC.getString(null, ALC.DEFAULT_ALL_DEVICES_SPECIFIER);

		if (name == null || name.length == 0)
		{
			name = ALC.getString(null, ALC.DEFAULT_DEVICE_SPECIFIER);
		}

		return name;
		#else
		return null;
		#end
	}

	private static function isOutputDeviceConnected():Bool
	{
		#if (lime_cffi && !macro && lime_openal)
		if (outputDevice == null || !outputDeviceHasDisconnectExt)
		{
			return true;
		}

		var connected = ALC.getIntegerv(outputDevice, ALC.CONNECTED, 1);
		return connected == null || connected.length == 0 || connected[0] == ALC.TRUE;
		#else
		return true;
		#end
	}

	private static function openOpenALContext(deviceName:String = null):Bool
	{
		#if !lime_doc_gen
		if (context == null || context.type != OPENAL)
		{
			return false;
		}

		var alc = context.openal;
		var device = alc.openDevice(deviceName);

		if (device == null && deviceName != null)
		{
			device = alc.openDevice();
		}

		if (device == null)
		{
			return false;
		}

		var currentContext = alc.createContext(device);

		if (currentContext == null)
		{
			alc.closeDevice(device);
			return false;
		}

		alc.makeContextCurrent(currentContext);
		alc.processContext(currentContext);
		__contextGeneration++;
		return true;
		#else
		return false;
		#end
	}

	private static function recoverOutputDevice(deviceName:String = null):Void
	{
		#if (lime_cffi && !macro && lime_openal)
		if (outputDeviceRecovering || context == null || context.type != OPENAL)
		{
			return;
		}

		outputDeviceRecovering = true;
		NativeAudioSource.prepareAudioContextRecovery();
		closeOpenALContext();

		if (openOpenALContext(deviceName))
		{
			refreshOutputDeviceRecovery();
			NativeAudioSource.restoreAudioContextRecovery();
		}

		outputDeviceRecovering = false;
		#end
	}

	private static function refreshOutputDeviceRecovery():Void
	{
		#if (lime_cffi && !macro && lime_openal)
		if (context == null || context.type != OPENAL)
		{
			outputDevice = null;
			outputDeviceHasDisconnectExt = false;
			outputDeviceName = null;
			return;
		}

		var alc = context.openal;
		var currentContext = alc.getCurrentContext();
		outputDevice = currentContext != null ? alc.getContextsDevice(currentContext) : null;
		outputDeviceHasDisconnectExt = outputDevice != null && ALC.isExtensionPresent(outputDevice, "ALC_EXT_disconnect");
		outputDeviceName = getCurrentOutputDeviceName();
		#end
	}

	private static function setupOutputDeviceRecovery():Void
	{
		#if (lime_cffi && !macro && lime_openal)
		stopOutputDeviceRecovery();

		if (context == null || context.type != OPENAL)
		{
			return;
		}

		refreshOutputDeviceRecovery();

		if (!outputDeviceHasDisconnectExt)
		{
			return;
		}

		outputDevicePreferredName = outputDeviceName;
		// ALC_EXT_disconnect exposes disconnect state, but not device-change events.
		// Polling is kept as the compatibility fallback for that older API.
		outputDeviceTimer = new Timer(OUTPUT_DEVICE_POLL_TIME);
		outputDeviceTimer.run = updateOutputDeviceRecovery;
		#end
	}

	private static function stopOutputDeviceRecovery():Void
	{
		if (outputDeviceTimer != null)
		{
			outputDeviceTimer.stop();
			outputDeviceTimer = null;
		}

		outputDevice = null;
		outputDeviceHasDisconnectExt = false;
		outputDeviceName = null;
		outputDevicePreferredName = null;
		outputDeviceRecovering = false;
	}

	private static function updateOutputDeviceRecovery():Void
	{
		#if (lime_cffi && !macro && lime_openal)
		if (outputDeviceRecovering || context == null || context.type != OPENAL)
		{
			return;
		}

		if (!isOutputDeviceConnected())
		{
			recoverOutputDevice();
			return;
		}

		if (outputDevicePreferredName != null && outputDeviceName != outputDevicePreferredName)
		{
			var currentName = getCurrentOutputDeviceName();

			if (currentName == outputDevicePreferredName)
			{
				recoverOutputDevice(outputDevicePreferredName);
				return;
			}

			outputDeviceName = currentName;
		}
		#end
	}
}
