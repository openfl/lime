package lime.utils;


import haxe.io.Bytes;
import lime.system.System;


class LZMA {
	
	
	public static function decode (bytes:ByteArray):ByteArray {
		
		#if (cpp || neko || nodejs)
		var data = lime_lzma_decode.call (bytes);
		return ByteArray.fromBytes (@:privateAccess new Bytes (data.length, data.b));
		#else
		return null;
		#end
		
	}
	
	
	public static function encode (bytes:ByteArray):ByteArray {
		
		#if (cpp || neko || nodejs)
		var data = lime_lzma_encode.call (bytes);
		return ByteArray.fromBytes (@:privateAccess new Bytes (data.length, data.b));
		#else
		return null;
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_lzma_decode = System.loadPrime ("lime", "lime_lzma_decode", "oo");
	private static var lime_lzma_encode = System.loadPrime ("lime", "lime_lzma_encode", "oo");
	#end
	
	
}