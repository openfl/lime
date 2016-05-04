package lime.graphics.format;


import haxe.io.Bytes;
import lime.graphics.Image;
import lime.system.CFFI;
import lime.utils.UInt8Array;

#if (js && html5)
import js.Browser;
#end

#if format
import format.png.Data;
import format.png.Writer;
import format.tools.Deflate;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
#end

@:access(lime.graphics.ImageBuffer)

#if !macro
@:build(lime.system.CFFI.build())
#end


class PNG {
	
	
	public static function decodeBytes (bytes:Bytes, decodeData:Bool = true):Image {
		
		#if ((cpp || neko || nodejs) && !macro)
		
		var bufferData:Dynamic = lime_png_decode_bytes (bytes, decodeData);
		
		if (bufferData != null) {
			var u8a : UInt8Array = null;

			if(decodeData){
				u8a = new UInt8Array (@:privateAccess new Bytes (bufferData.data.length, bufferData.data.b));
			}
			var buffer = new ImageBuffer (u8a, bufferData.width, bufferData.height, bufferData.bpp, bufferData.format);
			buffer.transparent = bufferData.transparent;
			return new Image (buffer);
			
		}
		
		#end
		
		return null;
		
	}
	
	
	public static function decodeFile (path:String, decodeData:Bool = true):Image {
		
		#if ((cpp || neko || nodejs) && !macro)
		
		var bufferData:Dynamic = lime_png_decode_file (path, decodeData);
		
		if (bufferData != null) {

			var u8a : UInt8Array = null;

			if(decodeData){
				u8a = new UInt8Array (@:privateAccess new Bytes (bufferData.data.length, bufferData.data.b));
			}
			var buffer = new ImageBuffer (u8a, bufferData.width, bufferData.height, bufferData.bpp, bufferData.format);
			buffer.transparent = bufferData.transparent;
			return new Image (buffer);
			
		}
		
		#end
		
		return null;
		
	}
	
	
	public static function encode (image:Image):Bytes {
		
		if (image.premultiplied || image.format != RGBA32) {
			
			// TODO: Handle encode from different formats
			
			image = image.clone ();
			image.premultiplied = false;
			image.format = RGBA32;
			
		}
		
		#if java
		
		#elseif (sys && (!disable_cffi || !format) && !macro)
		
		if (CFFI.enabled) {
			
			var data:Dynamic = lime_image_encode (image.buffer, 0, 0);
			return @:privateAccess new Bytes (data.length, data.b);
			
		}
		
		#if (!html5 && format)
		
		else {
			
			try {
				
				var bytes = Bytes.alloc (image.width * image.height * 4 + image.height);
				
				#if flash
				var sourceBytes = Bytes.ofData (image.buffer.data.getByteBuffer ());
				#else
				var sourceBytes = cast image.buffer.data;
				#end
				
				var sourceIndex:Int, index:Int;
				
				for (y in 0...image.height) {
					
					sourceIndex = y * image.width * 4;
					index = y * image.width * 4 + y;
					
					bytes.set (index, 0);
					bytes.blit (index + 1, sourceBytes, sourceIndex, image.width * 4);
					
				}
				
				var data = new List ();
				data.add (CHeader ({ width: image.width, height: image.height, colbits: 8, color: ColTrue (true), interlaced: false }));
				data.add (CData (Deflate.run (bytes)));
				data.add (CEnd);
				
				var output = new BytesOutput ();
				var png = new Writer (output);
				png.write (data);
				
				return output.getBytes ();
				
			} catch (e:Dynamic) { }
			
		}
		
		#elseif (js && html5)
		
		ImageCanvasUtil.sync (image, false);
		
		if (image.buffer.__srcCanvas != null) {
			
			var data = image.buffer.__srcCanvas.toDataURL ("image/png");
			var buffer = Browser.window.atob (data.split (";base64,")[1]);
			var bytes = Bytes.alloc (buffer.length);
			
			for (i in 0...buffer.length) {
				
				bytes[i] = buffer.charCodeAt (i);
				
			}
			
			return bytes;
			
		}
		
		#end
		#end
		
		return null;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_png_decode_bytes (data:Dynamic, decodeData:Bool):Dynamic;
	@:cffi private static function lime_png_decode_file (path:String, decodeData:Bool):Dynamic;
	@:cffi private static function lime_image_encode (data:Dynamic, type:Int, quality:Int):Dynamic;
	#end
	
	
}