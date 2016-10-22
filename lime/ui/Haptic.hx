package lime.ui;

#if android
import lime.system.JNI;
#elseif (lime_cffi && !macro)
import lime.system.CFFI;
#end

class Haptic {

	#if ( android || ios )
	private static var __vibrate:Int->Int->Void = null;
	#end

	public static function vibrate(period:Int, duration:Int){
		#if android
			if(__vibrate==null){
				__vibrate = JNI.createStaticMethod("org/haxe/lime/GameActivity", "vibrate", "(II)V");
			}
			try{
				// This will raise an exception if you don't have VIBRATE permission
				__vibrate(period, duration);				
			} catch (e:Dynamic) {
				trace("JNI Exception: Have you added VIBRATE permission?");
			}
		#elseif ios
			if(__vibrate == null){
				__vibrate = CFFI.load ("lime", "lime_haptic_vibrate", 2);
			}
			__vibrate(period, duration);
		#end
	}

}