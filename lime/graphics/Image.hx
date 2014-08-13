package lime.graphics;


import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import lime.app.Application;
import lime.graphics.utils.ImageCanvasUtil;
import lime.graphics.utils.ImageDataUtil;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.utils.ByteArray;
import lime.utils.UInt8Array;
import lime.system.System;

#if js
import js.html.CanvasElement;
import js.html.ImageElement;
import js.Browser;
#elseif flash
import flash.display.BitmapData;
import flash.geom.Matrix;
#end

#if format
import format.png.Data;
import format.png.Reader;
import format.png.Tools;
import format.png.Writer;
import format.tools.Deflate;
#if sys
import sys.io.File;
#end
#end

@:allow(lime.graphics.util.ImageCanvasUtil)
@:allow(lime.graphics.util.ImageDataUtil)
@:access(lime.app.Application)
@:access(lime.math.ColorMatrix)
@:access(lime.math.Rectangle)
@:access(lime.math.Vector2)


class Image {
	
	
	private static var __base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	private static var __base64Encoder:BaseCode;
	
	public var buffer:ImageBuffer;
	public var data (get, set):UInt8Array;
	public var dirty:Bool;
	public var height:Int;
	public var offsetX:Int;
	public var offsetY:Int;
	public var powerOfTwo (get, set):Bool;
	public var premultiplied (get, set):Bool;
	public var rect (get, null):Rectangle;
	public var src (get, set):Dynamic;
	public var transparent (get, set):Bool;
	public var type:ImageType;
	public var width:Int;
	
	
	public function new (buffer:ImageBuffer = null, offsetX:Int = 0, offsetY:Int = 0, width:Int = 0, height:Int = 0, color:Null<Int> = null, type:ImageType = null) {
		
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		this.width = width;
		this.height = height;
		
		if (type == null) {
			
			if (Application.__instance != null && Application.__instance.windows != null && Application.__instance.window.currentRenderer != null) {
				
				this.type = switch (Application.__instance.window.currentRenderer.context) {
					
					case DOM (_), CANVAS (_): CANVAS;
					case FLASH (_): FLASH;
					default: DATA;
					
				}
				
			} else {
				
				this.type = DATA;
				
			}
			
		} else {
			
			this.type = type;
			
		}
		
		if (buffer == null) {
			
			if (width > 0 && height > 0) {
				
				switch (this.type) {
					
					case CANVAS:
						
						this.buffer = new ImageBuffer (null, width, height);
						ImageCanvasUtil.createCanvas (this, width, height);
						
						if (color != null) {
							
							fillRect (new Rectangle (0, 0, width, height), color);
							
						}
					
					case DATA:
						
						this.buffer = new ImageBuffer (new UInt8Array (width * height * 4), width, height);
						
						if (color != null) {
							
							fillRect (new Rectangle (0, 0, width, height), color);
							
						}
					
					case FLASH:
						
						#if flash
						this.buffer = new ImageBuffer (null, width, height);
						this.buffer.src = new BitmapData (width, height, true, color);
						#end
					
					default:
					
				}
				
			}
			
		} else {
			
			__fromImageBuffer (buffer);
			
		}
		
	}
	
	
	public function clone ():Image {
		
		#if js
		ImageCanvasUtil.sync (this);
		#end
		
		var image = new Image (buffer.clone (), offsetX, offsetY, width, height, null, type);
		return image;
		
	}
	
	
	public function colorTransform (rect:Rectangle, colorMatrix:ColorMatrix):Void {
		
		rect = __clipRect (rect);
		if (buffer == null || rect == null) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.colorTransform (this, rect, colorMatrix);
			
			case DATA:
				
				#if js
				ImageCanvasUtil.convertToData (this);
				#end
				
				ImageDataUtil.colorTransform (this, rect, colorMatrix);
			
			case FLASH:
				
				rect.offset (offsetX, offsetY);
				buffer.__srcBitmapData.colorTransform (rect.__toFlashRectangle (), colorMatrix.__toFlashColorTransform ());
			
			default:
			
		}
		
	}
	
	
	public function copyChannel (sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, sourceChannel:ImageChannel, destChannel:ImageChannel):Void {
		
		sourceRect = __clipRect (sourceRect);
		if (buffer == null || sourceRect == null) return;
		
		if (destChannel == ImageChannel.ALPHA && !transparent) return;
		if (sourceRect.width <= 0 || sourceRect.height <= 0) return;
		if (sourceRect.x + sourceRect.width > sourceImage.width) sourceRect.width = sourceImage.width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceImage.height) sourceRect.height = sourceImage.height - sourceRect.y;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.copyChannel (this, sourceImage, sourceRect, destPoint, sourceChannel, destChannel);
			
			case DATA:
				
				#if js
				ImageCanvasUtil.convertToData (this);
				#end
				
				ImageDataUtil.copyChannel (this, sourceImage, sourceRect, destPoint, sourceChannel, destChannel);
			
			case FLASH:
				
				var srcChannel = switch (sourceChannel) { 
					case RED: 1;
					case GREEN: 2;
					case BLUE: 4;
					case ALPHA: 8;
				}
				
				var dstChannel = switch (destChannel) { 
					case RED: 1;
					case GREEN: 2;
					case BLUE: 4;
					case ALPHA: 8;
				}
				
				sourceRect.offset (sourceImage.offsetX, sourceImage.offsetY);
				destPoint.offset (offsetX, offsetY);
				
				buffer.__srcBitmapData.copyChannel (sourceImage.buffer.src, sourceRect.__toFlashRectangle (), destPoint.__toFlashPoint (), srcChannel, dstChannel);
			
			default:
				
		}
		
	}
	
	
	public function copyPixels (sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, alphaImage:Image = null, alphaPoint:Vector2 = null, mergeAlpha:Bool = false):Void {
		
		if (buffer == null || sourceImage == null) return;
		
		if (sourceRect.x + sourceRect.width > sourceImage.width) sourceRect.width = sourceImage.width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceImage.height) sourceRect.height = sourceImage.height - sourceRect.y;
		if (sourceRect.width <= 0 || sourceRect.height <= 0) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.copyPixels (this, sourceImage, sourceRect, destPoint, alphaImage, alphaPoint, mergeAlpha);
			
			case DATA:
				
				#if js
				ImageCanvasUtil.convertToData (this);
				ImageCanvasUtil.convertToData (sourceImage);
				#end
				
				ImageDataUtil.copyPixels (this, sourceImage, sourceRect, destPoint, alphaImage, alphaPoint, mergeAlpha);
			
			case FLASH:
				
				sourceRect.offset (sourceImage.offsetX, sourceImage.offsetY);
				destPoint.offset (offsetX, offsetY);
				
				if (alphaImage != null && alphaPoint != null) {
					
					alphaPoint.offset (alphaImage.offsetX, alphaImage.offsetY);
					
				}
				
				buffer.__srcBitmapData.copyPixels (sourceImage.buffer.__srcBitmapData, sourceRect.__toFlashRectangle (), destPoint.__toFlashPoint (), alphaImage != null ? alphaImage.buffer.src : null, alphaPoint != null ? alphaPoint.__toFlashPoint () : null, mergeAlpha);
			
			default:
				
		}
		
	}
	
	
	public function encode (format:String = "png"):ByteArray {
		
		#if (!js && !flash)
		#if format
		switch (format) {
			
			case "png":
				
				try {
					
					var bytes = Bytes.alloc (width * height * 4 + height);
					var sourceBytes = buffer.data.getByteBuffer ();
					var sourceIndex:Int, index:Int;
					
					for (y in 0...height) {
						
						sourceIndex = y * width * 4;
						index = y * width * 4 + y;
						
						bytes.set (index, 0);
						bytes.blit (index + 1, sourceBytes, sourceIndex, width * 4);
						
					}
					
					var data = new List ();
					data.add (CHeader ({ width: width, height: height, colbits: 8, color: ColTrue (true), interlaced: false }));
					data.add (CData (Deflate.run (bytes)));
					data.add (CEnd);
					
					var output = new BytesOutput ();
					var png = new Writer (output);
					png.write (data);
					
					return ByteArray.fromBytes (output.getBytes ());
					
				} catch (e:Dynamic) {}
			
			default:
				
			
		}
		#end
		#end
		
		return null;
		
	}
	
	
	public function fillRect (rect:Rectangle, color:Int):Void {
		
		rect = __clipRect (rect);
		if (buffer == null || rect == null) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.fillRect (this, rect, color);
			
			case DATA:
				
				#if js
				ImageCanvasUtil.convertToData (this);
				#end
				
				ImageDataUtil.fillRect (this, rect, color);
			
			case FLASH:
				
				rect.offset (offsetX, offsetY);
				buffer.__srcBitmapData.fillRect (rect.__toFlashRectangle (), color);
				
			default:
			
		}
		
	}
	
	
	public function floodFill (x:Int, y:Int, color:Int):Void {
		
		if (buffer == null) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.floodFill (this, x, y, color);
			
			case DATA:
				
				#if js
				ImageCanvasUtil.convertToData (this);
				#end
				
				ImageDataUtil.floodFill (this, x, y, color);
			
			case FLASH:
				
				buffer.__srcBitmapData.floodFill (x + offsetX, y + offsetY, color);
			
			default:
			
		}
		
	}
	
	
	public static function fromBase64 (base64:String, type:String, onload:Image -> Void):Image {
		
		var image = new Image ();
		image.__fromBase64 (base64, type, onload);
		return image;
		
	}
	
	
	public static function fromBitmapData (bitmapData:#if flash BitmapData #else Dynamic #end):Image {
		
		var buffer = new ImageBuffer (null, bitmapData.width, bitmapData.height);
		buffer.__srcBitmapData = bitmapData;
		return new Image (buffer);
		
	}
	
	
	public static function fromBytes (bytes:ByteArray, onload:Image -> Void = null):Image {
		
		var image = new Image ();
		image.__fromBytes (bytes, onload);
		return image;
		
	}
	
	
	public static function fromCanvas (canvas:#if js CanvasElement #else Dynamic #end):Image {
		
		var buffer = new ImageBuffer (null, canvas.width, canvas.height);
		buffer.src = canvas;
		return new Image (buffer);
		
	}
	
	
	public static function fromFile (path:String, onload:Image -> Void = null, onerror:Void -> Void = null):Image {
		
		var image = new Image ();
		image.__fromFile (path, onload, onerror);
		return image;
		
	}
	
	
	public static function fromImageElement (image:#if js ImageElement #else Dynamic #end):Image {
		
		var buffer = new ImageBuffer (null, image.width, image.height);
		buffer.src = image;
		return new Image (buffer);
		
	}
	
	
	public function getPixel (x:Int, y:Int):Int {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return 0;
		
		switch (type) {
			
			case CANVAS:
				
				return ImageCanvasUtil.getPixel (this, x, y);
			
			case DATA:
				
				#if js
				ImageCanvasUtil.convertToData (this);
				#end
				
				return ImageDataUtil.getPixel (this, x, y);
			
			case FLASH:
				
				return buffer.__srcBitmapData.getPixel (x + offsetX, y + offsetY);
			
			default:
				
				return 0;
			
		}
		
	}
	
	
	public function getPixel32 (x:Int, y:Int):Int {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return 0;
		
		switch (type) {
			
			case CANVAS:
				
				return ImageCanvasUtil.getPixel32 (this, x, y);
			
			case DATA:
				
				#if js
				ImageCanvasUtil.convertToData (this);
				#end
				
				return ImageDataUtil.getPixel32 (this, x, y);
				
			case FLASH:
				
				return buffer.__srcBitmapData.getPixel32 (x + offsetX, y + offsetY);
			
			default:
				
				return 0;
			
		}
		
	}
	
	
	public function getPixels (rect:Rectangle):ByteArray {
		
		if (buffer == null) return null;
		
		switch (type) {
			
			case CANVAS:
				
				return ImageCanvasUtil.getPixels (this, rect);
			
			case DATA:
				
				#if js
				ImageCanvasUtil.convertToData (this);
				#end
				
				return ImageDataUtil.getPixels (this, rect);
			
			case FLASH:
				
				rect.offset (offsetX, offsetY);
				return buffer.__srcBitmapData.getPixels (rect.__toFlashRectangle ());
			
			default:
				
				return null;
			
		}
		
	}
	
	
	public function resize (newWidth:Int, newHeight:Int):Void {
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.resize (this, newWidth, newHeight);
			
			case DATA:
				
				ImageDataUtil.resize (this, newWidth, newHeight);
			
			case FLASH:
				
				#if flash
				var matrix = new Matrix ();
				matrix.scale (newWidth / buffer.__srcBitmapData.width, newHeight / buffer.__srcBitmapData.height);
				var data = new BitmapData (newWidth, newHeight, true, 0x00FFFFFF);
				data.draw (buffer.__srcBitmapData, matrix, null, null, null, true);
				buffer.__srcBitmapData = data;
				#end
			
			default:
			
		}
		
		buffer.width = newWidth;
		buffer.height = newHeight;
		
		offsetX = 0;
		offsetY = 0;
		width = newWidth;
		height = newHeight;
		
	}
	
	
	public function setPixel (x:Int, y:Int, color:Int):Void {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.setPixel (this, x, y, color);
			
			case DATA:
				
				#if js
				ImageCanvasUtil.convertToData (this);
				#end
				
				ImageDataUtil.setPixel (this, x, y, color);
			
			case FLASH:
				
				buffer.__srcBitmapData.setPixel (x + offsetX, y + offsetX, color);
			
			default:
			
		}
		
	}
	
	
	public function setPixel32 (x:Int, y:Int, color:Int):Void {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.setPixel32 (this, x, y, color);
			
			case DATA:
				
				#if js
				ImageCanvasUtil.convertToData (this);
				#end
				
				ImageDataUtil.setPixel32 (this, x, y, color);
			
			case FLASH:
				
				buffer.__srcBitmapData.setPixel32 (x + offsetX, y + offsetY, color);
			
			default:
			
		}
		
	}
	
	
	public function setPixels (rect:Rectangle, byteArray:ByteArray):Void {
		
		rect = __clipRect (rect);
		if (buffer == null || rect == null) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.setPixels (this, rect, byteArray);
			
			case DATA:
				
				#if js
				ImageCanvasUtil.convertToData (this);
				#end
				
				ImageDataUtil.setPixels (this, rect, byteArray);
			
			case FLASH:
				
				rect.offset (offsetX, offsetY);
				buffer.__srcBitmapData.setPixels (rect.__toFlashRectangle (), byteArray);
			
			default:
			
		}
		
	}
	
	
	private static function __base64Encode (bytes:ByteArray):String {
		
		#if js
		var extension = switch (bytes.length % 3) {
			
			case 1: "==";
			case 2: "=";
			default: "";
			
		}
		
		if (__base64Encoder == null) {
			
			__base64Encoder = new BaseCode (Bytes.ofString (__base64Chars));
			
		}
		
		return __base64Encoder.encodeBytes (Bytes.ofData (cast bytes.byteView)).toString () + extension;
		#else
		return "";
		#end
		
	}
	
	
	private function __clipRect (r:Rectangle):Rectangle {
		
		if (r == null) return null;
		
		if (r.x < 0) {
			
			r.width -= -r.x;
			r.x = 0;
			
			if (r.x + r.width <= 0) return null;
			
		}
		
		if (r.y < 0) {
			
			r.height -= -r.y;
			r.y = 0;
			
			if (r.y + r.height <= 0) return null;
			
		}
		
		if (r.x + r.width >= width) {
			
			r.width -= r.x + r.width - width;
			
			if (r.width <= 0) return null;
			
		}
		
		if (r.y + r.height >= height) {
			
			r.height -= r.y + r.height - height;
			
			if (r.height <= 0) return null;
			
		}
		
		return r;
		
	}
	
	
	private function __fromBase64 (base64:String, type:String, onload:Image -> Void = null):Void {
		
		#if js
		var image:ImageElement = cast Browser.document.createElement ("img");
		
		var image_onLoaded = function (event) {
			
			buffer = new ImageBuffer (null, image.width, image.height);
			buffer.__srcImage = cast image;
			
			offsetX = 0;
			offsetY = 0;
			width = buffer.width;
			height = buffer.height;
			
			if (onload != null) {
				
				onload (this);
				
			}
			
		}
		
		image.addEventListener ("load", image_onLoaded, false);
		image.src = "data:" + type + ";base64," + base64;
		#end
		
	}
	
	
	private function __fromBytes (bytes:ByteArray, onload:Image -> Void):Void {
		
		#if js
		
		var type = "";
		
		if (__isPNG (bytes)) {
			
			type = "image/png";
			
		} else if (__isJPG (bytes)) {
			
			type = "image/jpeg";
			
		} else if (__isGIF (bytes)) {
			
			type = "image/gif";
			
		} else {
			
			throw "Image tried to read a PNG/JPG ByteArray, but found an invalid header.";
			
		}
		
		__fromBase64 (__base64Encode (bytes), type, onload);
		
		#elseif (cpp || neko)
		
		var data = lime_image_load (bytes);
		
		if (data != null) {
			
			__fromImageBuffer (new ImageBuffer (new UInt8Array (data.data), data.width, data.height, data.bpp));
			
			if (onload != null) {
				
				onload (this);
				
			}
			
		}
		
		#else
		
		throw "ImageBuffer.loadFromBytes not supported on this target";
		
		#end
		
	}
	
	
	private function __fromFile (path:String, onload:Image -> Void, onerror:Void -> Void):Void {
		
		#if js
		
		var image = cast Browser.document.createElement ("img");
		
		image.onload = function (_) {
			
			buffer = new ImageBuffer (null, image.width, image.height);
			buffer.__srcImage = cast image;
			
			if (onload != null) {
				
				onload (this);
				
			}
			
		}
		
		image.onerror = function (_) {
			
			if (onerror != null) {
				
				onerror ();
				
			}
			
		}
		
		image.src = path;
		
		// Another IE9 bug: loading 20+ images fails unless this line is added.
		// (issue #1019768)
		if (image.complete) { }
		
		#elseif (cpp || neko)
		
		var buffer = null;
		
		#if (sys && (!disable_cffi || !format))
		
		var data = lime_image_load (path);
		if (data != null) buffer = new ImageBuffer (new UInt8Array (data.data), data.width, data.height, data.bpp);
		
		#else
		
		try {
			
			var bytes = File.getBytes (path);
			var input = new BytesInput (bytes, 0, bytes.length);
			var png = new Reader (input).read ();
			var data = Tools.extract32 (png);
			var header = Tools.getHeader (png);
			
			var data = new UInt8Array (ByteArray.fromBytes (Bytes.ofData (data.getData ())));
			var length = header.width * header.height;
			var b, g, r, a;
			
			for (i in 0...length) {
				
				var b = data[i * 4];
				var g = data[i * 4 + 1];
				var r = data[i * 4 + 2];
				var a = data[i * 4 + 3];
				
				data[i * 4] = r;
				data[i * 4 + 1] = g;
				data[i * 4 + 2] = b;
				data[i * 4 + 3] = a;
				
			}
			
			buffer = new ImageBuffer (data, header.width, header.height);
			
		} catch (e:Dynamic) {}
		
		#end
		
		if (buffer != null) {
			
			__fromImageBuffer (buffer);
			
			if (onload != null) {
				
				onload (this);
				
			}
			
		}
		
		#else
		
		throw "ImageBuffer.loadFromFile not supported on this target";
		
		#end
		
	}
	
	
	private function __fromImageBuffer (buffer:ImageBuffer):Void {
		
		this.buffer = buffer;
		
		if (buffer != null) {
			
			if (width == 0) {
				
				this.width = buffer.width;
				
			}
			
			if (height == 0) {
				
				this.height = buffer.height;
				
			}
			
		}
		
	}
	
	
	private static function __isJPG (bytes:ByteArray) {
		
		bytes.position = 0;
		return bytes.readByte () == 0xFF && bytes.readByte () == 0xD8;
		
	}
	
	
	private static function __isPNG (bytes:ByteArray) {
		
		bytes.position = 0;
		return (bytes.readByte () == 0x89 && bytes.readByte () == 0x50 && bytes.readByte () == 0x4E && bytes.readByte () == 0x47 && bytes.readByte () == 0x0D && bytes.readByte () == 0x0A && bytes.readByte () == 0x1A && bytes.readByte () == 0x0A);
		
	}
	
	private static function __isGIF (bytes:ByteArray) {
		
		bytes.position = 0;
		
		if (bytes.readByte () == 0x47 && bytes.readByte () == 0x49 && bytes.readByte () == 0x46 && bytes.readByte () == 38) {
			
			var b = bytes.readByte ();
			return ((b == 7 || b == 9) && bytes.readByte () == 0x61);
			
		}
		
		return false;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_data ():UInt8Array {
		
		if (buffer.data == null && buffer.width > 0 && buffer.height > 0) {
			
			#if js
			ImageCanvasUtil.convertToCanvas (this);
			ImageCanvasUtil.createImageData (this);
			#elseif flash
			var pixels = buffer.__srcBitmapData.getPixels (buffer.__srcBitmapData.rect);
			buffer.data = new UInt8Array (pixels);
			#end
			
		}
		
		return buffer.data;
		
	}
	
	
	private function set_data (value:UInt8Array):UInt8Array {
		
		return buffer.data = value;
		
	}
	
	
	private function get_powerOfTwo ():Bool {
		
		return ((buffer.width != 0) && ((buffer.width & (~buffer.width + 1)) == buffer.width)) && ((buffer.height != 0) && ((buffer.height & (~buffer.height + 1)) == buffer.height));
		
	}
	
	
	private function set_powerOfTwo (value:Bool):Bool {
		
		if (value != powerOfTwo) {
			
			var newWidth = 1;
			var newHeight = 1;
			
			while (newWidth < buffer.width) {
				
				newWidth <<= 1;
				
			}
			
			while (newHeight < buffer.height) {
				
				newHeight <<= 1;
				
			}
			
			switch (type) {
				
				case CANVAS:
					
					// TODO
				
				case DATA:
					
					ImageDataUtil.resizeBuffer (this, newWidth, newHeight);
				
				case FLASH:
					
					#if flash
					var bitmapData = new BitmapData (newWidth, newHeight, true, 0x000000);
					bitmapData.draw (buffer.src, null, null, null, true);
					
					buffer.src = bitmapData;
					buffer.width = newWidth;
					buffer.height = newHeight;
					#end
				
				default:
			}
			
		}
		
		return value;
		
	}
	
	
	private function get_premultiplied ():Bool {
		
		return buffer.premultiplied;
		
	}
	
	
	private function set_premultiplied (value:Bool):Bool {
		
		if (value && !buffer.premultiplied) {
			
			switch (type) {
				
				case DATA:
					
					#if js
					ImageCanvasUtil.convertToData (this);
					#end
					
					ImageDataUtil.multiplyAlpha (this);
				
				default:
					
					// TODO
				
			}
			
		} else if (!value && buffer.premultiplied) {
			
			switch (type) {
				
				case DATA:
					
					#if js
					ImageCanvasUtil.convertToData (this);
					#end
					
					ImageDataUtil.unmultiplyAlpha (this);
				
				default:
					
					// TODO
				
			}
			
		}
		
		return value;
		
	}
	
	
	public function get_rect ():Rectangle {
		
		return new Rectangle (0, 0, width, height);
		
	}
	
	
	public function get_src ():Dynamic {
		
		return buffer.src;
		
	}
	
	
	private function set_src (value:Dynamic):Dynamic {
		
		return buffer.src = value;
		
	}
	
	
	private function get_transparent ():Bool {
		
		return buffer.transparent;
		
	}
	
	
	private function set_transparent (value:Bool):Bool {
		
		// TODO, modify data to set transparency
		
		return buffer.transparent = value;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko)
	private static var lime_image_load:Dynamic = System.load ("lime", "lime_image_load", 1);
	#end
	
	
}


enum ImageChannel {
	
	RED;
	GREEN;
	BLUE;
	ALPHA;
	
}