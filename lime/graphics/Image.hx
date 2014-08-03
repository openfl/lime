package lime.graphics;


import haxe.ds.Vector;
import lime.app.Application;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.utils.ByteArray;
import lime.utils.UInt8Array;
import lime.system.System;

#if js
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.Image in HTMLImage;
import js.Browser;
#elseif flash
import flash.display.BitmapData;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle in FlashRectangle;
#end

@:access(lime.app.Application)


class Image {
	
	
	private static var __clamp:Vector<Int>;
	
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
	public var transparent:Bool;
	public var width:Int;
	
	private var __sourceImageDataChanged:Bool;
	private var __type:StoreType;
	
	
	public function new (buffer:ImageBuffer, context:RenderContext = null) {
		
		this.buffer = buffer;
		
		if (context == null) {
			
			context = Application.__instance.window.currentRenderer.context;
			
		}
		
		width = buffer.width;
		height = buffer.height;
		offsetX = 0;
		offsetY = 0;
		
		__type = switch (context) {
			
			case DOM (_), CANVAS (_): HTML5;
			case FLASH (_): FLASH;
			default: DATA;
			
		}
		
		if (__clamp == null) {
			
			__clamp = new Vector<Int> (0xFF + 0xFF);
			
			for (i in 0...0xFF) {
				
				__clamp[i] = i;
				
			}
			
			for (i in 255...(0xFF + 0xFF + 1)) {
				
				__clamp[i] = 255;
				
			}
			
		}
		
	}
	
	
	public function clone ():Image {
		
		var image = new Image (buffer.clone (), null);
		image.__type = __type;
		
		image.width = width;
		image.height = height;
		image.offsetX = offsetX;
		image.offsetY = offsetY;
		
		return image;
		
	}
	
	
	public function colorTransform (rect:Rectangle, colorMatrix:ColorMatrix):Void {
		
		rect = __clipRect (rect);
		if (buffer == null || rect == null) return;
		
		#if js
		__convertToCanvas ();
		__createImageData ();
		__sourceImageDataChanged = true;
		#end
		
		switch (__type) {
			
			case DATA, HTML5:
				
				var data = buffer.data;
				var stride = buffer.width * 4;
				var offset:Int;
				
				for (row in Std.int (rect.y + offsetY)...Std.int (rect.height + offsetY)) {
					
					for (column in Std.int (rect.x + offsetX)...Std.int (rect.width + offsetX)) {
						
						offset = (row * stride) + (column * 4);
						
						data[offset] = Std.int ((data[offset] * colorMatrix.redMultiplier) + colorMatrix.redOffset);
						data[offset + 1] = Std.int ((data[offset + 1] * colorMatrix.greenMultiplier) + colorMatrix.greenOffset);
						data[offset + 2] = Std.int ((data[offset + 2] * colorMatrix.blueMultiplier) + colorMatrix.blueOffset);
						data[offset + 3] = Std.int ((data[offset + 3] * colorMatrix.alphaMultiplier) + colorMatrix.alphaOffset);
						
					}
					
				}
			
			case FLASH:
				
				#if flash
				var rect = new FlashRectangle (rect.x + offsetX, rect.y + offsetY, rect.width + offsetX, rect.height + offsetY);
				var transform = new ColorTransform (colorMatrix.redMultiplier, colorMatrix.greenMultiplier, colorMatrix.blueMultiplier, colorMatrix.alphaMultiplier, colorMatrix.redOffset, colorMatrix.greenOffset, colorMatrix.blueOffset, colorMatrix.alphaOffset);
				buffer.src.colorTransform (rect, transform);
				#end
			
		}
		
		dirty = true;
		
	}
	
	
	public function copyChannel (sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, sourceChannel:ImageChannel, destChannel:ImageChannel):Void {
		
		sourceRect = __clipRect (sourceRect);
		if (buffer == null || sourceRect == null) return;
		
		if (destChannel == ImageChannel.ALPHA && !transparent) return;
		if (sourceRect.width <= 0 || sourceRect.height <= 0) return;
		if (sourceRect.x + sourceRect.width > sourceImage.width) sourceRect.width = sourceImage.width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceImage.height) sourceRect.height = sourceImage.height - sourceRect.y;
		
		var destIdx = -1;
		
		if (destChannel == ImageChannel.ALPHA) { 
			
			destIdx = 3;
			
		} else if (destChannel == ImageChannel.BLUE) {
			
			destIdx = 2;
			
		} else if (destChannel == ImageChannel.GREEN) {
			
			destIdx = 1;
			
		} else if (destChannel == ImageChannel.RED) {
			
			destIdx = 0;
			
		} else {
			
			throw "Invalid destination BitmapDataChannel passed to BitmapData::copyChannel.";
			
		}
		
		var srcIdx = -1;
		
		if (sourceChannel == ImageChannel.ALPHA) {
			
			srcIdx = 3;
			
		} else if (sourceChannel == ImageChannel.BLUE) {
			
			srcIdx = 2;
			
		} else if (sourceChannel == ImageChannel.GREEN) {
			
			srcIdx = 1;
			
		} else if (sourceChannel == ImageChannel.RED) {
			
			srcIdx = 0;
			
		} else {
			
			throw "Invalid source ImageChannel passed to Image.copyChannel.";
			
		}
		
		#if js
		sourceImage.__convertToCanvas ();
		sourceImage.__createImageData ();
		__convertToCanvas ();
		__createImageData ();
		__sourceImageDataChanged = true;
		#end
		
		switch (__type) {
			
			case DATA, HTML5:
				
				var srcStride = Std.int (sourceImage.buffer.width * 4);
				var srcPosition = Std.int (((sourceRect.x + sourceImage.offsetX) * 4) + (srcStride * (sourceRect.y + sourceImage.offsetY)) + srcIdx);
				var srcRowOffset = srcStride - Std.int (4 * (sourceRect.width + sourceImage.offsetX));
				var srcRowEnd = Std.int (4 * (sourceRect.x + sourceImage.offsetX + sourceRect.width));
				var srcData = sourceImage.buffer.data;
				
				var destStride = Std.int (buffer.width * 4);
				var destPosition = Std.int (((destPoint.x + offsetX) * 4) + (destStride * (destPoint.y + offsetY)) + destIdx);
				var destRowOffset = destStride - Std.int (4 * (sourceRect.width + offsetX));
				var destRowEnd = Std.int (4 * (destPoint.x + offsetX + sourceRect.width));
				var destData = buffer.data;
				
				var length = Std.int (sourceRect.width * sourceRect.height);
				
				for (i in 0...length) {
					
					destData[destPosition] = srcData[srcPosition];
					
					srcPosition += 4;
					destPosition += 4;
					
					if ((srcPosition % srcStride) > srcRowEnd) {
						
						srcPosition += srcRowOffset;
						
					}
					
					if ((destPosition % destStride) > destRowEnd) {
						
						destPosition += destRowOffset;
						
					}
					
				}
			
			case FLASH:
				
				#if flash
				var sourceBitmapData = sourceImage.buffer.src;
				var rect = new FlashRectangle (sourceRect.x + sourceImage.offsetX, sourceRect.y + sourceImage.offsetY, sourceRect.width + sourceImage.offsetX, sourceRect.height + sourceImage.offsetY);
				var point = new Point (destPoint.x + offsetX, destPoint.y + offsetY);
				
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
				
				buffer.src.copyChannel (sourceBitmapData, rect, point, srcChannel, dstChannel);
				#end
				
		}
		
		dirty = true;
		
	}
	
	
	public function copyPixels (sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, alphaImage:Image = null, alphaPoint:Vector2 = null, mergeAlpha:Bool = false):Void {
		
		if (buffer == null || sourceImage == null) return;
		
		if (sourceRect.x + sourceRect.width > sourceImage.width) sourceRect.width = sourceImage.width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceImage.height) sourceRect.height = sourceImage.height - sourceRect.y;
		if (sourceRect.width <= 0 || sourceRect.height <= 0) return;
		
		if (alphaImage != null && alphaImage.transparent) {
			
			if (alphaPoint == null) alphaPoint = new Vector2 ();
			
			// TODO: use faster method
			
			var tempData = clone ();
			tempData.copyChannel (alphaImage, new Rectangle (alphaPoint.x, alphaPoint.y, sourceRect.width, sourceRect.height), new Vector2 (sourceRect.x, sourceRect.y), ImageChannel.ALPHA, ImageChannel.ALPHA);
			sourceImage = tempData;
			
		}
		
		switch (__type) {
			
			case DATA:
				
				#if js
				__convertToCanvas ();
				__createImageData ();
				#end
				
				var rowOffset = Std.int (destPoint.y + offsetY - sourceRect.y - sourceImage.offsetY);
				var columnOffset = Std.int (destPoint.x + offsetX - sourceRect.x - sourceImage.offsetY);
				
				var sourceData = sourceImage.buffer.data;
				var sourceStride = sourceImage.buffer.width * 4;
				var sourceOffset:Int;
				
				var data = buffer.data;
				var stride = buffer.width * 4;
				var offset:Int;
				
				if (!mergeAlpha || !sourceImage.transparent) {
					
					for (row in Std.int (sourceRect.y + sourceImage.offsetY)...Std.int (sourceRect.height + sourceImage.offsetY)) {
						
						for (column in Std.int (sourceRect.x + sourceImage.offsetX)...Std.int (sourceRect.width + sourceImage.offsetX)) {
							
							sourceOffset = (row * sourceStride) + (column * 4);
							offset = ((row + rowOffset) * stride) + ((column + columnOffset) * 4);
							
							data[offset] = sourceData[sourceOffset];
							data[offset + 1] = sourceData[sourceOffset + 1];
							data[offset + 2] = sourceData[sourceOffset + 2];
							data[offset + 3] = sourceData[sourceOffset + 3];
							
						}
						
					}
					
				} else {
					
					var sourceAlpha:Float;
					var oneMinusSourceAlpha:Float;
					
					for (row in Std.int (sourceRect.y + sourceImage.offsetY)...Std.int (sourceRect.height + sourceImage.offsetY)) {
						
						for (column in Std.int (sourceRect.x + sourceImage.offsetX)...Std.int (sourceRect.width + sourceImage.offsetX)) {
							
							sourceOffset = (row * sourceStride) + (column * 4);
							offset = ((row + rowOffset) * stride) + ((column + columnOffset) * 4);
							
							sourceAlpha = sourceData[sourceOffset + 3] / 255;
							oneMinusSourceAlpha = (1 - sourceAlpha);
							
							data[offset] = __clamp[Std.int (sourceData[sourceOffset] + (data[offset] * oneMinusSourceAlpha))];
							data[offset + 1] = __clamp[Std.int (sourceData[sourceOffset + 1] + (data[offset + 1] * oneMinusSourceAlpha))];
							data[offset + 2] = __clamp[Std.int (sourceData[sourceOffset + 2] + (data[offset + 2] * oneMinusSourceAlpha))];
							data[offset + 3] = __clamp[Std.int (sourceData[sourceOffset + 3] + (data[offset + 3] * oneMinusSourceAlpha))];
							
						}
						
					}
					
				}
			
			case FLASH:
				
				// TODO
			
			case HTML5:
				
				#if js
				__syncImageData ();
				
				if (!mergeAlpha) {
					
					if (transparent && sourceImage.transparent) {
						
						buffer.__canvasContext.clearRect (destPoint.x + offsetX, destPoint.y + offsetY, sourceRect.width + offsetX, sourceRect.height + offsetY);
						
					}
					
				}
				
				sourceImage.__syncImageData ();
				
				if (sourceImage.buffer.__image != null) {
					
					buffer.__canvasContext.drawImage (sourceImage.buffer.__image, Std.int (sourceRect.x + sourceImage.offsetX), Std.int (sourceRect.y + sourceImage.offsetY), Std.int (sourceRect.width), Std.int (sourceRect.height), Std.int (destPoint.x + offsetX), Std.int (destPoint.y + offsetY), Std.int (sourceRect.width), Std.int (sourceRect.height));
					
				} else if (sourceImage.buffer.__canvas != null) {
					
					buffer.__canvasContext.drawImage (sourceImage.buffer.__canvas, Std.int (sourceRect.x + sourceImage.offsetX), Std.int (sourceRect.y + sourceImage.offsetY), Std.int (sourceRect.width), Std.int (sourceRect.height), Std.int (destPoint.x + offsetX), Std.int (destPoint.y + offsetY), Std.int (sourceRect.width), Std.int (sourceRect.height));
					
				}
				#end
			
		}
		
		dirty = true;
		
	}
	
	
	public function fillRect (rect:Rectangle, color:Int):Void {
		
		rect = __clipRect (rect);
		if (buffer == null || rect == null) return;
		
		#if js
		__convertToCanvas ();
		__syncImageData ();
		#end
		
		if (__type == HTML5 && rect.x == 0 && rect.y == 0 && rect.width == width && rect.height == height) {
			
			if (transparent && ((color & 0xFF000000) == 0)) {
				
				buffer.__canvas.width = buffer.width;
				return;
				
			}
			
		}
		
		__fillRect (rect, color);
		
	}
	
	
	public function floodFill (x:Int, y:Int, color:Int):Void {
		
		if (buffer == null) return;
		
		#if js
		__convertToCanvas ();
		__createImageData ();
		__sourceImageDataChanged = true;
		#end
		
		switch (__type) {
			
			case DATA, HTML5:
				
				var data = buffer.data;
				var offset = (((y + offsetY) * (buffer.width * 4)) + ((x + offsetX) * 4));
				var hitColorR = data[offset + 0];
				var hitColorG = data[offset + 1];
				var hitColorB = data[offset + 2];
				var hitColorA = transparent ? data[offset + 3] : 0xFF;
				
				var r = (color & 0xFF0000) >>> 16;
				var g = (color & 0x00FF00) >>> 8;
				var b = (color & 0x0000FF);
				var a = transparent ? (color & 0xFF000000) >>> 24 : 0xFF;
				
				if (hitColorR == r && hitColorG == g && hitColorB == b && hitColorA == a) return;
				
				var dx = [ 0, -1, 1, 0 ];
				var dy = [ -1, 0, 0, 1 ];
				
				var queue = new Array<Int> ();
				queue.push (x);
				queue.push (y);
				
				while (queue.length > 0) {
					
					var curPointY = queue.pop ();
					var curPointX = queue.pop ();
					
					for (i in 0...4) {
						
						var nextPointX = curPointX + dx[i];
						var nextPointY = curPointY + dy[i];
						
						if (nextPointX < 0 || nextPointY < 0 || nextPointX >= width || nextPointY >= height) {
							
							continue;
							
						}
						
						var nextPointOffset = (nextPointY * width + nextPointX) * 4;
						
						if (data[nextPointOffset + 0] == hitColorR && data[nextPointOffset + 1] == hitColorG && data[nextPointOffset + 2] == hitColorB && data[nextPointOffset + 3] == hitColorA) {
							
							data[nextPointOffset + 0] = r;
							data[nextPointOffset + 1] = g;
							data[nextPointOffset + 2] = b;
							data[nextPointOffset + 3] = a;
						    
							queue.push (nextPointX);
							queue.push (nextPointY);
							
						}
						
					}
					
				}
			
			case FLASH:
				
				// TODO
			
		}
		
		dirty = true;
		
	}
	
	
	#if flash
	public static function fromBitmapData (bitmapData:BitmapData):Image {
		
		var buffer = new ImageBuffer (null, bitmapData.width, bitmapData.height);
		buffer.src = bitmapData;
		return new Image (buffer);
		
	}
	#end
	
	
	public static function fromBytes (bytes:ByteArray):Image {
		
		#if (cpp || neko)
		
		var data = lime_image_load (bytes);
		
		if (data != null) {
			
			var buffer = new ImageBuffer (new UInt8Array (data.data), data.width, data.height, data.bpp);
			return new Image (buffer);
			
		} else {
			
			return null;
			
		}
		
		#else
		
		throw "ImageBuffer.loadFromFile not supported on this target";
		
		#end
		
	}
	
	
	public static function fromFile (path:String):Image {
		
		#if (cpp || neko)
		
		var data = lime_image_load (path);
		
		if (data != null) {
			
			var buffer = new ImageBuffer (new UInt8Array (data.data), data.width, data.height, data.bpp);
			return new Image (buffer);
			
		} else {
			
			return null;
			
		}
		
		#else
		
		throw "ImageBuffer.loadFromFile not supported on this target";
		
		#end
		
	}
	
	
	#if js
	public static function fromImage (image:HTMLImage):Image {
		
		var buffer = new ImageBuffer (null, image.width, image.height);
		buffer.src = image;
		return new Image (buffer);
		
	}
	#end
	
	
	public function getPixel (x:Int, y:Int):Int {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return 0;
		
		#if js
		__convertToCanvas ();
		__createImageData ();
		#end
		
		switch (__type) {
			
			case DATA, HTML5:
				
				var data = buffer.data;
				var offset = (4 * (y + offsetY) * buffer.width + (x + offsetX) * 4);
				return (data[offset] << 16) | (data[offset + 1] << 8) | (data[offset + 2]);
			
			case FLASH:
				
				return buffer.src.getPixel (x + offsetX, y + offsetY);
			
		}
		
	}
	
	
	public function getPixel32 (x:Int, y:Int):Int {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return 0;
		
		#if js
		__convertToCanvas ();
		__createImageData ();
		#end
		
		switch (__type) {
			
			case DATA, HTML5:
				
				var data = buffer.data;
				var offset = (4 * (y + offsetY) * buffer.width + (x + offsetX) * 4);
				return (transparent ? data[offset + 3] : 0xFF) << 24 | data[offset] << 16 | data[offset + 1] << 8 | data[offset + 2];
			
			case FLASH:
				
				return buffer.src.getPixel32 (x + offsetX, y + offsetY);
			
		}
		
	}
	
	
	public function setPixel (x:Int, y:Int, color:Int):Void {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return;
		
		#if js
		__convertToCanvas ();
		__createImageData ();
		__sourceImageDataChanged = true;
		#end
		
		switch (__type) {
			
			case DATA, HTML5:
				
				var data = buffer.data;
				var offset = (4 * (y + offsetY) * buffer.width + (x + offsetX) * 4);
				
				data[offset] = (color & 0xFF0000) >>> 16;
				data[offset + 1] = (color & 0x00FF00) >>> 8;
				data[offset + 2] = (color & 0x0000FF);
				if (transparent) data[offset + 3] = (0xFF);
			
			case FLASH:
				
				buffer.src.setPixel (x + offsetX, y + offsetX, color);
			
		}
		
		dirty = true;
		
	}
	
	
	public function setPixel32 (x:Int, y:Int, color:Int):Void {
		
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return;
		
		#if js
		__convertToCanvas ();
		__createImageData ();
		__sourceImageDataChanged = true;
		#end
		
		switch (__type) {
			
			case DATA, HTML5:
				
				var data = buffer.data;
				var offset = (4 * (y + offsetY) * buffer.width + (x + offsetX) * 4);
				
				data[offset] = (color & 0x00FF0000) >>> 16;
				data[offset + 1] = (color & 0x0000FF00) >>> 8;
				data[offset + 2] = (color & 0x000000FF);
				
				if (transparent) {
					
					data[offset + 3] = (color & 0xFF000000) >>> 24;
					
				} else {
					
					data[offset + 3] = (0xFF);
					
				}
			
			case FLASH:
				
				buffer.src.setPixel32 (x + offsetX, y + offsetY, color);
			
		}
		
		dirty = true;
		
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
	
	
	private function __convertToCanvas ():Void {
		
		if (buffer.__image != null) {
			
			if (buffer.__canvas == null) {
				
				__createCanvas (buffer.__image.width, buffer.__image.height);
				buffer.__canvasContext.drawImage (buffer.__image, 0, 0);
				
			}
			
			buffer.__image = null;
			
		}
		
	}
	
	
	private function __createCanvas (width:Int, height:Int):Void {
		
		#if js
		if (buffer.__canvas == null) {
			
			buffer.__canvas = cast Browser.document.createElement ("canvas");
			buffer.__canvas.width = buffer.width;
			buffer.__canvas.height = buffer.height;
			
			if (!transparent) {
				
				if (!transparent) buffer.__canvas.setAttribute ("moz-opaque", "true");
				buffer.__canvasContext = untyped __js__ ('this.buffer.__canvas.getContext ("2d", { alpha: false })');
				
			} else {
				
				buffer.__canvasContext = buffer.__canvas.getContext ("2d");
				
			}
			
			untyped (buffer.__canvasContext).mozImageSmoothingEnabled = false;
			untyped (buffer.__canvasContext).webkitImageSmoothingEnabled = false;
			buffer.__canvasContext.imageSmoothingEnabled = false;
			
		}
		#end
		
	}
	
	
	private function __createImageData ():Void {
		
		#if js
		if (buffer.data == null) {
			
			buffer.data = new UInt8Array (buffer.__canvasContext.getImageData (0, 0, buffer.width, buffer.height).data);
			
			if (__type == DATA) {
				
				buffer.__image = null;
				buffer.__canvas = null;
				buffer.__canvasContext = null;
				
			}
			
		}
		#end
		
	}
	
	
	private function __fillRect (rect:Rectangle, color:Int) {
		
		var a = (transparent) ? ((color & 0xFF000000) >>> 24) : 0xFF;
		var r = (color & 0x00FF0000) >>> 16;
		var g = (color & 0x0000FF00) >>> 8;
		var b = (color & 0x000000FF);
		
		switch (__type) {
			
			case DATA:
				
				var data = buffer.data;
				var stride = buffer.width * 4;
				var offset:Int;
				
				for (row in Std.int (rect.y + offsetY)...Std.int (rect.height + offsetY)) {
					
					for (column in Std.int (rect.x + offsetX)...Std.int (rect.width + offsetX)) {
						
						offset = (row * stride) + (column * 4);
						
						data[offset] = r;
						data[offset + 1] = g;
						data[offset + 2] = b;
						data[offset + 3] = a;
						
					}
					
				}
				
				trace (data);
			
			case FLASH:
				
				#if flash
				buffer.src.fillRect (new FlashRectangle (rect.x + offsetX, rect.y + offsetY, rect.width + offsetX, rect.height + offsetY), color);
				#end
			
			case HTML5:
				
				buffer.__canvasContext.fillStyle = 'rgba(' + r + ', ' + g + ', ' + b + ', ' + (a / 255) + ')';
				buffer.__canvasContext.fillRect (rect.x + offsetX, rect.y + offsetY, rect.width + offsetX, rect.height + offsetY);
			
		}
		
		dirty = true;
		
	}
	
	
	private function __syncImageData ():Void {
		
		#if js
		if (__sourceImageDataChanged && __type != DATA) {
			
			buffer.__canvasContext.putImageData (cast buffer.data, 0, 0);
			buffer.data = null;
			__sourceImageDataChanged = false;
			
		}
		#end
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_data ():UInt8Array {
		
		if (buffer.data == null && buffer.width > 0 && buffer.height > 0) {
			
			#if js
			__convertToCanvas ();
			__createImageData ();
			#elseif flash
			var pixels = buffer.src.getPixels (buffer.src.rect);
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
			
			switch (__type) {
				
				case DATA:
					
					var data = this.data;
					var newData = new UInt8Array (newWidth * newHeight * 4);
					var sourceIndex:Int, index:Int;
					
					for (y in 0...buffer.height) {
						
						for (x in 0...buffer.width) {
							
							sourceIndex = y * buffer.width + x;
							index = y * newWidth + x * 4;
							
							newData[index] = data[sourceIndex];
							newData[index + 1] = data[sourceIndex + 1];
							newData[index + 2] = data[sourceIndex + 2];
							newData[index + 3] = data[sourceIndex + 3];
							
						}
						
					}
					
					buffer.data = newData;
					buffer.width = newWidth;
					buffer.height = newHeight;
				
				case FLASH:
					
					#if flash
					var bitmapData = new BitmapData (newWidth, newHeight, true, 0x000000);
					bitmapData.draw (buffer.src, null, null, null, true);
					
					buffer.src = bitmapData;
					buffer.width = newWidth;
					buffer.height = newHeight;
					#end
				
				case HTML5:
					
					// TODO
				
			}
			
		}
		
		return value;
		
	}
	
	
	private function get_premultiplied ():Bool {
		
		return buffer.premultiplied;
		
	}
	
	
	private function set_premultiplied (value:Bool):Bool {
		
		if (value && !buffer.premultiplied) {
			
			switch (__type) {
				
				case DATA:
					
					var data = buffer.data;
					var index, a;
					var length = Std.int (data.length / 4);
					
					for (i in 0...length) {
						
						index = i * 4;
						
						a = data[index + 3];
						data[index] = (data[index] * a) >> 8;
						data[index + 1] = (data[index + 1] * a) >> 8;
						data[index + 2] = (data[index + 2] * a) >> 8;
						
					}
					
					buffer.premultiplied = true;
				
				default:
					
					// TODO
				
			}
			
		} else {
			
			// TODO, unmultiply
			
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


private enum StoreType {
	
	DATA;
	HTML5;
	FLASH;
	
}