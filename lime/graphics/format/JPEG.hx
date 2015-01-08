package lime.graphics.format;


import lime.graphics.Image;
import lime.system.System;
import lime.utils.ByteArray;


class JPEG {
	
	
	public static function encode (image:Image, quality:Int):ByteArray {
		
		#if java
		
		#elseif (sys && (!disable_cffi || !format))
			
			return lime_image_encode (image.buffer, 1, quality);
			
		#end
		
		return null;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_image_encode:ImageBuffer -> Int -> Int -> ByteArray = System.load ("lime", "lime_image_encode", 3);
	#end
	
	
}