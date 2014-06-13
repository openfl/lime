package lime.graphics;


import lime.utils.ByteArray;


class JPG {
	
	
	public static function encode (imageData:ImageData):ByteArray {
		
		return null;
		
	}
	
	
	public static function decode (bytes:ByteArray):ImageData {
		
		return null;
		
	}
	
	
	public static function isFormat (bytes:ByteArray):Bool {
		
		if (bytes != null) {
			
			var cachePosition = bytes.position;
			bytes.position = 0;
			var result = (bytes.readByte () == 0xFF && bytes.readByte () == 0xD8);
			bytes.position = cachePosition;
			
			return result;
			
		}
		
		return false;
		
	}
	
	
}