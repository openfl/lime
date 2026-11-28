package graphics;

#if (lime_cffi && !macro)
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.PixelFormat;
import lime.utils.Bytes as LimeBytes;
import lime.utils.UInt8Array;
#end
import utest.Assert;
import utest.Test;

/**
	Pins the bytes today's native PNG and JPEG encoders write, as each file's length and a CRC-32 of it.

	Lime builds its own libpng, zlib-ng and libjpeg-turbo, so the bytes are the same on every platform. These
	pin current output for the performance work on encoding, which changes how the output is collected
	and not what is written, so each file must come out the same afterwards.

	The images are large enough that libpng writes many chunks and libjpeg-turbo flushes its buffer many
	times, which is where collecting the output does its work.
**/
class ImageEncodeOutputTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	public function testPNGEncodingOfNoiseKeepsItsBytes():Void
	{
		assertEncodes("240686:DDA524DC", noise(300, 200, RGBA32, false).encode(PNG), "noise as a PNG");
	}

	public function testPNGEncodingOfAGradientKeepsItsBytes():Void
	{
		// Compresses well, so zlib's output arrives in a few large writes rather than many full ones
		assertEncodes("3924:A23FB52D", gradient(640, 480).encode(PNG), "a gradient as a PNG");
	}

	public function testPNGEncodingOfEachFormatKeepsItsBytes():Void
	{
		var results = [];

		for (format in [RGBA32, BGRA32, ARGB32])
		{
			for (premultiplied in [false, true])
			{
				results.push(describe(noise(97, 61, format, premultiplied).encode(PNG)));
			}
		}

		assertPin([
			"23826:E89763A8",
			"23826:D39F697C",
			"23826:3C33F039",
			"23826:A311CE10",
			"23826:BF35E3BB",
			"23826:3A65AC84"
		].join(" "), results.join(" "), "noise in each format, straight and premultiplied, as PNGs");
	}

	public function testJPEGEncodingAtEachQualityKeepsItsBytes():Void
	{
		var image = noise(300, 200, RGBA32, false);
		var results = [for (quality in [10, 50, 90, 100]) describe(image.encode(JPEG, quality))];

		assertPin([
			"7462:187A97D9",
			"25623:E5AD6D9B",
			"55655:66C2214A",
			"122080:BFF50FCC"
		].join(" "), results.join(" "), "noise as JPEGs at quality 10, 50, 90 and 100");
	}

	public function testJPEGEncodingOfAGradientKeepsItsBytes():Void
	{
		assertEncodes("15695:3C774643", gradient(640, 480).encode(JPEG, 90), "a gradient as a JPEG");
	}

	public function testEncodingDecodedFilesKeepsTheirBytes():Void
	{
		var results = [];

		for (path in ["assets/image-rgba.png", "assets/image-palette.png", "assets/image-420.jpg"])
		{
			var image = Image.fromBytes(LimeBytes.fromFile(path));
			results.push(describe(image.encode(PNG)) + "/" + describe(image.encode(JPEG, 85)));
		}

		assertPin([
			"788:8B2B544B/1071:80621DF0",
			"263:63FE28E9/1601:BF75BDCC",
			"3961:B56E7B29/1199:25CF6E5F"
		].join(" "), results.join(" "), "the decoded image files as PNGs and JPEGs");
	}

	public function testEncodingTheSameImageTwiceGivesTheSameBytes():Void
	{
		var image = noise(300, 200, BGRA32, true);

		Assert.equals(describe(image.encode(PNG)), describe(image.encode(PNG)));
		Assert.equals(describe(image.encode(JPEG, 90)), describe(image.encode(JPEG, 90)));
	}

	// Helpers

	private static function assertEncodes(expected:String, bytes:Bytes, name:String, ?pos:haxe.PosInfos):Void
	{
		assertPin(expected, describe(bytes), name, pos);
	}

	private static function assertPin(expected:String, actual:String, name:String, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(expected, actual, name + " gave " + actual + ", pinned " + expected, pos);
	}

	private static function describe(bytes:Bytes):String
	{
		return bytes == null ? "null" : bytes.length + ":" + StringTools.hex(Crc32.make(bytes), 8);
	}

	/** Xorshift noise with alpha, premultiplied when asked, so no channel is above its alpha **/
	private static function noise(width:Int, height:Int, format:PixelFormat, premultiplied:Bool):Image
	{
		var data = new UInt8Array(width * height * 4);
		var state = 0x6A09E667;
		var alphaIndex = (format == ARGB32 ? 0 : 3);

		for (i in 0...width * height)
		{
			state ^= state << 13;
			state ^= state >>> 17;
			state ^= state << 5;

			var a = (state >>> (alphaIndex * 8)) & 0xFF;

			for (channel in 0...4)
			{
				var value = (state >>> (channel * 8)) & 0xFF;
				if (premultiplied && channel != alphaIndex) value = Std.int((value * a + 127) / 255);
				data[i * 4 + channel] = value;
			}
		}

		var buffer = new ImageBuffer(data, width, height, 32, format);
		buffer.premultiplied = premultiplied;
		buffer.transparent = true;
		return new Image(buffer, 0, 0, width, height, null, DATA);
	}

	/** Opaque, with red across, green down and blue along the diagonal **/
	private static function gradient(width:Int, height:Int):Image
	{
		var data = new UInt8Array(width * height * 4);

		for (y in 0...height)
		{
			for (x in 0...width)
			{
				var offset = (y * width + x) * 4;
				data[offset] = Std.int(x * 255 / (width - 1));
				data[offset + 1] = Std.int(y * 255 / (height - 1));
				data[offset + 2] = ((x + y) >> 2) & 0xFF;
				data[offset + 3] = 0xFF;
			}
		}

		var buffer = new ImageBuffer(data, width, height, 32, RGBA32);
		buffer.transparent = false;
		return new Image(buffer, 0, 0, width, height, null, DATA);
	}
	#end
}
