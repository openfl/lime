package text;

import lime.text.Font;
import utest.Assert;
import utest.Test;

/**
	assets/mono.ttf is a subset of Noto Mono, under the SIL Open Font License
	in assets/mono-OFL.txt.
**/
class FontTest extends Test
{
	private static inline var PATH = "assets/mono.ttf";

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	public function testRenderGlyphsGivesEachGlyphItsCoverage():Void
	{
		var font = Font.fromFile(PATH);
		if (font == null)
		{
			Assert.fail("cannot open " + PATH);
			return;
		}

		var glyphs = font.getGlyphs("0123456789");
		var images = font.renderGlyphs(glyphs, 24);
		Assert.notNull(images);
		if (images == null) return;

		var buffer = null;

		for (glyph in glyphs)
		{
			var image = images.get(glyph);
			Assert.notNull(image, "glyph " + glyph + " was not rendered");
			if (image == null) continue;

			// Every glyph shares one 8-bit atlas, and lies inside it
			if (buffer == null) buffer = image.buffer;
			Assert.equals(buffer, image.buffer);
			Assert.equals(8, image.buffer.bitsPerPixel);
			Assert.isTrue(image.width > 0 && image.height > 0);
			Assert.isTrue(image.offsetX + image.width <= buffer.width && image.offsetY + image.height <= buffer.height);

			// A digit covers some of its box fully, and leaves some of it empty
			var covered = 0;
			var empty = 0;

			for (y in 0...image.height)
			{
				for (x in 0...image.width)
				{
					var coverage = buffer.data[(image.offsetY + y) * buffer.width + image.offsetX + x];
					if (coverage > 200) covered++;
					if (coverage == 0) empty++;
				}
			}

			Assert.isTrue(covered > 0, "glyph " + glyph + " has no coverage");
			Assert.isTrue(empty > 0, "glyph " + glyph + " covers its whole box");
		}
	}
	#end
}
