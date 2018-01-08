package lime.graphics.format;


import haxe.io.Bytes;
import lime._backend.native.NativeCFFI;
import lime.graphics.utils.ImageCanvasUtil;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.system.CFFI;
import lime.utils.UInt8Array;

#if (js && html5)
import js.Browser;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)
@:access(lime.graphics.ImageBuffer)


class JPEG {
	
	
	public static function decodeBytes (bytes:Bytes, decodeData:Bool = true):Image {
		
		#if (lime_cffi && !macro)
		
		#if !cs
		return NativeCFFI.lime_jpeg_decode_bytes (bytes, decodeData, new ImageBuffer (new UInt8Array (Bytes.alloc (0))));
		#else
		var bufferData:Dynamic = NativeCFFI.lime_jpeg_decode_bytes (bytes, decodeData, null);
		
		if (bufferData != null) {
			
			var buffer = new ImageBuffer (bufferData.data, bufferData.width, bufferData.height, bufferData.bpp, bufferData.format);
			buffer.transparent = bufferData.transparent;
			return new Image (buffer);
			
		}
		#end
		
		#end
		
		return null;
		
	}
	
	
	public static function decodeFile (path:String, decodeData:Bool = true):Image {
		
		#if (lime_cffi && !macro)
		
		#if !cs
		return NativeCFFI.lime_jpeg_decode_file (path, decodeData, new ImageBuffer (new UInt8Array (Bytes.alloc (0))));
		#else
		var bufferData:Dynamic = NativeCFFI.lime_jpeg_decode_file (path, decodeData, null);
		
		if (bufferData != null) {
			
			var buffer = new ImageBuffer (bufferData.data, bufferData.width, bufferData.height, bufferData.bpp, bufferData.format);
			buffer.transparent = bufferData.transparent;
			return new Image (buffer);
			
		}
		#end
		
		#end
		
		return null;
		
	}
	
	
	public static function encode (image:Image, quality:Int):Bytes {
		
		if (image.premultiplied || image.format != RGBA32) {
			
			// TODO: Handle encode from different formats
			
			image = image.clone ();
			image.premultiplied = false;
			image.format = RGBA32;
			
		}
		
		#if java
		
		#elseif (sys && (!disable_cffi || !format) && !macro)
		
		#if !cs
		return NativeCFFI.lime_image_encode (image.buffer, 1, quality, Bytes.alloc (0));
		#else
		var data:Dynamic = NativeCFFI.lime_image_encode (image.buffer, 1, quality, null);
		return @:privateAccess new Bytes (data.length, data.b);
		#end
		
		#elseif js
		
		image.type = CANVAS;
		ImageCanvasUtil.sync (image, false);
		
		if (image.buffer.__srcCanvas != null) {
			
			var data = image.buffer.__srcCanvas.toDataURL ("image/jpeg", quality / 100);
			#if nodejs
			var buffer = new js.node.Buffer ((data.split (";base64,")[1]:String), "base64").toString ("binary");
			#else
			var buffer = Browser.window.atob (data.split (";base64,")[1]);
			#end
			var bytes = Bytes.alloc (buffer.length);
			
			for (i in 0...buffer.length) {
				
				bytes.set (i, buffer.charCodeAt (i));
				
			}
			
			return bytes;
			
		}
		
		#end
		
		return null;
		
	}
	
	
}