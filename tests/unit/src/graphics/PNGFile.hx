package graphics;

import haxe.crypto.Adler32;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import haxe.zip.InflateImpl;

typedef PNGChunk =
{
	var type:String;
	var data:Bytes;
}

typedef PNGImage =
{
	var width:Int;
	var height:Int;
	var bitDepth:Int;
	var colourType:Int;
	var chunkTypes:Array<String>;
	/** 0xRRGGBBAA, row by row **/
	var pixels:Array<Int>;
	/** Everything found that breaks the PNG specification **/
	var problems:Array<String>;
}

/**
	PNG files written and read by hand from the PNG specification (W3C, Third Edition), so the codec
	tests don't take their expectations from the codec they check. Image data is stored in zlib's
	uncompressed blocks (RFC 1950, RFC 1951 §3.2.4), which need no compressor.
**/
class PNGFile
{
	// Colour types, PNG §11.2.1
	public static inline var GREYSCALE = 0;
	public static inline var TRUECOLOUR = 2;
	public static inline var INDEXED_COLOUR = 3;
	public static inline var GREYSCALE_ALPHA = 4;
	public static inline var TRUECOLOUR_ALPHA = 6;

	// x, y, x spacing and y spacing of each Adam7 pass, PNG §8.2
	private static var ADAM7 = [[0, 0, 8, 8], [4, 0, 8, 8], [0, 4, 4, 8], [2, 0, 4, 4], [0, 2, 2, 4], [1, 0, 2, 2], [0, 1, 1, 2]];

	/**
		Encodes an image given as rows of samples, in the order the colour type names them
		(`channels(colourType)` samples a pixel). Scanlines take the filter types in `filters` in turn,
		or filter type 0 without them. `idatSize` splits the zlib stream over IDAT chunks of that size.
	**/
	public static function create(width:Int, height:Int, colourType:Int, bitDepth:Int, rows:Array<Array<Int>>, ?beforeData:Array<PNGChunk>,
			interlaced:Bool = false, ?filters:Array<Int>, idatSize:Int = 0):Bytes
	{
		var stream = zlibStored(imageData(width, height, colourType, bitDepth, rows, interlaced, filters));
		var out = new BytesBuffer();
		out.add(signature());
		out.add(chunk("IHDR", header(width, height, bitDepth, colourType, interlaced)));

		if (beforeData != null)
		{
			for (extra in beforeData)
			{
				out.add(chunk(extra.type, extra.data));
			}
		}

		if (idatSize <= 0) idatSize = stream.length;
		var position = 0;

		while (position < stream.length)
		{
			var length = Std.int(Math.min(idatSize, stream.length - position));
			out.add(chunk("IDAT", stream.sub(position, length)));
			position += length;
		}

		out.add(chunk("IEND", Bytes.alloc(0)));
		return out.getBytes();
	}

	/** Rows of 0xRRGGBBAA pixels as rows of truecolour-with-alpha samples **/
	public static function samplesOf(width:Int, pixels:Array<Int>):Array<Array<Int>>
	{
		var rows = [];
		var y = 0;

		while (y * width < pixels.length)
		{
			var row = [];

			for (x in 0...width)
			{
				var pixel = pixels[y * width + x];
				row.push((pixel >>> 24) & 0xFF);
				row.push((pixel >>> 16) & 0xFF);
				row.push((pixel >>> 8) & 0xFF);
				row.push(pixel & 0xFF);
			}

			rows.push(row);
			y++;
		}

		return rows;
	}

	public static function signature():Bytes
	{
		var bytes = Bytes.alloc(8);
		var values = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

		for (i in 0...8)
		{
			bytes.set(i, values[i]);
		}

		return bytes;
	}

	public static function header(width:Int, height:Int, bitDepth:Int, colourType:Int, interlaced:Bool):Bytes
	{
		var out = new BytesBuffer();
		writeUInt32BE(out, width);
		writeUInt32BE(out, height);
		out.addByte(bitDepth);
		out.addByte(colourType);
		out.addByte(0);
		out.addByte(0);
		out.addByte(interlaced ? 1 : 0);
		return out.getBytes();
	}

	/** A chunk: its length, type, data and the CRC of its type and data (PNG §5.3) **/
	public static function chunk(type:String, data:Bytes):Bytes
	{
		var typeAndData = Bytes.alloc(4 + data.length);

		for (i in 0...4)
		{
			typeAndData.set(i, type.charCodeAt(i));
		}

		typeAndData.blit(4, data, 0, data.length);

		var out = new BytesBuffer();
		writeUInt32BE(out, data.length);
		out.add(typeAndData);
		writeUInt32BE(out, Crc32.make(typeAndData));
		return out.getBytes();
	}

	/** A PLTE chunk of 0xRRGGBB entries **/
	public static function palette(colours:Array<Int>):PNGChunk
	{
		var data = Bytes.alloc(colours.length * 3);

		for (i in 0...colours.length)
		{
			data.set(i * 3, (colours[i] >> 16) & 0xFF);
			data.set(i * 3 + 1, (colours[i] >> 8) & 0xFF);
			data.set(i * 3 + 2, colours[i] & 0xFF);
		}

		return {type: "PLTE", data: data};
	}

	/** A tRNS chunk of one byte a value for indexed colour, or two bytes a value otherwise (PNG §11.3.2.1) **/
	public static function transparency(values:Array<Int>, twoBytes:Bool):PNGChunk
	{
		var data = Bytes.alloc(values.length * (twoBytes ? 2 : 1));

		for (i in 0...values.length)
		{
			if (twoBytes)
			{
				data.set(i * 2, (values[i] >> 8) & 0xFF);
				data.set(i * 2 + 1, values[i] & 0xFF);
			}
			else
			{
				data.set(i, values[i]);
			}
		}

		return {type: "tRNS", data: data};
	}

	public static function channels(colourType:Int):Int
	{
		return switch (colourType)
		{
			case GREYSCALE, INDEXED_COLOUR: 1;
			case GREYSCALE_ALPHA: 2;
			case TRUECOLOUR: 3;
			case TRUECOLOUR_ALPHA: 4;
			default: throw "Unknown colour type " + colourType;
		}
	}

	/** Filtered scanlines, each led by its filter type, pass by pass when interlaced (PNG §7.3, §8.2, §9) **/
	public static function imageData(width:Int, height:Int, colourType:Int, bitDepth:Int, rows:Array<Array<Int>>, interlaced:Bool, filters:Array<Int>):Bytes
	{
		var channelCount = channels(colourType);
		var bytesPerPixel = Std.int(Math.max(1, Math.ceil(channelCount * bitDepth / 8)));
		var out = new BytesBuffer();
		var scanline = 0;

		for (pass in (interlaced ? ADAM7 : [[0, 0, 1, 1]]))
		{
			// A pass with no pixels has no scanlines, not even filter type bytes
			if (pass[0] >= width || pass[1] >= height) continue;

			var previous:Bytes = null;
			var y = pass[1];

			while (y < height)
			{
				var samples = [];
				var x = pass[0];

				while (x < width)
				{
					for (c in 0...channelCount)
					{
						samples.push(rows[y][x * channelCount + c]);
					}

					x += pass[2];
				}

				var raw = pack(samples, bitDepth);

				// The first scanline of each pass is filtered against a row of zeros
				if (previous == null)
				{
					previous = Bytes.alloc(raw.length);
					previous.fill(0, raw.length, 0);
				}

				var type = (filters == null ? 0 : filters[scanline % filters.length]);
				out.addByte(type);
				out.add(filter(type, raw, previous, bytesPerPixel));

				previous = raw;
				scanline++;
				y += pass[3];
			}
		}

		return out.getBytes();
	}

	/** A zlib stream (RFC 1950) of stored blocks (RFC 1951 §3.2.4) **/
	public static function zlibStored(data:Bytes):Bytes
	{
		var out = new BytesBuffer();
		// CM 8 and a 32K window, no dictionary, and FCHECK making 0x7801 a multiple of 31
		out.addByte(0x78);
		out.addByte(0x01);

		var position = 0;

		do
		{
			var length = Std.int(Math.min(65535, data.length - position));
			var last = (position + length >= data.length);
			out.addByte(last ? 1 : 0);
			out.addByte(length & 0xFF);
			out.addByte((length >> 8) & 0xFF);
			out.addByte(~length & 0xFF);
			out.addByte((~length >> 8) & 0xFF);
			out.addBytes(data, position, length);
			position += length;
		}
		while (position < data.length);

		writeUInt32BE(out, Adler32.make(data));
		return out.getBytes();
	}

	/**
		Reads a PNG of 8-bit samples without interlacing into 0xRRGGBBAA pixels, checking each chunk's CRC,
		the chunk order and the zlib stream's Adler-32 on the way.
	**/
	public static function read(bytes:Bytes):PNGImage
	{
		var result:PNGImage = {width: 0, height: 0, bitDepth: 0, colourType: -1, chunkTypes: [], pixels: [], problems: []};
		var problems = result.problems;

		if (bytes == null || bytes.length < 8 || bytes.sub(0, 8).compare(signature()) != 0)
		{
			problems.push("no PNG signature");
			return result;
		}

		var interlaced = false;
		var paletteData:Bytes = null;
		var alphaData:Bytes = null;
		var idat = new BytesBuffer();
		var position = 8;
		var ended = false;

		while (position + 12 <= bytes.length)
		{
			var length = readUInt32BE(bytes, position);
			if (position + 12 + length > bytes.length)
			{
				problems.push("a chunk runs past the end of the file");
				break;
			}

			var type = bytes.getString(position + 4, 4);
			var data = bytes.sub(position + 8, length);
			var crc = readUInt32BE(bytes, position + 8 + length);

			if (crc != Crc32.make(bytes.sub(position + 4, 4 + length)))
			{
				problems.push("the " + type + " chunk's CRC is wrong");
			}

			result.chunkTypes.push(type);
			position += 12 + length;

			switch (type)
			{
				case "IHDR":
					result.width = readUInt32BE(data, 0);
					result.height = readUInt32BE(data, 4);
					result.bitDepth = data.get(8);
					result.colourType = data.get(9);
					interlaced = (data.get(12) == 1);
				case "PLTE":
					paletteData = data;
				case "tRNS":
					alphaData = data;
				case "IDAT":
					idat.add(data);
				case "IEND":
					ended = true;
					break;
				default:
			}
		}

		if (result.chunkTypes[0] != "IHDR") problems.push("IHDR is not the first chunk");
		if (!ended) problems.push("there is no IEND chunk");
		if (position != bytes.length) problems.push((bytes.length - position) + " bytes follow IEND");

		var firstData = result.chunkTypes.indexOf("IDAT");
		var lastData = result.chunkTypes.lastIndexOf("IDAT");
		if (firstData < 0) problems.push("there is no IDAT chunk");

		for (i in firstData...lastData + 1)
		{
			if (result.chunkTypes[i] != "IDAT")
			{
				problems.push("the IDAT chunks are not consecutive");
				break;
			}
		}

		if (result.width <= 0 || result.height <= 0) problems.push("the image is " + result.width + "x" + result.height);
		if (interlaced || result.bitDepth != 8)
		{
			problems.push("this reader only reads 8-bit PNGs without interlacing");
		}

		if (problems.length > 0) return result;

		var inflated:Bytes = null;

		try
		{
			inflated = InflateImpl.run(new BytesInput(idat.getBytes()));
		}
		catch (e:Dynamic)
		{
			problems.push("the image data does not inflate: " + e);
			return result;
		}

		var channelCount = channels(result.colourType);
		var stride = result.width * channelCount;

		if (inflated.length != (stride + 1) * result.height)
		{
			problems.push("the image data is " + inflated.length + " bytes, not " + ((stride + 1) * result.height));
			return result;
		}

		var previous = Bytes.alloc(stride);
		previous.fill(0, stride, 0);

		for (y in 0...result.height)
		{
			var type = inflated.get(y * (stride + 1));
			if (type > 4)
			{
				problems.push("scanline " + y + " has filter type " + type);
				return result;
			}

			var row = unfilter(type, inflated.sub(y * (stride + 1) + 1, stride), previous, channelCount);

			for (x in 0...result.width)
			{
				var r, g, b, a = 255;
				var i = x * channelCount;

				switch (result.colourType)
				{
					case GREYSCALE:
						r = g = b = row.get(i);
					case GREYSCALE_ALPHA:
						r = g = b = row.get(i);
						a = row.get(i + 1);
					case TRUECOLOUR:
						r = row.get(i);
						g = row.get(i + 1);
						b = row.get(i + 2);
					case INDEXED_COLOUR:
						var index = row.get(i);
						r = paletteData.get(index * 3);
						g = paletteData.get(index * 3 + 1);
						b = paletteData.get(index * 3 + 2);
						if (alphaData != null && index < alphaData.length) a = alphaData.get(index);
					default:
						r = row.get(i);
						g = row.get(i + 1);
						b = row.get(i + 2);
						a = row.get(i + 3);
				}

				result.pixels.push((r << 24) | (g << 16) | (b << 8) | a);
			}

			previous = row;
		}

		return result;
	}

	private static function pack(samples:Array<Int>, bitDepth:Int):Bytes
	{
		if (bitDepth == 16)
		{
			var bytes = Bytes.alloc(samples.length * 2);

			for (i in 0...samples.length)
			{
				bytes.set(i * 2, (samples[i] >> 8) & 0xFF);
				bytes.set(i * 2 + 1, samples[i] & 0xFF);
			}

			return bytes;
		}

		// Samples below 8 bits fill each byte from its high bit, and a scanline ends on a whole byte
		var bytes = Bytes.alloc(Math.ceil(samples.length * bitDepth / 8));
		bytes.fill(0, bytes.length, 0);
		var perByte = Std.int(8 / bitDepth);

		for (i in 0...samples.length)
		{
			var index = Std.int(i / perByte);
			var shift = 8 - bitDepth * (i % perByte + 1);
			bytes.set(index, bytes.get(index) | ((samples[i] & ((1 << bitDepth) - 1)) << shift));
		}

		return bytes;
	}

	private static function filter(type:Int, raw:Bytes, previous:Bytes, bytesPerPixel:Int):Bytes
	{
		var out = Bytes.alloc(raw.length);

		for (i in 0...raw.length)
		{
			var a = (i >= bytesPerPixel ? raw.get(i - bytesPerPixel) : 0);
			var b = previous.get(i);
			var c = (i >= bytesPerPixel ? previous.get(i - bytesPerPixel) : 0);
			out.set(i, (raw.get(i) - predict(type, a, b, c)) & 0xFF);
		}

		return out;
	}

	private static function unfilter(type:Int, filtered:Bytes, previous:Bytes, bytesPerPixel:Int):Bytes
	{
		var out = Bytes.alloc(filtered.length);

		for (i in 0...filtered.length)
		{
			var a = (i >= bytesPerPixel ? out.get(i - bytesPerPixel) : 0);
			var b = previous.get(i);
			var c = (i >= bytesPerPixel ? previous.get(i - bytesPerPixel) : 0);
			out.set(i, (filtered.get(i) + predict(type, a, b, c)) & 0xFF);
		}

		return out;
	}

	// PNG §9.2: a is the byte to the left, b the byte above, c the byte above and to the left
	private static function predict(type:Int, a:Int, b:Int, c:Int):Int
	{
		return switch (type)
		{
			case 0: 0;
			case 1: a;
			case 2: b;
			case 3: (a + b) >> 1;
			case 4:
				var p = a + b - c;
				var pa = Std.int(Math.abs(p - a));
				var pb = Std.int(Math.abs(p - b));
				var pc = Std.int(Math.abs(p - c));
				(pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c);
			default: throw "Unknown filter type " + type;
		}
	}

	private static function readUInt32BE(bytes:Bytes, position:Int):Int
	{
		return (bytes.get(position) << 24) | (bytes.get(position + 1) << 16) | (bytes.get(position + 2) << 8) | bytes.get(position + 3);
	}

	private static function writeUInt32BE(out:BytesBuffer, value:Int):Void
	{
		out.addByte((value >>> 24) & 0xFF);
		out.addByte((value >>> 16) & 0xFF);
		out.addByte((value >>> 8) & 0xFF);
		out.addByte(value & 0xFF);
	}
}
