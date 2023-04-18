package lime.utils;

import haxe.io.BytesData;
import haxe.io.Bytes;
import lime.utils.Bytes as LimeBytes;

@:access(haxe.io.Bytes)
@:access(lime.utils.BytePointerData)
@:forward()
@:transitive
abstract BytePointer(BytePointerData) from BytePointerData to BytePointerData
{
	public inline function new(bytes:Bytes = null, offset:Int = 0):Void
	{
		this = new BytePointerData(bytes, offset);
	}

	public function set(?bytes:Bytes, ?bufferView:ArrayBufferView, ?buffer:ArrayBuffer, ?offset:Int):Void
	{
		if (buffer != null)
		{
			#if js
			bytes = Bytes.ofData(cast buffer);
			#else
			bytes = buffer;
			#end
		}

		if (bytes != null || bufferView == null)
		{
			this.bytes = bytes;
			this.offset = offset != null ? offset : 0;
		}
		else
		{
			#if js
			this.bytes = Bytes.ofData(cast bufferView.buffer);
			#else
			this.bytes = bufferView.buffer;
			#end

			this.offset = offset != null ? bufferView.byteOffset + offset : bufferView.byteOffset;
		}
	}

	@:arrayAccess @:noCompletion private inline function __arrayGet(index:Int):Int
	{
		return (this.bytes != null) ? this.bytes.get(index + this.offset) : 0;
	}

	@:arrayAccess @:noCompletion private inline function __arraySet(index:Int, value:Int):Int
	{
		if (this.bytes == null) this.bytes.set(index + this.offset, value);
		return value;
	}

	@:from @:noCompletion public static function fromArrayBufferView(arrayBufferView:ArrayBufferView):BytePointer
	{
		if (arrayBufferView == null) return null;

		#if (js && !doc_gen)
		return new BytePointerData(Bytes.ofData(arrayBufferView.buffer), arrayBufferView.byteOffset);
		#else
		return new BytePointerData((arrayBufferView.buffer : Bytes), arrayBufferView.byteOffset);
		#end
	}

	@:from @:noCompletion public static function fromArrayBuffer(buffer:ArrayBuffer):BytePointer
	{
		if (buffer == null) return null;

		#if (js && !doc_gen)
		return new BytePointerData(Bytes.ofData(buffer), 0);
		#else
		return new BytePointerData((buffer : Bytes), 0);
		#end
	}

	@:from @:noCompletion public static function fromBytes(bytes:Bytes):BytePointer
	{
		return new BytePointerData(bytes, 0);
	}

	@:from @:noCompletion public static function fromBytesData(bytesData:BytesData):BytePointer
	{
		if (bytesData == null) return new BytePointerData(null, 0);
		else
			return new BytePointerData(Bytes.ofData(bytesData), 0);
	}

	public static function fromFile(path:String):BytePointer
	{
		return new BytePointerData(LimeBytes.fromFile(path), 0);
	}

	@:from @:noCompletion public static function fromLimeBytes(bytes:LimeBytes):BytePointer
	{
		return new BytePointerData(bytes, 0);
	}

	@:to @:noCompletion public static function toUInt8Array(bytePointer:BytePointer):UInt8Array
	{
		#if (js && !doc_gen)
		return new UInt8Array(bytePointer.bytes.getData(), Std.int(bytePointer.offset / 8));
		#else
		return new UInt8Array(bytePointer.bytes, Std.int(bytePointer.offset / 8));
		#end
	}

	@:to @:noCompletion public static function toUInt8ClampedArray(bytePointer:BytePointer):UInt8ClampedArray
	{
		if (bytePointer == null || bytePointer.bytes == null) return null;

		#if (js && !doc_gen)
		return new UInt8ClampedArray(bytePointer.bytes.getData(), Std.int(bytePointer.offset / 8));
		#else
		return new UInt8ClampedArray(bytePointer.bytes, Std.int(bytePointer.offset / 8));
		#end
	}

	@:to @:noCompletion public static function toInt8Array(bytePointer:BytePointer):Int8Array
	{
		if (bytePointer == null || bytePointer.bytes == null) return null;

		#if (js && !doc_gen)
		return new Int8Array(bytePointer.bytes.getData(), Std.int(bytePointer.offset / 8));
		#else
		return new Int8Array(bytePointer.bytes, Std.int(bytePointer.offset / 8));
		#end
	}

	@:to @:noCompletion public static function toUInt16Array(bytePointer:BytePointer):UInt16Array
	{
		if (bytePointer == null || bytePointer.bytes == null) return null;

		#if (js && !doc_gen)
		return new UInt16Array(bytePointer.bytes.getData(), Std.int(bytePointer.offset / 16));
		#else
		return new UInt16Array(bytePointer.bytes, Std.int(bytePointer.offset / 16));
		#end
	}

	@:to @:noCompletion public static function toInt16Array(bytePointer:BytePointer):Int16Array
	{
		if (bytePointer == null || bytePointer.bytes == null) return null;

		#if (js && !doc_gen)
		return new Int16Array(bytePointer.bytes.getData(), Std.int(bytePointer.offset / 16));
		#else
		return new Int16Array(bytePointer.bytes, Std.int(bytePointer.offset / 16));
		#end
	}

	@:to @:noCompletion public static function toUInt32Array(bytePointer:BytePointer):UInt32Array
	{
		if (bytePointer == null || bytePointer.bytes == null) return null;

		#if (js && !doc_gen)
		return new UInt32Array(bytePointer.bytes.getData(), Std.int(bytePointer.offset / 32));
		#else
		return new UInt32Array(bytePointer.bytes, Std.int(bytePointer.offset / 32));
		#end
	}

	@:to @:noCompletion public static function toInt32Array(bytePointer:BytePointer):Int32Array
	{
		if (bytePointer == null || bytePointer.bytes == null) return null;

		#if (js && !doc_gen)
		return new Int32Array(bytePointer.bytes.getData(), Std.int(bytePointer.offset / 32));
		#else
		return new Int32Array(bytePointer.bytes, Std.int(bytePointer.offset / 32));
		#end
	}

	@:to @:noCompletion public static function toFloat32Array(bytePointer:BytePointer):Float32Array
	{
		if (bytePointer == null || bytePointer.bytes == null) return null;

		#if (js && !doc_gen)
		return new Float32Array(bytePointer.bytes.getData(), Std.int(bytePointer.offset / 32));
		#else
		return new Float32Array(bytePointer.bytes, Std.int(bytePointer.offset / 32));
		#end
	}

	@:to @:noCompletion public static function toFloat64Array(bytePointer:BytePointer):Float64Array
	{
		if (bytePointer == null || bytePointer.bytes == null) return null;

		#if (js && !doc_gen)
		return new Float64Array(bytePointer.bytes.getData(), Std.int(bytePointer.offset / 64));
		#else
		return new Float64Array(bytePointer.bytes, Std.int(bytePointer.offset / 64));
		#end
	}
}

@:noCompletion @:dox(hide) class BytePointerData
{
	public var bytes:Bytes;
	public var offset:Int;

	public function new(bytes:Bytes, offset:Int)
	{
		this.bytes = bytes;
		this.offset = offset;
	}
}
