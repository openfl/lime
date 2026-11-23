package lime._internal.format;

import haxe.io.Bytes;
import lime.graphics.Image;
import lime.math.Rectangle;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class BMP
{
	public static function encode(image:Image, type:BMPType = null):Bytes
	{
		if (image.premultiplied || image.format != RGBA32)
		{
			// TODO: Handle encode from different formats

			image = image.clone();
			image.premultiplied = false;
			image.format = RGBA32;
		}

		if (type == null)
		{
			type = RGB;
		}

		var fileHeaderLength = 14;
		var infoHeaderLength = 40;
		var pixelValuesLength = (image.width * image.height * 4);

		// 24-bit rows are padded to a multiple of 4 bytes, and an icon's 1-bit
		// AND mask has rows padded to 32 bits
		var rgbStride = ((image.width * 3 + 3) >> 2) << 2;
		var maskStride = ((image.width + 31) >> 5) * 4;

		switch (type)
		{
			case BITFIELD:
				infoHeaderLength = 108;

			case ICO:
				fileHeaderLength = 0;
				pixelValuesLength += maskStride * image.height;

			case RGB:
				pixelValuesLength = rgbStride * image.height;

			default:
		}

		var data = Bytes.alloc(fileHeaderLength + infoHeaderLength + pixelValuesLength);
		var position = 0;

		if (fileHeaderLength > 0)
		{
			data.set(position++, 0x42);
			data.set(position++, 0x4D);
			data.setInt32(position, data.length);
			position += 4;
			data.setUInt16(position, 0);
			position += 2;
			data.setUInt16(position, 0);
			position += 2;
			data.setInt32(position, fileHeaderLength + infoHeaderLength);
			position += 4;
		}

		data.setInt32(position, infoHeaderLength);
		position += 4;
		data.setInt32(position, image.width);
		position += 4;
		data.setInt32(position, type == ICO ? image.height * 2 : image.height);
		position += 4;
		data.setUInt16(position, 1);
		position += 2;
		data.setUInt16(position, type == RGB ? 24 : 32);
		position += 2;
		data.setInt32(position, type == BITFIELD ? 3 : 0);
		position += 4;
		data.setInt32(position, pixelValuesLength);
		position += 4;
		data.setInt32(position, 0x2e30);
		position += 4;
		data.setInt32(position, 0x2e30);
		position += 4;
		data.setInt32(position, 0);
		position += 4;
		data.setInt32(position, 0);
		position += 4;

		if (type == BITFIELD)
		{
			data.setInt32(position, 0x00FF0000);
			position += 4;
			data.setInt32(position, 0x0000FF00);
			position += 4;
			data.setInt32(position, 0x000000FF);
			position += 4;
			data.setInt32(position, 0xFF000000);
			position += 4;

			data.set(position++, 0x20);
			data.set(position++, 0x6E);
			data.set(position++, 0x69);
			data.set(position++, 0x57);

			for (i in 0...48)
			{
				data.set(position++, 0);
			}
		}

		var pixels = image.getPixels(new Rectangle(0, 0, image.width, image.height), ARGB32);
		var readPosition = 0;
		var a:Int;
		var r:Int;
		var g:Int;
		var b:Int;

		switch (type)
		{
			case BITFIELD:
				for (y in 0...image.height)
				{
					readPosition = (image.height - 1 - y) * 4 * image.width;

					for (x in 0...image.width)
					{
						a = pixels.get(readPosition++);
						r = pixels.get(readPosition++);
						g = pixels.get(readPosition++);
						b = pixels.get(readPosition++);

						data.set(position++, b);
						data.set(position++, g);
						data.set(position++, r);
						data.set(position++, a);
					}
				}

			case ICO:
				var andMask = Bytes.alloc(maskStride * image.height);
				andMask.fill(0, andMask.length, 0);

				for (y in 0...image.height)
				{
					readPosition = (image.height - 1 - y) * 4 * image.width;

					for (x in 0...image.width)
					{
						a = pixels.get(readPosition++);
						r = pixels.get(readPosition++);
						g = pixels.get(readPosition++);
						b = pixels.get(readPosition++);

						data.set(position++, b);
						data.set(position++, g);
						data.set(position++, r);
						data.set(position++, a);

						// A set bit leaves what is behind the icon showing
						if (a < 128)
						{
							var maskPosition = y * maskStride + (x >> 3);
							andMask.set(maskPosition, andMask.get(maskPosition) | (0x80 >> (x & 7)));
						}
					}
				}

				data.blit(position, andMask, 0, andMask.length);

			case RGB:
				for (y in 0...image.height)
				{
					readPosition = (image.height - 1 - y) * 4 * image.width;

					for (x in 0...image.width)
					{
						a = pixels.get(readPosition++);
						r = pixels.get(readPosition++);
						g = pixels.get(readPosition++);
						b = pixels.get(readPosition++);

						data.set(position++, b);
						data.set(position++, g);
						data.set(position++, r);
					}

					for (i in 0...(rgbStride - image.width * 3))
					{
						data.set(position++, 0);
					}
				}

			default:
		}

		return data;
	}
}

enum BMPType
{
	RGB;
	BITFIELD;
	ICO;
}
