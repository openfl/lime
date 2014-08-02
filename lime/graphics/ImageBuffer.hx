package lime.graphics;


import lime.utils.UInt8Array;

#if js
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Image in HTMLImage;
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
	public var width:Int;
	
	private var __bitmapData:#if flash BitmapData #else Dynamic #end;
	private var __canvas:#if js CanvasElement #else Dynamic #end;
	private var __canvasContext:#if js CanvasRenderingContext2D #else Dynamic #end;
	private var __custom:Dynamic;
	private var __image:#if js HTMLImage #else Dynamic #end;
	
	
	public function new (data:UInt8Array = null, width:Int = 0, height:Int = 0, bitsPerPixel:Int = 4) {
		
		this.data = data;
		this.width = width;
		this.height = height;
		this.bitsPerPixel = bitsPerPixel;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_src ():Dynamic {
		
		#if js
		if (__image != null) return __image;
		return __canvas;
		#elseif flash
		return __bitmapData;
		#else
		return __custom;
		#end
		
	}
	
	
	private function set_src (value:Dynamic):Dynamic {
		
		#if js
		if (Std.is (value, HTMLImage)) {
			
			__image = cast value;
			
		} else if (Std.is (value, CanvasElement)) {
			
			__canvas = cast value;
			__canvasContext = cast __canvas.getContext ("2d");
			
		}
		#elseif flash
		__bitmapData = cast value;
		#else
		__custom = value;
		#end
		
		return value;
		
	}
	
	
}