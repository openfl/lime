package lime.utils;

#if (js && !doc_gen)
#if haxe4
import js.lib.Float32Array as JSFloat32Array;
import js.lib.Uint8Array as JSUInt8Array;
#else
import js.html.Float32Array as JSFloat32Array;
import js.html.Uint8Array as JSUInt8Array;
#end
@:forward
@:arrayAccess
@:transitive
abstract Float32Array(JSFloat32Array) from JSFloat32Array to JSFloat32Array
{
	@:to function toArrayBufferView():ArrayBufferView
		return this;

	public inline static var BYTES_PER_ELEMENT:Int = 4;

	@:generic
	public inline function new<T>(?elements:Int, ?array:Array<T>, #if openfl ?vector:openfl.Vector<Float>, #end ?view:ArrayBufferView, ?buffer:ArrayBuffer,
			?byteoffset:Int = 0, ?len:Null<Int>)
	{
		if (elements != null)
		{
			this = new JSFloat32Array(elements);
		}
		else if (array != null)
		{
			this = new JSFloat32Array(untyped array);
		#if (openfl && commonjs)
		}
		else if (vector != null)
		{
			this = new JSFloat32Array(untyped (vector));
		#elseif openfl
		}
		else if (vector != null)
		{
			this = new JSFloat32Array(untyped untyped (vector).__array);
		#end
		}
		else if (view != null)
		{
			this = new JSFloat32Array(untyped view);
		}
		else if (buffer != null)
		{
			if (len == null)
			{
				this = new JSFloat32Array(buffer, byteoffset);
			}
			else
			{
				this = new JSFloat32Array(buffer, byteoffset, len);
			}
		}
		else
		{
			this = null;
		}
	}

	@:arrayAccess @:extern inline function __set(idx:Int, val:Float):Float
		return this[idx] = val;

	@:arrayAccess @:extern inline function __get(idx:Int):Float
		return this[idx];

	// non spec haxe conversions
	inline public static function fromBytes(bytes:haxe.io.Bytes, ?byteOffset:Int = 0, ?len:Int):Float32Array
	{
		if (byteOffset == null) return new JSFloat32Array(cast bytes.getData());
		if (len == null) return new JSFloat32Array(cast bytes.getData(), byteOffset);
		return new JSFloat32Array(cast bytes.getData(), byteOffset, len);
	}

	inline public function toBytes():haxe.io.Bytes
	{
		return @:privateAccess new haxe.io.Bytes(cast new JSUInt8Array(this.buffer));
	}

	inline function toString()
		return this != null ? 'Float32Array [byteLength:${this.byteLength}, length:${this.length}]' : null;
}
#else
import lime.utils.ArrayBuffer;
import lime.utils.ArrayBufferView;

@:transitive
@:forward
abstract Float32Array(ArrayBufferView) from ArrayBufferView to ArrayBufferView
{
	public inline static var BYTES_PER_ELEMENT:Int = 4;
	public static var hello:Int;

	public var length(get, never):Int;

	#if (haxe_ver < 4.2) @:generic #end
	public inline function new<T>(?elements:Int, ?buffer:ArrayBuffer, ?array:Array<T>, #if openfl ?vector:openfl.Vector<Float>, #end ?view:ArrayBufferView,
			?byteoffset:Int = 0, ?len:Null<Int>)
	{
		if (elements != null)
		{
			this = new ArrayBufferView(elements, Float32);
		}
		else if (array != null)
		{
			this = new ArrayBufferView(0, Float32).initArray(array);
		#if openfl
		}
		else if (vector != null)
		{
			this = new ArrayBufferView(0, Float32).initArray(untyped (vector).__array);
		#end
		}
		else if (view != null)
		{
			this = new ArrayBufferView(0, Float32).initTypedArray(view);
		}
		else if (buffer != null)
		{
			this = new ArrayBufferView(0, Float32).initBuffer(buffer, byteoffset, len);
		}
		else
		{
			throw "Invalid constructor arguments for Float32Array";
		}
	}

	// Public API
	public inline function subarray(begin:Int, end:Null<Int> = null):Float32Array
		return this.subarray(begin, end);

	// non spec haxe conversions
	inline public static function fromBytes(bytes:haxe.io.Bytes, ?byteOffset:Int = 0, ?len:Int):Float32Array
	{
		return new Float32Array(bytes, byteOffset, len);
	}

	inline public function toBytes():haxe.io.Bytes
	{
		return this.buffer;
	}

	// Internal
	inline function toString()
		return this != null ? 'Float32Array [byteLength:${this.byteLength}, length:${this.length}]' : null;

	@:extern inline function get_length()
		return this.length;

	@:noCompletion
	@:arrayAccess @:extern
	public inline function __get(idx:Int):Float
	{
		return ArrayBufferIO.getFloat32(this.buffer, this.byteOffset + (idx * BYTES_PER_ELEMENT));
	}

	@:noCompletion
	@:arrayAccess @:extern
	public inline function __set(idx:Int, val:Float):Float
	{
		ArrayBufferIO.setFloat32(this.buffer, this.byteOffset + (idx * BYTES_PER_ELEMENT), val);
		return val;
	}
}
#end // !js
