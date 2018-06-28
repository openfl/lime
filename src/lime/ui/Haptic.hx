package lime.ui;


import lime._internal.backend.native.NativeCFFI;
import lime.system.JNI;
import lime.utils.Log;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._internal.backend.native.NativeCFFI)


class Haptic {
	
	
	#if android
	private static var lime_haptic_vibrate:Int->Int->Void;
	#end
	
	
	public static function vibrate (period:Int, duration:Int):Void {
		
		#if android
		
		if (lime_haptic_vibrate == null) {
			
			lime_haptic_vibrate = JNI.createStaticMethod ("org/haxe/lime/GameActivity", "vibrate", "(II)V");
			
		}
		
		try {
			
			lime_haptic_vibrate (period, duration);
			
		} catch (e:Dynamic) {
			
			Log.warn ("Haptic.vibrate is not available (the VIBRATE permission may be missing)");
			
		}
		
		#elseif (lime_cffi && !macro)
		
		NativeCFFI.lime_haptic_vibrate (period, duration);
		
		#end
		
	}
	
	
}