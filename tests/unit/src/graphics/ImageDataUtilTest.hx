package graphics;

import lime._internal.graphics.ImageDataUtil;
import lime.graphics.Image;
import lime.math.Vector2;
import utest.Assert;
import utest.Test;

class ImageDataUtilTest extends Test
{
	public function new()
	{
		super();
	}

	// on Flash, the pixels of an Image are in a flash.display.BitmapData, not in the data this blur reads
	#if !flash
	public function testGaussianBlurMultipliesTheBlurredAlphaByTheStrength()
	{
		var plain = blurredDot(1);
		var strong = blurredDot(4);

		var edge = plain.getPixel32(5, 4) & 0xFF;
		Assert.isTrue(edge > 0 && edge < 0x40, "the blur did not spread the dot: " + edge);
		Assert.equals(edge * 4, strong.getPixel32(5, 4) & 0xFF);

		var far = plain.getPixel32(6, 4) & 0xFF;
		Assert.equals(Std.int(Math.min(0xFF, far * 4)), strong.getPixel32(6, 4) & 0xFF);

		// the alpha stays within a byte
		Assert.equals(0xFF, blurredDot(255).getPixel32(4, 4) & 0xFF);
	}

	private static function blurredDot(strength:Float):Image
	{
		var source = new Image(null, 0, 0, 9, 9, 0x00000000);
		source.setPixel32(4, 4, 0xFFFFFFFF);
		var image = new Image(null, 0, 0, 9, 9, 0x00000000);
		ImageDataUtil.gaussianBlur(image, source, source.rect, new Vector2(), 4, 4, 1, strength);
		return image;
	}
	#end
}
