package tools;

#if (sys && lime_cffi && !macro && (windows || mac || linux))
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
	#end
}
