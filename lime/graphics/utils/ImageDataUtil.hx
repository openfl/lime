package lime.graphics.utils;


import haxe.ds.Vector;
import lime.graphics.Image;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.utils.ByteArray;
import lime.utils.UInt8Array;


class ImageDataUtil {
	
	
	private static var __clamp:Vector<Int>;
	
	
	public static function colorTransform (image:Image, rect:Rectangle, colorMatrix:ColorMatrix):Void {
		
		var data = image.buffer.data;
		var stride = image.buffer.width * 4;
		var offset:Int;
		
		var rowStart = Std.int (rect.y + image.offsetY);
		var rowEnd = Std.int (rect.height + image.offsetY);
		var columnStart = Std.int (rect.x + image.offsetX);
		var columnEnd = Std.int (rect.width + image.offsetX);
		
		for (row in rowStart...rowEnd) {
			
			for (column in columnStart...columnEnd) {
				
				offset = (row * stride) + (column * 4);
				
				data[offset] = Std.int ((data[offset] * colorMatrix.redMultiplier) + colorMatrix.redOffset);
				data[offset + 1] = Std.int ((data[offset + 1] * colorMatrix.greenMultiplier) + colorMatrix.greenOffset);
				data[offset + 2] = Std.int ((data[offset + 2] * colorMatrix.blueMultiplier) + colorMatrix.blueOffset);
				data[offset + 3] = Std.int ((data[offset + 3] * colorMatrix.alphaMultiplier) + colorMatrix.alphaOffset);
				
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
		var sourceOffset:Int;
		
		var data = image.buffer.data;
		var stride = image.buffer.width * 4;
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
			
			if (__clamp == null) {
				
				__clamp = new Vector<Int> (0xFF + 0xFF);
				
				for (i in 0...0xFF) {
					
					__clamp[i] = i;
					
				}
				
				for (i in 255...(0xFF + 0xFF + 1)) {
					
					__clamp[i] = 255;
					
				}
				
			}
			
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
		
		image.dirty = true;
		
	}
	
	
	public static function fillRect (image:Image, rect:Rectangle, color:Int):Void {
		
		var a = (image.transparent) ? ((color & 0xFF000000) >>> 24) : 0xFF;
		var r = (color & 0x00FF0000) >>> 16;
		var g = (color & 0x0000FF00) >>> 8;
		var b = (color & 0x000000FF);
		
		var data = image.buffer.data;
		var stride = image.buffer.width * 4;
		var offset:Int;
		
		var rowStart = Std.int (rect.y + image.offsetY);
		var rowEnd = Std.int (rect.height + image.offsetY);
		var columnStart = Std.int (rect.x + image.offsetX);
		var columnEnd = Std.int (rect.width + image.offsetX);
		
		for (row in rowStart...rowEnd) {
			
			for (column in columnStart...columnEnd) {
				
				offset = (row * stride) + (column * 4);
				
				data[offset] = r;
				data[offset + 1] = g;
				data[offset + 2] = b;
				data[offset + 3] = a;
				
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
		
		return (data[offset] << 16) | (data[offset + 1] << 8) | (data[offset + 2]);
		
	}
	
	
	public static function getPixel32 (image:Image, x:Int, y:Int):Int {
		
		var data = image.buffer.data;
		var offset = (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4);
		
		return (image.transparent ? data[offset + 3] : 0xFF) << 24 | data[offset] << 16 | data[offset + 1] << 8 | data[offset + 2];
		
	}
	
	
	public static function getPixels (image:Image, rect:Rectangle):ByteArray {
		
		var byteArray = new ByteArray ();
		
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
			
			byteArray.__set (i, srcData[srcPosition++]);
			
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
		
		var index, a;
		var length = Std.int (data.length / 4);
		
		for (i in 0...length) {
			
			index = i * 4;
			
			a = data[index + 3];
			data[index] = (data[index] * a) >> 8;
			data[index + 1] = (data[index + 1] * a) >> 8;
			data[index + 2] = (data[index + 2] * a) >> 8;
			
		}
		
		image.buffer.premultiplied = true;
		image.dirty = true;
		
	}
	
	
	public static function resizeBuffer (image:Image, newWidth:Int, newHeight:Int):Void {
		
		var buffer = image.buffer;
		var data = image.data;
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
		
		data[offset] = (color & 0x00FF0000) >>> 16;
		data[offset + 1] = (color & 0x0000FF00) >>> 8;
		data[offset + 2] = (color & 0x000000FF);
		
		if (image.transparent) {
			
			data[offset + 3] = (color & 0xFF000000) >>> 24;
			
		} else {
			
			data[offset + 3] = (0xFF);
			
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
		
		if (__clamp == null) {
			
			__clamp = new Vector<Int> (0xFF + 0xFF);
			
			for (i in 0...0xFF) {
				
				__clamp[i] = i;
				
			}
			
			for (i in 255...(0xFF + 0xFF + 1)) {
				
				__clamp[i] = 255;
				
			}
			
		}
		
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