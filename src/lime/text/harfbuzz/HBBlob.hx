package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;
import lime.utils.DataPointer;

@:access(lime._internal.backend.native.NativeCFFI)
abstract HBBlob(CFFIPointer) from CFFIPointer to CFFIPointer
{
	public static var empty(get, never):HBBlob;

	public var data(get, never):DataPointer;
	public var dataWritable(get, never):DataPointer;
	public var immutable(get, never):Bool;
	public var length(get, never):Int;

	public function new(data:DataPointer, length:Int, memoryMode:Int)
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		this = NativeCFFI.lime_hb_blob_create(data, length, memoryMode);
		#else
		this = null;
		#end
	}

	public function createSubBlob(offset:Int, length:Int):HBBlob
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_blob_create_sub_blob(this, offset, length);
		#else
		return null;
		#end
	}

	public function makeImmutable():Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_blob_make_immutable(this);
		#end
	}

	// Get & Set Methods
	@:noCompletion private inline function get_data():DataPointer
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_blob_get_data(this);
		#else
		return cast 0;
		#end
	}

	@:noCompletion private inline function get_dataWritable():DataPointer
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_blob_get_data_writable(this);
		#else
		return cast 0;
		#end
	}

	private static inline function get_empty():HBBlob
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_blob_get_empty();
		#else
		return null;
		#end
	}

	@:noCompletion private inline function get_immutable():Bool
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_blob_is_immutable(this);
		#else
		return false;
		#end
	}

	@:noCompletion private inline function get_length():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_blob_get_length(this);
		#else
		return 0;
		#end
	}
}
#end
