package lime.ui;

#if android
import lime.system.JNI;
#end

class Haptic {

	#if android
	private static var jni_vibrate:Int->Int->Void = null;
	#end

	public static function vibrate(period:Int, duration:Int){
		#if android
			if(jni_vibrate==null){
				jni_vibrate = JNI.createStaticMethod("org/haxe/lime/GameActivity", "vibrate", "(II)V");
			}
			try{
				// This will raise an exception if you don't have VIBRATE permission
				jni_vibrate(period, duration);				
			} catch (e:Dynamic) {
				trace("JNI Exception: Have you added VIBRATE permission?");
			}
		#end
	}

}