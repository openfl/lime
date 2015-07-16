package lime.graphics.format;


import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.system.System;
import lime.utils.ByteArray;


class JPEG {
	
	
	public static function decodeBytes (bytes:ByteArray, decodeData:Bool = true):Image {
		
		#if (cpp || neko || nodejs)
		
		var bufferData = lime_jpeg_decode_bytes (bytes, decodeData);
		
		if (bufferData != null) {
			
			var buffer = new ImageBuffer (bufferData.data, bufferData.width, bufferData.height, bufferData.bpp, bufferData.format);
			buffer.transparent = bufferData.transparent;
			return new Image (buffer);
			
		}
		
		#end
		
		return null;
		
	}
	
	
	public static function decodeFile (path:String, decodeData:Bool = true):Image {
		
		#if (cpp || neko || nodejs)
		
		var bufferData = lime_jpeg_decode_file (path, decodeData);
		
		if (bufferData != null) {
			
			var buffer = new ImageBuffer (bufferData.data, bufferData.width, bufferData.height, bufferData.bpp, bufferData.format);
			buffer.transparent = bufferData.transparent;
			return new Image (buffer);
			
		}
		
		#end
		
		return null;
		
	}
	
	
	public static function encode (image:Image, quality:Int):ByteArray {
		
		#if java
		
		#elseif (sys && (!disable_cffi || !format))
			
			var data:Dynamic = lime_image_encode (image.buffer, 1, quality);
			var bytes = @:privateAccess new Bytes (data.length, data.b);
			return ByteArray.fromBytes (bytes);
			
		#end
		
		return null;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_jpeg_decode_bytes:ByteArray -> Bool -> Dynamic = System.load ("lime", "lime_jpeg_decode_bytes", 2);
	private static var lime_jpeg_decode_file:String -> Bool -> Dynamic = System.load ("lime", "lime_jpeg_decode_file", 2);
	private static var lime_image_encode = System.load ("lime", "lime_image_encode", 3);
	#end
	
	
}