package lime.utils;


import lime.system.System;


class JNI {
	
	
	public static function getEnv ():Dynamic {
		
		#if android
		return lime_jni_getenv ();
		#else
		return null;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_jni_getenv = System.load ("lime", "lime_jni_getenv", 0);
	#end
	
	
}