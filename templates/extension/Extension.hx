package;

#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#end

#if (android && openfl)
import openfl.utils.JNI;
#end


class ::className:: {
	
	
	public static function sampleMethod (inputValue:Int):Int {
		
		#if (android && openfl)
		
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
	
	
	private static var ::extensionLowerCase::_sample_method = Lib.load ("::extensionLowerCase::", "::extensionLowerCase::_sample_method", 1);
	
	#if (android && openfl)
	private static var ::extensionLowerCase::_sample_method_jni = JNI.createStaticMethod ("org.haxe.extension.::className::", "sampleMethod", "(I)I");
	#end
	
	
}