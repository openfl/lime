package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
import lime._internal.backend.native.NativeCFFI;
import lime.math.Vector2;
import lime.system.CFFIPointer;

@:access(lime._internal.backend.native.NativeCFFI)
abstract HBSet(CFFIPointer) from CFFIPointer to CFFIPointer
{
	public static var empty(get, never):HBSet;

	public var allocationSuccessful(get, never):Bool;
	public var isEmpty(get, never):Bool;
	public var max(get, never):Int;
	public var min(get, never):Int;
	public var population(get, never):Int;

	public function new()
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		this = NativeCFFI.lime_hb_set_create();
		#else
		this = null;
		#end
	}

	public function add(codepoint:Int):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_set_add(this, codepoint);
		#end
	}

	public function addRange(first:Int, last:Int):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_set_add_range(this, first, last);
		#end
	}

	public function clear():Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_set_clear(this);
		#end
	}

	public function del(codepoint:Int):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_set_del(this, codepoint);
		#end
	}

	public function delRange(first:Int, last:Int):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_set_del_range(this, first, last);
		#end
	}

	public function has(codepoint:Int):Bool
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_set_has(this, codepoint);
		#else
		return false;
		#end
	}

	public function intersect(other:HBSet):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_set_intersect(this, other);
		#end
	}

	public function invert():Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_set_invert(this);
		#end
	}

	public function isEqual(other:HBSet):Bool
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_set_is_equal(this, other);
		#else
		return false;
		#end
	}

	public function next():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_set_next(this);
		#else
		return 0;
		#end
	}

	public function nextRange():Vector2
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_set_next_range(this #if hl, new Vector2() #end);
		#else
		return null;
		#end
	}

	public function set(other:HBSet):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_set_set(this, other);
		#end
	}

	public function subtract(other:HBSet):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_set_subtract(this, other);
		#end
	}

	public function symmetricDifference(other:HBSet):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_set_symmetric_difference(this, other);
		#end
	}

	public function union(other:HBSet):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_set_union(this, other);
		#end
	}

	// Get & Set Methods
	@:noCompletion private inline function get_allocationSuccessful():Bool
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_set_allocation_successful(this);
		#else
		return false;
		#end
	}

	private static inline function get_empty():HBSet
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_set_get_empty();
		#else
		return null;
		#end
	}

	@:noCompletion private inline function get_isEmpty():Bool
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_set_is_empty(this);
		#else
		return false;
		#end
	}

	@:noCompletion private inline function get_max():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_set_get_max(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function get_min():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_set_get_min(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function get_population():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_set_get_population(this);
		#else
		return 0;
		#end
	}
}
#end
