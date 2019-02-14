package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;

@:access(lime._internal.backend.native.NativeCFFI)
abstract HBFace(CFFIPointer) from CFFIPointer to CFFIPointer
{
	public static var empty(get, never):HBFace;

	public var glyphCount(get, set):Int;
	public var immutable(get, never):Bool;
	public var index(get, set):Int;
	public var upem(get, set):Int;

	public function new(blob:HBBlob, index:Int)
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		this = NativeCFFI.lime_hb_face_create(blob, index);
		#else
		this = null;
		#end
	}

	// Get & Set Methods
	private static inline function get_empty():HBFace
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_face_get_empty();
		#else
		return null;
		#end
	}

	@:noCompletion private inline function get_glyphCount():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_face_get_glyph_count(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function set_glyphCount(value:Int):Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_face_set_glyph_count(this, value);
		#end
		return value;
	}

	@:noCompletion private inline function get_immutable():Bool
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_face_is_immutable(this);
		#else
		return false;
		#end
	}

	@:noCompletion private inline function get_index():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_face_get_index(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function set_index(value:Int):Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_face_set_index(this, value);
		#end
		return value;
	}

	@:noCompletion private inline function get_upem():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_face_get_upem(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function set_upem(value:Int):Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_face_set_upem(this, value);
		#end
		return value;
	}
}
#end
