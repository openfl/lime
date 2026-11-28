package lime.utils;

import haxe.io.BytesData;
import haxe.io.Bytes;
import lime.system.CFFIPointer;
import lime.utils.Bytes as LimeBytes;
#if cpp
import cpp.Char;
import cpp.Pointer;
import cpp.UInt8;
import haxe.io.FPHelper;
#end
#if (lime_cffi && !macro)
import lime._internal.backend.native.NativeCFFI;

@:access(lime._internal.backend.native.NativeCFFI)
#end
@:access(haxe.io.Bytes)
@:transitive
abstract DataPointer(DataPointerType) to DataPointerType
{
	@:noCompletion private function new(data:#if !doc_gen DataPointerType #else Dynamic #end)
	{
		this = data;
	}

	#if (lime_cffi && !js && !doc_gen)
	@:from @:noCompletion private static function fromInt(value:Int):DataPointer
	{
		#if (lime_cffi && !macro)
		var float:Float = value;
		return new DataPointer(float);
		#else
		return cast value;
		#end
	}
	#else
	@:from @:noCompletion private static function fromFloat(value:Float):DataPointer
	{
		return cast value;
	}
	#end

	#if (cpp && !cppia && !doc_gen)
	#if (haxe_ver < 4)
	@:from @:noCompletion public static inline function fromCharPointer(pointer:Pointer<Char>):DataPointer
	{
		var high:Int = untyped __cpp__('(int)((unsigned long long)(uintptr_t){0} >> 32)', pointer.ptr);
		var low:Int = untyped __cpp__('(int)(unsigned int)(uintptr_t){0}', pointer.ptr);
		return __fromAddress(high, low);
	}

	@:from @:noCompletion public static inline function fromUint8Pointer(pointer:Pointer<UInt8>):DataPointer
	{
		var high:Int = untyped __cpp__('(int)((unsigned long long)(uintptr_t){0} >> 32)', pointer.ptr);
		var low:Int = untyped __cpp__('(int)(unsigned int)(uintptr_t){0}', pointer.ptr);
		return __fromAddress(high, low);
	}
	#end

	@:generic @:from @:noCompletion public static inline function fromPointer<T>(pointer:Pointer<T>):DataPointer
	{
		var high:Int = untyped __cpp__('(int)((unsigned long long)(uintptr_t){0} >> 32)', pointer.ptr);
		var low:Int = untyped __cpp__('(int)(unsigned int)(uintptr_t){0}', pointer.ptr);
		return __fromAddress(high, low);
	}

	/**
		The value an address has as a DataPointer, as project/include/utils/DataPointer.h
		gives it: the address itself below 2^53, and for an address with its top byte set,
		as the heap gives on 64-bit Android from Android 11, the bits of a double from 2^53
		up that keep every bit of it.
	**/
	@:noCompletion private static function __fromAddress(high:Int, low:Int):DataPointer
	{
		var lowValue:Float = low < 0 ? low + 4294967296.0 : low;

		if ((high >>> 21) == 0 || ((high >>> 20) & 0xF) != 0)
		{
			var highValue:Float = high < 0 ? high + 4294967296.0 : high;
			return new DataPointer(highValue * 4294967296.0 + lowValue);
		}

		// The top byte moves down to bits 52 to 59, over the bits of the double 2^53
		return new DataPointer(FPHelper.i64ToDouble(low, 0x43400000 + (((high >>> 24) << 20) | (high & 0xFFFFF))));
	}
	#end

	@:from @:noCompletion public static function fromBytesPointer(pointer:BytePointer):DataPointer
	{
		#if (cpp && !doc_gen)
		if (pointer == null || pointer.bytes == null) return cast 0;
		return Pointer.arrayElem(pointer.bytes.b, 0).add(pointer.offset);
		#elseif (lime_cffi && !macro)
		if (pointer == null || pointer.bytes == null) return cast 0;
		var data:Float = NativeCFFI.lime_bytes_get_data_pointer_offset(pointer.bytes, pointer.offset);
		return new DataPointer(data);
		#else
		return 0;
		#end
	}

	@:from @:noCompletion public static function fromArrayBufferView(arrayBufferView:ArrayBufferView):DataPointer
	{
		#if (cpp && !doc_gen)
		if (arrayBufferView == null) return cast 0;
		return Pointer.arrayElem(arrayBufferView.buffer.b, 0).add(arrayBufferView.byteOffset);
		#elseif (lime_cffi && !js && !macro)
		if (arrayBufferView == null) return cast 0;
		var data:Float = NativeCFFI.lime_bytes_get_data_pointer_offset(arrayBufferView.buffer, arrayBufferView.byteOffset);
		return new DataPointer(data);
		#else
		return 0;
		#end
	}

	@:from @:noCompletion public static function fromArrayBuffer(buffer:ArrayBuffer):DataPointer
	{
		#if (lime_cffi && !macro)
		if (buffer == null) return cast 0;
		return fromBytes(buffer);
		#else
		return 0;
		#end
	}

	@:from @:noCompletion public static function fromBytes(bytes:Bytes):DataPointer
	{
		#if (cpp && !doc_gen)
		if (bytes == null) return cast 0;
		return Pointer.arrayElem(bytes.b, 0);
		#elseif (lime_cffi && !macro)
		if (bytes == null) return cast 0;
		var data:Float = NativeCFFI.lime_bytes_get_data_pointer(bytes);
		return new DataPointer(data);
		#else
		return 0;
		#end
	}

	@:from @:noCompletion public static function fromBytesData(bytesData:BytesData):DataPointer
	{
		#if (lime_cffi && !macro)
		if (bytesData == null) return cast 0;
		return fromBytes(Bytes.ofData(bytesData));
		#else
		return 0;
		#end
	}

	@:from @:noCompletion public static function fromLimeBytes(bytes:LimeBytes):DataPointer
	{
		return fromBytes(bytes);
	}

	#if !lime_doc_gen
	@:from @:noCompletion public static function fromCFFIPointer(pointer:CFFIPointer):DataPointer
	{
		#if (lime_cffi && !macro)
		if (pointer == null) return cast 0;
		return new DataPointer(pointer.get());
		#else
		return 0;
		#end
	}
	#end

	public static function fromFile(path:String):DataPointer
	{
		#if (lime_cffi && !macro)
		return fromBytes(LimeBytes.fromFile(path));
		#else
		return 0;
		#end
	}

	private static function __withOffset(data:DataPointer, offset:Int):DataPointer
	{
		#if (lime_cffi && !macro)
		if (data == 0) return cast 0;
		var data:Float = NativeCFFI.lime_data_pointer_offset(data, offset);
		return new DataPointer(data);
		#else
		return 0;
		#end
	}

	@:noCompletion @:op(A == B) private static inline function equals(a:DataPointer, b:Int):Bool
	{
		return (a : Float) == b;
	}

	@:noCompletion @:op(A == B) private static inline function equalsPointer(a:DataPointer, b:DataPointer):Bool
	{
		return (a : Float) == (b : Float);
	}

	@:noCompletion @:op(A > B) private static inline function greaterThan(a:DataPointer, b:Int):Bool
	{
		return (a : Float) > b;
	}

	#if !lime_doc_gen
	@:noCompletion @:op(A > B) private static inline function greaterThanPointer(a:DataPointer, b:CFFIPointer):Bool
	{
		return (a : Float) > b;
	}
	#end

	@:noCompletion @:op(A >= B) private static inline function greaterThanOrEqual(a:DataPointer, b:Int):Bool
	{
		return (a : Float) >= b;
	}

	#if !lime_doc_gen
	@:noCompletion @:op(A >= B) private static inline function greaterThanOrEqualPointer(a:DataPointer, b:CFFIPointer):Bool
	{
		return (a : Float) >= b;
	}
	#end

	@:noCompletion @:op(A < B) private static inline function lessThan(a:DataPointer, b:Int):Bool
	{
		return (a : Float) < b;
	}

	#if !lime_doc_gen
	@:noCompletion @:op(A < B) private static inline function lessThanPointer(a:DataPointer, b:CFFIPointer):Bool
	{
		return (a : Float) < b;
	}
	#end

	@:noCompletion @:op(A <= B) private static inline function lessThanOrEqual(a:DataPointer, b:Int):Bool
	{
		return (a : Float) <= b;
	}

	#if !lime_doc_gen
	@:noCompletion @:op(A <= B) private static inline function lessThanOrEqualPointer(a:DataPointer, b:CFFIPointer):Bool
	{
		return (a : Float) <= b;
	}
	#end

	@:noCompletion @:op(A != B) private static inline function notEquals(a:DataPointer, b:Int):Bool
	{
		return (a : Float) != b;
	}

	@:noCompletion @:op(A != B) private static inline function notEqualsPointer(a:DataPointer, b:DataPointer):Bool
	{
		return (a : Float) != (b : Float);
	}

	@:noCompletion @:op(A + B) private static inline function plus(a:DataPointer, b:Int):DataPointer
	{
		return __withOffset(a, b);
	}

	@:noCompletion @:op(A + B) private static inline function plusPointer(a:DataPointer, b:DataPointer):DataPointer
	{
		return __withOffset(a, Std.int((b : Float)));
	}

	@:noCompletion @:op(A - B) private static inline function minus(a:DataPointer, b:Int):DataPointer
	{
		return __withOffset(a, -b);
	}

	@:noCompletion @:op(A - B) private static inline function minusPointer(a:DataPointer, b:DataPointer):DataPointer
	{
		return __withOffset(a, -Std.int((b : Float)));
	}
}

#if (lime_cffi && !js)
private typedef DataPointerType = Float;
#else
private typedef DataPointerType = Int;
#end
