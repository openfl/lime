package lime.graphics;

import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import lime._internal.backend.native.NativeCFFI;
import lime._internal.format.Base64;
import lime._internal.format.BMP;
import lime._internal.format.JPEG;
import lime._internal.format.PNG;
import lime._internal.graphics.ImageCanvasUtil;
import lime._internal.graphics.ImageDataUtil;
import lime.app.Application;
import lime.app.Future;
import lime.app.Promise;
import lime.math.ARGB;
import lime.math.BGRA;
import lime.math.ColorMatrix;
import lime.math.Rectangle;
import lime.math.RGBA;
import lime.math.Vector2;
import lime.net.HTTPRequest;
import lime.system.CFFI;
import lime.system.Endian;
import lime.system.System;
import lime.utils.ArrayBuffer;
import lime.utils.BytePointer;
import lime.utils.Log;
import lime.utils.UInt8Array;
#if (js && html5)
#if !display
import lime._internal.backend.html5.HTML5HTTPRequest;
#end
import js.html.CanvasElement;
import js.html.ImageElement;
import js.html.Image as JSImage;
import js.Browser;
#elseif flash
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.geom.Matrix;
import flash.net.URLRequest;
import flash.system.LoaderContext;
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

/**
	`Image` is a convenience class for working with bitmap images in Lime.

	Although `ImageBuffer` holds the actual bitmap data, `Image` includes convenience methods for
	loading from files, loading from bytes, and performing many pixel operations over an
	`ImageBuffer` instance.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:autoBuild(lime._internal.macros.AssetsMacro.embedImage())
@:access(lime._internal.backend.native.NativeCFFI)
@:allow(lime._internal.graphics.ImageCanvasUtil)
@:allow(lime._internal.graphics.ImageDataUtil)
@:access(lime.app.Application)
@:access(lime.math.ColorMatrix)
@:access(lime.math.Rectangle)
@:access(lime.math.Vector2)
#if hl
@:keep
#end
#if (js && html5 && !display)
@:access(lime._internal.backend.html5.HTML5HTTPRequest)
#end
class Image
{
	/**
		The `ImageBuffer` store that backs the `Image`
	**/
	public var buffer:ImageBuffer;

	/**
		Retrieves `UInt8Array` data from the `ImageBuffer`. If the `ImageBuffer`
		is not in a data format, it will be converted.
	**/
	public var data(get, set):UInt8Array;

	/**
		Whether the `Image` is dirty. This is set to `true` when pixel operations
		have been performed on the underlying `buffer`, and can be set to `false`
		again by your own renderer.
	**/
	public var dirty:Bool;

	/**
		Get or set the `PixelFormat` for the underlying `ImageBuffer`. This can be
		used to convert the `ImageBuffer` to a new format.
	**/
	public var format(get, set):PixelFormat;

	/**
		The logical height of the `Image`. This can be smaller than the `height`
		of the underlying `buffer`.
	**/
	public var height:Int;

	/**
		The offset X position of the `Image`, from the source `buffer`,
		when the `Image` is smaller than the full size of the source `buffer`
	**/
	public var offsetX:Int;

	/**
		The offset Y position of the `Image`, from the source `buffer`,
		when the `Image` is smaller than the full size of the source `buffer`
	**/
	public var offsetY:Int;

	/**
		Get or set whether the `ImageBuffer` dimensions are both a power-of-two
		(such as 2, 4, 8, 16, so on). Setting this value may resize the underlying
		`buffer`
	**/
	public var powerOfTwo(get, set):Bool;

	/**
		Get or set whether this `Image` has premultiplied alpha. Setting this value
		may multiply or unmultiply data if the underlying `ImageBuffer` uses a
		different format.
	**/
	public var premultiplied(get, set):Bool;

	/**
		The offset, width and height of this image as a `Rectangle`
	**/
	public var rect(get, null):Rectangle;

	/**
		A higher-level representation of the source `ImageBuffer`. This might be an
		HTML5 Image, CanvasElement or a Flash BitmapData instance.
	**/
	public var src(get, set):Dynamic;

	/**
		Get or set whether the underlying `ImageBuffer` is transparent.
	**/
	public var transparent(get, set):Bool;

	/**
		The current `ImageType`, representing what is being used to store the `Image`'s graphics
	**/
	public var type:ImageType;

	/**
		The `version` of the `Image` increases each time it is modified, helpful to determining
		whether a cache is out-of-date.
	**/
	public var version:Int;

	/**
		The logical width of the `Image`. This can be smaller than the `width`
		of the underlying `buffer`.
	**/
	public var width:Int;

	/**
		A convenience property, unused internally, which may be helpful for different renderer
		implementations
	**/
	public var x:Float;

	/**
		A convenience property, unused internally, which may be helpful for different renderer
		implementations
	**/
	public var y:Float;

	#if commonjs
	private static function __init__()
	{
		var p = untyped Image.prototype;
		untyped Object.defineProperties(p,
			{
				"data": {get: p.get_data, set: p.set_data},
				"format": {get: p.get_format, set: p.set_format},
				"powerOfTwo": {get: p.get_powerOfTwo, set: p.set_powerOfTwo},
				"premultiplied": {get: p.get_premultiplied, set: p.set_premultiplied},
				"rect": {get: p.get_rect},
				"src": {get: p.get_src, set: p.set_src},
				"transparent": {get: p.get_transparent, set: p.set_transparent}
			});
	}
	#end

	/**
		Creates a new `Image` instance.

		If `buffer` is null, but `width` and `height` are set, a new `ImageBuffer` is allocated matching the `color` requested.
		@param	buffer	(Optional) The `ImageBuffer` this `Image` represents
		@param	offsetX	(Optional) A logical offset value within the `ImageBuffer` dimensions
		@param	offsetY	(Optional) A logical offset value within the `ImageBuffer` dimensions
		@param	width	(Optional) A logical width value within the `ImageBuffer` dimensions
		@param	height	(Optional) A logical height value within the `ImageBuffer` dimensions
		@param	color	(Optional) A fill color to use if the `buffer` property is `null`
		@param	type	(Optional) An `ImageType` to use for this `Image`
	**/
	public function new(buffer:ImageBuffer = null, offsetX:Int = 0, offsetY:Int = 0, width:Int = -1, height:Int = -1, color:Null<Int> = null,
			type:ImageType = null)
	{
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		this.width = width;
		this.height = height;

		version = 0;

		if (type == null)
		{
			#if (js && html5)
			type = CANVAS;
			#elseif flash
			type = FLASH;
			#else
			type = DATA;
			#end
		}

		this.type = type;

		if (buffer == null)
		{
			if (width > 0 && height > 0)
			{
				switch (this.type)
				{
					case CANVAS:
						this.buffer = new ImageBuffer(null, width, height);
						ImageCanvasUtil.createCanvas(this, width, height);

						if (color != null && color != 0)
						{
							fillRect(new Rectangle(0, 0, width, height), color);
						}

					case DATA:
						this.buffer = new ImageBuffer(new UInt8Array(width * height * 4), width, height);

						if (color != null && color != 0)
						{
							fillRect(new Rectangle(0, 0, width, height), color);
						}

					case FLASH:
						#if flash
						this.buffer = new ImageBuffer(null, width, height);
						this.buffer.src = new BitmapData(width, height, true, ((color & 0xFF) << 24) | (color >> 8));
						#end

					default:
				}
			}
		}
		else
		{
			__fromImageBuffer(buffer);
		}
	}

	/**
		Creates a duplicate copy of this `Image` and `ImageBuffer`
		@return	A new `Image` instance
	**/
	public function clone():Image
	{
		if (buffer != null)
		{
			#if (js && html5)
			if (type == CANVAS)
			{
				ImageCanvasUtil.convertToCanvas(this);
			}
			else
			{
				ImageCanvasUtil.convertToData(this);
			}
			#end

			var image = new Image(buffer.clone(), offsetX, offsetY, width, height, null, type);
			image.version = version;
			return image;
		}
		else
		{
			return new Image(null, offsetX, offsetY, width, height, null, type);
		}
	}

	/**
		Applies a color transform to the underlying `ImageBuffer` data
		@param	rect	The target rectangle to transform
		@param	colorMatrix	A `ColorMatrix` for color offset and/or multiplication
	**/
	public function colorTransform(rect:Rectangle, colorMatrix:ColorMatrix):Void
	{
		rect = __clipRect(rect);
		if (buffer == null || rect == null) return;

		switch (type)
		{
			case CANVAS:
				ImageCanvasUtil.colorTransform(this, rect, colorMatrix);

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				#end

				ImageDataUtil.colorTransform(this, rect, colorMatrix);

			case FLASH:
				rect.offset(offsetX, offsetY);
				buffer.__srcBitmapData.colorTransform(rect.__toFlashRectangle(), colorMatrix.__toFlashColorTransform());

			default:
		}
	}

	/**
		Copy a color channel from one `Image` to another. This can also be within the same `Image` instance.
		@param	sourceImage	The `Image` to copy from
		@param	sourceRect	The source rectangle to copy from in the `sourceImage`
		@param	destPoint	The destination point to apply the channel in the current `Image`
		@param	sourceChannel	The source color channel to copy the data from
		@param	destChannel	The destination color channel to apply the data into
	**/
	public function copyChannel(sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, sourceChannel:ImageChannel, destChannel:ImageChannel):Void
	{
		sourceRect = __clipRect(sourceRect);
		if (buffer == null || sourceRect == null) return;
		if (destChannel == ALPHA && !transparent) return;
		if (sourceRect.width <= 0 || sourceRect.height <= 0) return;
		if (sourceRect.x + sourceRect.width > sourceImage.width) sourceRect.width = sourceImage.width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceImage.height) sourceRect.height = sourceImage.height - sourceRect.y;

		switch (type)
		{
			case CANVAS:
				ImageCanvasUtil.copyChannel(this, sourceImage, sourceRect, destPoint, sourceChannel, destChannel);

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				ImageCanvasUtil.convertToData(sourceImage);
				#end

				ImageDataUtil.copyChannel(this, sourceImage, sourceRect, destPoint, sourceChannel, destChannel);

			case FLASH:
				var srcChannel = switch (sourceChannel)
				{
					case RED: 1;
					case GREEN: 2;
					case BLUE: 4;
					case ALPHA: 8;
				}

				var dstChannel = switch (destChannel)
				{
					case RED: 1;
					case GREEN: 2;
					case BLUE: 4;
					case ALPHA: 8;
				}

				sourceRect.offset(sourceImage.offsetX, sourceImage.offsetY);
				destPoint.offset(offsetX, offsetY);

				buffer.__srcBitmapData.copyChannel(sourceImage.buffer.src, sourceRect.__toFlashRectangle(), destPoint.__toFlashPoint(), srcChannel,
					dstChannel);

			default:
		}
	}

	/**
		Copies pixels from one `Image` to another. The source `Image` can also be this `Image`
		@param	sourceImage	The source `Image` to copy from
		@param	sourceRect	The source rectangle to use when copying
		@param	destPoint	The destination point to use when copying
		@param	alphaImage	(Optional) A different `Image` to use as the alpha channel while copying
		@param	alphaPoint	(Optional) A point in the alpha image to use when copying
		@param	mergeAlpha	(Optional) Whether to blend the source and destination alpha (`true`), or to replace the destination alpha (`false`)
	**/
	public function copyPixels(sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, alphaImage:Image = null, alphaPoint:Vector2 = null,
			mergeAlpha:Bool = false):Void
	{
		if (buffer == null || sourceImage == null) return;
		if (sourceRect.width <= 0 || sourceRect.height <= 0) return;
		if (width <= 0 || height <= 0) return;

		if (sourceRect.x + sourceRect.width > sourceImage.width) sourceRect.width = sourceImage.width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceImage.height) sourceRect.height = sourceImage.height - sourceRect.y;

		if (sourceRect.x < 0)
		{
			sourceRect.width += sourceRect.x;
			sourceRect.x = 0;
		}

		if (sourceRect.y < 0)
		{
			sourceRect.height += sourceRect.y;
			sourceRect.y = 0;
		}

		if (destPoint.x + sourceRect.width > width) sourceRect.width = width - destPoint.x;
		if (destPoint.y + sourceRect.height > height) sourceRect.height = height - destPoint.y;

		if (destPoint.x < 0)
		{
			sourceRect.width += destPoint.x;
			sourceRect.x -= destPoint.x;
			destPoint.x = 0;
		}

		if (destPoint.y < 0)
		{
			sourceRect.height += destPoint.y;
			sourceRect.y -= destPoint.y;
			destPoint.y = 0;
		}

		if (sourceImage == this && destPoint.x < sourceRect.right && destPoint.y < sourceRect.bottom)
		{
			// TODO: Optimize further?
			sourceImage = clone();
		}

		if (alphaImage == sourceImage && (alphaPoint == null || (alphaPoint.x == 0 && alphaPoint.y == 0)))
		{
			alphaImage = null;
			alphaPoint = null;
		}

		switch (type)
		{
			case CANVAS:
				if (alphaImage != null)
				{
					ImageCanvasUtil.convertToData(this);
					ImageCanvasUtil.convertToData(sourceImage);
					if (alphaImage != null) ImageCanvasUtil.convertToData(alphaImage);

					ImageDataUtil.copyPixels(this, sourceImage, sourceRect, destPoint, alphaImage, alphaPoint, mergeAlpha);
				}
				else
				{
					ImageCanvasUtil.convertToCanvas(this);
					ImageCanvasUtil.convertToCanvas(sourceImage);
					ImageCanvasUtil.copyPixels(this, sourceImage, sourceRect, destPoint, alphaImage, alphaPoint, mergeAlpha);
				}

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				ImageCanvasUtil.convertToData(sourceImage);
				if (alphaImage != null) ImageCanvasUtil.convertToData(alphaImage);
				#end

				ImageDataUtil.copyPixels(this, sourceImage, sourceRect, destPoint, alphaImage, alphaPoint, mergeAlpha);

			case FLASH:
				sourceRect.offset(sourceImage.offsetX, sourceImage.offsetY);
				destPoint.offset(offsetX, offsetY);

				if (alphaImage != null && alphaPoint != null)
				{
					alphaPoint.offset(alphaImage.offsetX, alphaImage.offsetY);
				}

				buffer.__srcBitmapData.copyPixels(sourceImage.buffer.__srcBitmapData, sourceRect.__toFlashRectangle(), destPoint.__toFlashPoint(),
					alphaImage != null ? alphaImage.buffer.src : null, alphaPoint != null ? alphaPoint.__toFlashPoint() : null, mergeAlpha);

			default:
		}
	}

	/**
		Encodes this `Image` into an image file format, such as PNG or JPEG.
		@param	format	(Optional) An `ImageFileFormat` to encode into (default is `PNG`)
		@param	quality	(Optional) A quality value to use when encoding as JPEG (from 0 to 100)
		@return	`Bytes` for the encoded `Image`, or `null` if encoding was not successful
	**/
	public function encode(format:ImageFileFormat = null, quality:Int = 90):Bytes
	{
		switch (format)
		{
			case null, ImageFileFormat.PNG:
				return PNG.encode(this);

			case ImageFileFormat.JPEG:
				return JPEG.encode(this, quality);

			case ImageFileFormat.BMP:
				return BMP.encode(this);

			default:
		}

		return null;
	}

	/**
		Fill a rectangle in the `Image` with a solid color
		@param	rect	A destination rectangle in this `Image` to fill
		@param	color	The color to use when filling this `Image`
		@param	format	(Optional) The `PixelFormat` that `color` is encoded in (default is `RGBA`)
	**/
	public function fillRect(rect:Rectangle, color:Int, format:PixelFormat = null):Void
	{
		rect = __clipRect(rect);
		if (buffer == null || rect == null) return;

		switch (type)
		{
			case CANVAS:
				ImageCanvasUtil.fillRect(this, rect, color, format);

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				#end

				if (buffer.data.length == 0) return;

				ImageDataUtil.fillRect(this, rect, color, format);

			case FLASH:
				rect.offset(offsetX, offsetY);

				var argb:ARGB = switch (format)
				{
					case ARGB32: color;
					case BGRA32: (color : BGRA);
					default: (color : RGBA);
				}

				buffer.__srcBitmapData.fillRect(rect.__toFlashRectangle(), argb);

			default:
		}
	}

	/**
		Applies a flood fill to this `Image`, starting with the point specified.

		A flood fill behaves similarly to the "paint can" tool in many image editors,
		the fill will apply the chosen color to neighboring pixels of the same color.
		@param	x	The target x coordinate within the `Image` to use with the fill
		@param	y	The target y coordinate within the `Image` to use with the fill
		@param	color	The color to use when performing the fill
		@param	format	(Optional) The `PixelFormat` that `color` is encoded in (default is `RGBA`)
	**/
	public function floodFill(x:Int, y:Int, color:Int, format:PixelFormat = null):Void
	{
		if (buffer == null) return;

		switch (type)
		{
			case CANVAS:
				ImageCanvasUtil.floodFill(this, x, y, color, format);

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				#end

				ImageDataUtil.floodFill(this, x, y, color, format);

			case FLASH:
				var argb:ARGB = switch (format)
				{
					case ARGB32: color;
					case BGRA32: (color : BGRA);
					default: (color : RGBA);
				}

				buffer.__srcBitmapData.floodFill(x + offsetX, y + offsetY, argb);

			default:
		}
	}

	/**
		Converts a Base64-encoded `String` into an `Image`, or returns `null` if this is not possible
		@param	base64	A Base64-encoded `String`
		@param	type	A mime-type to describe the image data (such as "image/png")
		@return	A new `Image`, or `null` if conversion was not possible
	**/
	public static function fromBase64(base64:String, type:String):Image
	{
		if (base64 == null) return null;
		var image = new Image();
		image.__fromBase64(base64, type);
		return image;
	}

	#if (!lime_doc_gen || flash)
	/**
		Creates a new `Image` from a Flash `BitmapData` instance
		@param	bitmapData	A source `bitmapData` to use
		@return		A new `Image` instance
	**/
	public static function fromBitmapData(bitmapData:#if flash BitmapData #else Dynamic #end):Image
	{
		if (bitmapData == null) return null;
		#if flash
		var buffer = new ImageBuffer(null, bitmapData.width, bitmapData.height);
		buffer.__srcBitmapData = bitmapData;
		buffer.transparent = bitmapData.transparent;
		return new Image(buffer);
		#else
		return bitmapData.image;
		#end
	}
	#end

	/**
		Converts a `Bytes` object to an `Image` instance

		Some platforms (such as Flash and HTML5) cannot convert `Bytes` to an
		`Image` synchronously, and may not work properly.

		`Image.loadFromBytes` works asynchronously, and should work
		consistently on all platforms.
		@param	bytes	A `Bytes` holding encoded image data
		@return	A new `Image` instance
	**/
	public static function fromBytes(bytes:Bytes):Image
	{
		if (bytes == null) return null;
		var image = new Image();
		if (image.__fromBytes(bytes))
		{
			return image;
		}
		else
		{
			return null;
		}
	}

	#if (!lime_doc_gen || lime_canvas)
	/**
		Converts an `js.html.CanvasElement` instance to an `Image`
		@param	canvas	A `CanvasElement`
		@return	A new `Image` instance
	**/
	public static function fromCanvas(canvas:#if (js && html5) CanvasElement #else Dynamic #end):Image
	{
		if (canvas == null) return null;
		var buffer = new ImageBuffer(null, canvas.width, canvas.height);
		buffer.src = canvas;
		var image = new Image(buffer);

		image.type = CANVAS;
		return image;
	}
	#end

	/**
		Loads an `Image` from a path synchronously.

		Some platforms, such as Flash and HTML5, cannot load
		images synchronously.

		`Image.loadFromFile` works asynchronously, and should
		behave consistently on all platforms.
		@param	path	The source file path or URL of an encoded image file
		@return	A new `Image` instance
	**/
	public static function fromFile(path:String):Image
	{
		if (path == null) return null;
		var image = new Image();
		if (image.__fromFile(path))
		{
			return image;
		}
		else
		{
			return null;
		}
	}

	#if (!lime_doc_gen || (js && html5))
	/**
		Converts a `js.html.Image` instance to an `Image`
		@param	image	An `ImageElement` instance
		@return	A new `Image` instance
	**/
	public static function fromImageElement(image:#if (js && html5) ImageElement #else Dynamic #end):Image
	{
		if (image == null) return null;
		var buffer = new ImageBuffer(null, image.width, image.height);
		buffer.src = image;
		var _image = new Image(buffer);

		_image.type = CANVAS;
		return _image;
	}
	#end

	/**
		Finds a region in the `Image` that includes pixels all of a certain color (when `findColor` is `true`) or
		excludes a certain color (`findColor` is `false`)
		@param	mask	A hexadecimal mask to use when comparing colors. You can use this to compare all of a color, or only certain color channels
		@param	color	The color value to use in comparisons
		@param	findColor	(Optional) Whether to find a region that does match the color (`true`) or excludes it (`false`)
		@param	format	(Optional) The `PixelFormat` that the `color` and `mask` are encoded in (default is `RGBA`)
		@return	The matching bounds `Rectangle`, or `null` if no matching region is found
	**/
	public function getColorBoundsRect(mask:Int, color:Int, findColor:Bool = true, format:PixelFormat = null):Rectangle
	{
		if (buffer == null) return null;

		switch (type)
		{
			case CANVAS:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				#end

				return ImageDataUtil.getColorBoundsRect(this, mask, color, findColor, format);

			case DATA:
				return ImageDataUtil.getColorBoundsRect(this, mask, color, findColor, format);

			case FLASH:
				var rect = buffer.__srcBitmapData.getColorBoundsRect(mask, color, findColor);
				return new Rectangle(rect.x, rect.y, rect.width, rect.height);

			default:
				return null;
		}
	}

	/**
		Gets a 24-bit pixel from the `Image` (red, green and blue, but no alpha)
		@param	x	The `x` location to fetch
		@param	y	The `y` location to fetch
		@param	format	(Optional) The `PixelFormat` to encode the return value in (default is `RGBA`)
		@return	The specified pixel, or `0` if it is out-of-bounds
	**/
	public function getPixel(x:Int, y:Int, format:PixelFormat = null):Int
	{
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return 0;

		switch (type)
		{
			case CANVAS:
				return ImageCanvasUtil.getPixel(this, x, y, format);

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				#end

				return ImageDataUtil.getPixel(this, x, y, format);

			case FLASH:
				var color:ARGB = buffer.__srcBitmapData.getPixel(x + offsetX, y + offsetY);

				switch (format)
				{
					case ARGB32: return color;
					case BGRA32:
						var bgra:BGRA = color;
						return bgra;
					default:
						var rgba:RGBA = color;
						return rgba;
				}

			default:
				return 0;
		}
	}

	/**
		Gets a 32-bit pixel from the `Image`, including alpha
		@param	x	The `x` location to fetch
		@param	y	The `y` location to fetch
		@param	format	(Optional) The `PixelFormat` to encode the return value in (default is `RGBA`)
		@return	The specified pixel, or `0` if it is out-of-bounds
	**/
	public function getPixel32(x:Int, y:Int, format:PixelFormat = null):Int
	{
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return 0;

		switch (type)
		{
			case CANVAS:
				return ImageCanvasUtil.getPixel32(this, x, y, format);

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				#end

				return ImageDataUtil.getPixel32(this, x, y, format);

			case FLASH:
				var color:ARGB = buffer.__srcBitmapData.getPixel32(x + offsetX, y + offsetY);

				switch (format)
				{
					case ARGB32: return color;
					case BGRA32:
						var bgra:BGRA = color;
						return bgra;
					default:
						var rgba:RGBA = color;
						return rgba;
				}

			default:
				return 0;
		}
	}

	/**
		Gets a region of pixels from the `Image`, as `Bytes`
		@param	rect	The source `Rectangle` to read from
		@param	format	(Optional) The `PixelFormat` to use when writing to the `Bytes` object (default is `RGBA`)
		@return	A `Bytes` object representing the region, or `null` if it is not possible to read
	**/
	public function getPixels(rect:Rectangle, format:PixelFormat = null):Bytes
	{
		if (buffer == null) return null;

		switch (type)
		{
			case CANVAS:
				return ImageCanvasUtil.getPixels(this, rect, format);

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				#end

				return ImageDataUtil.getPixels(this, rect, format);

			case FLASH:
				#if flash
				rect.offset(offsetX, offsetY);
				var byteArray:ByteArray = buffer.__srcBitmapData.getPixels(rect.__toFlashRectangle());

				switch (format)
				{
					case ARGB32: // do nothing
					case BGRA32:
						var color:BGRA;
						var length = Std.int(byteArray.length / 4);

						for (i in 0...length)
						{
							color = (byteArray.readUnsignedInt() : ARGB);
							byteArray.position -= 4;
							byteArray.writeUnsignedInt(color);
						}

						byteArray.position = 0;

					default:
						var color:RGBA;
						var length = Std.int(byteArray.length / 4);

						for (i in 0...length)
						{
							color = (byteArray.readUnsignedInt() : ARGB);
							byteArray.position -= 4;
							byteArray.writeUnsignedInt(color);
						}

						byteArray.position = 0;
				}

				return Bytes.ofData(byteArray);
				#else
				return null;
				#end

			default:
				return null;
		}
	}

	/**
		Creates a new `Image` instance from a Base64-encoded `String`, asynchronously
		@param	base64	A Base64-encoded string representing encoded image data
		@param	type	The mime type of the encoded data (such as "image/png")
		@return	A `Future` to return a new `Image` instance
	**/
	public static function loadFromBase64(base64:String, type:String):Future<Image>
	{
		if (base64 == null || type == null) return Future.withValue(null);

		#if (js && html5 && !display)
		return HTML5HTTPRequest.loadImage("data:" + type + ";base64," + base64);
		#else
		if (base64 != null)
		{
			return loadFromBytes(Base64.decode(base64));
		}
		else
		{
			return cast Future.withError("");
		}
		#end
	}

	/**
		Creates a new `Image` instance from image-encoded `Bytes`, loaded asynchronously
		@param	bytes	A `Bytes` instance
		@return	A `Future` to return a new `Image` instance
	**/
	public static function loadFromBytes(bytes:Bytes):Future<Image>
	{
		if (bytes == null) return Future.withValue(null);

		#if (js && html5)
		var type = "";

		if (__isPNG(bytes))
		{
			type = "image/png";
		}
		else if (__isJPG(bytes))
		{
			type = "image/jpeg";
		}
		else if (__isGIF(bytes))
		{
			type = "image/gif";
		}
		else if (__isWebP(bytes))
		{
			type = "image/webp";
		}
		else
		{
			// throw "Image tried to read PNG/JPG Bytes, but found an invalid header.";
			return Future.withValue(null);
		}
		#if !display
		return HTML5HTTPRequest.loadImageFromBytes(bytes, type);
		#else
		return loadFromBase64(Base64.encode(bytes), type);
		#end
		#elseif flash
		var promise = new Promise<Image>();

		var loader = new Loader();

		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event)
		{
			promise.complete(Image.fromBitmapData(cast(loader.content, Bitmap).bitmapData));
		});

		loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, function(event)
		{
			promise.progress(Std.int(event.bytesLoaded), Std.int(event.bytesTotal));
		});

		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(event)
		{
			promise.error(event.errorID);
		});

		loader.loadBytes(bytes.getData());

		return promise.future;
		#else
		return new Future<Image>(function() return fromBytes(bytes), true);
		#end
	}

	/**
		Creates a new `Image` instance from a file path or URL, loaded asynchronously
		@param	path	A file path or URL containing an encoded image
		@return	A `Future` to return a new `Image` instance
	**/
	public static function loadFromFile(path:String):Future<Image>
	{
		if (path == null) return Future.withValue(null);

		#if kha
		var promise = new Promise<Image>();

		function fromFileAsync(path:String, onload:Image->Void)
		{
			if (path == null) return null;
			var image = new Image();
			image.__fromFile(path, onload);
			return image;
		}

		fromFileAsync(path.substring(path.lastIndexOf('/') + 1), function(image:Image)
		{
			promise.complete(image);
		});

		return promise.future;
		#elseif (js && html5 && !display)
		return HTML5HTTPRequest.loadImage(path);
		#elseif flash
		var promise = new Promise<Image>();

		var loader = new Loader();

		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event)
		{
			promise.complete(Image.fromBitmapData(cast(loader.content, Bitmap).bitmapData));
		});

		loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, function(event)
		{
			promise.progress(Std.int(event.bytesLoaded), Std.int(event.bytesTotal));
		});

		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(event)
		{
			promise.error(event.errorID);
		});

		loader.load(new URLRequest(path), new LoaderContext(true));

		return promise.future;
		#else
		var request = new HTTPRequest<Image>();
		return request.load(path).then(function(image)
		{
			if (image != null)
			{
				return Future.withValue(image);
			}
			else
			{
				return cast Future.withError("");
			}
		});
		#end
	}

	/**
		Blits a second `Image` onto this one, using optional color multipliers
		@param	sourceImage	An `Image` instance to copy from
		@param	sourceRect	The source rectangle to use when copying
		@param	destPoint	The destination point in this `Image` to copy into
		@param	redMultiplier	A red multiplier to use when blitting
		@param	greenMultiplier	A green multiplier to use when blitting
		@param	blueMultiplier	A blue multiplier to use when blitting
		@param	alphaMultiplier	An alpha multiplier to use when blitting
	**/
	public function merge(sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, redMultiplier:Int, greenMultiplier:Int, blueMultiplier:Int,
			alphaMultiplier:Int):Void
	{
		if (buffer == null || sourceImage == null) return;

		switch (type)
		{
			case CANVAS:
				ImageCanvasUtil.convertToCanvas(this);
				ImageCanvasUtil.merge(this, sourceImage, sourceRect, destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				ImageCanvasUtil.convertToData(sourceImage);
				#end

				ImageDataUtil.merge(this, sourceImage, sourceRect, destPoint, redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier);

			case FLASH:
				sourceRect.offset(offsetX, offsetY);
				buffer.__srcBitmapData.merge(sourceImage.buffer.__srcBitmapData, sourceRect.__toFlashRectangle(), destPoint.__toFlashPoint(), redMultiplier,
					greenMultiplier, blueMultiplier, alphaMultiplier);

			default:
				return;
		}
	}

	/**
		Resizes the current `Image`, reallocating the `ImageBuffer` to a new size.
		The resize algorithm for most platforms is bilinear.
		@param	newWidth	A new width for the `Image`
		@param	newHeight	A new height for the `Image`
	**/
	public function resize(newWidth:Int, newHeight:Int):Void
	{
		switch (type)
		{
			case CANVAS:
				ImageCanvasUtil.resize(this, newWidth, newHeight);

			case DATA:
				ImageDataUtil.resize(this, newWidth, newHeight);

			case FLASH:
				#if flash
				var matrix = new Matrix();
				matrix.scale(newWidth / buffer.__srcBitmapData.width, newHeight / buffer.__srcBitmapData.height);
				var data = new BitmapData(newWidth, newHeight, true, 0x00FFFFFF);
				data.draw(buffer.__srcBitmapData, matrix, null, null, null, true);
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

	/**
		Scrolls the content of this `Image`.

		Pixels on the edges of the scroll will remain repeated, while others
		within the scroll area will be shifted

		@param	x	The amount of horizontal scroll to apply
		@param	y	The amount of vertical scroll to apply
	**/
	public function scroll(x:Int, y:Int):Void
	{
		if (buffer == null) return;

		switch (type)
		{
			case CANVAS:
				ImageCanvasUtil.scroll(this, x, y);

			case DATA:
				copyPixels(this, rect, new Vector2(x, y));

			case FLASH:
				buffer.__srcBitmapData.scroll(x + offsetX, y + offsetX);

			default:
		}
	}

	/**
		Sets a pixel in the current `Image` in 24-bit color format (red, green, blue, no alpha)
		@param	x	The x coordinate of the pixel
		@param	y	The y coordinate of the pixel
		@param	color	The color to use
		@param	format	(Optional) The `PixelFormat` that `color` is encoded in (default is `RGBA`)
	**/
	public function setPixel(x:Int, y:Int, color:Int, format:PixelFormat = null):Void
	{
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return;

		switch (type)
		{
			case CANVAS:
				ImageCanvasUtil.setPixel(this, x, y, color, format);

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				#end

				ImageDataUtil.setPixel(this, x, y, color, format);

			case FLASH:
				var argb:ARGB = switch (format)
				{
					case ARGB32: color;
					case BGRA32: (color : BGRA);
					default: (color : RGBA);
				}

				buffer.__srcBitmapData.setPixel(x + offsetX, y + offsetX, argb);

			default:
		}
	}

	/**
		Sets a pixel in the current `Image` in 32-bit color format (includes alpha)
		@param	x	The x coordinate of the pixel
		@param	y	The y coordinate of the pixel
		@param	color	The color to use
		@param	format	(Optional) The `PixelFormat` that `color` is encoded in (default is `RGBA`)
	**/
	public function setPixel32(x:Int, y:Int, color:Int, format:PixelFormat = null):Void
	{
		if (buffer == null || x < 0 || y < 0 || x >= width || y >= height) return;

		switch (type)
		{
			case CANVAS:
				ImageCanvasUtil.setPixel32(this, x, y, color, format);

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				#end

				ImageDataUtil.setPixel32(this, x, y, color, format);

			case FLASH:
				var argb:ARGB = switch (format)
				{
					case ARGB32: color;
					case BGRA32: (color : BGRA);
					default: (color : RGBA);
				}

				buffer.__srcBitmapData.setPixel32(x + offsetX, y + offsetY, argb);

			default:
		}
	}

	/**
		Sets a region of pixels at once using a `BytePointer`
		@param	rect	The region of pixels in this `Image` to replace with the incoming bytes
		@param	bytePointer	A `BytePointer` object referencing the `Bytes` and position to read from
		@param	format	(Optional) The `PixelFormat` that the pixels are encoded in (default is `RGBA`)
		@param	endian (Optional) The endianness of the incoming bytes (default is the system endianness)
	**/
	public function setPixels(rect:Rectangle, bytePointer:BytePointer, format:PixelFormat = null, endian:Endian = null):Void
	{
		rect = __clipRect(rect);
		if (buffer == null || rect == null) return;
		if (endian == null) endian = BIG_ENDIAN;

		switch (type)
		{
			case CANVAS:
				ImageCanvasUtil.setPixels(this, rect, bytePointer, format, endian);

			case DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				#end

				ImageDataUtil.setPixels(this, rect, bytePointer, format, endian);

			case FLASH:
				#if flash
				rect.offset(offsetX, offsetY);
				var byteArray = new ByteArray();

				switch (format)
				{
					case ARGB32: // do nothing
					case BGRA32:
						var srcData:ByteArray = bytePointer.bytes.getData();
						byteArray = new ByteArray();
						byteArray.position = bytePointer.offset;
						#if flash
						byteArray.length = srcData.length;
						#end

						var color:BGRA;
						var length = Std.int(byteArray.length / 4);

						for (i in 0...length)
						{
							color = srcData.readUnsignedInt();
							byteArray.writeUnsignedInt(cast(color, ARGB));
						}

						srcData.position = 0;
						byteArray.position = 0;

					default:
						var srcData = bytePointer.bytes.getData();
						byteArray = new ByteArray();
						byteArray.position = bytePointer.offset;
						#if flash
						byteArray.length = srcData.length;
						#end

						var color:RGBA;
						var length = Std.int(byteArray.length / 4);

						for (i in 0...length)
						{
							color = srcData.readUnsignedInt();
							byteArray.writeUnsignedInt(cast(color, ARGB));
						}

						srcData.position = 0;
						byteArray.position = 0;
				}

				buffer.__srcBitmapData.setPixels(rect.__toFlashRectangle(), byteArray);
				#end

			default:
		}
	}

	/**
		Tests pixel values in an image against a specified threshold and sets
		pixels that pass the test to new color values. Using the
		`threshold()` method, you can isolate and replace color ranges
		in an image and perform other logical operations on image pixels.

		The `threshold()` method's test logic is as follows:

		 1. If `((pixelValue & mask) operation(threshold & mask))`,
		then set the pixel to `color`;
		 2. Otherwise, if `copySource == true`, then set the pixel to
		corresponding pixel value from `sourceBitmap`.

		The `operation` parameter specifies the comparison operator
		to use for the threshold test. For example, by using "==" as the
		`operation` parameter, you can isolate a specific color value
		in an image. Or by using `{operation: "<", mask: 0xFF000000,
		threshold: 0x7F000000, color: 0x00000000}`, you can set all
		destination pixels to be fully transparent when the source image pixel's
		alpha is less than 0x7F. You can use this technique for animated
		transitions and other effects.

		@param	sourceImage	The input bitmap image to use. The source image can be a different `Image` object or it can refer to the current `Image` instance.
		@param	sourceRect	A rectangle that defines the area of the source image to use as input.
		@param	destPoint	The point within the destination image (the current `Image` instance) that corresponds to the upper-left corner of the source rectangle.
		@param	operation	One of the following comparison operators, passed as a `String`: "<", "<=", ">", ">=", "==", "!="
		@param	threshold	The value that each pixel is tested against to see if it meets or exceeds the threshhold.
		@param	color	The color value that a pixel is set to if the threshold test succeeds. The default value is 0x00000000.
		@param	mask	The mask to use to isolate a color component.
		@param	copySource	If the value is `true`, pixel values from the source image are copied to the destination when the threshold test fails. If the value is `false`, the source image is not copied when the threshold test fails.
		@return	The number of pixels that were changed.
	**/
	public function threshold(sourceImage:Image, sourceRect:Rectangle, destPoint:Vector2, operation:String, threshold:Int, color:Int = 0x00000000,
			mask:Int = 0xFFFFFFFF, copySource:Bool = false, format:PixelFormat = null):Int
	{
		if (buffer == null || sourceImage == null || sourceRect == null) return 0;

		switch (type)
		{
			case CANVAS, DATA:
				#if (js && html5)
				ImageCanvasUtil.convertToData(this);
				ImageCanvasUtil.convertToData(sourceImage);
				#end

				return ImageDataUtil.threshold(this, sourceImage, sourceRect, destPoint, operation, threshold, color, mask, copySource, format);

			case FLASH:
				var _color:ARGB = switch (format)
				{
					case ARGB32: color;
					case BGRA32: (color : BGRA);
					default: (color : RGBA);
				}

				var _mask:ARGB = switch (format)
				{
					case ARGB32: mask;
					case BGRA32: (mask : BGRA);
					default: (mask : RGBA);
				}

				sourceRect.offset(sourceImage.offsetX, sourceImage.offsetY);
				destPoint.offset(offsetX, offsetY);

				return buffer.__srcBitmapData.threshold(sourceImage.buffer.src, sourceRect.__toFlashRectangle(), destPoint.__toFlashPoint(), operation,
					threshold, _color, _mask, copySource);

			default:
		}

		return 0;
	}

	@:noCompletion private function __clipRect(r:Rectangle):Rectangle
	{
		if (r == null) return null;

		if (r.x < 0)
		{
			r.width -= -r.x;
			r.x = 0;

			if (r.x + r.width <= 0) return null;
		}

		if (r.y < 0)
		{
			r.height -= -r.y;
			r.y = 0;

			if (r.y + r.height <= 0) return null;
		}

		if (r.x + r.width >= width)
		{
			r.width -= r.x + r.width - width;

			if (r.width <= 0) return null;
		}

		if (r.y + r.height >= height)
		{
			r.height -= r.y + r.height - height;

			if (r.height <= 0) return null;
		}

		return r;
	}

	@:noCompletion private function __fromBase64(base64:String, type:String, onload:Image->Void = null):Void
	{
		#if (js && html5)
		var image:JSImage = untyped #if haxe4 js.Syntax.code #else __js__ #end ('new window.Image ()');

		var image_onLoaded = function(event)
		{
			buffer = new ImageBuffer(null, image.width, image.height);
			buffer.__srcImage = cast image;

			offsetX = 0;
			offsetY = 0;
			width = buffer.width;
			height = buffer.height;

			if (onload != null)
			{
				onload(this);
			}
		}

		image.addEventListener("load", image_onLoaded, false);
		image.src = "data:" + type + ";base64," + base64;
		#else
		if (base64 != null)
		{
			__fromBytes(Base64.decode(base64));
		}
		#end
	}

	@:noCompletion private function __fromBytes(bytes:Bytes, onload:Image->Void = null):Bool
	{
		#if (js && html5)
		var type = "";

		if (__isPNG(bytes))
		{
			type = "image/png";
		}
		else if (__isJPG(bytes))
		{
			type = "image/jpeg";
		}
		else if (__isGIF(bytes))
		{
			type = "image/gif";
		}
		else
		{
			// throw "Image tried to read PNG/JPG Bytes, but found an invalid header.";
			return false;
		}

		__fromBase64(Base64.encode(bytes), type, onload);
		return true;
		#elseif (lime_cffi && !macro)
		var imageBuffer:ImageBuffer = null;

		#if !cs
		imageBuffer = NativeCFFI.lime_image_load_bytes(bytes, new ImageBuffer(new UInt8Array(Bytes.alloc(0))));
		#else
		var data = NativeCFFI.lime_image_load_bytes(bytes, null);
		if (data != null)
		{
			imageBuffer = new ImageBuffer(new UInt8Array(@:privateAccess new Bytes(data.data.buffer.length, data.data.buffer.b)), data.width, data.height,
				data.bitsPerPixel);
		}
		#end

		if (imageBuffer != null)
		{
			__fromImageBuffer(imageBuffer);

			if (onload != null)
			{
				onload(this);
			}

			return true;
		}
		#else
		Log.warn("Image.fromBytes not supported on this target");
		#end

		return false;
	}

	@:noCompletion private function __fromFile(path:String, onload:Image->Void = null, onerror:Void->Void = null):Bool
	{
		#if (kha && !macro)
		kha.Assets.loadBlobFromPath(path, function(blob:kha.Blob)
		{
			try
			{
				var bytes = blob.bytes;
				var input = new BytesInput(bytes, 0, bytes.length);
				var png = new Reader(input).read();
				var data = Tools.extract32(png);
				var header = Tools.getHeader(png);

				var data = new js.html.Uint8Array(data.getData());
				var length = header.width * header.height;
				var b, g, r, a;

				for (i in 0...length)
				{
					var b = data[i * 4];
					var g = data[i * 4 + 1];
					var r = data[i * 4 + 2];
					var a = data[i * 4 + 3];

					data[i * 4] = r;
					data[i * 4 + 1] = g;
					data[i * 4 + 2] = b;
					data[i * 4 + 3] = a;
				}

				buffer = new ImageBuffer(data, header.width, header.height);

				if (buffer != null)
				{
					__fromImageBuffer(buffer);

					if (onload != null)
					{
						onload(this);
					}

					return true;
				}
			}
			catch (e:Dynamic) {}
		});
		#elseif (js && html5)
		var image:JSImage = untyped #if haxe4 js.Syntax.code #else __js__ #end ('new window.Image ()');

		#if !display
		if (!HTML5HTTPRequest.__isSameOrigin(path))
		{
			image.crossOrigin = "Anonymous";
		}
		#end

		image.onload = function(_)
		{
			buffer = new ImageBuffer(null, image.width, image.height);
			buffer.__srcImage = cast image;

			width = image.width;
			height = image.height;

			if (onload != null)
			{
				onload(this);
			}
		}

		image.onerror = function(_)
		{
			if (onerror != null)
			{
				onerror();
			}
		}

		image.src = path;

		// Another IE9 bug: loading 20+ images fails unless this line is added.
		// (issue #1019768)
		if (image.complete) {}

		return true;
		#elseif (lime_cffi || java)
		var buffer:ImageBuffer = null;

		#if (!sys || disable_cffi || java || macro)
		if (false) {}
		#else
		if (CFFI.enabled)
		{
			#if !cs
			buffer = NativeCFFI.lime_image_load_file(path, new ImageBuffer(new UInt8Array(Bytes.alloc(0))));
			#else
			var data = NativeCFFI.lime_image_load_file(path, null);
			if (data != null)
			{
				buffer = new ImageBuffer(new UInt8Array(@:privateAccess new Bytes(data.data.buffer.length, data.data.buffer.b)), data.width, data.height,
					data.bitsPerPixel);
			}
			#end
		}
		#end

		#if (sys && format)
		else
		{
			try
			{
				var bytes = File.getBytes(path);
				var input = new BytesInput(bytes, 0, bytes.length);
				var png = new Reader(input).read();
				var data = Tools.extract32(png);
				var header = Tools.getHeader(png);

				var data = new UInt8Array(Bytes.ofData(data.getData()));
				var length = header.width * header.height;
				var b, g, r, a;

				for (i in 0...length)
				{
					var b = data[i * 4];
					var g = data[i * 4 + 1];
					var r = data[i * 4 + 2];
					var a = data[i * 4 + 3];

					data[i * 4] = r;
					data[i * 4 + 1] = g;
					data[i * 4 + 2] = b;
					data[i * 4 + 3] = a;
				}

				buffer = new ImageBuffer(data, header.width, header.height);
			}
			catch (e:Dynamic) {}
		}
		#end

		if (buffer != null)
		{
			__fromImageBuffer(buffer);

			if (onload != null)
			{
				onload(this);
			}

			return true;
		}
		#else
		Log.warn("Image.fromFile not supported on this target");
		#end

		return false;
	}

	@:noCompletion private function __fromImageBuffer(buffer:ImageBuffer):Void
	{
		this.buffer = buffer;

		if (buffer != null)
		{
			if (width == -1)
			{
				this.width = buffer.width;
			}

			if (height == -1)
			{
				this.height = buffer.height;
			}
		}
	}

	private static function __isGIF(bytes:Bytes):Bool
	{
		if (bytes == null || bytes.length < 6) return false;

		var header = bytes.getString(0, 6);
		return (header == "GIF87a" || header == "GIF89a");
	}

	private static function __isJPG(bytes:Bytes):Bool
	{
		if (bytes == null || bytes.length < 4) return false;

		return bytes.get(0) == 0xFF
			&& bytes.get(1) == 0xD8
			&& bytes.get(bytes.length - 2) == 0xFF
			&& bytes.get(bytes.length - 1) == 0xD9;
	}

	private static function __isPNG(bytes:Bytes):Bool
	{
		if (bytes == null || bytes.length < 8) return false;

		return (bytes.get(0) == 0x89 && bytes.get(1) == "P".code && bytes.get(2) == "N".code && bytes.get(3) == "G".code && bytes.get(4) == "\r".code
			&& bytes.get(5) == "\n".code && bytes.get(6) == 0x1A && bytes.get(7) == "\n".code);
	}

	private static function __isWebP(bytes:Bytes):Bool
	{
		if (bytes == null || bytes.length < 16) return false;

		return (bytes.getString(0, 4) == "RIFF" && bytes.getString(8, 4) == "WEBP");
	}

	// Get & Set Methods
	@:noCompletion private function get_data():UInt8Array
	{
		if (buffer.data == null && buffer.width > 0 && buffer.height > 0)
		{
			#if (js && html5)
			ImageCanvasUtil.convertToData(this);
			#elseif flash
			var pixels = buffer.__srcBitmapData.getPixels(buffer.__srcBitmapData.rect);
			buffer.data = new UInt8Array(Bytes.ofData(pixels));
			#end
		}

		return buffer.data;
	}

	@:noCompletion private function set_data(value:UInt8Array):UInt8Array
	{
		return buffer.data = value;
	}

	@:noCompletion private function get_format():PixelFormat
	{
		return buffer.format;
	}

	@:noCompletion private function set_format(value:PixelFormat):PixelFormat
	{
		if (buffer.format != value)
		{
			switch (type)
			{
				case DATA:
					ImageDataUtil.setFormat(this, value);

				default:
			}
		}

		return buffer.format = value;
	}

	@:noCompletion private function get_powerOfTwo():Bool
	{
		return ((buffer.width != 0)
			&& ((buffer.width & (~buffer.width + 1)) == buffer.width))
			&& ((buffer.height != 0) && ((buffer.height & (~buffer.height + 1)) == buffer.height));
	}

	@:noCompletion private function set_powerOfTwo(value:Bool):Bool
	{
		if (value != powerOfTwo)
		{
			var newWidth = 1;
			var newHeight = 1;

			while (newWidth < buffer.width)
			{
				newWidth <<= 1;
			}

			while (newHeight < buffer.height)
			{
				newHeight <<= 1;
			}

			if (newWidth == buffer.width && newHeight == buffer.height)
			{
				return value;
			}

			switch (type)
			{
				case CANVAS:
					#if (js && html5)
					ImageCanvasUtil.convertToData(this);
					#end
					ImageDataUtil.resizeBuffer(this, newWidth, newHeight);

				case DATA:
					ImageDataUtil.resizeBuffer(this, newWidth, newHeight);

				case FLASH:
					#if flash
					var bitmapData = new BitmapData(newWidth, newHeight, true, 0x000000);
					bitmapData.draw(buffer.src, null, null, null, true);

					buffer.src = bitmapData;
					buffer.width = newWidth;
					buffer.height = newHeight;
					#end

				default:
			}
		}

		return value;
	}

	@:noCompletion private function get_premultiplied():Bool
	{
		return buffer.premultiplied;
	}

	@:noCompletion private function set_premultiplied(value:Bool):Bool
	{
		if (value && !buffer.premultiplied)
		{
			switch (type)
			{
				case CANVAS, DATA:
					#if (js && html5)
					ImageCanvasUtil.convertToData(this);
					#end

					ImageDataUtil.multiplyAlpha(this);

				default:
					// TODO
			}
		}
		else if (!value && buffer.premultiplied)
		{
			switch (type)
			{
				case DATA:
					#if (js && html5)
					ImageCanvasUtil.convertToData(this);
					#end

					ImageDataUtil.unmultiplyAlpha(this);

				default:
					// TODO
			}
		}

		return value;
	}

	@:noCompletion private function get_rect():Rectangle
	{
		return new Rectangle(0, 0, width, height);
	}

	@:noCompletion private function get_src():Dynamic
	{
		#if (js && html5)
		if (buffer.__srcCanvas == null && (buffer.data != null || type == DATA))
		{
			ImageCanvasUtil.convertToCanvas(this);
		}
		#end

		return buffer.src;
	}

	@:noCompletion private function set_src(value:Dynamic):Dynamic
	{
		return buffer.src = value;
	}

	@:noCompletion private function get_transparent():Bool
	{
		if (buffer == null) return false;
		return buffer.transparent;
	}

	@:noCompletion private function set_transparent(value:Bool):Bool
	{
		// TODO, modify data to set transparency
		if (buffer == null) return false;
		return buffer.transparent = value;
	}
}
