package text;

#if (lime_cffi && !macro)
import haxe.Timer;
import lime.graphics.Image;
import lime.text.Font;
import lime.text.Glyph;
#end
import utest.Assert;
import utest.Test;

/**
	What `Font.renderGlyphs()` and `Font.decompose()` give, for the performance work on both.

	`renderGlyphs()` renders every glyph into one block of bytes, which native code grows glyph by glyph,
	so rendering many glyphs at once must give each glyph what rendering it alone gives. Glyph images are
	compared with other renderings on the same machine rather than pinned, as `FontTest` does.

	`decompose()` asks FreeType for the kerning of every pair of characters, where the font's `kern`
	table lists only the pairs that have any. `assets/mono-kern.ttf` is `assets/mono.ttf` with a `kern`
	table added by `fixtures/make_mono_kern.py`: thirteen pairs, a pair of zero and two pairs with
	.notdef, which no character maps to. Only the thirteen are kerning.
**/
class FontGlyphOutputTest extends Test
{
	#if (lime_cffi && !macro)
	private static inline var PATH = "assets/mono.ttf";
	private static inline var KERN_PATH = "assets/mono-kern.ttf";
	private static var PAIRS = [
		"A V", "V A", "A T", "T o", "L T", "P .", "Y a", "f f", "r ,", "W e", "1 1", "  A", "~ !"
	];
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	public function testRenderGlyphsGivesEachGlyphWhatRenderingItAloneGives():Void
	{
		var font = Font.fromFile(PATH);
		Assert.notNull(font);
		if (font == null) return;

		for (size in [11, 24, 64])
		{
			var glyphs = font.getGlyphs(printable());
			var together = font.renderGlyphs(glyphs, size);
			var differ = [];

			for (glyph in glyphs)
			{
				var alone = font.renderGlyphs([glyph], size);
				var a = describe(together.get(glyph));
				var b = describe(alone != null ? alone.get(glyph) : null);
				if (a != b) differ.push(glyph);
			}

			Assert.equals(0, differ.length, "at " + size + " px, glyphs " + differ.join(", ") + " differ from rendering them alone");
		}
	}

	public function testRenderGlyphsInOneCallOrSeveralGivesTheSameGlyphs():Void
	{
		var font = Font.fromFile(PATH);
		Assert.notNull(font);
		if (font == null) return;

		var glyphs = font.getGlyphs(printable());
		var all = font.renderGlyphs(glyphs, 32);
		var first = font.renderGlyphs(glyphs.slice(0, 40), 32);
		var rest = font.renderGlyphs(glyphs.slice(40), 32);
		var differ = 0;

		for (i in 0...glyphs.length)
		{
			var part = i < 40 ? first : rest;
			if (describe(all.get(glyphs[i])) != describe(part.get(glyphs[i]))) differ++;
		}

		Assert.equals(0, differ, differ + " glyphs differ between one call and two");
	}

	@Ignored("Waiting on #2230")
	public function testRenderingManyGlyphsAtOnceTakesNoLongerThanOneAtATime():Void
	{
		// Growing the bytes by exactly each glyph copies everything rendered so far for every glyph
		var font = Font.fromFile(PATH);
		Assert.notNull(font);
		if (font == null) return;

		var glyphs = font.getGlyphs(printable());
		font.renderGlyphs(glyphs, 300);

		var together = 1e9;
		var alone = 1e9;

		for (round in 0...3)
		{
			var start = Timer.stamp();
			font.renderGlyphs(glyphs, 300);
			together = Math.min(together, Timer.stamp() - start);

			start = Timer.stamp();
			for (glyph in glyphs)
			{
				font.renderGlyphs([glyph], 300);
			}
			alone = Math.min(alone, Timer.stamp() - start);
		}

		Assert.isTrue(together < alone * 1.5, glyphs.length + " glyphs at 300 px took " + ms(together) + " together and " + ms(alone) + " one at a time");
	}

	public function testDecomposeGivesEveryKerningPairOfTheKernTableAndNoOthers():Void
	{
		var font = Font.fromFile(KERN_PATH);
		Assert.notNull(font, "cannot open " + KERN_PATH);
		if (font == null) return;

		// Read dynamically: on HashLink the arrays aren't Haxe arrays of these types
		var data:Dynamic = font.decompose();
		Assert.isTrue(data.has_kerning, "the font has no kerning");

		var pairs = [];
		var values = [];
		var kerning = list(data.kerning);
		var glyphs = list(data.glyphs);
		var count = kerning.length;
		for (i in 0...count)
		{
			var each:Dynamic = kerning[i];
			var left:Dynamic = glyphs[each.left_glyph];
			var right:Dynamic = glyphs[each.right_glyph];
			var pair = String.fromCharCode(left.char_code) + " " + String.fromCharCode(right.char_code);
			pairs.push(pair);
			values.push(pair + " " + each.x + "," + each.y);
		}

		var expected = PAIRS.copy();
		expected.sort(Reflect.compare);
		var sorted = pairs.copy();
		sorted.sort(Reflect.compare);
		Assert.equals(expected.join("|"), sorted.join("|"), "the pairs kerned");

		// In the order of the glyphs, which is by character, by the left one and then the right
		Assert.equals([
			"  A -128,0", "1 1 -192,0", "A T -896,0", "A V -1216,0", "L T -1408,0", "P . -1600,0", "T o -768,0", "V A -1088,0", "W e -384,0",
			"Y a -576,0", "f f 320,0", "r , -512,0", "~ ! 128,0"
		].join("|"), values.join("|"));
	}

	public function testAFontWithoutAKernTableHasNoKerning():Void
	{
		var data:Dynamic = Font.fromFile(PATH).decompose();
		Assert.isFalse(data.has_kerning);
		Assert.equals(0, list(data.kerning).length, "the font has kerning");
	}

	public function testAKernTableLeavesTheDecomposedGlyphsAsTheyAre():Void
	{
		var plain:Dynamic = Font.fromFile(PATH).decompose();
		var kerned:Dynamic = Font.fromFile(KERN_PATH).decompose();
		var a = list(plain.glyphs);
		var b = list(kerned.glyphs);

		Assert.equals(plain.num_glyphs, kerned.num_glyphs);
		Assert.equals(a.length, b.length);

		var differ = 0;
		for (i in 0...a.length)
		{
			var x:Dynamic = a[i];
			var y:Dynamic = b[i];
			if (x.char_code != y.char_code || x.advance != y.advance || Std.string(x.points) != Std.string(y.points)) differ++;
		}

		Assert.equals(0, differ, differ + " glyphs differ");
	}

	// Helpers

	/** HashLink gives the decomposed font's lists as native arrays **/
	private static function list(value:Dynamic):Array<Dynamic>
	{
		if (value == null) return [];
		#if hl
		if (!Std.isOfType(value, Array))
		{
			var native:hl.NativeArray<Dynamic> = value;
			return [for (i in 0...native.length) native[i]];
		}
		#end
		return value;
	}

	private static function printable():String
	{
		return [for (code in 32...127) String.fromCharCode(code)].join("");
	}

	/** The glyph image's size, place and coverage **/
	private static function describe(image:Image):String
	{
		if (image == null) return "null";

		var buffer = image.buffer;
		var values = [];
		for (y in 0...image.height)
		{
			for (x in 0...image.width)
			{
				values.push(buffer.data[(image.offsetY + y) * buffer.width + image.offsetX + x]);
			}
		}

		return image.width + "x" + image.height + " at " + image.x + "," + image.y + " " + haxe.crypto.Crc32.make(haxe.io.Bytes.ofString(values.join(",")));
	}

	private static function ms(seconds:Float):String
	{
		return Math.round(seconds * 1000) + " ms";
	}
	#end
}
