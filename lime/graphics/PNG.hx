package lime.graphics;


import lime.utils.ByteArray;


class PNG {
	
	
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
			var result = (bytes.readByte () == 0x89 && bytes.readByte () == 0x50 && bytes.readByte () == 0x4E && bytes.readByte () == 0x47 && bytes.readByte () == 0x0D && bytes.readByte () == 0x0A && bytes.readByte () == 0x1A && bytes.readByte () == 0x0A);
			bytes.position = cachePosition;
			
			return result;
			
		}
		
		return false;
		
	}
	
	
}