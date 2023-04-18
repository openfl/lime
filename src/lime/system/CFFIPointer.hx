package lime.system;

#if (!lime_doc_gen || lime_cffi)
import lime._internal.backend.native.NativeCFFI;

@:access(lime._internal.backend.native.NativeCFFI)
abstract CFFIPointer(Dynamic) from Dynamic to Dynamic
{
	public inline function new(handle:Dynamic)
	{
		this = handle;
	}

	public function get():Float
	{
		if (this != null)
		{
			#if (lime_cffi && !macro)
			return NativeCFFI.lime_cffi_get_native_pointer(this);
			#end
		}

		return 0;
	}

	@:noCompletion @:op(A == B) private static inline function equals(a:CFFIPointer, b:Int):Bool
	{
		return a.get() == b;
	}

	@:noCompletion @:op(A == B) private static inline function equalsPointer(a:CFFIPointer, b:CFFIPointer):Bool
	{
		return a.get() == b.get();
	}

	@:noCompletion @:op(A > B) private static inline function greaterThan(a:CFFIPointer, b:Int):Bool
	{
		return a.get() > b;
	}

	@:noCompletion @:op(A > B) private static inline function greaterThanPointer(a:CFFIPointer, b:CFFIPointer):Bool
	{
		return a.get() > b.get();
	}

	@:noCompletion @:op(A >= B) private static inline function greaterThanOrEqual(a:CFFIPointer, b:Int):Bool
	{
		return a.get() >= b;
	}

	@:noCompletion @:op(A >= B) private static inline function greaterThanOrEqualPointer(a:CFFIPointer, b:CFFIPointer):Bool
	{
		return a.get() >= b.get();
	}

	@:noCompletion @:op(A < B) private static inline function lessThan(a:CFFIPointer, b:Int):Bool
	{
		return a.get() < b;
	}

	@:noCompletion @:op(A < B) private static inline function lessThanPointer(a:CFFIPointer, b:CFFIPointer):Bool
	{
		return a.get() < b.get();
	}

	@:noCompletion @:op(A <= B) private static inline function lessThanOrEqual(a:CFFIPointer, b:Int):Bool
	{
		return a.get() <= b;
	}

	@:noCompletion @:op(A <= B) private static inline function lessThanOrEqualPointer(a:CFFIPointer, b:CFFIPointer):Bool
	{
		return a.get() <= b.get();
	}

	@:noCompletion @:op(A != B) private static inline function notEquals(a:CFFIPointer, b:Int):Bool
	{
		return a.get() != b;
	}

	@:noCompletion @:op(A != B) private static inline function notEqualsPointer(a:CFFIPointer, b:CFFIPointer):Bool
	{
		return a.get() != b.get();
	}
}
#end
