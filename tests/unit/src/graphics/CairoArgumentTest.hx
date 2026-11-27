package graphics;

#if (lime_cffi && lime_cairo && !macro)
import graphics.CairoFixture.*;
import lime.graphics.cairo.CairoFTFontFace;
import lime.graphics.cairo.CairoGlyph;
import lime.graphics.cairo.CairoPattern;
import lime.graphics.cairo.CairoStatus;
import lime.math.Matrix3;
import lime.text.Font;
#end
import utest.Assert;
import utest.Test;

/**
	Matrices, points and glyphs as they cross to Cairo and back.

	On C++ and Neko these go to native code as objects read field by field, and may go as plain doubles in
	a buffer instead. Whatever carries them has to give back exactly what comes back today, and a buffer
	reused from call to call must hold only what the call was given. Other Cairo tests compare to a few
	decimal places, so these compare every digit. `Matrix3` holds 32-bit floats, and Cairo keeps path
	coordinates in 24.8 fixed point, so today's values are those, not the doubles written here.
**/
class CairoArgumentTest extends Test
{
	#if (lime_cffi && lime_cairo && !macro)
	private static inline var PATH = "assets/mono.ttf";

	// Doubles that a 32-bit float rounds
	private static var AWKWARD = [0.1, 1e-7, -3.3333333333333335, 1234567.891, 0.30000000000000004, -2.5e-5];
	// As Matrix3 holds them, each rounded to a 32-bit float
	private static var STORED:Array<Float> = [for (value in AWKWARD) (haxe.io.FPHelper.i32ToFloat(haxe.io.FPHelper.floatToI32(value)) : Float)];
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_cairo && !macro)
	public function testTransformKeepsEveryDigitOfItsMatrix():Void
	{
		var fixture = new CairoFixture(4, 4);
		fixture.cairo.transform(matrix(AWKWARD));

		// Multiplied by the identity, which changes nothing
		assertExactly(STORED, values(fixture.cairo.matrix));
	}

	public function testSettingAndReadingTheMatrixKeepsEveryDigit():Void
	{
		var fixture = new CairoFixture(4, 4);
		fixture.cairo.matrix = matrix(AWKWARD);

		assertExactly(STORED, values(fixture.cairo.matrix));
	}

	public function testAPatternMatrixKeepsEveryDigit():Void
	{
		var pattern = CairoPattern.createLinear(0, 0, 4, 0);
		pattern.matrix = matrix(AWKWARD);

		assertExactly(STORED, values(pattern.matrix));

		// Set again with other values, the old ones are gone
		pattern.matrix = new Matrix3(2, 0, 0, 0.5, -1, 3);
		assertExactly([2, 0, 0, 0.5, -1, 3], values(pattern.matrix));
	}

	public function testTheCurrentPointKeepsEveryDigit():Void
	{
		var fixture = new CairoFixture(4, 4);
		// To the nearest 256th of a pixel
		fixture.cairo.moveTo(0.1, 1 / 3);
		assertExactly([0.1015625, 0.33203125], point(fixture));

		// A power of two scales exactly both ways
		fixture.cairo.scale(2, 0.25);
		fixture.cairo.moveTo(1e-7, -1234567.891);
		assertExactly([0, -1234567.890625], point(fixture));
		fixture.cairo.relLineTo(0.75, 3.3);
		assertExactly([0.75, -1234564.59375], point(fixture));
	}

	public function testATransformedPatternDrawsAsItsMatrixSays():Void
	{
		// A gradient across the image, its matrix squeezing it to the left half
		var whole = new CairoFixture(16, 2, WHITE);
		var pattern = CairoPattern.createLinear(0, 0, 16, 0);
		pattern.addColorStopRGB(0, 0, 0, 0);
		pattern.addColorStopRGB(1, 1, 1, 1);
		pattern.matrix = new Matrix3(2, 0, 0, 1, 0, 0);
		whole.cairo.source = pattern;
		whole.cairo.paint();

		var half = new CairoFixture(16, 2, WHITE);
		var squeezed = CairoPattern.createLinear(0, 0, 8, 0);
		squeezed.addColorStopRGB(0, 0, 0, 0);
		squeezed.addColorStopRGB(1, 1, 1, 1);
		half.cairo.source = squeezed;
		half.cairo.paint();

		Assert.same(half.pixels(), whole.pixels());
	}

	public function testManyGlyphsShownAtOnceDrawAsEachShownAlone():Void
	{
		var glyphs = manyGlyphs(240);

		var together = text();
		together.cairo.showGlyphs(glyphs);
		Assert.equals(CairoStatus.SUCCESS, together.cairo.status());

		var alone = text();
		for (glyph in glyphs)
		{
			alone.cairo.showGlyphs([glyph]);
		}

		Assert.same(alone.pixels(), together.pixels());
	}

	public function testShowingFewerGlyphsAfterMoreDrawsOnlyTheFewer():Void
	{
		// Each call draws only the glyphs it is given, however many the call before had
		var expected = text();
		expected.cairo.moveTo(10.25, 30.5);
		expected.cairo.showText("H");

		text().cairo.showGlyphs(manyGlyphs(240));

		var fixture = text();
		fixture.cairo.showGlyphs([new CairoGlyph(font().getGlyph("H"), 10.25, 30.5)]);
		Assert.same(expected.pixels(), fixture.pixels());
	}

	public function testGlyphsAtFractionalAndFarPositionsDrawWhereTheySay():Void
	{
		// Placed by showText from the same points, which goes through no glyph array of Lime's
		var fixture = text();
		var shown = text();
		var places = [[10.375, 30.625], [40.5, 12.125], [-5.75, 50.25], [100000.5, 20], [33.0625, -1000.5]];

		var glyphs = [];
		for (place in places)
		{
			glyphs.push(new CairoGlyph(font().getGlyph("g"), place[0], place[1]));
			shown.cairo.moveTo(place[0], place[1]);
			shown.cairo.showText("g");
		}

		fixture.cairo.showGlyphs(glyphs);
		Assert.same(shown.pixels(), fixture.pixels());
	}

	// Helpers

	private static function manyGlyphs(count:Int):Array<CairoGlyph>
	{
		var font = font();
		var glyphs = [];
		for (i in 0...count)
		{
			var code = 33 + (i * 7) % 94;
			// Apart, so no glyph's edge is drawn over another's
			glyphs.push(new CairoGlyph(font.getGlyph(String.fromCharCode(code)), 4 + (i % 20) * 8 + (i % 3) * 0.125, 12 + Std.int(i / 20) * 11.5));
		}
		return glyphs;
	}

	private static function matrix(values:Array<Float>):Matrix3
	{
		return new Matrix3(values[0], values[1], values[2], values[3], values[4], values[5]);
	}

	private static function values(matrix:Matrix3):Array<Float>
	{
		return matrix == null ? [] : [matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty];
	}

	private static function point(fixture:CairoFixture):Array<Float>
	{
		var point = fixture.cairo.currentPoint;
		return point == null ? [] : [point.x, point.y];
	}

	/** Compares every value exactly, as numbers, since targets print doubles to different numbers of digits **/
	private static function assertExactly(expected:Array<Float>, actual:Array<Float>, ?pos:haxe.PosInfos):Void
	{
		var same = expected.length == actual.length;
		for (i in 0...expected.length)
		{
			if (same && expected[i] != actual[i]) same = false;
		}

		Assert.isTrue(same, "expected " + expected.join(" ") + " but it is " + actual.join(" "), pos);
	}

	private static function font():Font
	{
		var font = Font.fromFile(PATH);
		if (font == null) throw "cannot open " + PATH;
		return font;
	}

	private static function text():CairoFixture
	{
		var fixture = new CairoFixture(170, 150, WHITE);
		fixture.cairo.fontFace = CairoFTFontFace.create(font(), 0);
		fixture.cairo.setFontSize(9);
		return fixture;
	}
	#end
}
