package lime.graphics;


import lime.utils.UInt8Array;

#if (js && html5)
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Image in HTMLImage;
import js.html.ImageData;
#elseif flash
import flash.display.BitmapData;
#end

@:allow(lime.graphics.Image)


class ImageBuffer {
	
	
	public var bitsPerPixel:Int;
	public var data:UInt8Array;
	public var height:Int;
	public var premultiplied:Bool;
	public var src (get, set):Dynamic;
	public var transparent:Bool;
	public var width:Int;
	
	@:noCompletion private var __srcBitmapData:#if flash BitmapData #else Dynamic #end;
	@:noCompletion private var __srcCanvas:#if (js && html5) CanvasElement #else Dynamic #end;
	@:noCompletion private var __srcContext:#if (js && html5) CanvasRenderingContext2D #else Dynamic #end;
	@:noCompletion private var __srcCustom:Dynamic;
	@:noCompletion private var __srcImage:#if (js && html5) HTMLImage #else Dynamic #end;
	@:noCompletion private var __srcImageData:#if (js && html5) ImageData #else Dynamic #end;
	
	
	public function new (data:UInt8Array = null, width:Int = 0, height:Int = 0, bitsPerPixel:Int = 4) {
		
		this.data = data;
		this.width = width;
		this.height = height;
		this.bitsPerPixel = bitsPerPixel;
		transparent = true;
		
	}
	
	
	public function clone ():ImageBuffer {
		
		var buffer = new ImageBuffer (data, width, height, bitsPerPixel);
		buffer.src = src;
		buffer.premultiplied = premultiplied;
		buffer.transparent = transparent;
		return buffer;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_src ():Dynamic {
		
		#if (js && html5)
			
			if (__srcImage != null) return __srcImage;
			return __srcCanvas;
			
		#elseif flash
			
			return __srcBitmapData;
			
		#else
			
			return __srcCustom;
			
		#end
		
	}
	
	
	private function set_src (value:Dynamic):Dynamic {
		
		#if (js && html5)
			
			if (Std.is (value, HTMLImage)) {
				
				__srcImage = cast value;
				
			} else if (Std.is (value, CanvasElement)) {
				
				__srcCanvas = cast value;
				__srcContext = cast __srcCanvas.getContext ("2d");
				
			}
			
		#elseif flash
			
			__srcBitmapData = cast value;
			
		#else
			
			__srcCustom = value;
			
		#end
		
		return value;
		
	}
	
	
}