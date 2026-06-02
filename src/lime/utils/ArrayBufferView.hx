package lime.utils;

#if (js && !doc_gen)
typedef ArrayBufferView = #if haxe4 js.lib.ArrayBufferView #else js.html.ArrayBufferView #end;
#else
import lime.system.System;
import lime.system.Endian;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class ArrayBufferView
{
	public var type = TypedArrayType.None;
	public var buffer:ArrayBuffer;
	public var byteOffset:Int;
	public var byteLength:Int;
	public var length:Int;

	// internal for avoiding switching on types
	var bytesPerElement(default, null):Int = 0;

	@:allow(lime.utils)
	#if !no_typedarray_inline
	inline
	#end
	function new(elements:Null<Int> = null, in_type:TypedArrayType)
	{
		type = in_type;
		bytesPerElement = bytesForType(type);

		// other constructor types use
		// the init calls below
		if (elements != null && elements != 0)
		{
			if (elements < 0) elements = 0;
			// :note:spec: also has, platform specific max int?
			// elements = min(elements,maxint);

			byteOffset = 0;
			byteLength = toByteLength(elements);
			buffer = new ArrayBuffer(byteLength);
			length = elements;
		}
	} // new

	// Constructor helpers
	@:allow(lime.utils)
	#if !no_typedarray_inline
	inline
	#end
	function initTypedArray(view:ArrayBufferView)
	{
		var srcData = view.buffer;
		var srcLength = view.length;
		var srcByteOffset = view.byteOffset;
		var srcElementSize = view.bytesPerElement;
		var elementSize = bytesPerElement;

		// same species, so just blit the data
		// in other words, it shares the same bytes per element etc
		if (view.type == type)
		{
			cloneBuffer(srcData, srcByteOffset);
		}
		else
		{
			// see :note:1: below use FPHelper!
			throw("unimplemented");
		}

		byteLength = bytesPerElement * srcLength;
		byteOffset = 0;
		length = srcLength;

		return this;
	} // (typedArray)

	@:allow(lime.utils)
	#if !no_typedarray_inline
	inline
	#end
	function initBuffer(in_buffer:ArrayBuffer, in_byteOffset:Int = 0, len:Null<Int> = null)
	{
		if (in_byteOffset < 0) throw TAError.RangeError;
		if (in_byteOffset % bytesPerElement != 0) throw TAError.RangeError;

		var bufferByteLength = in_buffer.length;
		var elementSize = bytesPerElement;
		var newByteLength = bufferByteLength;

		if (len == null)
		{
			newByteLength = bufferByteLength - in_byteOffset;

			if (bufferByteLength % bytesPerElement != 0) throw TAError.RangeError;
			if (newByteLength < 0) throw TAError.RangeError;
		}
		else
		{
			newByteLength = len * bytesPerElement;

			var newRange = in_byteOffset + newByteLength;
			if (newRange > bufferByteLength) throw TAError.RangeError;
		}

		buffer = in_buffer;
		byteOffset = in_byteOffset;
		byteLength = newByteLength;
		length = Std.int(newByteLength / bytesPerElement);

		return this;
	} // (buffer [, byteOffset [, length]])

	@:allow(lime.utils)
	#if !no_typedarray_inline
	inline
	#end
	function initArray<T>(array:Array<T>)
	{
		byteOffset = 0;
		length = array.length;
		byteLength = toByteLength(length);

		buffer = new ArrayBuffer(byteLength);
		copyFromArray(cast array);

		return this;
	}

	// Public shared APIs
	// T is required because it can translate [0,0] as Int array
	#if !no_typedarray_inline
	inline
	#end
	public function set<T>(view:ArrayBufferView = null, array:Array<T> = null, offset:Int = 0):Void
	{
		if (view != null && array == null)
		{
			if (offset + view.length > this.length) {
				throw TAError.RangeError;
			}
			if (bytesPerElement == view.bytesPerElement)
			{
				buffer.blit(toByteLength(offset), view.buffer, view.byteOffset, view.byteLength);
			}
			else
			{
				for (i in 0...view.length)
				{
					transferElement(view, i, this, offset + i);
				}
			}
		}
		else if (array != null && view == null)
		{
			copyFromArray(cast array, offset);
		}
		else
		{
			throw "Invalid .set call. either view, or array must be not-null.";
		}
	}

	// Internal TypedArray api
	#if !no_typedarray_inline
	inline
	#end
	function cloneBuffer(src:ArrayBuffer, srcByteOffset:Int = 0)
	{
		var srcLength = src.length;
		var cloneLength = srcLength - srcByteOffset;

		buffer = new ArrayBuffer(cloneLength);
		buffer.blit(0, src, srcByteOffset, cloneLength);
	}

	@:generic
	@:allow(lime.utils)
	#if !no_typedarray_inline
	inline
	#end
	function subarray<T_subarray>(begin:Int, end:Null<Int> = null):T_subarray
	{
		if (end == null) end = length;
		var len = end - begin;
		if (len < 0) len = 0;
		if (len > this.length) len = this.length;
		var byte_offset = toByteLength(begin) + byteOffset;

		var view:ArrayBufferView = switch (type)
		{
			case Int8:
				new Int8Array(buffer, byte_offset, len);

			case Int16:
				new Int16Array(buffer, byte_offset, len);

			case Int32:
				new Int32Array(buffer, byte_offset, len);

			case Uint8:
				new UInt8Array(buffer, byte_offset, len);

			case Uint8Clamped:
				new UInt8ClampedArray(buffer, byte_offset, len);

			case Uint16:
				new UInt16Array(buffer, byte_offset, len);

			case Uint32:
				new UInt32Array(buffer, byte_offset, len);

			case Float32:
				new Float32Array(buffer, byte_offset, len);

			case Float64:
				new Float64Array(buffer, byte_offset, len);

			case None:
				throw "subarray on a blank ArrayBufferView";
		}

		return cast view;
	}

	#if !no_typedarray_inline
	inline
	#end
	function bytesForType(type:TypedArrayType):Int
	{
		return switch (type)
		{
			case Int8:
				Int8Array.BYTES_PER_ELEMENT;

			case Uint8:
				UInt8Array.BYTES_PER_ELEMENT;

			case Uint8Clamped:
				UInt8ClampedArray.BYTES_PER_ELEMENT;

			case Int16:
				Int16Array.BYTES_PER_ELEMENT;

			case Uint16:
				UInt16Array.BYTES_PER_ELEMENT;

			case Int32:
				Int32Array.BYTES_PER_ELEMENT;

			case Uint32:
				UInt32Array.BYTES_PER_ELEMENT;

			case Float32:
				Float32Array.BYTES_PER_ELEMENT;

			case Float64:
				Float64Array.BYTES_PER_ELEMENT;

			case _: 1;
		}
	}

	#if !no_typedarray_inline
	inline
	#end
	function toString()
	{
		var name = switch (type)
		{
			case Int8: 'Int8Array';
			case Uint8: 'UInt8Array';
			case Uint8Clamped: 'UInt8ClampedArray';
			case Int16: 'Int16Array';
			case Uint16: 'UInt16Array';
			case Int32: 'Int32Array';
			case Uint32: 'UInt32Array';
			case Float32: 'Float32Array';
			case Float64: 'Float64Array';
			case _: 'ArrayBufferView';
		}

		return name + ' [byteLength:${this.byteLength}, length:${this.length}]';
	} // toString

	#if !no_typedarray_inline
	inline
	#end
	function toByteLength(elemCount:Int):Int
	{
		return elemCount * bytesPerElement;
	}

	// Non-spec
	#if !no_typedarray_inline
	#end
	function copyFromArray(array:Array<#if hl Dynamic #else Float #end>, offset:Int = 0)
	{
		// Ideally, native semantics could be used, like cpp.NativeArray.blit
		var i = 0, len = array.length;

		if (offset + len > this.length) {
			throw TAError.RangeError;
		}

		switch (type)
		{
			case Int8:
				while (i < len)
				{
					var pos = (offset + i) * bytesPerElement;
					#if neko
					var value = array[i];
					if (value == null) value = 0;
					ArrayBufferIO.setInt8(buffer, pos, Std.int(value));
					#else
					ArrayBufferIO.setInt8(buffer, pos, Std.int(array[i]));
					#end
					++i;
				}
			case Int16:
				while (i < len)
				{
					var pos = (offset + i) * bytesPerElement;
					#if neko
					var value = array[i];
					if (value == null) value = 0;
					ArrayBufferIO.setInt16(buffer, pos, Std.int(value));
					#else
					ArrayBufferIO.setInt16(buffer, pos, Std.int(array[i]));
					#end
					++i;
				}
			case Int32:
				while (i < len)
				{
					var pos = (offset + i) * bytesPerElement;
					#if neko
					var value = array[i];
					if (value == null) value = 0;
					ArrayBufferIO.setInt32(buffer, pos, Std.int(value));
					#else
					ArrayBufferIO.setInt32(buffer, pos, Std.int(array[i]));
					#end
					++i;
				}
			case Uint8:
				while (i < len)
				{
					var pos = (offset + i) * bytesPerElement;
					#if neko
					var value = array[i];
					if (value == null) value = 0;
					ArrayBufferIO.setUint8(buffer, pos, Std.int(value));
					#else
					ArrayBufferIO.setUint8(buffer, pos, Std.int(array[i]));
					#end
					++i;
				}
			case Uint16:
				while (i < len)
				{
					var pos = (offset + i) * bytesPerElement;
					#if neko
					var value = array[i];
					if (value == null) value = 0;
					ArrayBufferIO.setUint16(buffer, pos, Std.int(value));
					#else
					ArrayBufferIO.setUint16(buffer, pos, Std.int(array[i]));
					#end
					++i;
				}
			case Uint32:
				while (i < len)
				{
					var pos = (offset + i) * bytesPerElement;
					#if neko
					var value = array[i];
					if (value == null) value = 0;
					ArrayBufferIO.setUint32(buffer, pos, Std.int(value));
					#else
					ArrayBufferIO.setUint32(buffer, pos, Std.int(array[i]));
					#end
					++i;
				}
			case Uint8Clamped:
				while (i < len)
				{
					var pos = (offset + i) * bytesPerElement;
					#if neko
					var value = array[i];
					if (value == null) value = 0;
					ArrayBufferIO.setUint8Clamped(buffer, pos, Std.int(value));
					#else
					ArrayBufferIO.setUint8Clamped(buffer, pos, Std.int(array[i]));
					#end
					++i;
				}
			case Float32:
				while (i < len)
				{
					var pos = (offset + i) * bytesPerElement;
					ArrayBufferIO.setFloat32(buffer, pos, array[i]);
					++i;
				}
			case Float64:
				while (i < len)
				{
					var pos = (offset + i) * bytesPerElement;
					ArrayBufferIO.setFloat64(buffer, pos, array[i]);
					++i;
				}

			case None:
				throw "copyFromArray on a base type ArrayBuffer";
		}
	}

	static function transferElement(fromView:ArrayBufferView, fromIndex:Int, toView:ArrayBufferView, toIndex:Int):Void
	{
		var fromValue:Dynamic = null;
		var fromPos = fromView.byteOffset + (fromIndex * fromView.bytesPerElement);
		switch (fromView.type)
		{
			case Int8:
				fromValue = ArrayBufferIO.getInt8(fromView.buffer, fromPos);
			case Int16:
				fromValue = ArrayBufferIO.getInt16(fromView.buffer, fromPos);
			case Int32:
				fromValue = ArrayBufferIO.getInt32(fromView.buffer, fromPos);
			case Uint8:
				fromValue = ArrayBufferIO.getUint8(fromView.buffer, fromPos);
			case Uint16:
				fromValue = ArrayBufferIO.getUint16(fromView.buffer, fromPos);
			case Uint32:
				fromValue = ArrayBufferIO.getUint32(fromView.buffer, fromPos);
			case Uint8Clamped:
				fromValue = ArrayBufferIO.getUint8(fromView.buffer, fromPos);
			case Float32:
				fromValue = ArrayBufferIO.getFloat32(fromView.buffer, fromPos);
			case Float64:
				fromValue = ArrayBufferIO.getFloat64(fromView.buffer, fromPos);
			case None:
				throw "transferElement on a base type ArrayBuffer";
		}

		var toPos = toView.byteOffset + (toIndex * toView.bytesPerElement);
		switch (toView.type)
		{
			case Int8:
				ArrayBufferIO.setInt8(toView.buffer, toPos, fromValue);
			case Int16:
				ArrayBufferIO.setInt16(toView.buffer, toPos, fromValue);
			case Int32:
				ArrayBufferIO.setInt32(toView.buffer, toPos, fromValue);
			case Uint8:
				ArrayBufferIO.setUint8(toView.buffer, toPos, fromValue);
			case Uint16:
				ArrayBufferIO.setUint16(toView.buffer, toPos, fromValue);
			case Uint32:
				ArrayBufferIO.setUint32(toView.buffer, toPos, fromValue);
			case Uint8Clamped:
				ArrayBufferIO.setUint8Clamped(toView.buffer, toPos, fromValue);
			case Float32:
				ArrayBufferIO.setFloat32(toView.buffer, toPos, fromValue);
			case Float64:
				ArrayBufferIO.setFloat64(toView.buffer, toPos, fromValue);
			case None:
				throw "transferElement on a base type ArrayBuffer";
		}
	}

} // ArrayBufferView

#end // !js
@:noCompletion @:dox(hide) enum TAError
{
	RangeError;
}

@:noCompletion @:dox(hide) #if (haxe_ver >= 4.0) enum #else @:enum #end
abstract TypedArrayType(Int) from Int to Int
{
	var None = 0;
	var Int8 = 1;
	var Int16 = 2;
	var Int32 = 3;
	var Uint8 = 4;
	var Uint8Clamped = 5;
	var Uint16 = 6;
	var Uint32 = 7;
	var Float32 = 8;
	var Float64 = 9;
}

#if (!js || doc_gen)
@:noCompletion @:dox(hide) class ArrayBufferIO
{
	// 8
	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getInt8(buffer:ArrayBuffer, byteOffset:Int):Int
	{
		#if cpp
		var val:Int = untyped __global__.__hxcpp_memory_get_byte(buffer.getData(), byteOffset) & 0xFF;
		return ((val & 0x80) != 0) ? (val - 0x100) : val;
		#else
		var val:Int = buffer.get(byteOffset);
		return ((val & 0x80) != 0) ? (val - 0x100) : val;
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setInt8(buffer:ArrayBuffer, byteOffset:Int, value:Int)
	{
		#if cpp
		untyped __global__.__hxcpp_memory_set_byte(buffer.getData(), byteOffset, value & 0xFF);
		#elseif neko
		if (value == null) value = 0;
		untyped __dollar__sset(buffer.b, byteOffset, value & 0xFF);
		#else
		buffer.set(byteOffset, value);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getUint8(buffer:ArrayBuffer, byteOffset:Int):Null<UInt>
	{
		#if cpp
		return untyped __global__.__hxcpp_memory_get_byte(buffer.getData(), byteOffset) & 0xFF;
		#else
		return buffer.get(byteOffset);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setUint8Clamped(buffer:ArrayBuffer, byteOffset:Int, value:UInt)
	{
		setUint8(buffer, byteOffset, _clamp(value));
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setUint8(buffer:ArrayBuffer, byteOffset:Int, value:UInt)
	{
		#if cpp
		untyped __global__.__hxcpp_memory_set_byte(buffer.getData(), byteOffset, value & 0xFF);
		#else
		#if neko
		if (value == null) value = 0;
		#end
		buffer.set(byteOffset, value);
		#end
	}

	// 16
	public static function getInt16(buffer:ArrayBuffer, byteOffset:Int):Int
	{
		#if cpp
		untyped return __global__.__hxcpp_memory_get_i16(buffer.getData(), byteOffset);
		#else
		var ch1 = buffer.get(byteOffset);
		var ch2 = buffer.get(byteOffset + 1);

		var val = ((ch2 << 8) | ch1);

		return ((val & 0x8000) != 0) ? (val - 0x10000) : (val);
		#end
	}

	public static function getInt16_BE(buffer:ArrayBuffer, byteOffset:Int):Int
	{
		#if cpp
		var bufferData = buffer.getData();
		var ch1:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset) & 0xFF;
		var ch2:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset + 1) & 0xFF;
		var val = ((ch1 << 8) | ch2);
		return ((val & 0x8000) != 0) ? (val - 0x10000) : (val);
		#else
		var ch1 = buffer.get(byteOffset);
		var ch2 = buffer.get(byteOffset + 1);
		var val = ((ch1 << 8) | ch2);
		return ((val & 0x8000) != 0) ? (val - 0x10000) : (val);
		#end
	}

	public static function setInt16(buffer:ArrayBuffer, byteOffset:Int, value:Int)
	{
		#if cpp
		untyped __global__.__hxcpp_memory_set_i16(buffer.getData(), byteOffset, value);
		#elseif neko
		if (value == null) value = 0;
		untyped var b = buffer.b;
		untyped __dollar__sset(b, byteOffset, (value) & 0xFF);
		untyped __dollar__sset(b, byteOffset + 1, (value >> 8) & 0xFF);
		#else
		buffer.set(byteOffset, (value) & 0xFF);
		buffer.set(byteOffset + 1, (value >> 8) & 0xFF);
		#end
	}

	public static function setInt16_BE(buffer:ArrayBuffer, byteOffset:Int, value:Int)
	{
		#if cpp
		var bufferData = buffer.getData();
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset, (value >> 8) & 0xFF);
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset + 1, value & 0xFF);
		#elseif neko
		if (value == null) value = 0;
		untyped var b = buffer.b;
		untyped __dollar__sset(b, byteOffset, (value >> 8) & 0xFF);
		untyped __dollar__sset(b, byteOffset + 1, (value) & 0xFF);
		#else
		buffer.set(byteOffset, (value >> 8) & 0xFF);
		buffer.set(byteOffset + 1, (value) & 0xFF);
		#end
	} // setInt16_BE

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getUint16(buffer:ArrayBuffer, byteOffset:Int):Null<UInt>
	{
		#if cpp
		untyped return __global__.__hxcpp_memory_get_ui16(buffer.getData(), byteOffset) & 0xFFFF;
		#else
		var ch1 = buffer.get(byteOffset);
		var ch2 = buffer.get(byteOffset + 1);

		return ((ch2 << 8) | ch1);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getUint16_BE(buffer:ArrayBuffer, byteOffset:Int):Null<UInt>
	{
		#if cpp
		var bufferData = buffer.getData();
		var ch1:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset) & 0xFF;
		var ch2:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset + 1) & 0xFF;
		return ((ch1 << 8) | ch2);
		#else
		var ch1 = buffer.get(byteOffset);
		var ch2 = buffer.get(byteOffset + 1);
		return ((ch1 << 8) | ch2);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setUint16(buffer:ArrayBuffer, byteOffset:Int, value:UInt)
	{
		#if cpp
		untyped __global__.__hxcpp_memory_set_ui16(buffer.getData(), byteOffset, value);
		#else
		setInt16(buffer, byteOffset, value);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setUint16_BE(buffer:ArrayBuffer, byteOffset:Int, value:UInt)
	{
		#if cpp
		var bufferData = buffer.getData();
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset, (value >> 8) & 0xFF);
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset + 1, value & 0xFF);
		#elseif neko
		if (value == null) value = 0;
		untyped var b = buffer.b;
		untyped __dollar__sset(b, byteOffset, (value >> 8) & 0xFF);
		untyped __dollar__sset(b, byteOffset + 1, (value) & 0xFF);
		#else
		buffer.set(byteOffset, (value >> 8) & 0xFF);
		buffer.set(byteOffset + 1, (value) & 0xFF);
		#end
	}

	// 32
	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getInt32(buffer:ArrayBuffer, byteOffset:Int):Int
	{
		#if cpp
		untyped return __global__.__hxcpp_memory_get_i32(buffer.getData(), byteOffset);
		#else
		return buffer.getInt32(byteOffset);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getInt32_BE(buffer:ArrayBuffer, byteOffset:Int):Int
	{
		#if cpp
		var bufferData = buffer.getData();
		var ch1:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset) & 0xFF;
		var ch2:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset + 1) & 0xFF;
		var ch3:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset + 2) & 0xFF;
		var ch4:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset + 3) & 0xFF;
		return (ch1 << 24) | (ch2 << 16) | (ch3 << 8) | ch4;
		#else
		var ch1 = buffer.get(byteOffset);
		var ch2 = buffer.get(byteOffset + 1);
		var ch3 = buffer.get(byteOffset + 2);
		var ch4 = buffer.get(byteOffset + 3);
		return (ch1 << 24) | (ch2 << 16) | (ch3 << 8) | ch4;
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setInt32(buffer:ArrayBuffer, byteOffset:Int, value:Int)
	{
		#if cpp
		untyped __global__.__hxcpp_memory_set_i32(buffer.getData(), byteOffset, value);
		#else
		#if neko
		if (value == null) value = 0;
		#end

		buffer.setInt32(byteOffset, value);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setInt32_BE(buffer:ArrayBuffer, byteOffset:Int, value:Int)
	{
		#if cpp
		var bufferData = buffer.getData();
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset, (value >> 24) & 0xFF);
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset + 1, (value >> 16) & 0xFF);
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset + 2, (value >> 8) & 0xFF);
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset + 3, value & 0xFF);
		#elseif neko
		if (value == null) value = 0;
		untyped var b = buffer.b;
		untyped __dollar__sset(b, byteOffset, (value >> 24) & 0xFF);
		untyped __dollar__sset(b, byteOffset + 1, (value >> 16) & 0xFF);
		untyped __dollar__sset(b, byteOffset + 2, (value >> 8) & 0xFF);
		untyped __dollar__sset(b, byteOffset + 3, value & 0xFF);
		#else
		buffer.set(byteOffset, (value >> 24) & 0xFF);
		buffer.set(byteOffset + 1, (value >> 16) & 0xFF);
		buffer.set(byteOffset + 2, (value >> 8) & 0xFF);
		buffer.set(byteOffset + 3, value & 0xFF);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getUint32(buffer:ArrayBuffer, byteOffset:Int):Null<UInt>
	{
		#if cpp
		untyped return __global__.__hxcpp_memory_get_ui32(buffer.getData(), byteOffset);
		#else
		var ch1:Int = buffer.get(byteOffset);
		var ch2:Int = buffer.get(byteOffset + 1);
		var ch3:Int = buffer.get(byteOffset + 2);
		var ch4:Int = buffer.get(byteOffset + 3);
		return ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getUint32_BE(buffer:ArrayBuffer, byteOffset:Int):Null<UInt>
	{
		#if cpp
		var bufferData = buffer.getData();
		var ch1:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset) & 0xFF;
		var ch2:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset + 1) & 0xFF;
		var ch3:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset + 2) & 0xFF;
		var ch4:Int = untyped __global__.__hxcpp_memory_get_byte(bufferData, byteOffset + 3) & 0xFF;
		return (ch1 << 24) | (ch2 << 16) | (ch3 << 8) | ch4;
		#else
		var ch1 = buffer.get(byteOffset);
		var ch2 = buffer.get(byteOffset + 1);
		var ch3 = buffer.get(byteOffset + 2);
		var ch4 = buffer.get(byteOffset + 3);
		return (ch1 << 24) | (ch2 << 16) | (ch3 << 8) | ch4;
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setUint32(buffer:ArrayBuffer, byteOffset:Int, value:UInt)
	{
		#if cpp
		untyped __global__.__hxcpp_memory_set_ui32(buffer.getData(), byteOffset, value);
		#else
		setInt32(buffer, byteOffset, value);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setUint32_BE(buffer:ArrayBuffer, byteOffset:Int, value:UInt):Void
	{
		#if cpp
		var bufferData = buffer.getData();
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset, (value >> 24) & 0xFF);
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset + 1, (value >> 16) & 0xFF);
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset + 2, (value >> 8) & 0xFF);
		untyped __global__.__hxcpp_memory_set_byte(bufferData, byteOffset + 3, value & 0xFF);
		#elseif neko
		if (value == null) value = 0;
		untyped var b = buffer.b;
		untyped __dollar__sset(b, byteOffset, (value >> 24) & 0xFF);
		untyped __dollar__sset(b, byteOffset + 1, (value >> 16) & 0xFF);
		untyped __dollar__sset(b, byteOffset + 2, (value >> 8) & 0xFF);
		untyped __dollar__sset(b, byteOffset + 3, value & 0xFF);
		#else
		buffer.set(byteOffset, (value >> 24) & 0xFF);
		buffer.set(byteOffset + 1, (value >> 16) & 0xFF);
		buffer.set(byteOffset + 2, (value >> 8) & 0xFF);
		buffer.set(byteOffset + 3, value & 0xFF);
		#end
	}

	// Float
	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getFloat32(buffer:ArrayBuffer, byteOffset:Int):Float
	{
		#if cpp
		untyped return __global__.__hxcpp_memory_get_float(buffer.getData(), byteOffset);
		#else
		return buffer.getFloat(byteOffset);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getFloat32_BE(buffer:ArrayBuffer, byteOffset:Int):Float
	{
		#if cpp
		untyped return __global__.__hxcpp_memory_get_float(buffer.getData(), byteOffset);
		#else
		return buffer.getFloat(byteOffset);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setFloat32(buffer:ArrayBuffer, byteOffset:Int, value:Float)
	{
		#if cpp
		untyped __global__.__hxcpp_memory_set_float(buffer.getData(), byteOffset, value);
		#else
		#if neko
		if (value == null) value = 0;
		#end
		buffer.setFloat(byteOffset, value);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setFloat32_BE(buffer:ArrayBuffer, byteOffset:Int, value:Float)
	{
		#if cpp
		untyped __global__.__hxcpp_memory_set_float(buffer.getData(), byteOffset, value);
		#else
		#if neko
		if (value == null) value = 0;
		#end
		buffer.setFloat(byteOffset, value);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getFloat64(buffer:ArrayBuffer, byteOffset:Int):Float
	{
		#if cpp
		untyped return __global__.__hxcpp_memory_get_double(buffer.getData(), byteOffset);
		#else
		return buffer.getDouble(byteOffset);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function getFloat64_BE(buffer:ArrayBuffer, byteOffset:Int):Float
	{
		#if cpp
		untyped return __global__.__hxcpp_memory_get_double(buffer.getData(), byteOffset);
		#else
		return buffer.getDouble(byteOffset);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setFloat64(buffer:ArrayBuffer, byteOffset:Int, value:Float)
	{
		#if cpp
		untyped __global__.__hxcpp_memory_set_double(buffer.getData(), byteOffset, value);
		#else
		#if neko
		if (value == null) value = 0;
		#end
		buffer.setDouble(byteOffset, value);
		#end
	}

	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	public static function setFloat64_BE(buffer:ArrayBuffer, byteOffset:Int, value:Float)
	{
		#if cpp
		untyped __global__.__hxcpp_memory_set_double(buffer.getData(), byteOffset, value);
		#else
		#if neko
		if (value == null) value = 0;
		#end
		buffer.setDouble(byteOffset, value);
		#end
	}

	// Internal
	#if !no_typedarray_inline
	#if (haxe_ver >= 4.0) extern #else @:extern #end
	inline
	#end
	// clamp a Int to a 0-255 Uint8 (for Uint8Clamped array)
	static function _clamp(_in:Float):Int
	{
		var _out = Std.int(_in);
		_out = _out > 255 ? 255 : _out;
		return _out < 0 ? 0 : _out;
	} // _clamp
}
#else // #error "ArrayBufferIO is not used on js target, use DataView instead"
#end // !js
