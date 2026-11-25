package lime.media;

import haxe.Timer;
#if (lime_cffi && !macro && lime_openal)
import lime._internal.backend.native.NativeCFFI;
import lime._internal.backend.native.NativeAudioSource;
import lime._internal.backend.native.NativeVideoSource;
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
	@:noCompletion public static var __suspended(default, null):Bool = false;
	private static inline var AL_STOP_SOURCES_ON_DISCONNECT_SOFT:Int = 0x19AB;
	private static inline var OUTPUT_DEVICE_POLL_TIME:Int = 1000;
	private static inline var OUTPUT_DEVICE_EVENT_POLL_TIME:Int = 250;
	// A little under the poll time, so polling without events still retries on every tick
	private static inline var OUTPUT_DEVICE_RETRY_TIME:Float = 0.9;
	#if (!lime_doc_gen || lime_openal)
	private static var outputDevice:ALDevice;
	#else
	private static var outputDevice:Dynamic;
	#end
	private static var outputDeviceCanReopen:Bool;
	private static var outputDeviceEvents:Array<Int>;
	private static var outputDeviceFollowsDefault:Bool;
	private static var outputDeviceHasDisconnectExt:Bool;
	private static var outputDeviceName:String;
	private static var outputDevicePreferredName:String;
	private static var outputDeviceRecovering:Bool;
	private static var outputDeviceRetryStamp:Float = 0;
	private static var outputDeviceTimer:Timer;

	public static function init(context:AudioContext = null)
	{
		if (AudioManager.context == null)
		{
			// Only the output Lime opens itself is the default one, which it can follow
			outputDeviceFollowsDefault = (context == null);

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

			#if (lime_cffi && !macro && lime_openal)
			// Releases the objects that were collected if nothing else gets to them
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
		__suspended = false;

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
		outputDeviceFollowsDefault = false;
	}

	public static function suspend():Void
	{
		// Paused output is not a stall, so videos wait for it instead of playing on
		__suspended = true;

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

		#if lime_openalsoft
		if (outputDeviceCanReopen && outputDevice != null)
		{
			// The device moves to the new output with its contexts, sources and
			// buffers, so nothing has to be made again
			if (ALC.reopenDevice(outputDevice, deviceName) || (deviceName != null && ALC.reopenDevice(outputDevice)))
			{
				refreshOutputDeviceRecovery();
				NativeAudioSource.audioOutputReopened();
				NativeVideoSource.audioOutputReopened();
			}

			outputDeviceRecovering = false;
			return;
		}
		#end

		NativeAudioSource.prepareAudioContextRecovery();
		NativeVideoSource.prepareAudioContextRecovery();
		closeOpenALContext();

		if (openOpenALContext(deviceName))
		{
			refreshOutputDeviceRecovery();
			NativeAudioSource.restoreAudioContextRecovery();
			NativeVideoSource.restoreAudioContextRecovery();

			// The new device starts playing, so it is paused until resume() as the old one was
			if (__suspended)
			{
				suspend();
			}
		}

		outputDeviceRecovering = false;
		#end
	}

	private static function refreshOutputDeviceRecovery():Void
	{
		#if (lime_cffi && !macro && lime_openalsoft)
		if (context == null || context.type != OPENAL)
		{
			outputDevice = null;
			outputDeviceCanReopen = false;
			outputDeviceHasDisconnectExt = false;
			outputDeviceName = null;
			return;
		}

		var alc = context.openal;
		var currentContext = alc.getCurrentContext();
		outputDevice = currentContext != null ? alc.getContextsDevice(currentContext) : null;
		outputDeviceCanReopen = outputDevice != null && ALC.isExtensionPresent(outputDevice, "ALC_SOFT_reopen_device");
		outputDeviceHasDisconnectExt = outputDevice != null && ALC.isExtensionPresent(outputDevice, "ALC_EXT_disconnect");
		outputDeviceName = getCurrentOutputDeviceName();
		#end
	}

	// Asks OpenAL Soft to report output devices that are added, removed or made the
	// default, and returns the events it will report
	private static function startOutputDeviceEvents():Array<Int>
	{
		#if (lime_cffi && !macro && lime_openalsoft)
		// Following a new default output needs the device to be reopened in place
		if (!outputDeviceCanReopen || !ALC.isExtensionPresent(outputDevice, "ALC_SOFT_system_events"))
		{
			return null;
		}

		if (ALC.eventIsSupported(ALC.EVENT_TYPE_DEFAULT_DEVICE_CHANGED_SOFT, ALC.PLAYBACK_DEVICE_SOFT) != ALC.EVENT_SUPPORTED_SOFT)
		{
			return null;
		}

		var events = [];

		for (event in [
			ALC.EVENT_TYPE_DEFAULT_DEVICE_CHANGED_SOFT,
			ALC.EVENT_TYPE_DEVICE_ADDED_SOFT,
			ALC.EVENT_TYPE_DEVICE_REMOVED_SOFT
		])
		{
			if (ALC.eventIsSupported(event, ALC.PLAYBACK_DEVICE_SOFT) == ALC.EVENT_SUPPORTED_SOFT)
			{
				events.push(event);
			}
		}

		if (!ALC.__eventControl(events, true))
		{
			return null;
		}

		// Anything already queued is older than the device that was just opened
		ALC.__pollEvents();
		return events;
		#else
		return null;
		#end
	}

	private static function setupOutputDeviceRecovery():Void
	{
		// Only OpenAL Soft reports ALC_EXT_disconnect to Lime, so the system OpenAL on iOS and tvOS,
		// MojoAL and Emscripten have no way to notice a lost device
		#if (lime_cffi && !macro && lime_openalsoft)
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

		// OpenAL Soft stops every source when its output is lost. Held instead, they
		// carry on from where they were once the device is reopened. The extension
		// is still in progress, so its name is checked exactly.
		if (outputDeviceCanReopen && AL.isExtensionPresent("AL_SOFTX_hold_on_disconnect"))
		{
			AL.disable(AL_STOP_SOURCES_ON_DISCONNECT_SOFT);
		}

		outputDeviceEvents = startOutputDeviceEvents();
		// With device events the timer only reads the queued events and the
		// connection state, so it runs often enough to follow a new default output
		// quickly. ALC_EXT_disconnect alone reports a lost device but not a change of
		// the default output, so without events the default is polled as before.
		outputDeviceTimer = new Timer(outputDeviceEvents != null ? OUTPUT_DEVICE_EVENT_POLL_TIME : OUTPUT_DEVICE_POLL_TIME);
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

		#if (lime_cffi && !macro && lime_openalsoft)
		if (outputDeviceEvents != null)
		{
			ALC.__eventControl(outputDeviceEvents, false);
		}
		#end

		outputDevice = null;
		outputDeviceCanReopen = false;
		outputDeviceEvents = null;
		outputDeviceHasDisconnectExt = false;
		outputDeviceName = null;
		outputDevicePreferredName = null;
		outputDeviceRecovering = false;
		outputDeviceRetryStamp = 0;
	}

	private static function updateOutputDeviceRecovery():Void
	{
		#if (lime_cffi && !macro && lime_openal)
		if (outputDeviceRecovering || context == null || context.type != OPENAL)
		{
			return;
		}

		var defaultChanged = false;
		var devicesChanged = false;

		#if lime_openalsoft
		if (outputDeviceEvents != null)
		{
			var events = ALC.__pollEvents();
			var i = 0;

			while (i + 1 < events.length)
			{
				if (events[i + 1] == ALC.PLAYBACK_DEVICE_SOFT)
				{
					if (events[i] == ALC.EVENT_TYPE_DEFAULT_DEVICE_CHANGED_SOFT)
					{
						defaultChanged = true;
					}
					else
					{
						devicesChanged = true;
					}
				}

				i += 2;
			}
		}
		#end

		if (!isOutputDeviceConnected())
		{
			// Opening an output can be slow, so a lost device is tried again about
			// once a second, or as soon as the outputs change
			var now = Timer.stamp();

			if (defaultChanged || devicesChanged || now >= outputDeviceRetryStamp)
			{
				outputDeviceRetryStamp = now + OUTPUT_DEVICE_RETRY_TIME;
				recoverOutputDevice();
			}

			return;
		}

		if (outputDeviceEvents != null)
		{
			if (outputDeviceFollowsDefault)
			{
				// Lime opened the default output, so it moves with the default
				if (defaultChanged)
				{
					recoverOutputDevice();
				}

				return;
			}

			// Listing the outputs is slow, so with events it waits for them to change
			if (!defaultChanged && !devicesChanged)
			{
				return;
			}
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
