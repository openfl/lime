package lime.ui;

import lime._internal.backend.native.NativeCFFI;
import lime.system.JNI;
import lime.utils.Log;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class Haptic
{
	#if android
	private static var lime_haptic_vibrate:Int->Int->Void;
	#end

	public static function vibrate(period:Int, duration:Int):Void
	{
		#if android
		if (lime_haptic_vibrate == null)
		{
			lime_haptic_vibrate = JNI.createStaticMethod("org/haxe/lime/GameActivity", "vibrate", "(II)V");
		}

		try
		{
			lime_haptic_vibrate(period, duration);
		}
		catch (e:Dynamic)
		{
			Log.warn("Haptic.vibrate is not available (the VIBRATE permission may be missing)");
		}
		#elseif (js && html5)
		var pattern = [];

		if (period == 0)
		{
			pattern = [duration];
		}
		else
		{
			var periodMS = Std.int(Math.ceil(period / 2));
			var count = Std.int(Math.ceil((duration / period) * 2));
			pattern = [0]; // w3c spec says to vibrate on even elements of the pattern and android waits on even elements. This line makes the Navigator.vibrate match android behavior. https://w3c.github.io/vibration/ vs https://developer.android.com/reference/android/os/Vibrator.html#vibrate(long[],%20int)

			for (i in 0...count)
			{
				pattern.push(periodMS);
			}
		}

		try
		{
			if (!js.Browser.navigator.vibrate(pattern))
			{
				Log.verbose("Navigator.vibrate() returned false.");
			}
		}
		catch (e:Dynamic)
		{
			Log.verbose("Navigator.vibrate() threw an error (it might be Internet Explorer or Edge not supporting the feature)");
		}
		#elseif (lime_cffi && !macro)
		NativeCFFI.lime_haptic_vibrate(period, duration);
		#end
	}
}
