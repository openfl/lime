package;


import lime.system.CFFI;
import lime.system.JNI;


class ::className:: {
	
	
	public static function sampleMethod (inputValue:Int):Int {
		
		#if android
		
		var resultJNI = ::extensionLowerCase::_sample_method_jni(inputValue);
		var resultNative = ::extensionLowerCase::_sample_method(inputValue);
		
		if (resultJNI != resultNative) {
			
			throw "Fuzzy math!";
			
		}
		
		return resultNative;
		
		#else
		
		return ::extensionLowerCase::_sample_method(inputValue);
		
		#end
		
	}
	
	
	private static var ::extensionLowerCase::_sample_method = CFFI.load ("::extensionLowerCase::", "::extensionLowerCase::_sample_method", 1);
	
	#if android
	private static var ::extensionLowerCase::_sample_method_jni = JNI.createStaticMethod ("org.haxe.extension.::className::", "sampleMethod", "(I)I");
	#end
	
	
}