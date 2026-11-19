package graphics;

#if (lime_cffi && lime_cairo && !macro)
import graphics.CairoFixture.*;
import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoAntialias;
import lime.graphics.cairo.CairoFontFace;
import lime.graphics.cairo.CairoFontOptions;
import lime.graphics.cairo.CairoFTFontFace;
import lime.graphics.cairo.CairoGlyph;
import lime.graphics.cairo.CairoHintMetrics;
import lime.graphics.cairo.CairoHintStyle;
import lime.graphics.cairo.CairoStatus;
import lime.graphics.cairo.CairoSubpixelOrder;
import lime.text.Font;
#end
import utest.Assert;
import utest.Test;

/**
	Text drawn with a font face made from a `lime.text.Font`. Where text is
	placed, how the current point moves and what the font options change are
	as the cairo manual gives them for `cairo_show_text()`,
	`cairo_show_glyphs()`, `cairo_text_path()`, `cairo_font_options_t` and
	`cairo_ft_font_face_create_for_ft_face()`
	(cairographics.org/manual/cairo-text.html, cairo-cairo-font-options-t.html
	and cairo-FreeType-Fonts.html).

	assets/mono.ttf is a subset of Noto Mono holding the printable ASCII
	characters, under the SIL Open Font License in assets/mono-OFL.txt. It
	has 2048 units to the em, capitals 1462 units tall and an advance of 1229
	units for every glyph. Text is drawn in black on white.
**/
class CairoTextTest extends Test
{
	#if (lime_cffi && lime_cairo && !macro)
	private static inline var PATH = "assets/mono.ttf";
	private static inline var CAPITAL_HEIGHT = 1462 / 2048;
	private static inline var ADVANCE = 1229 / 2048;

	// FT_LOAD_VERTICAL_LAYOUT in FreeType's freetype.h
	private static inline var VERTICAL_LAYOUT = 1 << 4;
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_cairo && !macro)
	// Font faces

	public function testAFontFaceMadeFromAFontHasNoError():Void
	{
		var face = CairoFTFontFace.create(font(), 0);
		Assert.notNull(face);

		var plain:CairoFontFace = face;
		Assert.equals(CairoStatus.SUCCESS, plain.status());
		Assert.equals(1 << 5, CairoFTFontFace.FT_LOAD_FORCE_AUTOHINT);
	}

	public function testAContextHasAFontFaceBeforeOneIsSet():Void
	{
		var face = new CairoFixture(4, 4).cairo.fontFace;

		Assert.notNull(face);
		if (face != null) Assert.equals(CairoStatus.SUCCESS, face.status());
	}

	public function testFontFaceGivesBackTheFaceThatWasSet():Void
	{
		var first = text(32);
		first.cairo.moveTo(10, 40);
		first.cairo.showText("Hg");

		var face = first.cairo.fontFace;
		Assert.notNull(face);
		if (face == null) return;
		Assert.equals(CairoStatus.SUCCESS, face.status());

		var second = new CairoFixture(64, 48, WHITE);
		second.cairo.fontFace = face;
		second.cairo.setFontSize(32);
		second.cairo.moveTo(10, 40);
		second.cairo.showText("Hg");

		Assert.isTrue(inkBounds(first) != null);
		Assert.same(first.pixels(), second.pixels());
	}

	public function testLoadFlagsReachTheFontFace():Void
	{
		var fixture = new CairoFixture(64, 64, WHITE);
		var cairo = fixture.cairo;

		// The one flag the manual says changes where glyphs go: each is
		// placed below the last rather than beside it
		cairo.fontFace = CairoFTFontFace.create(font(), VERTICAL_LAYOUT);
		cairo.setFontSize(16);
		cairo.moveTo(30, 10);
		cairo.showText("H");

		Assert.equals(CairoStatus.SUCCESS, cairo.status());
		Assert.floatEquals(30.0, cairo.currentPoint.x);
		Assert.isTrue(cairo.currentPoint.y > 10 + 8, "the current point is at " + cairo.currentPoint.x + ", " + cairo.currentPoint.y);
	}

	public function testAFontFaceKeepsItsFont():Void
	{
		var face = faceOfADroppedFont();
		collect();

		var fixture = new CairoFixture(64, 48, WHITE);
		fixture.cairo.fontFace = face;
		fixture.cairo.setFontSize(32);
		fixture.cairo.moveTo(10, 40);
		fixture.cairo.showText("H");

		Assert.equals(CairoStatus.SUCCESS, fixture.cairo.status());
		Assert.same(pixelsOf("H", 32), fixture.pixels());
	}

	// Font options

	public function testNewFontOptionsHaveEveryDefault():Void
	{
		var options = new CairoFontOptions();

		Assert.equals(CairoAntialias.DEFAULT, options.antialias);
		Assert.equals(CairoHintMetrics.DEFAULT, options.hintMetrics);
		Assert.equals(CairoHintStyle.DEFAULT, options.hintStyle);
		Assert.equals(CairoSubpixelOrder.DEFAULT, options.subpixelOrder);
	}

	public function testEveryFontAntialiasModeIsReadBackAsSet():Void
	{
		var options = new CairoFontOptions();
		var modes = [
			CairoAntialias.NONE,
			CairoAntialias.GRAY,
			CairoAntialias.SUBPIXEL,
			CairoAntialias.FAST,
			CairoAntialias.GOOD,
			CairoAntialias.BEST,
			CairoAntialias.DEFAULT
		];

		for (mode in modes)
		{
			Assert.equals(mode, options.antialias = mode);
			Assert.equals(mode, options.antialias);
		}
	}

	public function testEveryHintMetricsModeIsReadBackAsSet():Void
	{
		var options = new CairoFontOptions();

		for (mode in [CairoHintMetrics.OFF, CairoHintMetrics.ON, CairoHintMetrics.DEFAULT])
		{
			Assert.equals(mode, options.hintMetrics = mode);
			Assert.equals(mode, options.hintMetrics);
		}
	}

	public function testEveryHintStyleIsReadBackAsSet():Void
	{
		var options = new CairoFontOptions();
		var styles = [
			CairoHintStyle.NONE,
			CairoHintStyle.SLIGHT,
			CairoHintStyle.MEDIUM,
			CairoHintStyle.FULL,
			CairoHintStyle.DEFAULT
		];

		for (style in styles)
		{
			Assert.equals(style, options.hintStyle = style);
			Assert.equals(style, options.hintStyle);
		}
	}

	public function testEverySubpixelOrderIsReadBackAsSet():Void
	{
		var options = new CairoFontOptions();
		var orders = [
			CairoSubpixelOrder.RGB,
			CairoSubpixelOrder.BGR,
			CairoSubpixelOrder.VRGB,
			CairoSubpixelOrder.VBGR,
			CairoSubpixelOrder.DEFAULT
		];

		for (order in orders)
		{
			Assert.equals(order, options.subpixelOrder = order);
			Assert.equals(order, options.subpixelOrder);
		}
	}

	public function testEachFontOptionKeepsItsOwnValue():Void
	{
		var options = new CairoFontOptions();

		options.antialias = CairoAntialias.SUBPIXEL;
		options.hintMetrics = CairoHintMetrics.ON;
		options.hintStyle = CairoHintStyle.NONE;
		options.subpixelOrder = CairoSubpixelOrder.VBGR;

		Assert.equals(CairoAntialias.SUBPIXEL, options.antialias);
		Assert.equals(CairoHintMetrics.ON, options.hintMetrics);
		Assert.equals(CairoHintStyle.NONE, options.hintStyle);
		Assert.equals(CairoSubpixelOrder.VBGR, options.subpixelOrder);
	}

	public function testFontOptionsSetOnAContextAreReadBack():Void
	{
		var cairo = new CairoFixture(4, 4).cairo;
		var options = new CairoFontOptions();
		options.antialias = CairoAntialias.NONE;
		options.hintMetrics = CairoHintMetrics.OFF;
		options.hintStyle = CairoHintStyle.FULL;
		options.subpixelOrder = CairoSubpixelOrder.BGR;

		cairo.fontOptions = options;
		var read = cairo.fontOptions;

		Assert.notNull(read);
		if (read == null) return;

		Assert.equals(CairoAntialias.NONE, read.antialias);
		Assert.equals(CairoHintMetrics.OFF, read.hintMetrics);
		Assert.equals(CairoHintStyle.FULL, read.hintStyle);
		Assert.equals(CairoSubpixelOrder.BGR, read.subpixelOrder);
	}

	public function testAContextWithoutFontOptionsGivesDefaults():Void
	{
		var read = new CairoFixture(4, 4).cairo.fontOptions;

		Assert.notNull(read);
		if (read == null) return;

		Assert.equals(CairoAntialias.DEFAULT, read.antialias);
		Assert.equals(CairoHintMetrics.DEFAULT, read.hintMetrics);
		Assert.equals(CairoHintStyle.DEFAULT, read.hintStyle);
		Assert.equals(CairoSubpixelOrder.DEFAULT, read.subpixelOrder);
	}

	public function testFontAntialiasingShadesTheEdgesOfGlyphsUnlessTurnedOff():Void
	{
		var shaded = text(32);
		shaded.cairo.moveTo(10, 40);
		shaded.cairo.showText("S");

		Assert.isTrue(shades(shaded) > 0, "no pixel of an antialiased glyph is between black and white");

		var options = new CairoFontOptions();
		options.antialias = CairoAntialias.NONE;

		var plain = text(32);
		plain.cairo.fontOptions = options;
		plain.cairo.moveTo(10, 40);
		plain.cairo.showText("S");

		Assert.notNull(inkBounds(plain));
		Assert.equals(0, shades(plain));
	}

	public function testHintedMetricsAdvanceByWholePixels():Void
	{
		// 12.6 pixels at this size
		var size = 21;
		var exact = ADVANCE * size;

		var options = new CairoFontOptions();
		options.hintMetrics = CairoHintMetrics.ON;

		var hinted = text(size);
		hinted.cairo.fontOptions = options;
		hinted.cairo.moveTo(10, 40);
		hinted.cairo.showText("H");

		var advance = hinted.cairo.currentPoint.x - 10;
		Assert.floatEquals(Math.fround(advance), advance);
		Assert.isTrue(Math.abs(advance - exact) < 1, "advanced by " + advance);

		options.hintMetrics = CairoHintMetrics.OFF;

		var unhinted = text(size);
		unhinted.cairo.fontOptions = options;
		unhinted.cairo.moveTo(10, 40);
		unhinted.cairo.showText("H");

		Assert.floatEquals(exact, unhinted.cairo.currentPoint.x - 10, 0.02);
	}

	// Showing text

	public function testShowTextSetsTheTextOnTheCurrentPoint():Void
	{
		var fixture = text(32);

		fixture.cairo.moveTo(10, 40);
		fixture.cairo.showText("H");

		Assert.equals(CairoStatus.SUCCESS, fixture.cairo.status());

		var ink = inkBounds(fixture);
		Assert.notNull(ink);
		if (ink == null) return;

		// An H stands on the baseline, as tall as a capital, within its advance
		Assert.isTrue(Math.abs(ink.bottom - 40) <= 1, "the ink ends at row " + ink.bottom);
		Assert.isTrue(Math.abs((ink.bottom - ink.top) - CAPITAL_HEIGHT * 32) <= 1.5, "the ink is " + (ink.bottom - ink.top) + " rows tall");
		Assert.isTrue(ink.left >= 10, "the ink starts at column " + ink.left);
		Assert.isTrue(ink.right <= 10 + ADVANCE * 32 + 1, "the ink ends at column " + ink.right);
	}

	public function testSetFontSizeSetsTheHeightOfAnEmInUserSpace():Void
	{
		for (size in [16, 32, 48])
		{
			var fixture = text(size, 96, 64);
			fixture.cairo.moveTo(10, 56);
			fixture.cairo.showText("H");

			var ink = inkBounds(fixture);
			Assert.notNull(ink);
			if (ink == null) continue;

			Assert.isTrue(Math.abs((ink.bottom - ink.top) - CAPITAL_HEIGHT * size) <= 1.5, "at size " + size + " the ink is " + (ink.bottom - ink.top) + " rows tall");
		}
	}

	public function testShowTextMovesTheCurrentPointPastTheText():Void
	{
		var options = new CairoFontOptions();
		options.hintMetrics = CairoHintMetrics.OFF;

		var one = text(32);
		one.cairo.fontOptions = options;
		one.cairo.moveTo(10, 40);
		one.cairo.showText("H");

		Assert.isTrue(one.cairo.hasCurrentPoint);
		Assert.floatEquals(10 + ADVANCE * 32, one.cairo.currentPoint.x, 0.02);
		Assert.floatEquals(40.0, one.cairo.currentPoint.y);

		var three = text(32, 128, 48);
		three.cairo.fontOptions = options;
		three.cairo.moveTo(10, 40);
		three.cairo.showText("H.i");

		Assert.floatEquals(10 + 3 * ADVANCE * 32, three.cairo.currentPoint.x, 0.05);
		Assert.floatEquals(40.0, three.cairo.currentPoint.y);
	}

	public function testShowTextSetsEachCharacterAfterTheLast():Void
	{
		var fixture = text(32, 96, 48);

		fixture.cairo.moveTo(10, 40);
		fixture.cairo.showText("H");
		var advance = Std.int(fixture.cairo.currentPoint.x - 10);
		fixture.cairo.showText("H");

		// Advances are whole pixels on an image unless hinting is turned
		// off, so the second letter is the first one moved along
		Assert.isTrue(advance >= 18 && advance <= 20, "advanced by " + advance);

		var differences = 0;

		for (y in 0...48)
		{
			for (x in 10...10 + advance)
			{
				if (fixture.pixel(x, y) != fixture.pixel(x + advance, y)) differences++;
			}
		}

		Assert.equals(0, differences);
		Assert.floatEquals(10.0 + 2 * advance, fixture.cairo.currentPoint.x);
	}

	public function testShowTextPaintsWithTheSource():Void
	{
		var fixture = new CairoFixture(64, 48);
		fixture.cairo.fontFace = CairoFTFontFace.create(font(), 0);
		fixture.cairo.setFontSize(32);
		fixture.cairo.setSourceRGB(1, 0, 0);
		fixture.cairo.moveTo(10, 40);
		fixture.cairo.showText("H");

		var solid = 0;

		for (color in fixture.pixels())
		{
			if (color == RED) solid++;

			// Red at any coverage, premultiplied, has red equal to its alpha and nothing else
			Assert.isTrue((color & 0xFFFF) == 0 && (color >>> 24) == ((color >> 16) & 0xFF), "a pixel is " + ImageFixture.hex(color));
		}

		Assert.isTrue(solid > 32, solid + " pixels are solid red");
	}

	public function testShowTextOfNothingDrawsNothing():Void
	{
		var fixture = text(32);

		fixture.cairo.moveTo(10, 40);
		fixture.cairo.showText("");

		Assert.equals(CairoStatus.SUCCESS, fixture.cairo.status());
		Assert.isNull(inkBounds(fixture));
		assertPoint(10, 40, fixture.cairo.currentPoint);
	}

	public function testShowTextOfNullDrawsNothing():Void
	{
		var fixture = text(32);

		fixture.cairo.moveTo(10, 40);
		fixture.cairo.showText(null);

		Assert.equals(CairoStatus.SUCCESS, fixture.cairo.status());
		Assert.isNull(inkBounds(fixture));
	}

	public function testShowTextFollowsTheTransformation():Void
	{
		var scaled = text(16);
		scaled.cairo.scale(2, 2);
		scaled.cairo.moveTo(5, 20);
		scaled.cairo.showText("Hg");

		Assert.same(pixelsOf("Hg", 32), scaled.pixels());
	}

	// Showing glyphs

	public function testShowGlyphsDrawsEachGlyphAtItsOwnPosition():Void
	{
		var shown = text(32, 96, 64);
		shown.cairo.moveTo(10, 30);
		shown.cairo.showText("H");
		shown.cairo.moveTo(50, 60);
		shown.cairo.showText("g");

		var fixture = text(32, 96, 64);
		fixture.cairo.showGlyphs([new CairoGlyph(font().getGlyph("H"), 10, 30), new CairoGlyph(font().getGlyph("g"), 50, 60)]);

		Assert.equals(CairoStatus.SUCCESS, fixture.cairo.status());
		Assert.notNull(inkBounds(fixture));
		Assert.same(shown.pixels(), fixture.pixels());
	}

	public function testShowGlyphsOfNoGlyphsDrawsNothing():Void
	{
		var fixture = text(32);

		fixture.cairo.showGlyphs([]);

		Assert.equals(CairoStatus.SUCCESS, fixture.cairo.status());
		Assert.isNull(inkBounds(fixture));
	}

	// Text paths

	public function testTextPathAddsTheOutlineOfTheTextToThePath():Void
	{
		var shown = text(32);
		shown.cairo.moveTo(10, 40);
		shown.cairo.showText("H");

		var fixture = text(32);
		fixture.cairo.moveTo(10, 40);
		fixture.cairo.textPath("H");

		Assert.isTrue(fixture.cairo.hasCurrentPoint);
		Assert.isNull(inkBounds(fixture), "the path was drawn before it was filled");
		assertPoint(shown.cairo.currentPoint.x, 40, fixture.cairo.currentPoint);

		fixture.cairo.fill();

		// Filled, the outline covers what showing the text covers, give or
		// take the shade of a pixel on its edge
		var differences = 0;

		for (y in 0...48)
		{
			for (x in 0...64)
			{
				var a = shown.pixel(x, y);
				var b = fixture.pixel(x, y);

				if ((a == BLACK && (b & 0xFF) > 0x80) || (a == WHITE && (b & 0xFF) < 0x80)) differences++;
			}
		}

		Assert.notNull(inkBounds(fixture));
		Assert.equals(0, differences);
	}

	public function testTextPathCanBeTestedForHits():Void
	{
		var fixture = text(32);
		fixture.cairo.moveTo(10, 40);
		fixture.cairo.showText("H");
		var ink = inkBounds(fixture);
		if (ink == null)
		{
			Assert.fail("no text was drawn");
			return;
		}

		var cairo = text(32).cairo;
		cairo.moveTo(10, 40);
		cairo.textPath("H");

		// The crossbar of an H is halfway up, and nothing is between its
		// stems above that
		var middle = (ink.left + ink.right) / 2;
		Assert.isTrue(cairo.inFill(ink.left + 1.5, ink.top + 2), "the left stem");
		Assert.isTrue(cairo.inFill(ink.right - 1.5, ink.bottom - 2), "the right stem");
		Assert.isFalse(cairo.inFill(middle, ink.top + 2), "between the stems");
		Assert.isFalse(cairo.inFill(ink.left - 2, ink.top + 2), "left of the letter");
	}

	private static function font():Font
	{
		var font = Font.fromFile(PATH);
		if (font == null) throw "cannot open " + PATH;
		return font;
	}

	// A white image with the font set at a size, ready to draw black text
	private static function text(size:Float, width:Int = 64, height:Int = 48):CairoFixture
	{
		var fixture = new CairoFixture(width, height, WHITE);
		fixture.cairo.fontFace = CairoFTFontFace.create(font(), 0);
		fixture.cairo.setFontSize(size);
		return fixture;
	}

	private static function pixelsOf(string:String, size:Float):Array<Int>
	{
		var fixture = text(size);
		fixture.cairo.moveTo(10, 40);
		fixture.cairo.showText(string);
		return fixture.pixels();
	}

	private static function faceOfADroppedFont():CairoFontFace
	{
		return CairoFTFontFace.create(font(), 0);
	}

	// The rows and columns that hold anything but the white background,
	// with right and bottom one past the last
	private static function inkBounds(fixture:CairoFixture):{left:Int, top:Int, right:Int, bottom:Int}
	{
		var left = fixture.image.width;
		var top = fixture.image.height;
		var right = 0;
		var bottom = 0;

		for (y in 0...fixture.image.height)
		{
			for (x in 0...fixture.image.width)
			{
				if (fixture.pixel(x, y) == WHITE) continue;

				if (x < left) left = x;
				if (y < top) top = y;
				if (x + 1 > right) right = x + 1;
				if (y + 1 > bottom) bottom = y + 1;
			}
		}

		return right > left ? {left: left, top: top, right: right, bottom: bottom} : null;
	}

	// How many pixels are neither the black of the text nor the white behind it
	private static function shades(fixture:CairoFixture):Int
	{
		var count = 0;

		for (color in fixture.pixels())
		{
			if (color != BLACK && color != WHITE) count++;
		}

		return count;
	}
	#end
}
