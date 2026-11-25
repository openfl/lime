package tools;

#if (sys && lime_cffi && !macro && (windows || mac || linux))
import graphics.ImageFixture;
import lime.graphics.PixelFormat;
import lime.tools.ImageHelper;
import sys.FileSystem;
import sys.io.File;
#end
import utest.Assert;
import utest.Test;

/**
	The command-line tools' image work, as `lime build` does it for icons.
**/
class ImageHelperTest extends Test
{
	public function new()
	{
		super();
	}

	#if (sys && lime_cffi && !macro && (windows || mac || linux))
	public function testAnSVGSizedOnlyByItsViewBoxFillsTheImage():Void
	{
		// An icon as design tools export it: a viewBox and no width or height. Its bottom-right quarter is red.
		var path = hxp.System.getTemporaryFile(".svg");
		File.saveContent(path, '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">'
			+ '<rect x="32" y="32" width="32" height="32" fill="#FF0000"/></svg>');

		var image = ImageHelper.rasterizeSVG(path, 32, 32);
		FileSystem.deleteFile(path);

		if (image == null)
		{
			// Rasterizing needs Neko (or Java), which a test machine may not have
			trace("No SVG rasterizer could run here, so SVG icons were not tested");
			Assert.pass();
			return;
		}

		Assert.equals("32x32", image.width + "x" + image.height);
		Assert.equals(0xFFFF0000, image.getPixel32(24, 24, ARGB32), "the bottom-right quarter of the viewBox was not drawn there: " + StringTools.hex(image.getPixel32(24, 24, ARGB32), 8));
		Assert.equals(0, image.getPixel32(8, 8, ARGB32) >>> 24, "the top-left quarter of the viewBox was not left empty: " + StringTools.hex(image.getPixel32(8, 8, ARGB32), 8));
	}

	// A PNG icon made smaller averages the source pixels each icon pixel covers, rather than
	// sampling a few of them (#1116). These go through IconHelper.createIcon(), as `lime build` does.

	public function testAnIconMadeSmallerAveragesThePixelsEachPixelCovers():Void
	{
		// Squares of one pixel, black and white, average to mid grey at any smaller size, where
		// sampling a few of them gives black, white or anything between
		for (size in [[256, 16], [1024, 36], [1024, 48], [192, 72], [1024, 192]])
		{
			var label = size[0] + " to " + size[1];
			var icon = createIcon(checkerboard(size[0]), size[1]);
			if (icon == null)
			{
				Assert.fail(label + ": no icon was written");
				continue;
			}

			Assert.equals(size[1] + "x" + size[1], icon.width + "x" + icon.height, label);
			assertAll(0xFF808080, icon, 8, label);
		}
	}

	public function testAThinLineKeepsItsShareOfThePixelsItCrosses():Void
	{
		// A white line one pixel wide down a black square of 256 pixels, made 16 pixels wide: each
		// pixel covers 16 columns, one of them white for the pixels the line crosses
		var source = ImageFixture.create(256, 256, 0xFF000000);
		for (y in 0...256)
		{
			ImageFixture.poke(source, 40, y, 0xFFFFFFFF);
		}

		var icon = createIcon(source, 16);
		if (icon == null)
		{
			Assert.fail("no icon was written");
			return;
		}

		var differences = [];
		for (y in 0...16)
		{
			for (x in 0...16)
			{
				// 255 / 16, so 16, for the pixels in columns 32 to 47 of the source
				var expected = (x == 2 ? 0xFF101010 : 0xFF000000);
				var actual = ImageFixture.read(icon, x, y);
				if (!ImageFixture.sameColor(expected, actual, 4)) differences.push(x + "," + y + " " + ImageFixture.hex(actual));
			}
		}

		Assert.isTrue(differences.length == 0, "pixels that are not a 16th white where the line is, and black elsewhere: " + differences.join("; "));
	}

	public function testTransparentPixelsAddNoColor():Void
	{
		// Each pixel of the smaller icon covers as many transparent red pixels as opaque blue ones. A
		// transparent pixel has no color to give, so the result is blue, half transparent, not purple.
		var source = ImageFixture.create(64, 64, 0);
		for (y in 0...64)
		{
			for (x in 0...64)
			{
				ImageFixture.poke(source, x, y, (x % 8 < 4) ? 0x00FF0000 : 0xFF0000FF);
			}
		}

		var icon = createIcon(source, 8);
		if (icon == null)
		{
			Assert.fail("no icon was written");
			return;
		}

		assertAll(0x800000FF, icon, 8, "64 to 8");
	}

	/** Writes `image` as a PNG icon, has the tools make it `size` pixels square, and reads that back **/
	private static function createIcon(image:lime.graphics.Image, size:Int):lime.graphics.Image
	{
		var source = hxp.System.getTemporaryFile(".png");
		var target = hxp.System.getTemporaryFile(".png");
		File.saveBytes(source, image.encode(lime.graphics.ImageFileFormat.PNG));

		var created = lime.tools.IconHelper.createIcon([new lime.tools.Icon(source)], size, size, target);
		var result = (created && FileSystem.exists(target)) ? lime.graphics.Image.fromFile(target) : null;

		FileSystem.deleteFile(source);
		if (FileSystem.exists(target)) FileSystem.deleteFile(target);
		return result;
	}

	private static function checkerboard(size:Int):lime.graphics.Image
	{
		var image = ImageFixture.create(size, size, 0xFF000000);
		for (y in 0...size)
		{
			for (x in 0...size)
			{
				if ((x + y) % 2 == 0) ImageFixture.poke(image, x, y, 0xFFFFFFFF);
			}
		}
		return image;
	}

	/** Checks every pixel of `image` is `expected`, an unmultiplied ARGB color, within `tolerance` **/
	private static function assertAll(expected:Int, image:lime.graphics.Image, tolerance:Int, label:String, ?pos:haxe.PosInfos):Void
	{
		var differences = [];
		for (y in 0...image.height)
		{
			for (x in 0...image.width)
			{
				var actual = ImageFixture.read(image, x, y);
				if (!ImageFixture.sameColor(expected, actual, tolerance) && differences.length < 10)
				{
					differences.push(x + "," + y + " " + ImageFixture.hex(actual));
				}
			}
		}

		Assert.isTrue(differences.length == 0, label + ": expected every pixel to be " + ImageFixture.hex(expected) + " within " + tolerance
			+ ", but " + differences.join("; "), pos);
	}
	#end
}
