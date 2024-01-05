package lime.utils;

#if (js && !doc_gen)
#if haxe4
import js.lib.Int16Array as JSInt16Array;
import js.lib.Uint8Array as JSUInt8Array;
#else
import js.html.Int16Array as JSInt16Array;
import js.html.Uint8Array as JSUInt8Array;
#end
@:forward
@:transitive
abstract Int16Array(JSInt16Array) from JSInt16Array to JSInt16Array
{
	@:to inline function toArrayBufferView():ArrayBufferView
		return this;

	public inline static var BYTES_PER_ELEMENT:Int = 2;

	@:generic
	public inline function new<T>(?elements:Int, ?array:Array<T>, #if openfl ?vector:openfl.Vector<Int>, #end ?view:ArrayBufferView, ?buffer:ArrayBuffer,
			?byteoffset:Int = 0, ?len:Null<Int>)
	{
		if (elements != null)
		{
			this = new JSInt16Array(elements);
		}
		else if (array != null)
		{
			this = new JSInt16Array(untyped array);
		#if (openfl && commonjs)
		}
		else if (vector != null)
		{
			this = new JSInt16Array(untyped (vector));
		#elseif openfl
		}
		else if (vector != null)
		{
			this = new JSInt16Array(untyped untyped (vector).__array);
		#end
		}
		else if (view != null)
		{
			this = new JSInt16Array(untyped view);
		}
		else if (buffer != null)
		{
			if (len == null)
			{
				this = new JSInt16Array(buffer, byteoffset);
			}
			else
			{
				this = new JSInt16Array(buffer, byteoffset, len);
			}
		}
		else
		{
			this = null;
		}
	}

	@:arrayAccess #if (haxe_ver >= 4.0) extern #else @:extern #end inline function __set(idx:Int, val:Int):Int
		return this[idx] = val;

	@:arrayAccess #if (haxe_ver >= 4.0) extern #else @:extern #end inline function __get(idx:Int):Int
		return this[idx];

	// non spec haxe conversions
	inline public static function fromBytes(bytes:haxe.io.Bytes, ?byteOffset:Int = 0, ?len:Int):Int16Array
	{
		if (byteOffset == null) return new JSInt16Array(cast bytes.getData());
		if (len == null) return new JSInt16Array(cast bytes.getData(), byteOffset);
		return new JSInt16Array(cast bytes.getData(), byteOffset, len);
	}

	inline public function toBytes():haxe.io.Bytes
	{
		return @:privateAccess new haxe.io.Bytes(cast new JSUInt8Array(this.buffer));
	}

	inline function toString()
		return this != null ? 'Int16Array [byteLength:${this.byteLength}, length:${this.length}]' : null;
}
#else
import lime.utils.ArrayBufferView;

@:transitive
@:forward
abstract Int16Array(ArrayBufferView) from ArrayBufferView to ArrayBufferView
{
	public inline static var BYTES_PER_ELEMENT:Int = 2;

	public var length(get, never):Int;

	#if (haxe_ver < 4.2)
	@:generic
	#end
	public inline function new<T>(?elements:Int, ?buffer:ArrayBuffer, ?array:Array<T>, #if openfl ?vector:openfl.Vector<Int>, #end ?view:ArrayBufferView,
			?byteoffset:Int = 0, ?len:Null<Int>)
	{
		if (elements != null)
		{
			this = new ArrayBufferView(elements, Int16);
		}
		else if (array != null)
		{
			this = new ArrayBufferView(0, Int16).initArray(array);
		#if openfl
		}
		else if (vector != null)
		{
			this = new ArrayBufferView(0, Int16).initArray(untyped (vector).__array);
		#end
		}
		else if (view != null)
		{
			this = new ArrayBufferView(0, Int16).initTypedArray(view);
		}
		else if (buffer != null)
		{
			this = new ArrayBufferView(0, Int16).initBuffer(buffer, byteoffset, len);
		}
		else
		{
			throw "Invalid constructor arguments for Int16Array";
		}
	}

	// Public API
	public inline function subarray(begin:Int, end:Null<Int> = null):Int16Array
		return this.subarray(begin, end);

	// non spec haxe conversions
	inline public static function fromBytes(bytes:haxe.io.Bytes, ?byteOffset:Int = 0, ?len:Int):Int16Array
	{
		return new Int16Array(bytes, byteOffset, len);
	}

	inline public function toBytes():haxe.io.Bytes
	{
		return this.buffer;
	}

	// Internal
	inline function get_length()
		return this.length;

	@:noCompletion
	@:arrayAccess #if (haxe_ver >= 4.0) extern #else @:extern #end
	public inline function __get(idx:Int)
	{
		return ArrayBufferIO.getInt16(this.buffer, this.byteOffset + (idx * BYTES_PER_ELEMENT));
	}

	@:noCompletion
	@:arrayAccess #if (haxe_ver >= 4.0) extern #else @:extern #end
	public inline function __set(idx:Int, val:Int)
	{
		ArrayBufferIO.setInt16(this.buffer, this.byteOffset + (idx * BYTES_PER_ELEMENT), val);
		return val;
	}

	inline function toString()
		return this != null ? 'Int16Array [byteLength:${this.byteLength}, length:${this.length}]' : null;
}
#end // !js
