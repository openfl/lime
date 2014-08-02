package lime.media;


import lime.system.System;
import lime.utils.ByteArray;
import lime.utils.UInt8Array;

#if js
import js.html.Image in HTMLImage;
#elseif flash
import flash.display.BitmapData;
#end


class ImageBuffer {
	
	
	public var bitsPerPixel:Int;
	public var data:UInt8Array;
	public var height:Int;
	public var premultiplied:Bool;
	public var width:Int;
	
	#if js
	public var src:HTMLImage;
	#elseif flash
	public var src:BitmapData;
	#else
	public var src:Dynamic;
	#end
	
	
	public function new (data:UInt8Array = null, width:Int = 0, height:Int = 0, bitsPerPixel:Int = 4) {
		
		this.data = data;
		this.width = width;
		this.height = height;
		this.bitsPerPixel = bitsPerPixel;
		
	}
	
	
	#if flash
	public static function fromBitmapData (bitmapData:BitmapData):ImageBuffer {
		
		var buffer = new ImageBuffer (null, bitmapData.width, bitmapData.height);
		buffer.src = bitmapData;
		return buffer;
		
	}
	#end
	
	
	public static function fromBytes (bytes:ByteArray):ImageBuffer {
		
		#if (cpp || neko)
		
		var data = lime_image_load (bytes);
		
		if (data != null) {
			
			return new ImageBuffer (new UInt8Array (data.data), data.width, data.height, data.bpp);
			
		} else {
			
			return null;
			
		}
		
		#else
		
		throw "ImageBuffer.loadFromFile not supported on this target";
		
		#end
		
	}
	
	
	public static function fromFile (path:String):ImageBuffer {
		
		#if (cpp || neko)
		
		var data = lime_image_load (path);
		
		if (data != null) {
			
			return new ImageBuffer (new UInt8Array (data.data), data.width, data.height, data.bpp);
			
		} else {
			
			return null;
			
		}
		
		#else
		
		throw "ImageBuffer.loadFromFile not supported on this target";
		
		#end
		
	}
	
	
	#if js
	public static function fromImage (image:HTMLImage):ImageBuffer {
		
		var buffer = new ImageBuffer (null, image.width, image.height);
		buffer.src = image;
		return buffer;
		
	}
	#end
	
	
	#if (cpp || neko)
	private static var lime_image_load:Dynamic = System.load ("lime", "lime_image_load", 1);
	#end
	
	
}