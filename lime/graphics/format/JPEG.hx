package lime.graphics.format;


import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.system.CFFI;
import lime.utils.ByteArray;


class JPEG {
	
	
	public static function decodeBytes (bytes:ByteArray, decodeData:Bool = true):Image {
		
		#if (cpp || neko || nodejs)
		
		var bufferData:Dynamic = lime_jpeg_decode_bytes.call (bytes, decodeData);
		
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
		
		var bufferData:Dynamic = lime_jpeg_decode_file.call (path, decodeData);
		
		if (bufferData != null) {
			
			var buffer = new ImageBuffer (bufferData.data, bufferData.width, bufferData.height, bufferData.bpp, bufferData.format);
			buffer.transparent = bufferData.transparent;
			return new Image (buffer);
			
		}
		
		#end
		
		return null;
		
	}
	
	
	public static function encode (image:Image, quality:Int):ByteArray {
		
		if (image.premultiplied || image.format != RGBA32) {
			
			// TODO: Handle encode from different formats
			
			image = image.clone ();
			image.premultiplied = false;
			image.format = RGBA32;
			
		}
		
		#if java
		
		#elseif (sys && (!disable_cffi || !format))
			
			var data:Dynamic = lime_image_encode.call (image.buffer, 1, quality);
			var bytes = @:privateAccess new Bytes (data.length, data.b);
			return ByteArray.fromBytes (bytes);
			
		#end
		
		return null;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_jpeg_decode_bytes = new CFFI<Dynamic->Bool->Dynamic> ("lime", "lime_jpeg_decode_bytes");
	private static var lime_jpeg_decode_file = new CFFI<String->Bool->Dynamic> ("lime", "lime_jpeg_decode_file");
	private static var lime_image_encode = new CFFI<Dynamic->Int->Int->Dynamic> ("lime", "lime_image_encode");
	#end
	
	
}