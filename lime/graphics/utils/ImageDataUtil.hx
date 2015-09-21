package lime.graphics.utils;


import haxe.ds.Vector;
import haxe.Int32;
import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.PixelFormat;
import lime.math.color.ARGB;
import lime.math.color.BGRA;
import lime.math.color.RGBA;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.system.CFFI;
import lime.utils.ByteArray;
import lime.utils.UInt8Array;

#if !macro
@:build(lime.system.CFFI.build())
#end

@:access(lime.math.color.RGBA)


class ImageDataUtil {
	
	
	public static function colorTransform (image:Image, rect:Rectangle, colorMatrix:ColorMatrix):Void {
		
		var data = image.buffer.data;
		if (data == null) return;
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_color_transform (image, rect, colorMatrix); else
		#end
		{
			
			var format = image.buffer.format;
			var premultiplied = image.buffer.premultiplied;
			
			var dataView = new ImageDataView (image, rect);
			
			var alphaTable = colorMatrix.getAlphaTable ();
			var redTable = colorMatrix.getRedTable ();
			var greenTable = colorMatrix.getGreenTable ();
			var blueTable = colorMatrix.getBlueTable ();
			
			var row, offset, pixel:RGBA;
			
			for (y in 0...dataView.height) {
				
				row = dataView.row (y);
				
				for (x in 0...dataView.width) {
					
					offset = row + (x * 4);
					
					pixel.readUInt8 (data, offset, format, premultiplied);
					pixel.set (redTable[pixel.r], greenTable[pixel.g], blueTable[pixel.b], alphaTable[pixel.a]);
					pixel.writeUInt8 (data, offset, format, premultiplied);
					
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
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_copy_channel (image, sourceImage, sourceRect, destPoint, srcIdx, destIdx); else
		#end
		{
			
			var srcView = new ImageDataView (sourceImage, sourceRect);
			var destView = new ImageDataView (image, new Rectangle (destPoint.x, destPoint.y, srcView.width, srcView.height));
			
			var srcFormat = sourceImage.buffer.format;
			var destFormat = image.buffer.format;
			var srcPremultiplied = sourceImage.buffer.premultiplied;
			var destPremultiplied = image.buffer.premultiplied;
			
			var srcPosition, destPosition, srcPixel:RGBA, destPixel:RGBA, value = 0;
			
			for (y in 0...destView.height) {
				
				srcPosition = srcView.row (y);
				destPosition = destView.row (y);
				
				for (x in 0...destView.width) {
					
					srcPixel.readUInt8 (srcData, srcPosition, srcFormat, srcPremultiplied);
					destPixel.readUInt8 (destData, destPosition, destFormat, destPremultiplied);
					
					switch (srcIdx) {
						
						case 0: value = srcPixel.r;
						case 1: value = srcPixel.g;
						case 2: value = srcPixel.b;
						case 3: value = srcPixel.a;
						
					}
					
					switch (destIdx) {
						
						case 0: destPixel.r = value;
						case 1: destPixel.g = value;
						case 2: destPixel.b = value;
						case 3: destPixel.a = value;
						
					}
					
					destPixel.writeUInt8 (destData, destPosition, destFormat, destPremultiplied);
					
					srcPosition += 4;
					destPosition += 4;
					
				}
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function copyPixels (image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, alphaImage:Image = null, alphaPoint:Vector2 = null, mergeAlpha:Bool = false):Void {
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_copy_pixels (image, sourceImage, sourceRect, destPoint, alphaImage, alphaPoint, mergeAlpha); else
		#end
		{
			
			var sourceData = sourceImage.buffer.data;
			var destData = image.buffer.data;
			
			if (sourceData == null || destData == null) return;
			
			var sourceView = new ImageDataView (sourceImage, sourceRect);
			var destView = new ImageDataView (image, new Rectangle (destPoint.x, destPoint.y, sourceView.width, sourceView.height));
			
			var sourceFormat = sourceImage.buffer.format;
			var destFormat = image.buffer.format;
			var sourcePremultiplied = sourceImage.buffer.premultiplied;
			var destPremultiplied = image.buffer.premultiplied;
			
			var sourcePosition, destPosition, sourcePixel:RGBA;
			
			if (!mergeAlpha || !sourceImage.transparent) {
				
				for (y in 0...destView.height) {
					
					sourcePosition = sourceView.row (y);
					destPosition = destView.row (y);
					
					for (x in 0...destView.width) {
						
						sourcePixel.readUInt8 (sourceData, sourcePosition, sourceFormat, sourcePremultiplied);
						sourcePixel.writeUInt8 (destData, destPosition, destFormat, destPremultiplied);
						
						sourcePosition += 4;
						destPosition += 4;
						
					}
					
				}
				
			} else {
				
				var sourceAlpha, destAlpha, oneMinusSourceAlpha, blendAlpha;
				var destPixel:RGBA;
				
				if (alphaImage == null) {
					
					for (y in 0...destView.height) {
						
						sourcePosition = sourceView.row (y);
						destPosition = destView.row (y);
						
						for (x in 0...destView.width) {
							
							sourcePixel.readUInt8 (sourceData, sourcePosition, sourceFormat, sourcePremultiplied);
							destPixel.readUInt8 (destData, destPosition, destFormat, destPremultiplied);
							
							sourceAlpha = sourcePixel.a / 255.0;
							destAlpha = destPixel.a / 255.0;
							oneMinusSourceAlpha = 1 - sourceAlpha;
							blendAlpha = sourceAlpha + (destAlpha * oneMinusSourceAlpha);
							
							if (blendAlpha == 0) {
								
								destPixel = 0;
								
							} else {
								
								destPixel.r = RGBA.__clamp[Math.round ((sourcePixel.r * sourceAlpha + destPixel.r * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.g = RGBA.__clamp[Math.round ((sourcePixel.g * sourceAlpha + destPixel.g * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.b = RGBA.__clamp[Math.round ((sourcePixel.b * sourceAlpha + destPixel.b * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.a = RGBA.__clamp[Math.round (blendAlpha * 255.0)];
								
							}
							
							destPixel.writeUInt8 (destData, destPosition, destFormat, destPremultiplied);
							
							sourcePosition += 4;
							destPosition += 4;
							
						}
						
					}
					
				} else {
					
					if (alphaPoint == null) alphaPoint = new Vector2 ();
					
					var alphaData = alphaImage.buffer.data;
					var alphaFormat = alphaImage.buffer.format;
					var alphaPremultiplied = alphaImage.buffer.premultiplied;
					
					var alphaView = new ImageDataView (alphaImage, new Rectangle (alphaPoint.x, alphaPoint.y, destView.width, destView.height));
					var alphaPosition, alphaPixel:RGBA;
					
					for (y in 0...alphaView.height) {
						
						sourcePosition = sourceView.row (y);
						destPosition = destView.row (y);
						alphaPosition = alphaView.row (y);
						
						for (x in 0...alphaView.width) {
							
							sourcePixel.readUInt8 (sourceData, sourcePosition, sourceFormat, sourcePremultiplied);
							destPixel.readUInt8 (destData, destPosition, destFormat, destPremultiplied);
							alphaPixel.readUInt8 (alphaData, alphaPosition, alphaFormat, alphaPremultiplied);
							
							sourceAlpha = alphaPixel.a / 0xFF;
							destAlpha = destPixel.a / 0xFF;
							oneMinusSourceAlpha = 1 - sourceAlpha;
							blendAlpha = sourceAlpha + (destAlpha * oneMinusSourceAlpha);
							
							if (blendAlpha == 0) {
								
								destPixel = 0;
								
							} else {
								
								destPixel.r = RGBA.__clamp[Math.round ((sourcePixel.r * sourceAlpha + destPixel.r * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.g = RGBA.__clamp[Math.round ((sourcePixel.g * sourceAlpha + destPixel.g * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.b = RGBA.__clamp[Math.round ((sourcePixel.b * sourceAlpha + destPixel.b * destAlpha * oneMinusSourceAlpha) / blendAlpha)];
								destPixel.a = RGBA.__clamp[Math.round (blendAlpha * 255.0)];
								
							}
							
							destPixel.writeUInt8 (destData, destPosition, destFormat, destPremultiplied);
							
							sourcePosition += 4;
							destPosition += 4;
							
						}
						
					}
					
				}
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function fillRect (image:Image, rect:Rectangle, color:Int, format:PixelFormat):Void {
		
		var fillColor:RGBA;
		
		switch (format) {
			
			case ARGB32: fillColor = (color:ARGB);
			case BGRA32: fillColor = (color:BGRA);
			default: fillColor = color;
			
		}
		
		if (!image.transparent) {
			
			fillColor.a = 0xFF;
			
		}
		
		var data = image.buffer.data;
		if (data == null) return;
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_fill_rect (image, rect, (fillColor >> 16) & 0xFFFF, (fillColor) & 0xFFFF); else // TODO: Better Int32 solution
		#end
		{
			
			var format = image.buffer.format;
			var premultiplied = image.buffer.premultiplied;
			
			var dataView = new ImageDataView (image, rect);
			var row;
			
			for (y in 0...dataView.height) {
				
				row = dataView.row (y);
				
				for (x in 0...dataView.width) {
					
					fillColor.writeUInt8 (data, row + (x * 4), format, premultiplied);
					
				}
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function floodFill (image:Image, x:Int, y:Int, color:Int, format:PixelFormat):Void {
		
		var data = image.buffer.data;
		if (data == null) return;
		
		if (format == ARGB32) color = ((color & 0xFFFFFF) << 8) | ((color >> 24) & 0xFF);
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_flood_fill (image, x, y, (color >> 16) & 0xFFFF, (color) & 0xFFFF); else // TODO: Better Int32 solution
		#end
		{
			
			var format = image.buffer.format;
			var premultiplied = image.buffer.premultiplied;
			
			var fillColor:RGBA = color;
			
			var hitColor:RGBA;
			hitColor.readUInt8 (data, ((y + image.offsetY) * (image.buffer.width * 4)) + ((x + image.offsetX) * 4), format, premultiplied);
			
			if (!image.transparent) {
				
				fillColor.a = 0xFF;
				hitColor.a = 0xFF;
				
			}
			
			if (fillColor == hitColor) return;
			
			var dx = [ 0, -1, 1, 0 ];
			var dy = [ -1, 0, 0, 1 ];
			
			var minX = -image.offsetX;
			var minY = -image.offsetY;
			var maxX = minX + image.width;
			var maxY = minY + image.height;
			
			var queue = new Array<Int> ();
			queue.push (x);
			queue.push (y);
			
			var curPointX, curPointY, nextPointX, nextPointY, nextPointOffset, readColor:RGBA;
			
			while (queue.length > 0) {
				
				curPointY = queue.pop ();
				curPointX = queue.pop ();
				
				for (i in 0...4) {
					
					nextPointX = curPointX + dx[i];
					nextPointY = curPointY + dy[i];
					
					if (nextPointX < minX || nextPointY < minY || nextPointX >= maxX || nextPointY >= maxY) {
						
						continue;
						
					}
					
					nextPointOffset = (nextPointY * image.width + nextPointX) * 4;
					readColor.readUInt8 (data, nextPointOffset, format, premultiplied);
					
					if (readColor == hitColor) {
						
						fillColor.writeUInt8 (data, nextPointOffset, format, premultiplied);
						
						queue.push (nextPointX);
						queue.push (nextPointY);
						
					}
					
				}
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function getColorBoundsRect (image:Image, mask:Int, color:Int, findColor:Bool = true, format:PixelFormat):Rectangle {
		
		var left = image.width + 1;
		var right = 0;
		var top = image.height + 1;
		var bottom = 0;
		
		var _color:RGBA, _mask:RGBA;
		
		switch (format) {
			
			case ARGB32:
				
				_color = (color:ARGB);
				_mask = (mask:ARGB);
			
			case BGRA32:
				
				_color = (color:BGRA);
				_mask = (mask:BGRA);
			
			default:
				
				_color = color;
				_mask = mask;
			
		}
		
		if (!image.transparent) {
			
			_color.a = 0xFF;
			_mask.a = 0xFF;
			
		}
		
		var pixel, hit;
		
		for (x in 0...image.width) {
			
			hit = false;
			
			for (y in 0...image.height) {
				
				pixel = image.getPixel32 (x, y, RGBA32);
				hit = findColor ? (pixel & _mask) == _color : (pixel & _mask) != _color;
				
				if (hit) {
					
					if (x < left) left = x;
					break;
					
				}
				
			}
			
			if (hit) {
				
				break;
				
			}
			
		}
		
		var ix;
		
		for (x in 0...image.width) {
			
			ix = (image.width - 1) - x;
			hit = false;
			
			for (y in 0...image.height) {
				
				pixel = image.getPixel32 (ix, y, RGBA32);
				hit = findColor ? (pixel & _mask) == _color : (pixel & _mask) != _color;
				
				if (hit) {
					
					if (ix > right) right = ix;
					break;
					
				}
				
			}
			
			if (hit) {
				
				break;
				
			}
			
		}
		
		for (y in 0...image.height) {
			
			hit = false;
			
			for (x in 0...image.width) {
				
				pixel = image.getPixel32 (x, y, RGBA32);
				hit = findColor ? (pixel & _mask) == _color : (pixel & _mask) != _color;
				
				if (hit) {
					
					if (y < top) top = y;
					break;
					
				}
				
			}
			
			if (hit) {
				
				break;
				
			}
			
		}
		
		var iy;
		
		for (y in 0...image.height) {
			
			iy = (image.height - 1) - y;
			hit = false;
			
			for (x in 0...image.width) {
				
				pixel = image.getPixel32 (x, iy, RGBA32);
				hit = findColor ? (pixel & _mask) == _color : (pixel & _mask) != _color;
				
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
		
		var pixel:RGBA;
		
		pixel.readUInt8 (image.buffer.data, (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4), image.buffer.format, image.buffer.premultiplied);
		pixel.a = 0;
		
		switch (format) {
			
			case ARGB32: return (pixel:ARGB);
			case BGRA32: return (pixel:BGRA);
			default: return pixel;
			
		}
		
	}
	
	
	public static function getPixel32 (image:Image, x:Int, y:Int, format:PixelFormat):Int {
		
		var pixel:RGBA;
		
		pixel.readUInt8 (image.buffer.data, (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4), image.buffer.format, image.buffer.premultiplied);
		
		switch (format) {
			
			case ARGB32: return (pixel:ARGB);
			case BGRA32: return (pixel:BGRA);
			default: return pixel;
			
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
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_get_pixels (image, rect, format, byteArray); else
		#end
		{
			
			var data = image.buffer.data;
			var sourceFormat = image.buffer.format;
			var premultiplied = image.buffer.premultiplied;
			
			var dataView = new ImageDataView (image, rect);
			var position, argb:ARGB, bgra:BGRA, pixel:RGBA;
			
			#if !flash
			var destPosition = 0;
			#end
			
			for (y in 0...dataView.height) {
				
				position = dataView.row (y);
				
				for (x in 0...dataView.width) {
					
					pixel.readUInt8 (data, position, sourceFormat, premultiplied);
					
					switch (format) {
						
						case ARGB32: argb = pixel; pixel = cast argb;
						case BGRA32: bgra = pixel; pixel = cast bgra;
						default:
						
					}
					
					#if flash
					byteArray.writeByte (pixel.r);
					byteArray.writeByte (pixel.g);
					byteArray.writeByte (pixel.b);
					byteArray.writeByte (pixel.a);
					#else
					byteArray.__set (destPosition++, pixel.r);
					byteArray.__set (destPosition++, pixel.g);
					byteArray.__set (destPosition++, pixel.b);
					byteArray.__set (destPosition++, pixel.a);
					#end
					
					position += 4;
					
				}
				
			}
			
		}
		
		byteArray.position = 0;
		return byteArray;
		
	}
	
	
	public static function merge (image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, redMultiplier:Int, greenMultiplier:Int, blueMultiplier:Int, alphaMultiplier:Int):Void {
		
		if (image.buffer.data == null || sourceImage.buffer.data == null) return;
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_merge (image, sourceImage, sourceRect, destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier); else
		#end
		{
			
			var sourceView = new ImageDataView (sourceImage, sourceRect);
			var destView = new ImageDataView (image, new Rectangle (destPoint.x, destPoint.y, sourceView.width, sourceView.height));
			
			var sourceData = sourceImage.buffer.data;
			var destData = image.buffer.data;
			var sourceFormat = sourceImage.buffer.format;
			var destFormat = image.buffer.format;
			var sourcePremultiplied = sourceImage.buffer.premultiplied;
			var destPremultiplied = image.buffer.premultiplied;
			
			var sourcePosition, destPosition, sourcePixel:RGBA, destPixel:RGBA;
			
			for (y in 0...destView.height) {
				
				sourcePosition = sourceView.row (y);
				destPosition = destView.row (y);
				
				for (x in 0...destView.width) {
					
					sourcePixel.readUInt8 (sourceData, sourcePosition, sourceFormat, sourcePremultiplied);
					destPixel.readUInt8 (destData, destPosition, destFormat, destPremultiplied);
					
					destPixel.r = Std.int (((sourcePixel.r * redMultiplier) + (destPixel.r * (256 - redMultiplier))) / 256);
					destPixel.g = Std.int (((sourcePixel.g * greenMultiplier) + (destPixel.g * (256 - greenMultiplier))) / 256);
					destPixel.b = Std.int (((sourcePixel.b * blueMultiplier) + (destPixel.b * (256 - blueMultiplier))) / 256);
					destPixel.a = Std.int (((sourcePixel.a * alphaMultiplier) + (destPixel.a * (256 - alphaMultiplier))) / 256);
					
					destPixel.writeUInt8 (destData, destPosition, destFormat, destPremultiplied);
					
					sourcePosition += 4;
					destPosition += 4;
					
				}
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function multiplyAlpha (image:Image):Void {
		
		var data = image.buffer.data;
		if (data == null || !image.buffer.transparent) return;
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_multiply_alpha (image); else
		#end
		{
			
			var format = image.buffer.format;
			var length = Std.int (data.length / 4);
			var pixel:RGBA;
			
			for (i in 0...length) {
				
				pixel.readUInt8 (data, i * 4, format, false);
				pixel.writeUInt8 (data, i * 4, format, true);
				
			}
			
		}
		
		image.buffer.premultiplied = true;
		image.dirty = true;
		
	}
	
	
	public static function resize (image:Image, newWidth:Int, newHeight:Int):Void {
		
		var buffer = image.buffer;
		if (buffer.width == newWidth && buffer.height == newHeight) return;
		var newBuffer = new ImageBuffer (new UInt8Array (newWidth * newHeight * 4), newWidth, newHeight);
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_resize (image, newBuffer, newWidth, newHeight); else
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
					
					// TODO: Handle more color formats
					
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
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_set_format (image, format); else
		#end
		{
			
			var index, a16;
			var length = Std.int (data.length / 4);
			var r1, g1, b1, a1, r2, g2, b2, a2;
			var r, g, b, a;
			
			switch (image.format) {
				
				case RGBA32:
					
					r1 = 0;
					g1 = 1;
					b1 = 2;
					a1 = 3;
				
				case ARGB32:
					
					r1 = 1;
					g1 = 2;
					b1 = 3;
					a1 = 0;
				
				case BGRA32:
					
					r1 = 2;
					g1 = 1;
					b1 = 0;
					a1 = 3;
				
			}
			
			switch (format) {
				
				case RGBA32:
					
					r2 = 0;
					g2 = 1;
					b2 = 2;
					a2 = 3;
				
				case ARGB32:
					
					r2 = 1;
					g2 = 2;
					b2 = 3;
					a2 = 0;
				
				case BGRA32:
					
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
		
		var pixel:RGBA;
		
		switch (format) {
			
			case ARGB32: pixel = (color:ARGB);
			case BGRA32: pixel = (color:BGRA);
			default: pixel = color;
			
		}
		
		// TODO: Write only RGB instead?
		
		var source = new RGBA ();
		source.readUInt8 (image.buffer.data, (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4), image.buffer.format, image.buffer.premultiplied);
		
		pixel.a = source.a;
		pixel.writeUInt8 (image.buffer.data, (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4), image.buffer.format, image.buffer.premultiplied);
		
		image.dirty = true;
		
	}
	
	
	public static function setPixel32 (image:Image, x:Int, y:Int, color:Int, format:PixelFormat):Void {
		
		var pixel:RGBA;
		
		switch (format) {
			
			case ARGB32: pixel = (color:ARGB);
			case BGRA32: pixel = (color:BGRA);
			default: pixel = color;
			
		}
		
		if (!image.transparent) pixel.a = 0xFF;
		pixel.writeUInt8 (image.buffer.data, (4 * (y + image.offsetY) * image.buffer.width + (x + image.offsetX) * 4), image.buffer.format, image.buffer.premultiplied);
		
		image.dirty = true;
		
	}
	
	
	public static function setPixels (image:Image, rect:Rectangle, byteArray:ByteArray, format:PixelFormat):Void {
		
		if (image.buffer.data == null) return;
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_set_pixels (image, rect, byteArray, format); else
		#end
		{
			
			var data = image.buffer.data;
			var sourceFormat = image.buffer.format;
			var premultiplied = image.buffer.premultiplied;
			var dataView = new ImageDataView (image, rect);
			var row, color, pixel:RGBA;
			var transparent = image.transparent;
			
			for (y in 0...dataView.height) {
				
				row = dataView.row (y);
				
				for (x in 0...dataView.width) {
					
					color = byteArray.readUnsignedInt ();
					
					switch (format) {
						
						case ARGB32: pixel = (color:ARGB);
						case BGRA32: pixel = (color:BGRA);
						default: pixel = color;
						
					}
					
					if (!transparent) pixel.a = 0xFF;
					pixel.writeUInt8 (data, row + (x * 4), sourceFormat, premultiplied);
					
				}
				
			}
			
		}
		
		image.dirty = true;
		
	}
	
	
	public static function unmultiplyAlpha (image:Image):Void {
		
		var data = image.buffer.data;
		if (data == null) return;
		
		#if ((cpp || neko) && !disable_cffi && !macro)
		if (CFFI.enabled) lime_image_data_util_unmultiply_alpha (image); else
		#end
		{
			
			var format = image.buffer.format;
			var length = Std.int (data.length / 4);
			var pixel:RGBA;
			
			for (i in 0...length) {
				
				pixel.readUInt8 (data, i * 4, format, true);
				pixel.writeUInt8 (data, i * 4, format, false);
				
			}
			
		}
		
		image.buffer.premultiplied = false;
		image.dirty = true;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if ((cpp || neko || nodejs) && !macro)
	@:cffi private static function lime_image_data_util_color_transform (image:Dynamic, rect:Dynamic, colorMatrix:Dynamic):Void;
	@:cffi private static function lime_image_data_util_copy_channel (image:Dynamic, sourceImage:Dynamic, sourceRect:Dynamic, destPoint:Dynamic, srcChannel:Int, destChannel:Int):Void;
	@:cffi private static function lime_image_data_util_copy_pixels (image:Dynamic, sourceImage:Dynamic, sourceRect:Dynamic, destPoint:Dynamic, alphaImage:Dynamic, alphaPoint:Dynamic, mergeAlpha:Bool):Void;
	@:cffi private static function lime_image_data_util_fill_rect (image:Dynamic, rect:Dynamic, rg:Int, ba:Int):Void;
	@:cffi private static function lime_image_data_util_flood_fill (image:Dynamic, x:Int, y:Int, rg:Int, ba:Int):Void;
	@:cffi private static function lime_image_data_util_get_pixels (image:Dynamic, rect:Dynamic, format:Int, bytes:Dynamic):Void;
	@:cffi private static function lime_image_data_util_merge (image:Dynamic, sourceImage:Dynamic, sourceRect:Dynamic, destPoint:Dynamic, redMultiplier:Int, greenMultiplier:Int, blueMultiplier:Int, alphaMultiplier:Int):Void;
	@:cffi private static function lime_image_data_util_multiply_alpha (image:Dynamic):Void;
	@:cffi private static function lime_image_data_util_resize (image:Dynamic, buffer:Dynamic, width:Int, height:Int):Void;
	@:cffi private static function lime_image_data_util_set_format (image:Dynamic, format:Int):Void;
	@:cffi private static function lime_image_data_util_set_pixels (image:Dynamic, rect:Dynamic, bytes:Dynamic, format:Int):Void;
	@:cffi private static function lime_image_data_util_unmultiply_alpha (image:Dynamic):Void;
	#end
	
	
}


private class ImageDataView {
	
	
	public var x (default, null):Int;
	public var y (default, null):Int;
	public var height (default, null):Int;
	public var width (default, null):Int;
	
	private var image:Image;
	private var offset:Int;
	private var rect:Rectangle;
	private var stride:Int;
	
	
	public function new (image:Image, rect:Rectangle = null) {
		
		this.image = image;
		
		if (rect == null) {
			
			this.rect = image.rect;
			
		} else {
			
			if (rect.x < 0) rect.x = 0;
			if (rect.y < 0) rect.y = 0;
			if (rect.x + rect.width > image.width) rect.width = image.width - rect.x;
			if (rect.y + rect.height > image.height) rect.height = image.height - rect.y;
			if (rect.width < 0) rect.width = 0;
			if (rect.height < 0) rect.height = 0;
			this.rect = rect;
			
		}
		
		stride = image.buffer.stride;
		
		x = Math.ceil (this.rect.x);
		y = Math.ceil (this.rect.y);
		width = Math.floor (this.rect.width);
		height = Math.floor (this.rect.height);
		offset = (stride * (this.y + image.offsetY)) + ((this.x + image.offsetX) * 4);
		
	}
	
	
	public function clip (x:Int, y:Int, width:Int, height:Int):Void {
		
		rect.__contract (x, y, width, height);
		
		this.x = Math.ceil (rect.x);
		this.y = Math.ceil (rect.y);
		this.width = Math.floor (rect.width);
		this.height = Math.floor (rect.height);
		offset = (stride * (this.y + image.offsetY)) + ((this.x + image.offsetX) * 4);
		
	}
	
	
	public inline function row (y:Int):Int {
		
		return offset + stride * y;
		
	}
	
	
}