package graphics;

#if (lime_cffi && lime_cairo && !macro)
import graphics.CairoFixture.*;
import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoFormat;
import lime.graphics.cairo.CairoImageSurface;
import lime.graphics.cairo.CairoOperator;
import lime.graphics.cairo.CairoPattern;
import lime.graphics.cairo.CairoStatus;
import lime.graphics.cairo.CairoSurface;
import lime.graphics.Image;
#end
import utest.Assert;
import utest.Test;

/**
	Image surfaces: those Cairo allocates, those made over memory it is
	given, and those made over a Lime `Image`. Sizes, formats, strides and
	the errors a bad size, format or stride gives are as the cairo manual
	has them (cairographics.org/manual/cairo-Image-Surfaces.html). ARGB32
	is a premultiplied 32-bit value in the machine's byte order, so blue,
	green, red and alpha in memory on the little-endian machines Lime
	builds for.

	A surface made over an image must draw into the part of the buffer the
	image says it uses, which `lime.graphics.Image` documents as its
	`offsetX`, `offsetY`, `width` and `height`.
**/
class CairoSurfaceTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_cairo && !macro)
	// Surfaces Cairo allocates

	public function testANewImageSurfaceHasTheSizeAndFormatAskedFor():Void
	{
		var surface = new CairoImageSurface(CairoFormat.ARGB32, 5, 3);

		Assert.equals(5, surface.width);
		Assert.equals(3, surface.height);
		Assert.equals(CairoFormat.ARGB32, surface.format);
		Assert.equals(20, surface.stride);
	}

	public function testEveryFormatIsReadBackWithARowWideEnoughForIt():Void
	{
		// The fewest bytes a row of 33 pixels can take in each format
		var formats:Array<Array<Int>> = [
			[CairoFormat.ARGB32, 132],
			[CairoFormat.RGB24, 132],
			[CairoFormat.A8, 33],
			[CairoFormat.A1, 5],
			[CairoFormat.RGB16_565, 66],
			[CairoFormat.RGB30, 132]
		];

		for (entry in formats)
		{
			var surface = new CairoImageSurface(entry[0], 33, 2);
			var label = "format " + entry[0];

			Assert.equals(entry[0], (surface.format : Int), label);
			Assert.equals(33, surface.width, label);
			Assert.equals(2, surface.height, label);
			Assert.isTrue(surface.stride >= entry[1], label + " has a stride of " + surface.stride);
			Assert.equals(CairoStatus.SUCCESS, new Cairo(surface).status(), label);
		}
	}

	public function testANewImageSurfaceIsTransparent():Void
	{
		var surface = new CairoImageSurface(CairoFormat.ARGB32, 3, 2);

		copyOf(surface, 3, 2).assertRows(["...", "..."]);
	}

	public function testWhatIsDrawnOnASurfaceCanBePaintedFromIt():Void
	{
		var surface = new CairoImageSurface(CairoFormat.ARGB32, 3, 2);
		var cairo = new Cairo(surface);

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(2, 1, 1, 1);
		cairo.fill();
		surface.flush();

		copyOf(surface, 3, 2).assertRows(["...", "..R"]);
	}

	public function testAnAlphaSurfaceKeepsOnlyAlpha():Void
	{
		var surface = new CairoImageSurface(CairoFormat.A8, 2, 1);
		var cairo = new Cairo(surface);

		cairo.setSourceRGBA(1, 0, 0, 0.5);
		cairo.paint();

		var copy = copyOf(surface, 2, 1);
		copy.assertPixel(0x80000000, 0, 0, 1);
		copy.assertPixel(0x80000000, 1, 0, 1);
	}

	public function testAOneBitSurfaceKeepsAlphaAsOnOrOff():Void
	{
		var surface = new CairoImageSurface(CairoFormat.A1, 2, 1);
		var cairo = new Cairo(surface);

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 1, 1);
		cairo.fill();

		copyOf(surface, 2, 1).assertRows(["K."]);
	}

	public function testAColorOnlySurfaceIsOpaque():Void
	{
		for (format in [CairoFormat.RGB24, CairoFormat.RGB30])
		{
			var surface = new CairoImageSurface(format, 2, 1);
			var cairo = new Cairo(surface);

			cairo.setSourceRGBA(1, 0.5, 0.25, 1);
			cairo.rectangle(0, 0, 1, 1);
			cairo.fill();

			var copy = copyOf(surface, 2, 1);
			copy.assertPixel(0xFFFF8040, 0, 0, 1, "format " + format);
			copy.assertPixel(BLACK, 1, 0, "format " + format);
		}
	}

	public function testASixteenBitSurfaceKeepsFiveSixAndFiveBitsOfColor():Void
	{
		var surface = new CairoImageSurface(CairoFormat.RGB16_565, 1, 1);
		var cairo = new Cairo(surface);

		cairo.setSourceRGB(1, 0.5, 0.25);
		cairo.paint();

		// Green has 64 levels and red and blue 32, so none is off by more than 255 / 31
		var copy = copyOf(surface, 1, 1);
		copy.assertPixel(0xFFFF8040, 0, 0, 8);
		Assert.notEquals(0xFFFF8040, copy.pixel(0, 0));
	}

	public function testAnImageSurfaceGivesTheAddressOfItsPixels():Void
	{
		var surface = new CairoImageSurface(CairoFormat.ARGB32, 2, 2);
		var address:Float = surface.data;

		Assert.isTrue(address != 0);
	}

	// Surfaces over memory

	public function testCreateTakesTheFormatThenTheSizeThenTheStride():Void
	{
		// Two rows of an 8-bit surface 8 bytes apart, seen as one row of two 32-bit pixels
		var owner = new CairoImageSurface(CairoFormat.A8, 8, 1);
		var cairo = new Cairo(owner);
		cairo.rectangle(4, 0, 4, 1);
		cairo.fill();
		owner.flush();

		var surface:CairoImageSurface = CairoImageSurface.create(owner.data, CairoFormat.ARGB32, 2, 1, 8);

		Assert.equals(2, surface.width);
		Assert.equals(1, surface.height);
		Assert.equals(8, surface.stride);
		copyOf(surface, 2, 1).assertRows([".W"]);
	}

	// Surfaces over an image

	public function testFromImageHasTheSizeOfTheImage():Void
	{
		var image = ImageFixture.create(5, 3, 0, BGRA32, true);
		var surface:CairoImageSurface = CairoImageSurface.fromImage(image);

		Assert.equals(5, surface.width);
		Assert.equals(3, surface.height);
		Assert.equals(CairoFormat.ARGB32, surface.format);
		Assert.equals(20, surface.stride);
	}

	public function testFromImageDrawsIntoTheBytesOfTheImage():Void
	{
		var image = ImageFixture.create(4, 3, 0, BGRA32, true);
		var surface = CairoImageSurface.fromImage(image);
		var cairo = new Cairo(surface);

		cairo.setSourceRGBA(1, 0, 0.5, 1);
		cairo.rectangle(2, 1, 1, 1);
		cairo.fill();
		surface.flush();

		var data = image.buffer.data;
		var offset = (1 * 4 + 2) * 4;

		// Blue, green, red and alpha, in that order
		Assert.equals(0x80, data[offset]);
		Assert.equals(0x00, data[offset + 1]);
		Assert.equals(0xFF, data[offset + 2]);
		Assert.equals(0xFF, data[offset + 3]);

		for (i in 0...data.length)
		{
			if (i < offset || i >= offset + 4) Assert.equals(0, data[i], "byte " + i);
		}
	}

	public function testFromImageStoresColorsMultipliedByTheirAlpha():Void
	{
		var image = ImageFixture.create(1, 1, 0, BGRA32, true);
		var surface = CairoImageSurface.fromImage(image);
		var cairo = new Cairo(surface);

		cairo.setSourceRGBA(1, 0.5, 0, 0.5);
		cairo.paint();
		surface.flush();

		ImageFixture.assertColor(0x80804000, ImageFixture.peek(image, 0, 0), 1);
		ImageFixture.assertColor(0x80FF8000, ImageFixture.read(image, 0, 0), 3);
	}

	public function testPixelsWrittenToTheImageArePaintedFromItsSurface():Void
	{
		var image = ImageFixture.create(2, 1, 0, BGRA32, true);
		var surface = CairoImageSurface.fromImage(image);

		ImageFixture.poke(image, 0, 0, GREEN);
		ImageFixture.poke(image, 1, 0, BLUE);

		copyOf(surface, 2, 1).assertRows(["GB"]);
	}

	public function testFromImageCoversThePartOfTheBufferTheImageUses():Void
	{
		var whole = ImageFixture.create(4, 3, 0, BGRA32, true);
		var part = new Image(whole.buffer, 2, 1, 2, 2);
		var surface:CairoImageSurface = CairoImageSurface.fromImage(part);

		Assert.equals(2, surface.width);
		Assert.equals(2, surface.height);

		var cairo = new Cairo(surface);
		cairo.setSourceRGB(1, 0, 0);
		cairo.paint();
		surface.flush();

		ImageFixture.assertPixels([
			0, 0, 0, 0,
			0, 0, RED, RED,
			0, 0, RED, RED
		], whole);
	}

	// Flush

	public function testFlushLeavesTheSurfaceReadyForMoreDrawing():Void
	{
		var fixture = new CairoFixture(3, 1);
		var cairo = fixture.cairo;

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 1, 1);
		cairo.fill();
		fixture.surface.flush();
		fixture.surface.flush();
		cairo.setSourceRGB(0, 0, 1);
		cairo.rectangle(2, 0, 1, 1);
		cairo.fill();

		Assert.equals(CairoStatus.SUCCESS, cairo.status());
		fixture.assertRows(["R.B"]);
	}

	// Errors

	public function testASurfaceWithAnImpossibleSizeIsInError():Void
	{
		var surface = new CairoImageSurface(CairoFormat.ARGB32, -1, 4);

		Assert.equals(CairoStatus.INVALID_SIZE, new Cairo(surface).status());
		Assert.equals(0, surface.width);
		Assert.equals(0, surface.height);
	}

	public function testASurfaceWithAnUnknownFormatIsInError():Void
	{
		var surface = new CairoImageSurface(CairoFormat.INVALID, 4, 4);

		Assert.equals(CairoStatus.INVALID_FORMAT, new Cairo(surface).status());
	}

	public function testASurfaceWithAStrideTooSmallForItsRowsIsInError():Void
	{
		var owner = new CairoImageSurface(CairoFormat.ARGB32, 4, 4);
		var narrow = CairoImageSurface.create(owner.data, CairoFormat.ARGB32, 4, 4, 8);
		var uneven = CairoImageSurface.create(owner.data, CairoFormat.ARGB32, 4, 4, 18);

		Assert.equals(CairoStatus.INVALID_STRIDE, new Cairo(narrow).status());
		Assert.equals(CairoStatus.INVALID_STRIDE, new Cairo(uneven).status());
	}

	public function testDrawingOnASurfaceInErrorDoesNothing():Void
	{
		var cairo = new Cairo(new CairoImageSurface(CairoFormat.ARGB32, -1, -1));

		cairo.setSourceRGB(1, 0, 0);
		cairo.rectangle(0, 0, 4, 4);
		cairo.fill();
		cairo.paint();

		Assert.equals(CairoStatus.INVALID_SIZE, cairo.status());
	}

	// Lifetimes

	public function testAContextKeepsItsSurface():Void
	{
		var cairo = contextOnADroppedSurface();
		collect();

		cairo.setSourceRGB(0, 1, 0);
		cairo.paint();

		Assert.equals(CairoStatus.SUCCESS, cairo.status());
		copyOf(cairo.target, 4, 4).assertRows(["GGGG", "GGGG", "GGGG", "GGGG"]);
	}

	public function testAPatternKeepsItsSurface():Void
	{
		var pattern = patternOfADroppedSurface();
		collect();

		var fixture = new CairoFixture(2, 2);
		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		fixture.assertRows(["RR", "RR"]);
	}

	public function testASourceOutlivesTheContextItWasReadFrom():Void
	{
		var source = sourceOfADroppedContext();
		collect();

		var fixture = new CairoFixture(2, 1);
		fixture.cairo.source = source;
		fixture.cairo.paint();

		fixture.assertRows(["BB"]);
	}

	public function testATargetOutlivesTheContextItWasReadFrom():Void
	{
		var target = targetOfADroppedContext();
		collect();

		copyOf(target, 2, 1).assertRows(["RR"]);
	}

	public function testDroppedObjectsAreReleasedWithoutHarmToThoseStillInUse():Void
	{
		var fixture = new CairoFixture(4, 4);
		var pattern = CairoPattern.createRGB(1, 0, 0);

		for (round in 0...8)
		{
			for (i in 0...64)
			{
				var surface = new CairoImageSurface(CairoFormat.ARGB32, 16, 16);
				var cairo = new Cairo(surface);
				cairo.source = pattern;
				cairo.paint();
				cairo.pushGroup();
				cairo.setSourceSurface(fixture.surface, 0, 0);
				cairo.paint();
				cairo.popGroup();
				cairo.source;
				cairo.target;
				CairoPattern.createForSurface(surface);
				CairoPattern.createLinear(0, 0, 1, 1).addColorStopRGB(0, 1, 1, 1);
			}

			collect();
		}

		fixture.cairo.source = pattern;
		fixture.cairo.paint();

		Assert.equals(CairoStatus.SUCCESS, fixture.cairo.status());
		fixture.assertRows(["RRRR", "RRRR", "RRRR", "RRRR"]);
	}

	// Each of these leaves the object it made in a call that has returned,
	// so that nothing on the stack still refers to it

	private static function contextOnADroppedSurface():Cairo
	{
		return new Cairo(new CairoImageSurface(CairoFormat.ARGB32, 4, 4));
	}

	private static function patternOfADroppedSurface():CairoPattern
	{
		var surface = new CairoImageSurface(CairoFormat.ARGB32, 2, 2);
		var cairo = new Cairo(surface);
		cairo.setSourceRGB(1, 0, 0);
		cairo.paint();

		return CairoPattern.createForSurface(surface);
	}

	private static function sourceOfADroppedContext():CairoPattern
	{
		var cairo = new Cairo(new CairoImageSurface(CairoFormat.ARGB32, 2, 2));
		cairo.setSourceRGB(0, 0, 1);

		return cairo.source;
	}

	private static function targetOfADroppedContext():CairoSurface
	{
		var cairo = new Cairo(new CairoImageSurface(CairoFormat.ARGB32, 2, 1));
		cairo.setSourceRGB(1, 0, 0);
		cairo.paint();

		return cairo.target;
	}
	#end
}
