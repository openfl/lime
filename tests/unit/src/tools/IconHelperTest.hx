package tools;

#if (sys && lime_cffi && !macro && format && (windows || mac || linux))
import graphics.ImageFixture;
import haxe.io.Bytes;
import lime.graphics.Image;
import lime.graphics.ImageFileFormat;
import lime.math.Rectangle;
import lime.tools.Icon;
import lime.tools.IconHelper;
import sys.FileSystem;
import sys.io.File;
#end
import utest.Assert;
import utest.Test;

/**
	The App Store icon the iOS target writes, Icon-Marketing.png, which App Store Connect turns down
	with an alpha channel (#1084): `IconHelper.createOpaqueIcon()` draws the icon over a background
	and writes RGB pixels, PNG color type 2, where the other icons keep theirs, color type 6.
**/
class IconHelperTest extends Test
{
	#if (sys && lime_cffi && !macro && format && (windows || mac || linux))
	private static inline var HALF_BLUE = 0x800000FF;
	private static inline var RED = 0xFFFF0000;

	private var files:Array<String> = [];
	#end

	public function new()
	{
		super();
	}

	#if (sys && lime_cffi && !macro && format && (windows || mac || linux))
	public function teardown():Void
	{
		for (file in files)
		{
			if (FileSystem.exists(file)) FileSystem.deleteFile(file);
		}

		files = [];
	}

	public function testAMarketingIconIsDrawnOverItsBackgroundWithoutAnAlphaChannel():Void
	{
		var source = writeSource();
		var target = temporaryFile();

		Assert.isTrue(IconHelper.createOpaqueIcon([new Icon(source)], 1024, 1024, target, 0xFFFFFF), "no icon was written");
		if (!assertRGB(target)) return;

		var image = Image.fromFile(target);
		// (0, 0, 255, 128) over white, half of each: 127 of red and green, as 255 * 127 / 255 rounds
		assertColor(0xFF7F7FFF, image, 100, 100, "a pixel half covered in blue");
		assertColor(0xFFFFFFFF, image, 800, 100, "a transparent pixel");
		assertColor(RED, image, 800, 800, "an opaque pixel");
	}

	public function testAMarketingIconOfAnSVGHasNoAlphaChannel():Void
	{
		// The icon a project without one of its own gets
		var svg = hxp.Path.combine(hxp.Haxelib.getPath(new hxp.Haxelib("lime")), "templates/default/icon.svg");
		var target = temporaryFile();

		if (!IconHelper.createOpaqueIcon([new Icon(svg)], 1024, 1024, target, 0xFFFFFF))
		{
			// Drawing an SVG needs svg.n and Neko, which a test machine may not have
			trace("No SVG rasterizer could run here, so the marketing icon of an SVG was not tested");
			Assert.pass();
			return;
		}

		assertRGB(target);
	}

	public function testTheOtherIconsKeepTheirAlphaChannel():Void
	{
		var source = writeSource();
		var target = temporaryFile();

		Assert.isTrue(IconHelper.createIcon([new Icon(source)], 180, 180, target), "no icon was written");

		var info = pngInfo(target);
		Assert.equals(6, info.colorType, "the color type of an icon made smaller");
		Assert.equals(0, ImageFixture.read(Image.fromFile(target), 150, 30) >>> 24, "the alpha of a transparent pixel");
	}

	// An earlier Lime wrote it with an alpha channel, and the icon hasn't changed since
	public function testAnRGBAMarketingIconNewerThanItsSourceIsWrittenAgain():Void
	{
		var source = writeSource();
		var target = temporaryFile();
		File.saveBytes(target, File.getBytes(source));

		Assert.equals(6, pngInfo(target).colorType, "the icon an earlier Lime wrote");
		Assert.isTrue(IconHelper.createOpaqueIcon([new Icon(source)], 1024, 1024, target, 0xFFFFFF), "no icon was written");
		assertRGB(target);
	}

	public function testAnRGBMarketingIconNewerThanItsSourceIsKept():Void
	{
		var source = writeSource();
		var target = temporaryFile();

		// Drawn over black, then asked for again over white
		Assert.isTrue(IconHelper.createOpaqueIcon([new Icon(source)], 1024, 1024, target, 0x000000), "no icon was written");
		Assert.isTrue(IconHelper.createOpaqueIcon([new Icon(source)], 1024, 1024, target, 0xFFFFFF), "no icon was given");

		assertColor(0xFF000000, Image.fromFile(target), 800, 100, "a transparent pixel of the icon written first");
	}

	/**
		Writes a 1024 pixel PNG icon whose left half is blue at half alpha, (0, 0, 255, 128), top right
		transparent, and bottom right opaque red, and gives its path.
	**/
	private function writeSource():String
	{
		var image = ImageFixture.create(1024, 1024, 0);
		image.fillRect(new Rectangle(0, 0, 512, 1024), HALF_BLUE, ARGB32);
		image.fillRect(new Rectangle(512, 512, 512, 512), RED, ARGB32);

		var path = temporaryFile();
		File.saveBytes(path, image.encode(ImageFileFormat.PNG));
		return path;
	}

	private function temporaryFile():String
	{
		var path = hxp.System.getTemporaryFile(".png");
		files.push(path);
		return path;
	}

	/** Checks that the PNG at `path` is 1024 pixels square, of RGB pixels, and with no transparent color **/
	private static function assertRGB(path:String, ?pos:haxe.PosInfos):Bool
	{
		var info = pngInfo(path);
		Assert.equals("1024x1024", info.width + "x" + info.height, "the icon's size", pos);
		Assert.equals(2, info.colorType, "the icon's color type", pos);
		Assert.equals(-1, info.chunks.indexOf("tRNS"), "the icon has a transparent color: " + info.chunks.join(","), pos);
		return info.colorType == 2;
	}

	private static function assertColor(expected:Int, image:Image, x:Int, y:Int, label:String, ?pos:haxe.PosInfos):Void
	{
		var actual = ImageFixture.read(image, x, y);
		Assert.isTrue(ImageFixture.sameColor(expected, actual, 1), label + ": expected " + ImageFixture.hex(expected) + " but was " + ImageFixture.hex(actual), pos);
	}

	/** The size and color type in the header of the PNG at `path`, and the types of its chunks in order **/
	private static function pngInfo(path:String):{width:Int, height:Int, colorType:Int, chunks:Array<String>}
	{
		var bytes = File.getBytes(path);
		var chunks = [];
		var position = 8;

		while (position + 8 <= bytes.length)
		{
			chunks.push(bytes.getString(position + 4, 4));
			position += 12 + bigEndian(bytes, position);
		}

		return {
			width: bigEndian(bytes, 16),
			height: bigEndian(bytes, 20),
			colorType: bytes.get(25),
			chunks: chunks
		};
	}

	private static function bigEndian(bytes:Bytes, position:Int):Int
	{
		return (bytes.get(position) << 24) | (bytes.get(position + 1) << 16) | (bytes.get(position + 2) << 8) | bytes.get(position + 3);
	}
	#end
}
