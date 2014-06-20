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
	
	#if (js || flash)
	public var bytes (get, set):UInt8Array;
	#else
	public var bytes:UInt8Array;
	#end
	
	public var data:ImageData;
	public var height:Int;
	public var offsetX:Int;
	public var offsetY:Int;
	public var width:Int;
	
	#if (js || flash)
	private var __bytes:UInt8Array;
	#end
	
	
	public function new (data:ImageData = null, width:Int = 0, height:Int = 0) {
		
		this.data = data;
		#if (!js && !flash)
		this.bytes = data;
		#end
		
		this.width = width;
		this.height = height;
		
	}
	
	
	#if (js || flash)
	private function get_bytes ():UInt8Array {
		
		if (data != null && width > 0 && height > 0) {
			
			#if js
			
			if (__canvas == null) {
				
				__canvas = cast Browser.document.createElement ("canvas");
				__context = cast __canvas.getContext ("2d");
				
			}
			
			__canvas.width = width;
			__canvas.height = height;
			__context.drawImage (data, 0, 0);
			js.Browser.document.body.appendChild (__canvas);
			
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
	#end
	
	
}


#if js
typedef ImageData = js.html.Image;
#elseif flash
typedef ImageData = flash.display.BitmapData;
#else
typedef ImageData = UInt8Array;
#end