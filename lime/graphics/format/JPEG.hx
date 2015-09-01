package lime.graphics.format;


import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.system.CFFI;
import lime.utils.ByteArray;

#if !macro
@:build(lime.system.CFFI.build())
#end


class JPEG {
	
	
	public static function decodeBytes (bytes:ByteArray, decodeData:Bool = true):Image {
		
		#if (cpp || neko || nodejs)
		
		var bufferData:Dynamic = lime_jpeg_decode_bytes (bytes, decodeData);
		
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
		
		var bufferData:Dynamic = lime_jpeg_decode_file (path, decodeData);
		
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
			
			var data:Dynamic = lime_image_encode (image.buffer, 1, quality);
			var bytes = @:privateAccess new Bytes (data.length, data.b);
			return ByteArray.fromBytes (bytes);
			
		#end
		
		return null;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	@:cffi private static function lime_jpeg_decode_bytes (data:Dynamic, decodeData:Bool):Dynamic;
	@:cffi private static function lime_jpeg_decode_file (path:String, decodeData:Bool):Dynamic;
	@:cffi private static function lime_image_encode (data:Dynamic, type:Int, quality:Int):Dynamic;
	#end
	
	
}