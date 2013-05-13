package;

#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#end


class ::className:: {
	
	
	public static function sampleMethod (inputValue:Int):Int {
		
		return ::extensionLowerCase::_sample_method(inputValue);
		
	}
	
	
	private static var ::extensionLowerCase::_sample_method = Lib.load ("::file::", "::extensionLowerCase::_sample_method", 1);
	
	
}