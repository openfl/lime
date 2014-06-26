package lime.graphics;


import lime.utils.UInt8Array;

#if js
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.Browser;
#end


class Image {
	
	
	#if js
	private static var __canvas:CanvasElement;
	private static var __context:CanvasRenderingContext2D;
	#end
	
	public var bytes (get, set):UInt8Array;
	public var data:ImageData;
	public var height:Int;
	public var offsetX:Int;
	public var offsetY:Int;
	public var width:Int;
	
	private var __bytes:UInt8Array;
	
	
	public function new (data:ImageData = null, width:Int = 0, height:Int = 0) {
		
		this.data = data;
		#if (!js && !flash)
		this.__bytes = data;
		#end
		
		this.width = width;
		this.height = height;
		
	}
	
	
	public function convertToPOT () {

		var potWidth = Std.int (Math.pow (2, Math.ceil (Math.log (width) / Math.log (2))));
		var potHeight = Std.int (Math.pow (2, Math.ceil (Math.log (height) / Math.log (2))));

		if (potWidth > width || potHeight > height) {

			#if js

			if (__canvas == null) {

				__canvas = cast Browser.document.createElement ("canvas");
				__context = cast __canvas.getContext ("2d");

			}

			__canvas.width = potWidth;
			__canvas.height = potHeight;
			__context.clearRect (0, 0, potWidth, potHeight);
			__context.drawImage (data, 0, 0, width, height);

			data.src = __canvas.toDataURL ("image/png");

			#elseif flash

			var potData = new flash.display.BitmapData(potWidth, potHeight, true, 0x000000);
			potData.draw(data, null, null, null, true);
			data = potData;

			#else

			var potData = new UInt8Array (potWidth * potHeight * 4);

			for (y in 0...height) {

				for (x in 0...width) {

					potData.setUInt32(y * potWidth * 4 + x * 4, data.getUInt32(y * width * 4 + x * 4));

				}

			}

			__bytes = data = potData;

			#end

			width = potWidth;
			height = potHeight;

		}

	}


	private function get_bytes ():UInt8Array {
		
		if (__bytes == null && data != null && width > 0 && height > 0) {
			
			#if js
			
			if (__canvas == null) {
				
				__canvas = cast Browser.document.createElement ("canvas");
				__context = cast __canvas.getContext ("2d");
				
			}
			
			__canvas.width = width;
			__canvas.height = height;
			__context.drawImage (data, 0, 0);
			
			var pixels = __context.getImageData (0, 0, width, height);
			__bytes = new UInt8Array (pixels.data);
			
			#elseif flash
			
			var pixels = data.getPixels (data.rect);
			__bytes = new UInt8Array (pixels);
			
			#end
			
		}
		
		return __bytes;
		
	}
	
	
	private function set_bytes (value:UInt8Array):UInt8Array {
		
		return __bytes = value;
		
	}
	
	
}


#if js
typedef ImageData = js.html.Image;
#elseif flash
typedef ImageData = flash.display.BitmapData;
#else
typedef ImageData = UInt8Array;
#end
