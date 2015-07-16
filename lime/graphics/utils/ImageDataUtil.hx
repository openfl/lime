package lime.graphics.utils;


import haxe.ds.Vector;
import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.PixelFormat;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.system.System;
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
		if (data == null) return;
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_color_transform (image, rect, colorMatrix); else
		#end
		{
			
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
		
		var srcData = sourceImage.buffer.data;
		var destData = image.buffer.data;
		
		if (srcData == null || destData == null) return;
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_copy_channel (image, sourceImage, sourceRect, destPoint, srcIdx, destIdx); else
		#end
		{
			
			var width = sourceRect.width;
			var height = sourceRect.height;
			
			if (destPoint.x + width > image.width) {
				
				width = image.width - destPoint.x;
				
			}
			
			if (sourceRect.x + width > sourceImage.width) {
				
				width = sourceImage.width - sourceRect.x;
				
			}
			
			if (destPoint.y + height > image.height) {
				
				height = image.height - destPoint.y;
				
			}
			
			if (sourceRect.y + height > sourceImage.height) {
				
				height = sourceImage.height - sourceRect.y;
				
			}
			
			if (width <= 0 || height <= 0) return;
			
			var srcStride = Std.int (sourceImage.buffer.width * 4);
			var srcPosition = Std.int (((sourceRect.x + sourceImage.offsetX) * 4) + (srcStride * (sourceRect.y + sourceImage.offsetY)) + srcIdx);
			var srcRowOffset = srcStride - Std.int (4 * width);
			var srcRowEnd = Std.int (4 * (sourceRect.x + sourceImage.offsetX + width));
			var srcData = sourceImage.buffer.data;
			
			var destStride = Std.int (image.buffer.width * 4);
			var destPosition = Std.int (((destPoint.x + image.offsetX) * 4) + (destStride * (destPoint.y + image.offsetY)) + destIdx);
			var destRowOffset = destStride - Std.int (4 * width);
			var destData = image.buffer.data;
			
			var length = Std.int (width * height);
			
			for (i in 0...length) {
				
				destData[destPosition] = srcData[srcPosition];
				
				srcPosition += 4;
				destPosition += 4;
				
				if ((srcPosition % srcStride) > srcRowEnd) {
					
					srcPosition += srcRowOffset;
					destPosition += destRowOffset;
					
				}
				
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
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_copy_pixels (image, sourceImage, sourceRect, destPoint, mergeAlpha); else
		#end
		{
			
			var rowOffset = Std.int (destPoint.y + image.offsetY - sourceRect.y - sourceImage.offsetY);
			var columnOffset = Std.int (destPoint.x + image.offsetX - sourceRect.x - sourceImage.offsetY);
			
			var sourceData = sourceImage.buffer.data;
			var sourceStride = sourceImage.buffer.width * 4;
			var sourceOffset:Int = 0;
			
			var data = image.buffer.data;
			var stride = image.buffer.width * 4;
			var offset:Int = 0;
			
			if (!mergeAlpha || !sourceImage.transparent) {
				
				//#if (!js && !flash)
				//if (sourceRect.width == image.width && sourceRect.height == image.height && image.width == sourceImage.width && image.height == sourceImage.height && sourceRect.x == 0 && sourceRect.y == 0 && destPoint.x == 0 && destPoint.y == 0) {
					//
					//image.buffer.data.buffer.blit (0, sourceImage.buffer.data.buffer, 0, Std.int (sourceRect.width * sourceRect.height) * 4);
					//return;
					//
				//}
				//#end
				
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
				var destAlpha:Float;
				var outA:Float;
				var oneMinusSourceAlpha:Float;
				
				for (row in Std.int (sourceRect.top + sourceImage.offsetY)...Std.int (sourceRect.bottom + sourceImage.offsetY)) {
					
					for (column in Std.int (sourceRect.left + sourceImage.offsetX)...Std.int (sourceRect.right + sourceImage.offsetX)) {
						
						sourceOffset = (row * sourceStride) + (column * 4);
						offset = ((row + rowOffset) * stride) + ((column + columnOffset) * 4);
						
						sourceAlpha = sourceData[sourceOffset + 3] / 255.0;
						destAlpha = data[offset + 3] / 255.0;
						oneMinusSourceAlpha = (1 - sourceAlpha);
						
						outA = sourceAlpha + destAlpha * oneMinusSourceAlpha;
						data[offset + 0] = __clamp[Math.round ((sourceData[sourceOffset + 0] * sourceAlpha + data[offset + 0] * destAlpha * oneMinusSourceAlpha) / outA)];
						data[offset + 1] = __clamp[Math.round ((sourceData[sourceOffset + 1] * sourceAlpha + data[offset + 1] * destAlpha * oneMinusSourceAlpha) / outA)];
						data[offset + 2] = __clamp[Math.round ((sourceData[sourceOffset + 2] * sourceAlpha + data[offset + 2] * destAlpha * oneMinusSourceAlpha) / outA)];
						data[offset + 3] = __clamp[Math.round (outA * 255.0)];
						
						
					}
					
				}
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function fillRect (image:Image, rect:Rectangle, color:Int, format:PixelFormat):Void {
		
		var r, g, b, a;
		
		if (format == ARGB) {
			
			a = (image.transparent) ? (color >> 24) & 0xFF : 0xFF;
			r = (color >> 16) & 0xFF;
			g = (color >> 8) & 0xFF;
			b = color & 0xFF;
			
		} else {
			
			r = (color >> 24) & 0xFF;
			g = (color >> 16) & 0xFF;
			b = (color >> 8) & 0xFF;
			a = (image.transparent) ? color & 0xFF : 0xFF;
			
		}
		
		var rgba = (r | (g << 8) | (b << 16) | (a << 24));
		
		var data = image.buffer.data;
		if (data == null) return;
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_fill_rect (image, rect, rgba); else
		#end
		{
			
			if (rect.width == image.buffer.width && rect.height == image.buffer.height && rect.x == 0 && rect.y == 0 && image.offsetX == 0 && image.offsetY == 0) {
				
				var length = image.buffer.width * image.buffer.height;
				
				var j = 0;
				for (i in 0...length) {
					
					j = i * 4;
					
					//#if js
					data[j + 0] = r;
					data[j + 1] = g;
					data[j + 2] = b;
					data[j + 3] = a;
					//#else
					//data.setUInt32 (j, rgba);
					//#end
					
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
						
						//#if js
						data[offset] = r;
						data[offset + 1] = g;
						data[offset + 2] = b;
						data[offset + 3] = a;
						//#else
						//data.setUInt32 (offset, rgba);
						//#end
						
					}
					
				}
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function floodFill (image:Image, x:Int, y:Int, color:Int, format:PixelFormat):Void {
		
		var data = image.buffer.data;
		if (data == null) return;
		
		if (format == ARGB) color = ((color & 0xFFFFFF) << 8) | ((color >> 24) & 0xFF);
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_flood_fill (image, x, y, color); else
		#end
		{
			
			var offset = (((y + image.offsetY) * (image.buffer.width * 4)) + ((x + image.offsetX) * 4));
			var hitColorR = data[offset + 0];
			var hitColorG = data[offset + 1];
			var hitColorB = data[offset + 2];
			var hitColorA = image.transparent ? data[offset + 3] : 0xFF;
			
			var r = (color >> 24) & 0xFF;
			var g = (color >> 16) & 0xFF;
			var b = (color >> 8) & 0xFF;
			var a = image.transparent ? color & 0xFF : 0xFF;
			
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
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function getColorBoundsRect (image:Image, mask:Int, color:Int, findColor:Bool = true, format:PixelFormat):Rectangle {
		
		var left:Int = image.width + 1;
		var right:Int = 0;
		var top:Int = image.height + 1;
		var bottom:Int = 0;
		
		var r, g, b, a;
		var mr, mg, mb, ma;
		
		if (format == ARGB) {
			
			a = (image.transparent) ? (color >> 24) & 0xFF : 0xFF;
			r = (color >> 16) & 0xFF;
			g = (color >> 8) & 0xFF;
			b = color & 0xFF;
			
			ma = (image.transparent) ? (mask >> 24) & 0xFF : 0xFF;
			mr = (mask >> 16) & 0xFF;
			mg = (mask >> 8) & 0xFF;
			mb = mask & 0xFF;
			
		} else {
			
			r = (color >> 24) & 0xFF;
			g = (color >> 16) & 0xFF;
			b = (color >> 8) & 0xFF;
			a = (image.transparent) ? color & 0xFF : 0xFF;
			
			mr = (mask >> 24) & 0xFF;
			mg = (mask >> 16) & 0xFF;
			mb = (mask >> 8) & 0xFF;
			ma = (image.transparent) ? mask & 0xFF : 0xFF;
			
		}
		
		color = (r | (g << 8) | (b << 16) | (a << 24));
		mask = (mr | (mg << 8) | (mb << 16) | (mask << 24));
		
		var pix:Int;
		
		for (ix in 0...image.width) {
			
			var hit = false;
			
			for (iy in 0...image.height) {
				
				pix = image.getPixel32 (ix, iy);
				hit = findColor ? (pix & mask) == color : (pix & mask) != color;
				
				if (hit) {
					
					if (ix < left) left = ix;
					break;
					
				}
				
			}
			
			if (hit) {
				
				break;
				
			}
			
		}
		
		for (_ix in 0...image.width) {
			
			var ix = (image.width - 1) - _ix;
			var hit = false;
			
			for (iy in 0...image.height) {
				
				pix = image.getPixel32 (ix, iy);
				hit = findColor ? (pix & mask) == color : (pix & mask) != color;
				
				if (hit) {
					
					if (ix > right) right = ix;
					break;
					
				}
				
			}
			
			if (hit) {
				
				break;
				
			}
			
		}
		
		for (iy in 0...image.height) {
			
			var hit = false;
			
			for (ix in 0...image.width) {
				
				pix = image.getPixel32 (ix, iy);
				hit = findColor ? (pix & mask) == color : (pix & mask) != color;
				
				if (hit) {
					
					if (iy < top) top = iy;
					break;
					
				}
				
			}
			
			if (hit) {
				
				break;
				
			}
			
		}
		
		for (_iy in 0...image.height) {
			
			var iy = (image.height - 1) - _iy;
			var hit = false;
			
			for (ix in 0...image.width) {
				
				pix = image.getPixel32 (ix, iy);
				hit = findColor ? (pix & mask) == color : (pix & mask) != color;
				
				if (hit) {
					
					if (iy > bottom) bottom = iy;
					break;
					
				}
				
			}
			
			if (hit) {
				
				break;
				
			}
			
		}
		
		var w = right - left;
		var h = bottom - top;
		
		if (w > 0) w++;
		if (h > 0) h++;
		
		if (w < 0) w = 0;
		if (h < 0) h = 0;
		
		if (left == right) w = 1;
		if (top == bottom) h = 1;
		
		if (left > image.width) left = 0;
		if (top > image.height) top = 0;
		
		return new Rectangle (left, top, w, h);
		
	}
	
	
	public static function getPixel (image:Image, x:Int, y:Int, format:PixelFormat):Int {
		
		var data = image.buffer.data;
		var offset = (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4);
		var pixel;
		
		if (image.premultiplied) {
			
			var unmultiply = 255.0 / data[offset + 3];
			pixel = __clamp[Std.int (data[offset] * unmultiply)] << 24 | __clamp[Std.int (data[offset + 1] * unmultiply)] << 16 | __clamp[Std.int (data[offset + 2] * unmultiply)] << 8;
			
		} else {
			
			pixel = (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8);
			
		}
		
		if (format == ARGB) {
			
			return pixel >> 8 & 0xFFFFFF;
			
		} else {
			
			return pixel;
			
		}
		
	}
	
	
	public static function getPixel32 (image:Image, x:Int, y:Int, format:PixelFormat):Int {
		
		var data = image.buffer.data;
		var offset = (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4);
		var a = (image.transparent ? data[offset + 3] : 0xFF);
		var r, g, b;
		
		if (image.premultiplied && a != 0) {
			
			var unmultiply = 255.0 / a;
			r = __clamp[Math.round (data[offset] * unmultiply)];
			g = __clamp[Math.round (data[offset + 1] * unmultiply)];
			b = __clamp[Math.round (data[offset + 2] * unmultiply)];
			
		} else {
			
			r = data[offset];
			g = data[offset + 1];
			b = data[offset + 2];
			
		}
		
		if (format == ARGB) {
			
			return a << 24 | r << 16 | g << 8 | b;
			
		} else {
			
			return r << 24 | g << 16 | b << 8 | a;
			
		}
		
	}
	
	
	public static function getPixels (image:Image, rect:Rectangle, format:PixelFormat):ByteArray {
		
		if (image.buffer.data == null) return null;
		
		var length = Std.int (rect.width * rect.height);
		
		#if flash
		var byteArray = new ByteArray ();
		#else
		var byteArray = new ByteArray (length * 4);
		byteArray.position = 0;
		#end
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_get_pixels (image, rect, format, byteArray); else
		#end
		{
			
			//#if (!js && !flash)
			//if (rect.width == image.width && rect.height == image.height && rect.x == 0 && rect.y == 0) {
				//
				//byteArray.blit (0, image.buffer.data.buffer, 0, length * 4);
				//return byteArray;
				//
			//}
			//#end
			
			// TODO: optimize if the rect is the same as the full buffer size
			
			var srcData = image.buffer.data;
			var srcStride = Std.int (image.buffer.width * 4);
			var srcPosition = Std.int ((rect.x * 4) + (srcStride * rect.y));
			var srcRowOffset = srcStride - Std.int (4 * rect.width);
			var srcRowEnd = Std.int (4 * (rect.x + rect.width));
			
			#if js
			byteArray.length = length * 4;
			#end
			
			if (format == ARGB) {
				
				for (i in 0...length) {
					
					#if flash
					byteArray.writeByte (srcData[srcPosition++]);
					byteArray.writeByte (srcData[srcPosition++]);
					byteArray.writeByte (srcData[srcPosition++]);
					byteArray.writeByte (srcData[srcPosition++]);
					#else
					byteArray.__set (i * 4 + 1, srcData[srcPosition++]);
					byteArray.__set (i * 4 + 2, srcData[srcPosition++]);
					byteArray.__set (i * 4 + 3, srcData[srcPosition++]);
					byteArray.__set (i * 4, srcData[srcPosition++]);
					#end
					
					if ((srcPosition % srcStride) > srcRowEnd) {
						
						srcPosition += srcRowOffset;
						
					}
					
				}
				
			} else {
				
				for (i in 0...length) {
					
					#if flash
					// TODO
					byteArray.writeByte (srcData[srcPosition++]);
					byteArray.writeByte (srcData[srcPosition++]);
					byteArray.writeByte (srcData[srcPosition++]);
					byteArray.writeByte (srcData[srcPosition++]);
					#else
					byteArray.__set (i * 4, srcData[srcPosition++]);
					byteArray.__set (i * 4 + 1, srcData[srcPosition++]);
					byteArray.__set (i * 4 + 2, srcData[srcPosition++]);
					byteArray.__set (i * 4 + 3, srcData[srcPosition++]);
					#end
					
					if ((srcPosition % srcStride) > srcRowEnd) {
						
						srcPosition += srcRowOffset;
						
					}
					
				}
				
			}
			
		}
		
		byteArray.position = 0;
		return byteArray;
		
	}
	
	
	public static function merge (image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, redMultiplier:Int, greenMultiplier:Int, blueMultiplier:Int, alphaMultiplier:Int):Void {
		
		if (image.buffer.data == null || sourceImage.buffer.data == null) return;
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_merge (image, sourceImage, sourceRect, destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier); else
		#end
		{
			
			var rowOffset = Std.int (destPoint.y + image.offsetY - sourceRect.y - sourceImage.offsetY);
			var columnOffset = Std.int (destPoint.x + image.offsetX - sourceRect.x - sourceImage.offsetY);
			
			var sourceData = sourceImage.buffer.data;
			var sourceStride = sourceImage.buffer.width * 4;
			var sourceOffset:Int = 0;
			
			var data = image.buffer.data;
			var stride = image.buffer.width * 4;
			var offset:Int = 0;
			
			for (row in Std.int (sourceRect.top + sourceImage.offsetY)...Std.int (sourceRect.bottom + sourceImage.offsetY)) {
				
				for (column in Std.int (sourceRect.left + sourceImage.offsetX)...Std.int (sourceRect.right + sourceImage.offsetX)) {
					
					sourceOffset = (row * sourceStride) + (column * 4);
					offset = ((row + rowOffset) * stride) + ((column + columnOffset) * 4);
					
					data[offset] = Std.int (((sourceData[offset] * redMultiplier) + (data[offset] * (256 - redMultiplier))) / 256);
					data[offset + 1] = Std.int (((sourceData[offset + 1] * greenMultiplier) + (data[offset + 1] * (256 - greenMultiplier))) / 256);
					data[offset + 2] = Std.int (((sourceData[offset + 2] * blueMultiplier) + (data[offset + 2] * (256 - blueMultiplier))) / 256);
					data[offset + 3] = Std.int (((sourceData[offset + 3] * alphaMultiplier) + (data[offset + 3] * (256 - alphaMultiplier))) / 256);
					
				}
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function multiplyAlpha (image:Image):Void {
		
		var data = image.buffer.data;
		if (data == null || !image.buffer.transparent) return;
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_multiply_alpha (image); else
		#end
		{
			
			var index, a16;
			var length = Std.int (data.length / 4);
			
			for (i in 0...length) {
				
				index = i * 4;
				
				a16 = __alpha16[data[index + 3]];
				data[index] = (data[index] * a16) >> 16;
				data[index + 1] = (data[index + 1] * a16) >> 16;
				data[index + 2] = (data[index + 2] * a16) >> 16;
				
			}
			
		}
		
		image.buffer.premultiplied = true;
		image.dirty = true;
		
	}
	
	
	public static function resize (image:Image, newWidth:Int, newHeight:Int):Void {
		
		var buffer = image.buffer;
		if (buffer.width == newWidth && buffer.height == newHeight) return;
		var newBuffer = new ImageBuffer (new UInt8Array (newWidth * newHeight * 4), newWidth, newHeight);
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_resize (image, newBuffer, newWidth, newHeight); else
		#end
		{
			
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
			
		}
		
		buffer.data = newBuffer.data;
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
	
	
	public static function setFormat (image:Image, format:PixelFormat):Void {
		
		var data = image.buffer.data;
		if (data == null) return;
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_set_format (image, format); else
		#end
		{
			
			var index, a16;
			var length = Std.int (data.length / 4);
			var r1, g1, b1, a1, r2, g2, b2, a2;
			var r, g, b, a;
			
			switch (image.format) {
				
				case RGBA:
					
					r1 = 0;
					g1 = 1;
					b1 = 2;
					a1 = 3;
				
				case ARGB:
					
					r1 = 1;
					g1 = 2;
					b1 = 3;
					a1 = 0;
				
				case BGRA:
					
					r1 = 2;
					g1 = 1;
					b1 = 0;
					a1 = 3;
				
			}
			
			switch (format) {
				
				case RGBA:
					
					r2 = 0;
					g2 = 1;
					b2 = 2;
					a2 = 3;
				
				case ARGB:
					
					r2 = 1;
					g2 = 2;
					b2 = 3;
					a2 = 0;
				
				case BGRA:
					
					r2 = 2;
					g2 = 1;
					b2 = 0;
					a2 = 3;
				
			}
			
			for (i in 0...length) {
				
				index = i * 4;
				
				r = data[index + r1];
				g = data[index + g1];
				b = data[index + b1];
				a = data[index + a1];
				
				data[index + r2] = r;
				data[index + g2] = g;
				data[index + b2] = b;
				data[index + a2] = a;
				
			}
			
		}
		
		image.buffer.format = format;
		image.dirty = true;
		
	}
	
	
	public static function setPixel (image:Image, x:Int, y:Int, color:Int, format:PixelFormat):Void {
		
		var data = image.buffer.data;
		var offset = (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4);
		if (format == RGBA) color = color >> 8;
		
		data[offset] = (color & 0xFF0000) >>> 16;
		data[offset + 1] = (color & 0x00FF00) >>> 8;
		data[offset + 2] = (color & 0x0000FF);
		if (image.transparent) data[offset + 3] = (0xFF);
		
		image.dirty = true;
		
	}
	
	
	public static function setPixel32 (image:Image, x:Int, y:Int, color:Int, format:PixelFormat):Void {
		
		var data = image.buffer.data;
		var offset = (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4);
		var a, r, g, b;
		
		if (format == ARGB) {
			
			a = image.transparent ? (color >> 24) & 0xFF : 0xFF;
			r = (color >> 16) & 0xFF;
			g = (color >> 8) & 0xFF;
			b = color & 0xFF;
			
		} else {
			
			r = (color >> 24) & 0xFF;
			g = (color >> 16) & 0xFF;
			b = (color >> 8) & 0xFF;
			a = image.transparent ? color & 0xFF : 0xFF;
			
		}
		
		if (image.transparent && image.premultiplied) {
			
			var a16 = __alpha16[a];
			data[offset] = (r * a16) >> 16;
			data[offset + 1] = (g * a16) >> 16;
			data[offset + 2] = (b * a16) >> 16;
			data[offset + 3] = a;
			
		} else {
			
			data[offset] = r;
			data[offset + 1] = g;
			data[offset + 2] = b;
			data[offset + 3] = a;
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function setPixels (image:Image, rect:Rectangle, byteArray:ByteArray, format:PixelFormat):Void {
		
		if (image.buffer.data == null) return;
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_set_pixels (image, rect, byteArray, format); else
		#end
		{
			
			var len = Math.round (rect.width * rect.height);
			
			//#if (!js && !flash)
			//if (rect.width == image.width && rect.height == image.height && rect.x == 0 && rect.y == 0) {
				//
				//image.buffer.data.buffer.blit (0, byteArray, 0, len * 4);
				//return;
				//
			//}
			//#end
			
			// TODO: optimize when rect is the same as the buffer size
			
			var data = image.buffer.data;
			var offset = Math.round (image.buffer.width * (rect.y + image.offsetX) + (rect.x + image.offsetY));
			var pos = offset * 4;
			var boundR = Math.round ((rect.x + rect.width + image.offsetX));
			var width = image.buffer.width;
			var color;
			
			if (format == ARGB) {
				
				for (i in 0...len) {
					
					if (((pos) % (width * 4)) >= boundR * 4) {
						
						pos += (width - boundR) * 4;
						
					}
					
					color = byteArray.readUnsignedInt ();
					
					data[pos++] = (color & 0xFF0000) >>> 16;
					data[pos++] = (color & 0x0000FF00) >>> 8;
					data[pos++] = (color & 0x000000FF);
					data[pos++] = (color & 0xFF000000) >>> 24;
					
				}
				
			} else {
				
				for (i in 0...len) {
					
					if (((pos) % (width * 4)) >= boundR * 4) {
						
						pos += (width - boundR) * 4;
						
					}
					
					color = byteArray.readUnsignedInt ();
					
					data[pos++] = (color & 0xFF000000) >>> 24;
					data[pos++] = (color & 0xFF0000) >>> 16;
					data[pos++] = (color & 0x0000FF00) >>> 8;
					data[pos++] = (color & 0x000000FF);
					
				}
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function unmultiplyAlpha (image:Image):Void {
		
		var data = image.buffer.data;
		if (data == null) return;
		
		#if ((cpp || neko) && !disable_cffi)
		if (!System.disableCFFI) lime_image_data_util_unmultiply_alpha (image); else
		#end
		{
			
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
			
		}
		
		image.buffer.premultiplied = false;
		image.dirty = true;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_image_data_util_color_transform = System.load ("lime", "lime_image_data_util_color_transform", 3);
	private static var lime_image_data_util_copy_channel = System.load ("lime", "lime_image_data_util_copy_channel", -1);
	private static var lime_image_data_util_copy_pixels = System.load ("lime", "lime_image_data_util_copy_pixels", 5);
	private static var lime_image_data_util_fill_rect = System.load ("lime", "lime_image_data_util_fill_rect", 3);
	private static var lime_image_data_util_flood_fill = System.load ("lime", "lime_image_data_util_flood_fill", 4);
	private static var lime_image_data_util_get_pixels = System.load ("lime", "lime_image_data_util_get_pixels", 4);
	private static var lime_image_data_util_merge = System.load ("lime", "lime_image_data_util_merge", -1);
	private static var lime_image_data_util_multiply_alpha = System.load ("lime", "lime_image_data_util_multiply_alpha", 1);
	private static var lime_image_data_util_resize = System.load ("lime", "lime_image_data_util_resize", 4);
	private static var lime_image_data_util_set_format = System.load ("lime", "lime_image_data_util_set_format", 2);
	private static var lime_image_data_util_set_pixels = System.load ("lime", "lime_image_data_util_set_pixels", 4);
	private static var lime_image_data_util_unmultiply_alpha = System.load ("lime", "lime_image_data_util_unmultiply_alpha", 1);
	#end
	
	
}