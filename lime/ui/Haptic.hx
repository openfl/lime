package lime.ui;


import lime.system.JNI;
import lime.utils.Log;

#if !macro
@:build(lime.system.CFFI.build())
#end


class Haptic {
	
	
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
		
		lime_haptic_vibrate (period, duration);
		
		#end
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if android
	private static var lime_haptic_vibrate (period:Int, duration:Int):Void;
	#elseif (lime_cffi && !macro)
	@:cffi private static function lime_haptic_vibrate (period:Int, duration:Int):Void;
	#end
	
}