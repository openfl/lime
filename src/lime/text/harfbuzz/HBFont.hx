package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
import lime._internal.backend.native.NativeCFFI;
import lime.math.Vector2;
import lime.system.CFFIPointer;

@:access(lime._internal.backend.native.NativeCFFI)
abstract HBFont(CFFIPointer) from CFFIPointer to CFFIPointer
{
	public static var empty(get, never):HBFont;

	public var face(get, never):HBFace;
	public var immutable(get, never):Bool;
	public var parent(get, never):HBFont;
	public var ppem(get, set):Vector2;
	public var scale(get, set):Vector2;

	public function new(face:HBFace)
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		this = NativeCFFI.lime_hb_font_create(face);
		#else
		this = null;
		#end
	}

	public function addGlyphOriginForDirection(glyph:Int, direction:HBDirection, x:Int, y:Int):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_font_add_glyph_origin_for_direction(this, glyph, direction, x, y);
		#end
	}

	public function createSubFont():HBFont
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_font_create_sub_font(this);
		#else
		return null;
		#end
	}

	public function getGlyphAdvanceForDirection(glyph:Int, direction:HBDirection):Vector2
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_font_get_glyph_advance_for_direction(this, glyph, direction #if hl, new Vector2() #end);
		#else
		return null;
		#end
	}

	public function getGlyphKerningForDirection(glyph:Int, firstGlyph:Int, secondGlyph:Int, direction:HBDirection):Vector2
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_font_get_glyph_kerning_for_direction(this, firstGlyph, secondGlyph, direction #if hl, new Vector2() #end);
		#else
		return null;
		#end
	}

	public function getGlyphOriginForDirection(glyph:Int, direction:HBDirection):Vector2
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_font_get_glyph_origin_for_direction(this, glyph, direction #if hl, new Vector2() #end);
		#else
		return null;
		#end
	}

	public function glyphFromString(s:String):Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_font_glyph_from_string(this, s);
		#else
		return 0;
		#end
	}

	public function glyphToString(codepoint:Int):String
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		var result = NativeCFFI.lime_hb_font_glyph_to_string(this, codepoint);
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public function makeImmutable():Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_font_make_immutable(this);
		#end
	}

	public function subtractGlyphOriginForDirection(glyph:Int, direction:HBDirection, x:Int, y:Int):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_font_subtract_glyph_origin_for_direction(this, glyph, direction, x, y);
		#end
	}

	// Get & Set Methods
	private static inline function get_empty():HBFont
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_font_get_empty();
		#else
		return null;
		#end
	}

	@:noCompletion private inline function get_face():HBFace
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_font_get_face(this);
		#else
		return null;
		#end
	}

	@:noCompletion private inline function get_immutable():Bool
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_font_is_immutable(this);
		#else
		return false;
		#end
	}

	@:noCompletion private inline function get_parent():HBFont
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_font_get_parent(this);
		#else
		return null;
		#end
	}

	@:noCompletion private inline function get_ppem():Vector2
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_font_get_ppem(this #if hl, new Vector2() #end);
		#else
		return null;
		#end
	}

	@:noCompletion private inline function set_ppem(value:Vector2):Vector2
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_font_set_ppem(this, Std.int(value.x), Std.int(value.y));
		#end
		return value;
	}

	@:noCompletion private inline function get_scale():Vector2
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_font_get_scale(this #if hl, new Vector2() #end);
		#else
		return null;
		#end
	}

	@:noCompletion private inline function set_scale(value:Vector2):Vector2
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_font_set_scale(this, Std.int(value.x), Std.int(value.y));
		#end
		return value;
	}
}
#end
