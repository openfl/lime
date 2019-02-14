package lime.utils;

#if (js && !doc_gen) @:forward
abstract Int16Array(js.html.Int16Array) from js.html.Int16Array to js.html.Int16Array
{
	public inline static var BYTES_PER_ELEMENT:Int = 2;

	@:generic
	public inline function new<T>(?elements:Int, ?array:Array<T>, #if openfl ? vector : openfl.Vector<Int>, #end?view:ArrayBufferView, ?buffer:ArrayBuffer,
			?byteoffset:Int = 0, ?len:Null<Int>)
	{
		if (elements != null)
		{
			this = new js.html.Int16Array(elements);
		}
		else if (array != null)
		{
			this = new js.html.Int16Array(untyped array);
			#if (openfl && commonjs)
			}
			else if (vector != null) {this = new js.html.Int16Array(untyped (vector));
			#elseif openfl
			}
			else if (vector != null) {this = new js.html.Int16Array(untyped untyped (vector).__array);
			#end
		}
		else if (view != null)
		{
			this = new js.html.Int16Array(untyped view);
		}
		else if (buffer != null)
		{
			if (len == null)
			{
				this = new js.html.Int16Array(buffer, byteoffset);
			}
			else
			{
				this = new js.html.Int16Array(buffer, byteoffset, len);
			}
		}
		else
		{
			this = null;
		}
	}

	@:arrayAccess @:extern inline function __set(idx:Int, val:Int):Int
		return this[idx] = val;

	@:arrayAccess @:extern inline function __get(idx:Int):Int
		return this[idx];

	// non spec haxe conversions
	inline public static function fromBytes(bytes:haxe.io.Bytes, ?byteOffset:Int = 0, ?len:Int):Int16Array
	{
		if (byteOffset == null) return new js.html.Int16Array(cast bytes.getData());
		if (len == null) return new js.html.Int16Array(cast bytes.getData(), byteOffset);
		return new js.html.Int16Array(cast bytes.getData(), byteOffset, len);
	}

	inline public function toBytes():haxe.io.Bytes
	{
		return @:privateAccess new haxe.io.Bytes(cast new js.html.Uint8Array(this.buffer));
	}

	inline function toString()
		return this != null ? 'Int16Array [byteLength:${this.byteLength}, length:${this.length}]' : null;
} #else import lime.utils.ArrayBufferView;

@:forward
abstract Int16Array(ArrayBufferView) from ArrayBufferView to ArrayBufferView
{
	public inline static var BYTES_PER_ELEMENT:Int = 2;

	public var length(get, never):Int;

	@:generic
	public inline function new<T>(?elements:Int, ?buffer:ArrayBuffer, ?array:Array<T>, #if openfl ? vector : openfl.Vector<Int>, #end?view:ArrayBufferView,
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
			else if (vector != null) {this = new ArrayBufferView(0, Int16).initArray(untyped (vector).__array);
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
	@:arrayAccess @:extern
	public inline function __get(idx:Int)
	{
		return ArrayBufferIO.getInt16(this.buffer, this.byteOffset + (idx * BYTES_PER_ELEMENT));
	}

	@:noCompletion
	@:arrayAccess @:extern
	public inline function __set(idx:Int, val:Int)
	{
		ArrayBufferIO.setInt16(this.buffer, this.byteOffset + (idx * BYTES_PER_ELEMENT), val);
		return val;
	}

	inline function toString()
		return this != null ? 'Int16Array [byteLength:${this.byteLength}, length:${this.length}]' : null;
} #end // !js
