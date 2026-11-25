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
		byteOffset = 0;
		length = view.length;
		byteLength = toByteLength(length);
		buffer = new ArrayBuffer(byteLength);

		if (view.type == type)
		{
			// Only the view's own bytes
			buffer.blit(0, view.buffer, view.byteOffset, view.byteLength);
		}
		else
		{
			// Each value is converted, as in ECMAScript
			copyElements(view, 0);
		}

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
			if (offset < 0 || offset + view.length > this.length)
			{
				throw TAError.RangeError;
			}

			if (view.type == type)
			{
				// Bytes are only copied as they are between the same types
				buffer.blit(byteOffset + toByteLength(offset), view.buffer, view.byteOffset, view.byteLength);
			}
			else
			{
				// A source that shares this buffer is read as it was before the copy
				copyElements(view.buffer == buffer ? copyOf(view) : view, offset);
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
	static function copyOf(view:ArrayBufferView):ArrayBufferView
	{
		var copy = new ArrayBufferView(null, view.type);
		copy.byteOffset = 0;
		copy.byteLength = view.byteLength;
		copy.length = view.length;
		copy.buffer = new ArrayBuffer(view.byteLength);
		copy.buffer.blit(0, view.buffer, view.byteOffset, view.byteLength);
		return copy;
	}

	@:generic
	@:allow(lime.utils)
	#if !no_typedarray_inline
	inline
	#end
	function subarray<T_subarray>(begin:Int, end:Null<Int> = null):T_subarray
	{
		// As in ECMAScript, negative indices count back from the end, and both
		// are clamped to this view so the subarray never reaches outside it
		if (end == null) end = length;
		if (begin < 0) begin = (begin + length < 0) ? 0 : begin + length;
		else if (begin > length) begin = length;
		if (end < 0) end = (end + length < 0) ? 0 : end + length;
		else if (end > length) end = length;
		var len = end - begin;
		if (len < 0) len = 0;
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
	function copyFromArray(array:Array< #if hl Dynamic #else Float #end>, offset:Int = 0)
	{
		var len = array.length;

		if (offset < 0 || offset + len > this.length)
		{
			throw TAError.RangeError;
		}

		// From the view's own offset, as element access is
		var pos = byteOffset + toByteLength(offset);

		for (i in 0...len)
		{
			#if (neko || hl)
			var element:Dynamic = array[i];
			var value:Float = (element == null) ? 0 : element;
			#else
			var value:Float = array[i];
			#end

			setElement(type, buffer, pos, value);
			pos += bytesPerElement;
		}
	}

	// Converts each element of view to this type, writing from element offset
	function copyElements(view:ArrayBufferView, offset:Int):Void
	{
		var fromPos = view.byteOffset;
		var toPos = byteOffset + toByteLength(offset);

		for (i in 0...view.length)
		{
			setElement(type, buffer, toPos, getElement(view.type, view.buffer, fromPos));
			fromPos += view.bytesPerElement;
			toPos += bytesPerElement;
		}
	}

	// An element as the Number ECMAScript reads, with a UInt32 one unsigned
	@:noCompletion @:allow(lime.utils) static function getElement(type:TypedArrayType, buffer:ArrayBuffer, pos:Int):Float
	{
		return switch (type)
		{
			case Int8: ArrayBufferIO.getInt8(buffer, pos);
			case Int16: ArrayBufferIO.getInt16(buffer, pos);
			case Int32: ArrayBufferIO.getInt32(buffer, pos);
			case Uint8, Uint8Clamped: ArrayBufferIO.getUint8(buffer, pos);
			case Uint16: ArrayBufferIO.getUint16(buffer, pos);
			case Uint32:
				var bits:Int = ArrayBufferIO.getInt32(buffer, pos);
				bits < 0 ? bits + 4294967296.0 : bits;
			case Float32: ArrayBufferIO.getFloat32(buffer, pos);
			case Float64: ArrayBufferIO.getFloat64(buffer, pos);
			case None: throw "getElement on a base type ArrayBuffer";
		}
	}

	// Writes value as ECMAScript's ToInt8, ToUint8Clamp and so on convert it
	@:noCompletion @:allow(lime.utils) static function setElement(type:TypedArrayType, buffer:ArrayBuffer, pos:Int, value:Float):Void
	{
		switch (type)
		{
			case Int8: ArrayBufferIO.setInt8(buffer, pos, toInt32(value));
			case Int16: ArrayBufferIO.setInt16(buffer, pos, toInt32(value));
			case Int32: ArrayBufferIO.setInt32(buffer, pos, toInt32(value));
			case Uint8: ArrayBufferIO.setUint8(buffer, pos, toInt32(value));
			case Uint8Clamped: ArrayBufferIO.setUint8(buffer, pos, toUint8Clamp(value));
			case Uint16: ArrayBufferIO.setUint16(buffer, pos, toInt32(value));
			case Uint32: ArrayBufferIO.setInt32(buffer, pos, toInt32(value));
			case Float32: ArrayBufferIO.setFloat32(buffer, pos, value);
			case Float64: ArrayBufferIO.setFloat64(buffer, pos, value);
			case None: throw "setElement on a base type ArrayBuffer";
		}
	}

	// ECMAScript's ToInt32: truncate, then wrap modulo 2^32, with NaN and the
	// infinities 0. Std.int leaves values outside the Int32 range unspecified,
	// and Neko and HashLink give -2147483648 for them.
	@:noCompletion @:allow(lime.utils) static function toInt32(value:Float):Int
	{
		// NaN fails both comparisons
		if (value >= -2147483648.0 && value <= 2147483647.0) return Std.int(value);
		if (Math.isNaN(value) || !Math.isFinite(value)) return 0;

		var truncated = value < 0 ? Math.fceil(value) : Math.ffloor(value);
		var wrapped = truncated - 4294967296.0 * Math.ffloor(truncated / 4294967296.0);
		if (wrapped >= 2147483648.0) wrapped -= 4294967296.0;
		return Std.int(wrapped);
	}

	// ECMAScript's ToUint8Clamp: clamp to 0...255, rounding half to even
	@:noCompletion @:allow(lime.utils) static function toUint8Clamp(value:Float):Int
	{
		// NaN fails the comparison too
		if (!(value > 0)) return 0;
		if (value >= 255) return 255;

		var floor = Math.ffloor(value);
		var whole = Std.int(floor);
		var fraction = value - floor;

		if (fraction < 0.5) return whole;
		if (fraction > 0.5) return whole + 1;
		return (whole & 1) == 0 ? whole : whole + 1;
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
	public static function setUint8Clamped(buffer:ArrayBuffer, byteOffset:Int, value:Float)
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
	// clamp a value to a 0-255 Uint8 (for Uint8Clamped array). The value is
	// clamped before Std.int sees it, since converting a float outside the Int32
	// range is undefined in C++, and ARM64 and x86 give different results.
	static function _clamp(_in:Float):Int
	{
		// NaN fails the comparison too
		if (!(_in > 0)) return 0;
		if (_in >= 255) return 255;
		return Std.int(_in);
	} // _clamp
}
#else // #error "ArrayBufferIO is not used on js target, use DataView instead"
#end // !js
