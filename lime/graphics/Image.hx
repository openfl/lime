package lime.graphics;


import lime.utils.UInt8Array;
import lime.system.System;

#if js
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.Browser;
#elseif flash
import flash.display.BitmapData;
#end


class Image {
	
	
	#if js
	private static var __canvas:CanvasElement;
	private static var __context:CanvasRenderingContext2D;
	#end
	
	public var data (get, set):ImageData;
	public var height:Int;
	public var offsetX:Int;
	public var offsetY:Int;
	public var powerOfTwo (get, null):Bool;
	public var premultiplied:Bool;
	public var src:ImageSource;
	public var textureHeight:Int;
	public var textureWidth:Int;
	public var width:Int;
	
	private var __data:ImageData;
	
	
	public function new (src:ImageSource = null, width:Int = 0, height:Int = 0) {
		
		this.src = src;
		#if (!js && !flash)
		this.__data = src;
		#end
		
		this.width = textureWidth = width;
		this.height = textureHeight = height;
		
	}
	
	
	public function forcePowerOfTwo () {
		
		if (powerOfTwo) return;
		
		textureWidth = 1;
		textureHeight = 1;
		
		while (textureWidth < width) {
			
			textureWidth <<= 1;
			
		}
		
		while (textureHeight < height) {
			
			textureHeight <<= 1;
			
		}
		
		#if js
		
		if (__canvas == null) {
			
			__canvas = cast Browser.document.createElement ("canvas");
			__context = cast __canvas.getContext ("2d");
			
		}
		
		__canvas.width = textureWidth;
		__canvas.height = textureHeight;
		__context.clearRect (0, 0, textureWidth, textureHeight);
		__context.drawImage (src, 0, 0, width, height);
		
		var pixels = __context.getImageData (0, 0, textureWidth, textureHeight);
		__data = new ImageData (pixels.data);
		
		#elseif flash
		
		var bitmapData = new BitmapData (textureWidth, textureHeight, true, 0x000000);
		bitmapData.draw (src, null, null, null, true);
		
		var pixels = bitmapData.getPixels (bitmapData.rect);
		__data = new ImageData (pixels);
		
		#else
		
		var newData = new ImageData (textureWidth * textureHeight * 4);
		
		for (y in 0...height) {
			
			for (x in 0...width) {
				
				newData.setPixel (y * textureWidth * 4 + x * 4, newData.getPixel (y * width * 4 + x * 4));
				
			}
			
		}
		
		__data = newData;
		
		#end
		
	}
	
	
	public static function loadFromFile (path:String) {
		
		#if flash
		
		throw "Can not load image from file in Flash";
		
		#elseif (cpp || neko)
		
		var imageData = lime_image_load (path);
		return (imageData == null ? null : new Image (new UInt8Array (imageData.data), imageData.width, imageData.height));
		
		#end
		
	}
	
	
	public function premultiplyAlpha ():Void {
		
		if (premultiplied) return;
		
		var data = this.data;
		data.premultiply ();
		
		premultiplied = true;
		
	}
	
	
	private function get_data ():ImageData {
		
		if (__data == null && src != null && width > 0 && height > 0) {
			
			#if js
			
			if (__canvas == null) {
				
				__canvas = cast Browser.document.createElement ("canvas");
				__context = cast __canvas.getContext ("2d");
				
			}
			
			__canvas.width = width;
			__canvas.height = height;
			__context.drawImage (src, 0, 0);
			
			var pixels = __context.getImageData (0, 0, width, height);
			__data = new ImageData (pixels.data);
			
			#elseif flash
			
			var pixels = src.getPixels (src.rect);
			__data = new ImageData (pixels);
			
			#end
			
		}
		
		return __data;
		
	}
	
	
	private function set_data (value:ImageData):ImageData {
		
		return __data = value;
		
	}
	
	
	private function get_powerOfTwo ():Bool {
		
		return ((width != 0) && ((width & (~width + 1)) == width)) && ((height != 0) && ((height & (~height + 1)) == height));
		
	}
	
	
	#if (cpp || neko)
	private static var lime_image_load = System.load ("lime", "lime_image_load", 1);
	#end
	
	
}


#if js
private typedef ImageSource = js.html.Image;
#elseif flash
private typedef ImageSource = flash.display.BitmapData;
#else
private typedef ImageSource = UInt8Array;
#end
