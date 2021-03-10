package lime.utils;

#if (js && !doc_gen)
#if haxe4
import js.lib.Uint8Array as JSUInt8Array;
import js.lib.Uint8ClampedArray as JSUInt8ClampedArray;
#else
import js.html.Uint8Array as JSUInt8Array;
import js.html.Uint8ClampedArray as JSUInt8ClampedArray;
#end
@:forward
@:transitive
abstract UInt8ClampedArray(JSUInt8ClampedArray) from JSUInt8ClampedArray to JSUInt8ClampedArray
{
	@:to inline function toArrayBufferView():ArrayBufferView
		return this;

	public inline static var BYTES_PER_ELEMENT:Int = 1;

	@:generic
	public inline function new<T>(?elements:Int, ?array:Array<T>, #if openfl ?vector:openfl.Vector<Int>, #end ?view:ArrayBufferView, ?buffer:ArrayBuffer,
			?byteoffset:Int = 0, ?len:Null<Int>)
	{
		if (elements != null)
		{
			this = new JSUInt8ClampedArray(elements);
		}
		else if (array != null)
		{
			this = new JSUInt8ClampedArray(untyped array);
		#if (openfl && commonjs)
		}
		else if (vector != null)
		{
			this = new JSUInt8ClampedArray(untyped (vector));
		#elseif openfl
		}
		else if (vector != null)
		{
			this = new JSUInt8ClampedArray(untyped untyped (vector).__array);
		#end
		}
		else if (view != null)
		{
			this = new JSUInt8ClampedArray(untyped view);
		}
		else if (buffer != null)
		{
			if (len == null)
			{
				this = new JSUInt8ClampedArray(buffer, byteoffset);
			}
			else
			{
				this = new JSUInt8ClampedArray(buffer, byteoffset, len);
			}
		}
		else
		{
			this = null;
		}
	}

	@:arrayAccess @:extern inline function __set(idx:Int, val:UInt):UInt
		return this[idx] = _clamp(val);

	@:arrayAccess @:extern inline function __get(idx:Int):UInt
		return this[idx];

	// non spec haxe conversions
	inline public static function fromBytes(bytes:haxe.io.Bytes, ?byteOffset:Int = 0, ?len:Int):UInt8ClampedArray
	{
		if (byteOffset == null) return new JSUInt8ClampedArray(cast bytes.getData());
		if (len == null) return new JSUInt8ClampedArray(cast bytes.getData(), byteOffset);
		return new JSUInt8ClampedArray(cast bytes.getData(), byteOffset, len);
	}

	inline public function toBytes():haxe.io.Bytes
	{
		return @:privateAccess new haxe.io.Bytes(cast new JSUInt8Array(this.buffer));
	}

	inline function toString()
		return this != null ? 'UInt8ClampedArray [byteLength:${this.byteLength}, length:${this.length}]' : null;

	// internal
	// clamp a Int to a 0-255 Uint8
	static function _clamp(_in:Float):Int
	{
		var _out = Std.int(_in);
		_out = _out > 255 ? 255 : _out;
		return _out < 0 ? 0 : _out;
	} // _clamp
}
#else
import lime.utils.ArrayBufferView;
@:transitive
@:forward
@:arrayAccess
abstract UInt8ClampedArray(ArrayBufferView) from ArrayBufferView to ArrayBufferView
{
	public inline static var BYTES_PER_ELEMENT:Int = 1;

	public var length(get, never):Int;

	#if (haxe_ver < 4.2) @:generic #end
	public inline function new<T>(?elements:Int, ?buffer:ArrayBuffer, ?array:Array<T>, #if openfl ?vector:openfl.Vector<Int>, #end ?view:ArrayBufferView,
			?byteoffset:Int = 0, ?len:Null<Int>)
	{
		if (elements != null)
		{
			this = new ArrayBufferView(elements, Uint8Clamped);
		}
		else if (array != null)
		{
			this = new ArrayBufferView(0, Uint8Clamped).initArray(array);
		#if openfl
		}
		else if (vector != null)
		{
			this = new ArrayBufferView(0, Uint8Clamped).initArray(untyped (vector).__array);
		#end
		}
		else if (view != null)
		{
			this = new ArrayBufferView(0, Uint8Clamped).initTypedArray(view);
		}
		else if (buffer != null)
		{
			this = new ArrayBufferView(0, Uint8Clamped).initBuffer(buffer, byteoffset, len);
		}
		else
		{
			throw "Invalid constructor arguments for UInt8ClampedArray";
		}
	}

	// Public API
	public inline function subarray(begin:Int, end:Null<Int> = null):UInt8ClampedArray
		return this.subarray(begin, end);

	// non spec haxe conversions
	inline public static function fromBytes(bytes:haxe.io.Bytes, ?byteOffset:Int = 0, ?len:Int):UInt8ClampedArray
	{
		return new UInt8ClampedArray(bytes, byteOffset, len);
	}

	inline public function toBytes():haxe.io.Bytes
	{
		return this.buffer;
	}

	// Internal
	inline function get_length()
		return this.length;

	@:noCompletion
	@:arrayAccess @:extern
	public inline function __get(idx:Int)
	{
		return ArrayBufferIO.getUint8(this.buffer, this.byteOffset + idx);
	}

	@:noCompletion
	@:arrayAccess @:extern
	public inline function __set(idx:Int, val:UInt)
	{
		ArrayBufferIO.setUint8Clamped(this.buffer, this.byteOffset + idx, val);
		return val;
	}

	inline function toString()
		return this != null ? 'UInt8ClampedArray [byteLength:${this.byteLength}, length:${this.length}]' : null;
}
#end // !js
