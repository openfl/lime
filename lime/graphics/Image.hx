package lime.graphics;


import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import lime.app.Application;
import lime.graphics.format.BMP;
import lime.graphics.format.JPEG;
import lime.graphics.format.PNG;
import lime.graphics.utils.ImageCanvasUtil;
import lime.graphics.utils.ImageDataUtil;
import lime.math.color.ARGB;
import lime.math.color.BGRA;
import lime.math.color.RGBA;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.system.CFFI;
import lime.utils.ArrayBuffer;
import lime.utils.UInt8Array;

#if (js && html5)
import js.html.CanvasElement;
import js.html.ImageElement;
import js.html.Image in JSImage;
import js.Browser;
#elseif flash
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.utils.ByteArray;
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

#if lime_console
import lime.graphics.console.TextureData;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end

@:autoBuild(lime.Assets.embedImage())
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
	public var format (get, set):PixelFormat;
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
	public var x:Float;
	public var y:Float;
	
	
	public function new (buffer:ImageBuffer = null, offsetX:Int = 0, offsetY:Int = 0, width:Int = -1, height:Int = -1, color:Null<Int> = null, type:ImageType = null) {
		
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		this.width = width;
		this.height = height;
		
		if (type == null) {
			
			if (Application.current != null && Application.current.renderer != null) {
				
				this.type = switch (Application.current.renderer.context) {
					
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
						this.buffer.src = new BitmapData (width, height, true, ((color & 0xFF) << 24) | (color >> 8));
						#end
					
					default:
					
				}
				
			}
			
		} else {
			
			__fromImageBuffer (buffer);
			
		}
		
	}
	
	
	public function clone ():Image {
		
		if (buffer != null) {
			
			if (type == CANVAS && buffer.__srcImage == null) {
				
				ImageCanvasUtil.convertToCanvas (this);
				ImageCanvasUtil.sync (this, true);
				
			}
			
			var image = new Image (buffer.clone (), offsetX, offsetY, width, height, null, type);
			image.dirty = dirty;
			return image;
			
		} else {
			
			return new Image (null, offsetX, offsetY, width, height, null, type);
			
		}
		
	}
	
	
	public function colorTransform (rect:Rectangle, colorMatrix:ColorMatrix):Void {
		
		rect = __clipRect (rect);
		if (buffer == null || rect == null) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.colorTransform (this, rect, colorMatrix);
			
			case DATA:
				
				#if (js && html5)
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
		
		if (destChannel == ALPHA && !transparent) return;
		if (sourceRect.width <= 0 || sourceRect.height <= 0) return;
		if (sourceRect.x + sourceRect.width > sourceImage.width) sourceRect.width = sourceImage.width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceImage.height) sourceRect.height = sourceImage.height - sourceRect.y;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.copyChannel (this, sourceImage, sourceRect, destPoint, sourceChannel, destChannel);
			
			case DATA:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				ImageCanvasUtil.convertToData (sourceImage);
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
		
		//fast fails -- if source or destination is null or of 0 dimensions, do nothing
		if (buffer == null || sourceImage == null) return;
		if (sourceRect.width <= 0 || sourceRect.height <= 0) return;
		if (width <= 0 || height <= 0) return;
		
		//source rect expands too far right or too far below source image boundaries
		if (sourceRect.x + sourceRect.width > sourceImage.width) sourceRect.width = sourceImage.width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceImage.height) sourceRect.height = sourceImage.height - sourceRect.y;
		
		//source rect starts too far left or too far above source image boundaries
		if (sourceRect.x < 0) {
			sourceRect.width += sourceRect.x;	//shrink width by amount off canvas
			sourceRect.x = 0;					//clamp rect to 0
		}
		if (sourceRect.y < 0) {
			sourceRect.height += sourceRect.y;	//shrink height by amount off canvas
			sourceRect.y = 0;					//clamp rect to 0
		}
		
		//draw area expands too far right or too far below destination image boundaries
		if (destPoint.x + sourceRect.width > width) sourceRect.width = width - destPoint.x;
		if (destPoint.y + sourceRect.height > height) sourceRect.height = height - destPoint.y;
		
		//draw area starts too far left or too far above destination image boundaries
		if (destPoint.x < 0) {
			sourceRect.width += destPoint.x;	//shrink width by amount off canvas
			sourceRect.x = -destPoint.x;		//adjust source rect to effective starting point
			destPoint.x = 0;					//clamp destination point to 0
		}
		if (destPoint.y < 0) {
			sourceRect.height += destPoint.y;	//shrink height by amount off canvas
			sourceRect.y = -destPoint.y;		//adjust source rect to effective starting point
			destPoint.y = 0;					//clamp destination point to 0
		}
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.convertToCanvas (this);
				ImageCanvasUtil.copyPixels (this, sourceImage, sourceRect, destPoint, alphaImage, alphaPoint, mergeAlpha);
			
			case DATA:
				
				#if (js && html5)
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
	
	
	public function encode (format:String = "png", quality:Int = 90):Bytes {
		
		switch (format) {
			
			case "png":
				
				return PNG.encode (this);
			
			case "jpg", "jpeg":
				
				return JPEG.encode (this, quality);
			
			case "bmp":
				
				return BMP.encode (this);
			
			default:
			
		}
		
		return null;
		
	}
	
	
	public function fillRect (rect:Rectangle, color:Int, format:PixelFormat = null):Void {
		
		rect = __clipRect (rect);
		if (buffer == null || rect == null) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.fillRect (this, rect, color, format);
			
			case DATA:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				#end
				
				if (buffer.data.length == 0) return;
				
				ImageDataUtil.fillRect (this, rect, color, format);
			
			case FLASH:
				
				rect.offset (offsetX, offsetY);
				
				var argb:ARGB = switch (format) {
					
					case ARGB32: color;
					case BGRA32: (color:BGRA);
					default: (color:RGBA);
					
				}
				
				buffer.__srcBitmapData.fillRect (rect.__toFlashRectangle (), argb);
				
			default:
			
		}
		
	}
	
	
	public function floodFill (x:Int, y:Int, color:Int, format:PixelFormat = null):Void {
		
		if (buffer == null) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.floodFill (this, x, y, color, format);
			
			case DATA:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				#end
				
				ImageDataUtil.floodFill (this, x, y, color, format);
			
			case FLASH:
				
				var argb:ARGB = switch (format) {
					
					case ARGB32: color;
					case BGRA32: (color:BGRA);
					default: (color:RGBA);
					
				}
				
				buffer.__srcBitmapData.floodFill (x + offsetX, y + offsetY, argb);
			
			default:
			
		}
		
	}
	
	
	public static function fromBase64 (base64:String, type:String, onload:Image -> Void):Image {
		
		if (base64 == null) return null;
		var image = new Image ();
		image.__fromBase64 (base64, type, onload);
		return image;
		
	}
	
	
	#if flash
	public static function fromBitmapData (bitmapData:BitmapData):Image {
	#else
	public static function fromBitmapData (bitmapData:Dynamic):Image {
	#end
		
		if (bitmapData == null) return null;
		#if flash
		var buffer = new ImageBuffer (null, bitmapData.width, bitmapData.height);
		buffer.__srcBitmapData = bitmapData;
		return new Image (buffer);
		#else
		return bitmapData.image;
		#end
		
	}
	
	
	public static function fromBytes (bytes:Bytes, onload:Image -> Void = null):Image {
		
		if (bytes == null) return null;
		var image = new Image ();
		image.__fromBytes (bytes, onload);
		return image;
		
	}
	
	
	#if (js && html5)
	public static function fromCanvas (canvas:CanvasElement):Image {
	#else
	public static function fromCanvas (canvas:Dynamic):Image {
	#end
		
		if (canvas == null) return null;
		var buffer = new ImageBuffer (null, canvas.width, canvas.height);
		buffer.src = canvas;
		return new Image (buffer);
		
	}
	
	
	public static function fromFile (path:String, onload:Image -> Void = null, onerror:Void -> Void = null):Image {
		
		var image = new Image ();
		image.__fromFile (path, onload, onerror);
		return image;
		
	}
	
	
	#if (js && html5)
	public static function fromImageElement (image:ImageElement):Image {
	#else
	public static function fromImageElement (image:Dynamic):Image {
	#end
		
		if (image == null) return null;
		var buffer = new ImageBuffer (null, image.width, image.height);
		buffer.src = image;
		return new Image (buffer);
		
	}
	
	public function getColorBoundsRect (mask:Int, color:Int, findColor:Bool = true, format:PixelFormat = null):Rectangle {
		
		if (buffer == null) return null;
		
		switch (type) {
			
			case CANVAS:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				#end
				
				return ImageDataUtil.getColorBoundsRect (this, mask, color, findColor, format);
			
			case DATA:
				
				return ImageDataUtil.getColorBoundsRect (this, mask, color, findColor, format);
			
			case FLASH:
				
				var rect = buffer.__srcBitmapData.getColorBoundsRect (mask, color, findColor);
				return new Rectangle (rect.x, rect.y, rect.width, rect.height);
			
			default:
				
				return null;
		}
		
	}
	
	public function getPixel (x:Int, y:Int, format:PixelFormat = null):Int {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return 0;
		
		switch (type) {
			
			case CANVAS:
				
				return ImageCanvasUtil.getPixel (this, x, y, format);
			
			case DATA:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				#end
				
				return ImageDataUtil.getPixel (this, x, y, format);
			
			case FLASH:
				
				var color:ARGB = buffer.__srcBitmapData.getPixel (x + offsetX, y + offsetY);
				
				switch (format) {
					
					case ARGB32: return color;
					case BGRA32: var bgra:BGRA = color; return bgra;
					default: var rgba:RGBA = color; return rgba;
					
				}
			
			default:
				
				return 0;
			
		}
		
	}
	
	
	public function getPixel32 (x:Int, y:Int, format:PixelFormat = null):Int {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return 0;
		
		switch (type) {
			
			case CANVAS:
				
				return ImageCanvasUtil.getPixel32 (this, x, y, format);
			
			case DATA:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				#end
				
				return ImageDataUtil.getPixel32 (this, x, y, format);
				
			case FLASH:
				
				var color:ARGB = buffer.__srcBitmapData.getPixel32 (x + offsetX, y + offsetY);
				
				switch (format) {
					
					case ARGB32: return color;
					case BGRA32: var bgra:BGRA = color; return bgra;
					default: var rgba:RGBA = color; return rgba;
					
				}
			
			default:
				
				return 0;
			
		}
		
	}
	
	
	public function getPixels (rect:Rectangle, format:PixelFormat = null):Bytes {
		
		if (buffer == null) return null;
		
		switch (type) {
			
			case CANVAS:
				
				return ImageCanvasUtil.getPixels (this, rect, format);
			
			case DATA:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				#end
				
				return ImageDataUtil.getPixels (this, rect, format);
			
			case FLASH:
				
				#if flash
				rect.offset (offsetX, offsetY);
				var byteArray:ByteArray = buffer.__srcBitmapData.getPixels (rect.__toFlashRectangle ());
				
				switch (format) {
					
					case ARGB32: // do nothing
					case BGRA32:
						
						var color:BGRA;
						var length = Std.int (byteArray.length / 4);
						
						for (i in 0...length) {
							
							color = (byteArray.readUnsignedInt ():ARGB);
							byteArray.position -= 4;
							byteArray.writeUnsignedInt (color);
							
						}
						
						byteArray.position = 0;
					
					default:
						
						var color:RGBA;
						var length = Std.int (byteArray.length / 4);
						
						for (i in 0...length) {
							
							color = (byteArray.readUnsignedInt ():ARGB);
							byteArray.position -= 4;
							byteArray.writeUnsignedInt (color);
							
						}
						
						byteArray.position = 0;
					
				}
				
				return Bytes.ofData (byteArray);
				#else
				return null;
				#end
			
			default:
				
				return null;
			
		}
		
	}
	
	
	public function merge (sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, redMultiplier:Int, greenMultiplier:Int, blueMultiplier:Int, alphaMultiplier:Int):Void {
		
		if (buffer == null || sourceImage == null) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.convertToCanvas (this);
				ImageCanvasUtil.merge (this, sourceImage, sourceRect, destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);
			
			case DATA:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				ImageCanvasUtil.convertToData (sourceImage);
				#end
				
				ImageDataUtil.merge (this, sourceImage, sourceRect, destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);
			
			case FLASH:
				
				sourceRect.offset (offsetX, offsetY);
				buffer.__srcBitmapData.merge (sourceImage.buffer.__srcBitmapData, sourceRect.__toFlashRectangle (), destPoint.__toFlashPoint (), redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);
			
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
	
	
	public function scroll (x:Int, y:Int):Void {
		
		if (buffer == null) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.scroll (this, x, y);
			
			case DATA:
				
				//#if (js && html5)
				//ImageCanvasUtil.convertToData (this);
				//#end
				
				//ImageDataUtil.scroll (this, x, y);
				
				copyPixels (this, rect, new Vector2 (x, y));
			
			case FLASH:
				
				buffer.__srcBitmapData.scroll (x + offsetX, y + offsetX);
			
			default:
			
		}
		
	}
	
	
	public function setPixel (x:Int, y:Int, color:Int, format:PixelFormat = null):Void {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.setPixel (this, x, y, color, format);
			
			case DATA:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				#end
				
				ImageDataUtil.setPixel (this, x, y, color, format);
			
			case FLASH:
				
				var argb:ARGB = switch (format) {
					
					case ARGB32: color;
					case BGRA32: (color:BGRA);
					default: (color:RGBA);
					
				}
				
				buffer.__srcBitmapData.setPixel (x + offsetX, y + offsetX, argb);
			
			default:
			
		}
		
	}
	
	
	public function setPixel32 (x:Int, y:Int, color:Int, format:PixelFormat = null):Void {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.setPixel32 (this, x, y, color, format);
			
			case DATA:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				#end
				
				ImageDataUtil.setPixel32 (this, x, y, color, format);
			
			case FLASH:
				
				var argb:ARGB = switch (format) {
					
					case ARGB32: color;
					case BGRA32: (color:BGRA);
					default: (color:RGBA);
					
				}
				
				buffer.__srcBitmapData.setPixel32 (x + offsetX, y + offsetY, argb);
			
			default:
			
		}
		
	}
	
	
	public function setPixels (rect:Rectangle, bytes:Bytes, format:PixelFormat = null):Void {
		
		rect = __clipRect (rect);
		if (buffer == null || rect == null) return;
		
		switch (type) {
			
			case CANVAS:
				
				ImageCanvasUtil.setPixels (this, rect, bytes, format);
			
			case DATA:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				#end
				
				ImageDataUtil.setPixels (this, rect, bytes, format);
			
			case FLASH:
				
				#if flash
				rect.offset (offsetX, offsetY);
				var byteArray = new ByteArray ();
				
				switch (format) {
					
					case ARGB32: // do nothing
					case BGRA32:
						
						var srcData:ByteArray = bytes.getData ();
						byteArray = new ByteArray ();
						#if flash
						byteArray.length = srcData.length;
						#end
						
						var color:BGRA;
						var length = Std.int (byteArray.length / 4);
						
						for (i in 0...length) {
							
							color = srcData.readUnsignedInt ();
							byteArray.writeUnsignedInt (cast (color, ARGB));
							
						}
						
						srcData.position = 0;
						byteArray.position = 0;
					
					default:
						
						var srcData = bytes.getData ();
						byteArray = new ByteArray ();
						#if flash
						byteArray.length = srcData.length;
						#end
						
						var color:RGBA;
						var length = Std.int (byteArray.length / 4);
						
						for (i in 0...length) {
							
							color = srcData.readUnsignedInt ();
							byteArray.writeUnsignedInt (cast (color, ARGB));
							
						}
						
						srcData.position = 0;
						byteArray.position = 0;
					
				}
				
				buffer.__srcBitmapData.setPixels (rect.__toFlashRectangle (), byteArray);
				#end
			
			default:
			
		}
		
	}
	
	
	public function threshold (sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, operation:String, threshold:Int, color:Int = 0x00000000, mask:Int = 0xFFFFFFFF, copySource:Bool = false, format:PixelFormat = null):Int {
		
		if (buffer == null || sourceImage == null || sourceRect == null) return 0;
		
		switch (type) {
			
			case CANVAS, DATA:
				
				#if (js && html5)
				ImageCanvasUtil.convertToData (this);
				#end
				
				return ImageDataUtil.threshold (this, sourceImage, sourceRect, destPoint, operation, threshold, color, mask, copySource, format);
			
			case FLASH:
				
				var _color:ARGB = switch (format) {
					
					case ARGB32: color;
					case BGRA32: (color:BGRA);
					default: (color:RGBA);
					
				}
				
				var _mask:ARGB = switch (format) {
					
					case ARGB32: mask;
					case BGRA32: (mask:BGRA);
					default: (mask:RGBA);
					
				}
				
				sourceRect.offset (sourceImage.offsetX, sourceImage.offsetY);
				destPoint.offset (offsetX, offsetY);
				
				return buffer.__srcBitmapData.threshold (sourceImage.buffer.src, sourceRect.__toFlashRectangle (), destPoint.__toFlashPoint (), operation, threshold, _color, _mask, copySource);
				
			default:
			
		}
		
		return 0;
		
	}
	
	
	private static function __base64Encode (bytes:Bytes):String {
		
		#if (js && html5)
			
			var extension = switch (bytes.length % 3) {
				
				case 1: "==";
				case 2: "=";
				default: "";
				
			}
			
			if (__base64Encoder == null) {
				
				__base64Encoder = new BaseCode (Bytes.ofString (__base64Chars));
				
			}
			
			return __base64Encoder.encodeBytes (bytes).toString () + extension;
			
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
		
		#if (js && html5)
		var image = new JSImage ();
		image.crossOrigin = "Anonymous";
		
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
	
	
	private function __fromBytes (bytes:Bytes, onload:Image -> Void):Void {
		
		#if (js && html5)
			
			var type = "";
			
			if (__isPNG (bytes)) {
				
				type = "image/png";
				
			} else if (__isJPG (bytes)) {
				
				type = "image/jpeg";
				
			} else if (__isGIF (bytes)) {
				
				type = "image/gif";
				
			} else {
				
				throw "Image tried to read PNG/JPG Bytes, but found an invalid header.";
				
			}
			
			__fromBase64 (__base64Encode (bytes), type, onload);
			
		#elseif lime_console
			
			throw "Image.fromBytes not implemented for console target";
			
		#elseif ((cpp || neko || nodejs) && !macro)
			
			var data:Dynamic = lime_image_load (bytes);
			
			if (data != null) {
				
				__fromImageBuffer (new ImageBuffer (new UInt8Array (@:privateAccess new Bytes (data.data.length, data.data.b)), data.width, data.height, data.bitsPerPixel));
				
				if (onload != null) {
					
					onload (this);
					
				}
				
			}
			
		#else
			
			throw "ImageBuffer.loadFromBytes not supported on this target";
			
		#end
		
	}
	
	
	private function __fromFile (path:String, onload:Image -> Void, onerror:Void -> Void):Void {
		
		#if (js && html5)
			
			var image = new JSImage ();
			image.crossOrigin = "Anonymous";
			
			image.onload = function (_) {
				
				buffer = new ImageBuffer (null, image.width, image.height);
				buffer.__srcImage = cast image;
				
				width = image.width;
				height = image.height;
				
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
			
		#elseif (cpp || neko || nodejs || java)
			
			var buffer = null;
			
			#if lime_console
			
			var td = TextureData.fromFile (path);
			
			if (td.valid) {
				
				var w = td.width;
				var h = td.height;
				var data = new Array<cpp.UInt8> ();
				
				#if 1
				
				var size = w * h * 4;
				cpp.NativeArray.setSize (data, size);
				
				td.decode (cpp.Pointer.arrayElem (data, 0), size);
				/*
				{
					var dest:cpp.Pointer<cpp.UInt32> = cast cpp.Pointer.arrayElem (data, 0);	
					var src:cpp.Pointer<cpp.UInt32> = cast td.pointer;	
					var n = w * h;
					for (i in 0...n) {
						dest[i] = src[i];
					}
				}
				*/
				td.release ();
				
				#else
				
				// TODO(james4k): caveats here with every image
				// pointing to the same piece of memory, and things may
				// change with compressed textures. but, may be worth
				// considering if game is hitting memory constraints.
				// can we do this safely somehow? copy on write?
				// probably too many people writing directly to the
				// buffer...
				cpp.NativeArray.setUnmanagedData (data, td.pointer, w*h*4);
				
				#end
				
				var array = new UInt8Array (Bytes.ofData (cast data));
				buffer = new ImageBuffer (array, w, h);
				buffer.format = BGRA32;
				
			}
			
			#else
			
			#if (!sys || disable_cffi || java || macro)
			if (false) {}
			#else
			if (CFFI.enabled) {
				
				var data:Dynamic = lime_image_load (path);
				
				if (data != null) {
					
					var u8a = new UInt8Array (@:privateAccess new Bytes (data.data.length, data.data.b));
					buffer = new ImageBuffer (u8a, data.width, data.height, data.bitsPerPixel);
					
				}
				
			}
			#end
			
			#if format
			
			else {
				
				try {
					
					var bytes = File.getBytes (path);
					var input = new BytesInput (bytes, 0, bytes.length);
					var png = new Reader (input).read ();
					var data = Tools.extract32 (png);
					var header = Tools.getHeader (png);
					
					var data = new UInt8Array (Bytes.ofData (data.getData ()));
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
				
			}
			
			#end
			
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
			
			if (width == -1) {
				
				this.width = buffer.width;
				
			}
			
			if (height == -1) {
				
				this.height = buffer.height;
				
			}
			
		}
		
	}
	
	
	private static function __isJPG (bytes:Bytes) {
		
		return bytes.get (0) == 0xFF && bytes.get (1) == 0xD8;
		
	}
	
	
	private static function __isPNG (bytes:Bytes) {
		
		return (bytes.get (0) == 0x89 && bytes.get (1) == 0x50 && bytes.get (2) == 0x4E && bytes.get (3) == 0x47 && bytes.get (4) == 0x0D && bytes.get (5) == 0x0A && bytes.get (6) == 0x1A && bytes.get (7) == 0x0A);
		
	}
	
	private static function __isGIF (bytes:Bytes) {
		
		if (bytes.get (0) == 0x47 && bytes.get (1) == 0x49 && bytes.get (2) == 0x46 && bytes.get (3) == 0x38) {
			
			var b = bytes.get (4);
			return ((b == 0x37 || b == 0x39) && bytes.get (5) == 0x61);
			
		}
		
		return false;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_data ():UInt8Array {
		
		if (buffer.data == null && buffer.width > 0 && buffer.height > 0) {
			
			#if (js && html5)
				
				ImageCanvasUtil.convertToCanvas (this);
				ImageCanvasUtil.sync (this, false);
				ImageCanvasUtil.createImageData (this);
				
			#elseif flash
				
				var pixels = buffer.__srcBitmapData.getPixels (buffer.__srcBitmapData.rect);
				buffer.data = new UInt8Array (Bytes.ofData (pixels));
				
			#end
			
		}
		
		return buffer.data;
		
	}
	
	
	private function set_data (value:UInt8Array):UInt8Array {
		
		return buffer.data = value;
		
	}
	
	
	private function get_format ():PixelFormat {
		
		return buffer.format;
		
	}
	
	
	private function set_format (value:PixelFormat):PixelFormat {
		
		if (buffer.format != value) {
			
			switch (type) {
				
				case DATA:
					
					ImageDataUtil.setFormat (this, value);
				
				default:
				
			}
			
		}
		
		return buffer.format = value;
		
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
					
					#if (js && html5)
					ImageCanvasUtil.convertToData (this);
					#end
					
					ImageDataUtil.multiplyAlpha (this);
				
				default:
					
					// TODO
				
			}
			
		} else if (!value && buffer.premultiplied) {
			
			switch (type) {
				
				case DATA:
					
					#if (js && html5)
					ImageCanvasUtil.convertToData (this);
					#end
					
					ImageDataUtil.unmultiplyAlpha (this);
				
				default:
					
					// TODO
				
			}
			
		}
		
		return value;
		
	}
	
	
	private function get_rect ():Rectangle {
		
		return new Rectangle (0, 0, width, height);
		
	}
	
	
	private function get_src ():Dynamic {
		
		#if (js && html5)
		if (buffer.__srcCanvas == null) {
			
			ImageCanvasUtil.convertToCanvas (this);
			
		}
		#end
		
		return buffer.src;
		
	}
	
	
	private function set_src (value:Dynamic):Dynamic {
		
		return buffer.src = value;
		
	}
	
	
	private function get_transparent ():Bool {
		
		if (buffer == null) return false;
		return buffer.transparent;
		
	}
	
	
	private function set_transparent (value:Bool):Bool {
		
		// TODO, modify data to set transparency
		if (buffer == null) return false;
		return buffer.transparent = value;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_image_load (data:Dynamic):Dynamic;
	#end
	
	
}