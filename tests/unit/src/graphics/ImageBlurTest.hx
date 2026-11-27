package graphics;

import graphics.ImageFixture.*;
import lime._internal.graphics.ImageDataUtil;
import lime.graphics.Image;
import lime.math.Vector2;
import utest.Assert;
import utest.Test;

/**
	`ImageDataUtil.gaussianBlur`, which blurs a bitmap for OpenFL's blur, glow and
	drop shadow filters.
**/
class ImageBlurTest extends Test
{
	public function new()
	{
		super();
	}

	// on Flash, the pixels of an Image are in a flash.display.BitmapData, not in the data this blur reads
	#if !flash
	public function testGaussianBlurOfTheAlphaAloneWritesTheSameAlpha():Void
	{
		var seed = 11;

		function next(n:Int):Int
		{
			seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
			return (seed >> 8) % n;
		}

		for (round in 0...60)
		{
			// two rows at least: the blur reads the row under the first one
			var width = 1 + next(24), height = 2 + next(24);
			var premultiplied = next(2) == 0;
			var colors = [for (i in 0...width * height) next(3) == 0 ? (next(256) << 24) | (next(256) << 16) | (next(256) << 8) | next(256) : 0];
			var blurX = next(4) == 0 ? 0 : next(33), blurY = next(4) == 0 ? 0 : next(33), quality = next(5);
			var message = "round " + round + ", " + width + "x" + height + ", blur " + blurX + "x" + blurY + ", quality " + quality;

			var whole = blurred(width, height, colors, premultiplied, blurX, blurY, quality, false);
			var alpha = blurred(width, height, colors, premultiplied, blurX, blurY, quality, true);
			var same = true, clear = true;

			for (i in 0...width * height)
			{
				if (alpha.data[i * 4 + 3] != whole.data[i * 4 + 3]) same = false;
				if (alpha.data[i * 4] != 0 || alpha.data[i * 4 + 1] != 0 || alpha.data[i * 4 + 2] != 0) clear = false;
			}

			Assert.isTrue(same, "another alpha, " + message);
			Assert.isTrue(clear, "a color left, " + message);
			Assert.equals(premultiplied, alpha.premultiplied);
		}
	}

	private static function blurred(width:Int, height:Int, colors:Array<Int>, premultiplied:Bool, blurX:Float, blurY:Float, quality:Int, alphaOnly:Bool):Image
	{
		var images = [];

		for (i in 0...2)
		{
			var image = create(width, height, 0, RGBA32, premultiplied);

			for (y in 0...height)
			{
				for (x in 0...width)
				{
					poke(image, x, y, colors[y * width + x]);
				}
			}

			images.push(image);
		}

		ImageDataUtil.gaussianBlur(images[0], images[1], images[1].rect, new Vector2(), blurX, blurY, quality, 1, null, alphaOnly);
		return images[0];
	}
	#end
}
