package lime.utils;

#if (js && !doc_gen)
#if haxe4
import js.lib.Uint8Array as JSUInt8Array;
#else
import js.html.Uint8Array as JSUInt8Array;
#end
@:forward
@:transitive
abstract UInt8Array(JSUInt8Array) from JSUInt8Array to JSUInt8Array
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
			this = new JSUInt8Array(elements);
		}
		else if (array != null)
		{
			this = new JSUInt8Array(untyped array);
		#if (openfl && commonjs)
		}
		else if (vector != null)
		{
			this = new JSUInt8Array(untyped (vector));
		#elseif openfl
		}
		else if (vector != null)
		{
			this = new JSUInt8Array(untyped untyped (vector).__array);
		#end
		}
		else if (view != null)
		{
			this = new JSUInt8Array(untyped view);
		}
		else if (buffer != null)
		{
			if (len == null)
			{
				this = new JSUInt8Array(buffer, byteoffset);
			}
			else
			{
				this = new JSUInt8Array(buffer, byteoffset, len);
			}
		}
		else
		{
			this = null;
		}
	}

	@:arrayAccess #if (haxe_ver >= 4.0) extern #else @:extern #end inline function __set(idx:Int, val:UInt):UInt
		return this[idx] = val;

	@:arrayAccess #if (haxe_ver >= 4.0) extern #else @:extern #end inline function __get(idx:Int):UInt
		return this[idx];

	// non spec haxe conversions
	inline public static function fromBytes(bytes:haxe.io.Bytes, ?byteOffset:Int, ?len:Int):UInt8Array
	{
		if (byteOffset == null) return new JSUInt8Array(cast bytes.getData());
		if (len == null) return new JSUInt8Array(cast bytes.getData(), byteOffset);
		return new JSUInt8Array(cast bytes.getData(), byteOffset, len);
	}

	inline public function toBytes():haxe.io.Bytes
	{
		return @:privateAccess new haxe.io.Bytes(cast new JSUInt8Array(this.buffer));
	}

	inline function toString()
		return this != null ? 'UInt8Array [byteLength:${this.byteLength}, length:${this.length}]' : null;
}
#else
import lime.utils.ArrayBufferView;

@:transitive
@:forward
abstract UInt8Array(ArrayBufferView) from ArrayBufferView to ArrayBufferView
{
	public inline static var BYTES_PER_ELEMENT:Int = 1;

	public var length(get, never):Int;

	#if (haxe_ver < 4.2)
	@:generic
	#end
	public inline function new<T>(?elements:Int, ?buffer:ArrayBuffer, ?array:Array<T>, #if openfl ?vector:openfl.Vector<Int>, #end ?view:ArrayBufferView,
			?byteoffset:Int = 0, ?len:Null<Int>)
	{
		if (elements != null)
		{
			this = new ArrayBufferView(elements, Uint8);
		}
		else if (array != null)
		{
			this = new ArrayBufferView(0, Uint8).initArray(array);
		#if openfl
		}
		else if (vector != null)
		{
			this = new ArrayBufferView(0, Uint8).initArray(untyped (vector).__array);
		#end
		}
		else if (view != null)
		{
			this = new ArrayBufferView(0, Uint8).initTypedArray(view);
		}
		else if (buffer != null)
		{
			this = new ArrayBufferView(0, Uint8).initBuffer(buffer, byteoffset, len);
		}
		else
		{
			throw "Invalid constructor arguments for UInt8Array";
		}
	}

	// Public API
	public inline function subarray(begin:Int, end:Null<Int> = null):UInt8Array
		return this.subarray(begin, end);

	// non spec haxe conversions
	inline public static function fromBytes(bytes:haxe.io.Bytes, ?byteOffset:Int = 0, ?len:Int):UInt8Array
	{
		return new UInt8Array(bytes, byteOffset, len);
	}

	inline public function toBytes():haxe.io.Bytes
	{
		return this.buffer;
	}

	// Internal
	inline function toString()
		return this != null ? 'UInt8Array [byteLength:${this.byteLength}, length:${this.length}]' : null;

	inline function get_length()
		return this.length;

	@:noCompletion
	@:arrayAccess #if (haxe_ver >= 4.0) extern #else @:extern #end
	public inline function __get(idx:Int)
	{
		return ArrayBufferIO.getUint8(this.buffer, this.byteOffset + idx);
	}

	@:noCompletion
	@:arrayAccess #if (haxe_ver >= 4.0) extern #else @:extern #end
	public inline function __set(idx:Int, val:UInt)
	{
		ArrayBufferIO.setUint8(this.buffer, this.byteOffset + idx, val);
		return val;
	}
}
#end // !js
