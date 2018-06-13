package lime.graphics;


import haxe.io.Bytes;
import lime.graphics.cairo.CairoSurface;
import lime.utils.UInt8Array;

#if (js && html5)
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Image in HTMLImage;
import js.html.ImageData;
import js.html.Uint8ClampedArray;
import js.Browser;
import lime.graphics.utils.ImageCanvasUtil;
#elseif flash
import flash.display.BitmapData;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

#if hl
@:keep
#end

@:allow(lime.graphics.Image)


class ImageBuffer {
	
	
	public var bitsPerPixel:Int;
	public var data:UInt8Array;
	public var format:PixelFormat;
	public var height:Int;
	public var premultiplied:Bool;
	public var src (get, set):Dynamic;
	public var stride (get, never):Int;
	public var transparent:Bool;
	public var width:Int;
	
	@:noCompletion private var __srcBitmapData:#if flash BitmapData #else Dynamic #end;
	@:noCompletion private var __srcCanvas:#if (js && html5) CanvasElement #else Dynamic #end;
	@:noCompletion private var __srcContext:#if (js && html5) CanvasRenderingContext2D #else Dynamic #end;
	@:noCompletion private var __srcCustom:Dynamic;
	@:noCompletion private var __srcImage:#if (js && html5) HTMLImage #else Dynamic #end;
	@:noCompletion private var __srcImageData:#if (js && html5) ImageData #else Dynamic #end;
	
	
	#if commonjs
	private static function __init__ () {
		
		var p = untyped ImageBuffer.prototype;
		untyped Object.defineProperties (p, {
			"src": { get: p.get_src, set: p.set_src },
			"stride": { get: p.get_stride }
		});
		
	}
	#end
	
	
	public function new (data:UInt8Array = null, width:Int = 0, height:Int = 0, bitsPerPixel:Int = 32, format:PixelFormat = null) {
		
		this.data = data;
		this.width = width;
		this.height = height;
		this.bitsPerPixel = bitsPerPixel;
		this.format = (format == null ? RGBA32 : format);
		premultiplied = false;
		transparent = true;
		
	}
	
	
	public function clone ():ImageBuffer {
		
		var buffer = new ImageBuffer (data, width, height, bitsPerPixel);
		
		#if kha
		// TODO
		#elseif flash
		if (__srcBitmapData != null) buffer.__srcBitmapData = __srcBitmapData.clone ();
		#elseif (js && html5)
		if (data != null) {
			
			buffer.data = new UInt8Array (data.byteLength);
			var copy = new UInt8Array (data);
			buffer.data.set (copy);
			
		} else if (__srcImageData != null) {
			
			buffer.__srcCanvas = cast Browser.document.createElement ("canvas");
			buffer.__srcContext = cast buffer.__srcCanvas.getContext ("2d");
			buffer.__srcCanvas.width = __srcImageData.width;
			buffer.__srcCanvas.height = __srcImageData.height;
			buffer.__srcImageData = buffer.__srcContext.createImageData (__srcImageData.width, __srcImageData.height);
			var copy = new Uint8ClampedArray (__srcImageData.data);
			buffer.__srcImageData.data.set (copy);
			
		} else if (__srcCanvas != null) {
			
			buffer.__srcCanvas = cast Browser.document.createElement ("canvas");
			buffer.__srcContext = cast buffer.__srcCanvas.getContext ("2d");
			buffer.__srcCanvas.width = __srcCanvas.width;
			buffer.__srcCanvas.height = __srcCanvas.height;
			buffer.__srcContext.drawImage (__srcCanvas, 0, 0);
			
		} else {
			
			buffer.__srcImage = __srcImage;
			
		}
		#elseif nodejs
		if (data != null) {
			
			buffer.data = new UInt8Array (data.byteLength);
			var copy = new UInt8Array (data);
			buffer.data.set (copy);
			
		}
		buffer.__srcCustom = __srcCustom;
		#else
		if (data != null) {
			
			var bytes = Bytes.alloc (data.byteLength);
			bytes.blit (0, buffer.data.buffer, 0, data.byteLength);
			buffer.data = new UInt8Array (bytes);
			
		}
		#end
		
		buffer.bitsPerPixel = bitsPerPixel;
		buffer.format = format;
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
	
	
	private function get_stride ():Int {
		
		return width * 4;
		
	}
	
	
}