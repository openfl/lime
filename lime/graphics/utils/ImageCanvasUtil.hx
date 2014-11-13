package lime.graphics.utils;


import haxe.format.JsonParser;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import lime.math.Vector2;
import lime.utils.ByteArray;
import lime.utils.UInt8Array;

#if (js && html5)
import js.Browser;
#end

@:access(lime.graphics.ImageBuffer)


class ImageCanvasUtil {
	
	
	public static function colorTransform (image:Image, rect:Rectangle, colorMatrix:ColorMatrix):Void {
		
		convertToCanvas (image);
		createImageData (image);
		
		ImageDataUtil.colorTransform (image, rect, colorMatrix);
		
	}
	
	
	public static function convertToCanvas (image:Image):Void {
		
		var buffer = image.buffer;
		
		if (buffer.__srcImage != null) {
			
			if (buffer.__srcCanvas == null) {
				
				createCanvas (image, buffer.__srcImage.width, buffer.__srcImage.height);
				buffer.__srcContext.drawImage (buffer.__srcImage, 0, 0);
				
			}
			
			buffer.__srcImage = null;
			
		}
		
	}
	
	
	public static function convertToData (image:Image):Void {
		
		#if (js && html5)
		if (image.buffer.data == null) {
			
			convertToCanvas (image);
			createImageData (image);
			
			image.buffer.__srcCanvas = null;
			image.buffer.__srcContext = null;
			
		}
		#end
		
	}
	
	
	public static function copyChannel (image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, sourceChannel:ImageChannel, destChannel:ImageChannel):Void {
		
		convertToCanvas (sourceImage);
		createImageData (sourceImage);
		convertToCanvas (image);
		createImageData (image);
		
		ImageDataUtil.copyChannel (image, sourceImage, sourceRect, destPoint, sourceChannel, destChannel);
		
	}
	
	
	public static function copyPixels (image:Image, sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, alphaImage:Image = null, alphaPoint:Vector2 = null, mergeAlpha:Bool = false):Void {
		
		if (alphaImage != null && alphaImage.transparent) {
			
			if (alphaPoint == null) alphaPoint = new Vector2 ();
			
			// TODO: use faster method
			
			var tempData = image.clone ();
			tempData.copyChannel (alphaImage, new Rectangle (alphaPoint.x, alphaPoint.y, sourceRect.width, sourceRect.height), new Vector2 (sourceRect.x, sourceRect.y), ImageChannel.ALPHA, ImageChannel.ALPHA);
			sourceImage = tempData;
			
		}
		
		sync (image);
		
		if (!mergeAlpha) {
			
			if (image.transparent && sourceImage.transparent) {
				
				image.buffer.__srcContext.clearRect (destPoint.x + image.offsetX, destPoint.y + image.offsetY, sourceRect.width + image.offsetX, sourceRect.height + image.offsetY);
				
			}
			
		}
		
		sync (sourceImage);
		
		if (sourceImage.buffer.src != null) {
			
			image.buffer.__srcContext.drawImage (sourceImage.buffer.src, Std.int (sourceRect.x + sourceImage.offsetX), Std.int (sourceRect.y + sourceImage.offsetY), Std.int (sourceRect.width), Std.int (sourceRect.height), Std.int (destPoint.x + image.offsetX), Std.int (destPoint.y + image.offsetY), Std.int (sourceRect.width), Std.int (sourceRect.height));
			
		}
		
	}
	
	
	public static function createCanvas (image:Image, width:Int, height:Int):Void {
		
		#if (js && html5)
		var buffer = image.buffer;
		
		if (buffer.__srcCanvas == null) {
			
			buffer.__srcCanvas = cast Browser.document.createElement ("canvas");
			buffer.__srcCanvas.width = width;
			buffer.__srcCanvas.height = height;
			
			if (!image.transparent) {
				
				if (!image.transparent) buffer.__srcCanvas.setAttribute ("moz-opaque", "true");
				buffer.__srcContext = untyped __js__ ('buffer.__srcCanvas.getContext ("2d", { alpha: false })');
				
			} else {
				
				buffer.__srcContext = buffer.__srcCanvas.getContext ("2d");
				
			}
			
			untyped (buffer.__srcContext).mozImageSmoothingEnabled = false;
			untyped (buffer.__srcContext).webkitImageSmoothingEnabled = false;
			buffer.__srcContext.imageSmoothingEnabled = false;
			
		}
		#end
		
	}
	
	
	public static function createImageData (image:Image):Void {
		
		var buffer = image.buffer;
		
		if (buffer.data == null) {
			
			buffer.__srcImageData = buffer.__srcContext.getImageData (0, 0, buffer.width, buffer.height);
			
			// TODO: Better solution?
			
			if (image.type == CANVAS) {
				
				buffer.data = cast buffer.__srcImageData.data;
				
			} else {
				
				buffer.data = new UInt8Array (buffer.__srcImageData.data);
				
			}
			
		}
		
	}
	
	
	public static function fillRect (image:Image, rect:Rectangle, color:Int):Void {
		
		convertToCanvas (image);
		sync (image);
		
		if (rect.x == 0 && rect.y == 0 && rect.width == image.width && rect.height == image.height) {
			
			if (image.transparent && ((color & 0xFF000000) == 0)) {
				
				image.buffer.__srcCanvas.width = image.buffer.width;
				return;
				
			}
			
		}
		
		var a = (image.transparent) ? ((color & 0xFF000000) >>> 24) : 0xFF;
		var r = (color & 0x00FF0000) >>> 16;
		var g = (color & 0x0000FF00) >>> 8;
		var b = (color & 0x000000FF);
		
		image.buffer.__srcContext.fillStyle = 'rgba(' + r + ', ' + g + ', ' + b + ', ' + (a / 255) + ')';
		image.buffer.__srcContext.fillRect (rect.x + image.offsetX, rect.y + image.offsetY, rect.width + image.offsetX, rect.height + image.offsetY);
		
	}
	
	
	public static function floodFill (image:Image, x:Int, y:Int, color:Int):Void {
		
		convertToCanvas (image);
		createImageData (image);
		
		ImageDataUtil.floodFill (image, x, y, color);
		
	}
	
	
	public static function getPixel (image:Image, x:Int, y:Int):Int {
		
		convertToCanvas (image);
		createImageData (image);
		
		return ImageDataUtil.getPixel (image, x, y);
		
	}
	
	
	public static function getPixel32 (image:Image, x:Int, y:Int):Int {
		
		convertToCanvas (image);
		createImageData (image);
		
		return ImageDataUtil.getPixel32 (image, x, y);
		
	}
	
	
	public static function getPixels (image:Image, rect:Rectangle):ByteArray {
		
		convertToCanvas (image);
		createImageData (image);
		
		return ImageDataUtil.getPixels (image, rect);
		
	}
	
	
	public static function resize (image:Image, newWidth:Int, newHeight:Int):Void {
		
		var buffer = image.buffer;
		
		if (buffer.__srcCanvas == null) {
			
			createCanvas (image, newWidth, newHeight);
			buffer.__srcContext.drawImage (buffer.src, 0, 0, newWidth, newHeight);
			
		} else {
			
			var sourceCanvas = buffer.__srcCanvas;
			buffer.__srcCanvas = null;
			createCanvas (image, newWidth, newHeight);
			buffer.__srcContext.drawImage (sourceCanvas, 0, 0, newWidth, newHeight);
			
		}
		
	}
	
	
	public static function setPixel (image:Image, x:Int, y:Int, color:Int):Void {
		
		convertToCanvas (image);
		createImageData (image);
		
		ImageDataUtil.setPixel (image, x, y, color);
		
	}
	
	
	public static function setPixel32 (image:Image, x:Int, y:Int, color:Int):Void {
		
		convertToCanvas (image);
		createImageData (image);
		
		ImageDataUtil.setPixel32 (image, x, y, color);
		
	}
	
	
	public static function setPixels (image:Image, rect:Rectangle, byteArray:ByteArray):Void {
		
		convertToCanvas (image);
		createImageData (image);
		
		ImageDataUtil.setPixels (image, rect, byteArray);
		
	}
	
	
	public static function sync (image:Image):Void {
		
		#if (js && html5)
		if (image.dirty && image.type != DATA) {
			
			image.buffer.__srcContext.putImageData (image.buffer.__srcImageData, 0, 0);
			image.buffer.data = null;
			image.dirty = false;
			
		}
		#end
		
	}
	
	
}