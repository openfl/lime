package lime.graphics.utils;


import haxe.ds.Vector;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.utils.ByteArray;
import lime.utils.UInt8Array;


class ImageDataUtil {
	
	
	private static var __alpha16:Vector<Int>;
	private static var __clamp:Vector<Int>;
	
	
	private static function __init__ ():Void {
		
		__alpha16 = new Vector<Int> (256);
		
		for (i in 0...256) {
			
			__alpha16[i] = Std.int (i * (1 << 16) / 255);
			
		}
		
		__clamp = new Vector<Int> (0xFF + 0xFF);
		
		for (i in 0...0xFF) {
			
			__clamp[i] = i;
			
		}
		
		for (i in 0xFF...(0xFF + 0xFF + 1)) {
			
			__clamp[i] = 0xFF;
			
		}
		
	}
	
	
	public static function colorTransform (image:Image, rect:Rectangle, colorMatrix:ColorMatrix):Void {
		
		var data = image.buffer.data;
		var stride = image.buffer.width * 4;
		var offset:Int;
		
		var rowStart = Std.int (rect.top + image.offsetY);
		var rowEnd = Std.int (rect.bottom + image.offsetY);
		var columnStart = Std.int (rect.left + image.offsetX);
		var columnEnd = Std.int (rect.right + image.offsetX);
		
		var r, g, b, a, ex = 0;
		
		for (row in rowStart...rowEnd) {
			
			for (column in columnStart...columnEnd) {
				
				offset = (row * stride) + (column * 4);
				
				a = Std.int ((data[offset + 3] * colorMatrix.alphaMultiplier) + colorMatrix.alphaOffset);
				ex = a > 0xFF ? a - 0xFF : 0;
				b = Std.int ((data[offset + 2] * colorMatrix.blueMultiplier) + colorMatrix.blueOffset + ex);
				ex = b > 0xFF ? b - 0xFF : 0;
				g = Std.int ((data[offset + 1] * colorMatrix.greenMultiplier) + colorMatrix.greenOffset + ex);
				ex = g > 0xFF ? g - 0xFF : 0;
				r = Std.int ((data[offset] * colorMatrix.redMultiplier) + colorMatrix.redOffset + ex);
				
				data[offset] = r > 0xFF ? 0xFF : r;
				data[offset + 1] = g > 0xFF ? 0xFF : g;
				data[offset + 2] = b > 0xFF ? 0xFF : b;
				data[offset + 3] = a > 0xFF ? 0xFF : a;
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function copyChannel (image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, sourceChannel:ImageChannel, destChannel:ImageChannel):Void {
		
		var destIdx = switch (destChannel) {
			
			case RED: 0;
			case GREEN: 1;
			case BLUE: 2;
			case ALPHA: 3;
			
		}
		
		var srcIdx = switch (sourceChannel) {
			
			case RED: 0;
			case GREEN: 1;
			case BLUE: 2;
			case ALPHA: 3;
			
		}
		
		var srcStride = Std.int (sourceImage.buffer.width * 4);
		var srcPosition = Std.int (((sourceRect.x + sourceImage.offsetX) * 4) + (srcStride * (sourceRect.y + sourceImage.offsetY)) + srcIdx);
		var srcRowOffset = srcStride - Std.int (4 * (sourceRect.width + sourceImage.offsetX));
		var srcRowEnd = Std.int (4 * (sourceRect.x + sourceImage.offsetX + sourceRect.width));
		var srcData = sourceImage.buffer.data;
		
		var destStride = Std.int (image.buffer.width * 4);
		var destPosition = Std.int (((destPoint.x + image.offsetX) * 4) + (destStride * (destPoint.y + image.offsetY)) + destIdx);
		var destRowOffset = destStride - Std.int (4 * (sourceRect.width + image.offsetX));
		var destRowEnd = Std.int (4 * (destPoint.x + image.offsetX + sourceRect.width));
		var destData = image.buffer.data;
		
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
		
		image.dirty = true;
		
	}
	
	
	public static function copyPixels (image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, alphaImage:Image = null, alphaPoint:Vector2 = null, mergeAlpha:Bool = false):Void {
		
		if (alphaImage != null && alphaImage.transparent) {
			
			if (alphaPoint == null) alphaPoint = new Vector2 ();
			
			// TODO: use faster method
			
			var tempData = image.clone ();
			tempData.copyChannel (alphaImage, new Rectangle (alphaPoint.x, alphaPoint.y, sourceRect.width, sourceRect.height), new Vector2 (sourceRect.x, sourceRect.y), ImageChannel.ALPHA, ImageChannel.ALPHA);
			sourceImage = tempData;
			
		}
		
		var rowOffset = Std.int (destPoint.y + image.offsetY - sourceRect.y - sourceImage.offsetY);
		var columnOffset = Std.int (destPoint.x + image.offsetX - sourceRect.x - sourceImage.offsetY);
		
		var sourceData = sourceImage.buffer.data;
		var sourceStride = sourceImage.buffer.width * 4;
		var sourceOffset:Int = 0;
		
		var data = image.buffer.data;
		var stride = image.buffer.width * 4;
		var offset:Int = 0;
		
		if (!mergeAlpha || !sourceImage.transparent) {
			
			for (row in Std.int (sourceRect.top + sourceImage.offsetY)...Std.int (sourceRect.bottom + sourceImage.offsetY)) {
				
				for (column in Std.int (sourceRect.left + sourceImage.offsetX)...Std.int (sourceRect.right + sourceImage.offsetX)) {
					
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
			
			for (row in Std.int (sourceRect.top + sourceImage.offsetY)...Std.int (sourceRect.bottom + sourceImage.offsetY)) {
				
				for (column in Std.int (sourceRect.left + sourceImage.offsetX)...Std.int (sourceRect.right + sourceImage.offsetX)) {
					
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
		
		image.dirty = true;
		
	}
	
	
	public static function fillRect (image:Image, rect:Rectangle, color:Int):Void {
		
		var a = (image.transparent) ? ((color & 0xFF000000) >>> 24) : 0xFF;
		var r = (color & 0x00FF0000) >>> 16;
		var g = (color & 0x0000FF00) >>> 8;
		var b = (color & 0x000000FF);
		
		var rgba = (r | (g << 8) | (b << 16) | (a << 24));
		var data = image.buffer.data;
		
		if (rect.width == image.buffer.width && rect.height == image.buffer.height && rect.x == 0 && rect.y == 0 && image.offsetX == 0 && image.offsetY == 0) {
			
			var length = image.buffer.width * image.buffer.height;
			
			for (i in 0...length) {
				
				#if html5
				data[i] = r;
				data[i + 1] = g;
				data[i + 2] = b;
				data[i + 3] = a;
				#else
				data.setUInt32 (i * 4, rgba);
				#end
				
			}
			
		} else {
			
			var stride = image.buffer.width * 4;
			var offset:Int;
			
			var rowStart = Std.int (rect.y + image.offsetY);
			var rowEnd = Std.int (rect.bottom + image.offsetY);
			var columnStart = Std.int (rect.x + image.offsetX);
			var columnEnd = Std.int (rect.right + image.offsetX);
			
			for (row in rowStart...rowEnd) {
				
				for (column in columnStart...columnEnd) {
					
					offset = (row * stride) + (column * 4);
					
					#if html5
					data[offset] = r;
					data[offset + 1] = g;
					data[offset + 2] = b;
					data[offset + 3] = a;
					#else
					data.setUInt32 (offset, rgba);
					#end
					
				}
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function floodFill (image:Image, x:Int, y:Int, color:Int):Void {
		
		var data = image.buffer.data;
		var offset = (((y + image.offsetY) * (image.buffer.width * 4)) + ((x + image.offsetX) * 4));
		var hitColorR = data[offset + 0];
		var hitColorG = data[offset + 1];
		var hitColorB = data[offset + 2];
		var hitColorA = image.transparent ? data[offset + 3] : 0xFF;
		
		var r = (color & 0xFF0000) >>> 16;
		var g = (color & 0x00FF00) >>> 8;
		var b = (color & 0x0000FF);
		var a = image.transparent ? (color & 0xFF000000) >>> 24 : 0xFF;
		
		if (hitColorR == r && hitColorG == g && hitColorB == b && hitColorA == a) return;
		
		var dx = [ 0, -1, 1, 0 ];
		var dy = [ -1, 0, 0, 1 ];
		
		var minX = -image.offsetX;
		var minY = -image.offsetY;
		var maxX = minX + image.width;
		var maxY = minY + image.height;
		
		var queue = new Array<Int> ();
		queue.push (x);
		queue.push (y);
		
		while (queue.length > 0) {
			
			var curPointY = queue.pop ();
			var curPointX = queue.pop ();
			
			for (i in 0...4) {
				
				var nextPointX = curPointX + dx[i];
				var nextPointY = curPointY + dy[i];
				
				if (nextPointX < minX || nextPointY < minY || nextPointX >= maxX || nextPointY >= maxY) {
					
					continue;
					
				}
				
				var nextPointOffset = (nextPointY * image.width + nextPointX) * 4;
				
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
		
		image.dirty = true;
		
	}
	
	
	public static function getPixel (image:Image, x:Int, y:Int):Int {
		
		var data = image.buffer.data;
		var offset = (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4);
		
		if (image.premultiplied) {
			
			var unmultiply = 255.0 / data[offset + 3];
			trace (unmultiply);
			return __clamp[Std.int (data[offset] * unmultiply)] << 16 | __clamp[Std.int (data[offset + 1] * unmultiply)] << 8 | __clamp[Std.int (data[offset + 2] * unmultiply)];
			
		} else {
			
			return (data[offset] << 16) | (data[offset + 1] << 8) | (data[offset + 2]);
			
		}
		
	}
	
	
	public static function getPixel32 (image:Image, x:Int, y:Int):Int {
		
		var data = image.buffer.data;
		var offset = (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4);
		var a = (image.transparent ? data[offset + 3] : 0xFF);
		
		if (image.premultiplied && a != 0) {
			
			var unmultiply = 255.0 / a;
			return a << 24 | __clamp[Math.round (data[offset] * unmultiply)] << 16 | __clamp[Std.int (data[offset + 1] * unmultiply)] << 8 | __clamp[Std.int (data[offset + 2] * unmultiply)];
			
		} else {
			
			return a << 24 | data[offset] << 16 | data[offset + 1] << 8 | data[offset + 2];
			
		}
		
	}
	
	
	public static function getPixels (image:Image, rect:Rectangle):ByteArray {
		
		#if flash
		var byteArray = new ByteArray ();
		#else
		var byteArray = new ByteArray (image.width * image.height * 4);
		#end
		
		// TODO: optimize if the rect is the same as the full buffer size
			
		var srcData = image.buffer.data;
		var srcStride = Std.int (image.buffer.width * 4);
		var srcPosition = Std.int ((rect.x * 4) + (srcStride * rect.y));
		var srcRowOffset = srcStride - Std.int (4 * rect.width);
		var srcRowEnd = Std.int (4 * (rect.x + rect.width));
		
		var length = Std.int (4 * rect.width * rect.height);
		#if js
		byteArray.length = length;
		#end
		
		for (i in 0...length) {
			
			#if flash
			byteArray.writeUnsignedInt (srcData[srcPosition++]);
			#else
			byteArray.__set (i, srcData[srcPosition++]);
			#end
			
			if ((srcPosition % srcStride) > srcRowEnd) {
				
				srcPosition += srcRowOffset;
				
			}
			
		}
		
		byteArray.position = 0;
		return byteArray;
		
	}
	
	
	public static function multiplyAlpha (image:Image):Void {
		
		var data = image.buffer.data;
		if (data == null) return;
		
		var index, a16;
		var length = Std.int (data.length / 4);
		
		for (i in 0...length) {
			
			index = i * 4;
			
			var a16 = __alpha16[data[index + 3]];
			data[index] = (data[index] * a16) >> 16;
			data[index + 1] = (data[index + 1] * a16) >> 16;
			data[index + 2] = (data[index + 2] * a16) >> 16;
			
		}
		
		image.buffer.premultiplied = true;
		image.dirty = true;
		
	}
	
	
	public static function resize (image:Image, newWidth:Int, newHeight:Int):Void {
		
		var buffer = image.buffer;
		var newBuffer = new ImageBuffer (new UInt8Array (newWidth * newHeight * 4), newWidth, newHeight);
		
		var imageWidth = image.width;
		var imageHeight = image.height;
		
		var data = image.data;
		var newData = newBuffer.data;
		var sourceIndex:Int, sourceIndexX:Int, sourceIndexY:Int, sourceIndexXY:Int, index:Int;
		var sourceX:Int, sourceY:Int;
		var u:Float, v:Float, uRatio:Float, vRatio:Float, uOpposite:Float, vOpposite:Float;
		
		for (y in 0...newHeight) {
			
			for (x in 0...newWidth) {
				
				u = ((x + 0.5) / newWidth) * imageWidth - 0.5;
				v = ((y + 0.5) / newHeight) * imageHeight - 0.5;
				
				sourceX = Std.int (u);
				sourceY = Std.int (v);
				
				sourceIndex = (sourceY * imageWidth + sourceX) * 4;
				sourceIndexX = (sourceX < imageWidth - 1) ? sourceIndex + 4 : sourceIndex;
				sourceIndexY = (sourceY < imageHeight - 1) ? sourceIndex + (imageWidth * 4) : sourceIndex;
				sourceIndexXY = (sourceIndexX != sourceIndex) ? sourceIndexY + 4 : sourceIndexY;
				
				index = (y * newWidth + x) * 4;
				
				uRatio = u - sourceX;
				vRatio = v - sourceY;
				uOpposite = 1 - uRatio;
				vOpposite = 1 - vRatio;
				
				newData[index] = Std.int ((data[sourceIndex] * uOpposite + data[sourceIndexX] * uRatio) * vOpposite + (data[sourceIndexY] * uOpposite + data[sourceIndexXY] * uRatio) * vRatio);
				newData[index + 1] = Std.int ((data[sourceIndex + 1] * uOpposite + data[sourceIndexX + 1] * uRatio) * vOpposite + (data[sourceIndexY + 1] * uOpposite + data[sourceIndexXY + 1] * uRatio) * vRatio);
				newData[index + 2] = Std.int ((data[sourceIndex + 2] * uOpposite + data[sourceIndexX + 2] * uRatio) * vOpposite + (data[sourceIndexY + 2] * uOpposite + data[sourceIndexXY + 2] * uRatio) * vRatio);
				
				// Maybe it would be better to not weigh colors with an alpha of zero, but the below should help prevent black fringes caused by transparent pixels made visible
				
				if (data[sourceIndexX + 3] == 0 || data[sourceIndexY + 3] == 0 || data[sourceIndexXY + 3] == 0) {
					
					newData[index + 3] = 0;
					
				} else {
					
					newData[index + 3] = data[sourceIndex + 3];
					
				}
				
			}
			
		}
		
		buffer.data = newData;
		buffer.width = newWidth;
		buffer.height = newHeight;
		
	}
	
	
	public static function resizeBuffer (image:Image, newWidth:Int, newHeight:Int):Void {
		
		var buffer = image.buffer;
		var data = image.data;
		var newData = new UInt8Array (newWidth * newHeight * 4);
		var sourceIndex:Int, index:Int;
		
		for (y in 0...buffer.height) {
			
			for (x in 0...buffer.width) {
				
				sourceIndex = (y * buffer.width + x) * 4;
				index = (y * newWidth + x) * 4;
				
				newData[index] = data[sourceIndex];
				newData[index + 1] = data[sourceIndex + 1];
				newData[index + 2] = data[sourceIndex + 2];
				newData[index + 3] = data[sourceIndex + 3];
				
			}
			
		}
		
		buffer.data = newData;
		buffer.width = newWidth;
		buffer.height = newHeight;
		
	}
	
	
	public static function setPixel (image:Image, x:Int, y:Int, color:Int):Void {
		
		var data = image.buffer.data;
		var offset = (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4);
		
		data[offset] = (color & 0xFF0000) >>> 16;
		data[offset + 1] = (color & 0x00FF00) >>> 8;
		data[offset + 2] = (color & 0x0000FF);
		if (image.transparent) data[offset + 3] = (0xFF);
		
		image.dirty = true;
		
	}
	
	
	public static function setPixel32 (image:Image, x:Int, y:Int, color:Int):Void {
		
		var data = image.buffer.data;
		var offset = (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4);
		var a = (image.transparent ? (color & 0xFF000000) >>> 24 : 0xFF);
		
		if (image.transparent && image.premultiplied) {
			
			var a16 = __alpha16[a];
			data[offset] = (((color & 0x00FF0000) >>> 16) * a16) >> 16;
			data[offset + 1] = (((color & 0x0000FF00) >>> 8) * a16) >> 16;
			data[offset + 2] = ((color & 0x000000FF) * a16) >> 16;
			data[offset + 3] = a;
			
		} else {
			
			data[offset] = (color & 0x00FF0000) >>> 16;
			data[offset + 1] = (color & 0x0000FF00) >>> 8;
			data[offset + 2] = (color & 0x000000FF);
			data[offset + 3] = a;
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function setPixels (image:Image, rect:Rectangle, byteArray:ByteArray):Void {
		
		var len = Math.round (4 * rect.width * rect.height);
		
		// TODO: optimize when rect is the same as the buffer size
		
		var data = image.buffer.data;
		var offset = Math.round (4 * image.buffer.width * (rect.y + image.offsetX) + (rect.x + image.offsetY) * 4);
		var pos = offset;
		var boundR = Math.round (4 * (rect.x + rect.width + image.offsetX));
		var width = image.buffer.width;
		
		for (i in 0...len) {
			
			if (((pos) % (width * 4)) > boundR - 1) {
				
				pos += width * 4 - boundR;
				
			}
			
			data[pos] = byteArray.readByte ();
			pos++;
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function unmultiplyAlpha (image:Image):Void {
		
		var data = image.buffer.data;
		var index, a, unmultiply;
		var length = Std.int (data.length / 4);
		
		for (i in 0...length) {
			
			index = i * 4;
			
			a = data[index + 3];
			
			if (a != 0) {
				
				unmultiply = 255.0 / a;
				
				data[index] = __clamp[Std.int (data[index] * unmultiply)];
				data[index + 1] = __clamp[Std.int (data[index + 1] * unmultiply)];
				data[index + 2] = __clamp[Std.int (data[index + 2] * unmultiply)];
				
			}
			
		}
		
		image.buffer.premultiplied = false;
		image.dirty = true;
		
	}
	
	
}