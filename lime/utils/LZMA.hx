package lime.utils;


import haxe.io.Bytes;


@:deprecated class LZMA {
	
	
	public static function decode (bytes:Bytes):Bytes {
		
		return lime.utils.compress.LZMA.decompress (bytes);
		
	}
	
	
	public static function encode (bytes:Bytes):Bytes {
		
		return lime.utils.compress.LZMA.compress (bytes);
		
	}
	
	
}