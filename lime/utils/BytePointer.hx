package lime.utils;


import haxe.io.BytesData;
import haxe.io.Bytes;
import lime.utils.Bytes in LimeBytes;

@:access(haxe.io.Bytes)
@:access(lime.utils.BytePointerData)
@:forward()


abstract BytePointer(BytePointerData) from BytePointerData to BytePointerData {
	
	
	public inline function new (bytes:Bytes, offset:Int = 0):Void {
		
		this = new BytePointerData (bytes, offset);
		
	}
	
	
	@:arrayAccess @:noCompletion private inline function get (index:Int):Int {
		
		return this.bytes.get (index + this.offset);
		
	}
	
	
	@:arrayAccess @:noCompletion private inline function set (index:Int, value:Int):Int {
		
		this.bytes.set (index + this.offset, value);
		return value;
		
	}
	
	
	@:from @:noCompletion public static function fromArrayBufferView (arrayBufferView:ArrayBufferView):BytePointer {
		
		if (arrayBufferView == null) return null;
		
		#if (js && !display)
		return new BytePointerData (Bytes.ofData (arrayBufferView.buffer), arrayBufferView.byteOffset);
		#else
		return new BytePointerData ((arrayBufferView.buffer:Bytes), arrayBufferView.byteOffset);
		#end
		
	}
	
	
	@:from @:noCompletion public static function fromArrayBuffer (buffer:ArrayBuffer):BytePointer {
		
		if (buffer == null) return null;
		
		#if (js && !display)
		return new BytePointerData (Bytes.ofData (buffer), 0);
		#else
		return new BytePointerData ((buffer:Bytes), 0);
		#end
		
	}
	
	
	@:from @:noCompletion public static function fromBytes (bytes:Bytes):BytePointer {
		
		if (bytes == null) return null;
		
		return new BytePointerData (bytes, 0);
		
	}
	
	
	@:from @:noCompletion public static function fromBytesData (bytesData:BytesData):BytePointer {
		
		if (bytesData == null) return null;
		
		return new BytePointerData (Bytes.ofData (bytesData), 0);
		
	}
	
	
	public static function fromFile (path:String):BytePointer {
		
		return new BytePointerData (LimeBytes.fromFile (path), 0);
		
	}
	
	
	@:from @:noCompletion public static function fromLimeBytes (bytes:LimeBytes):BytePointer {
		
		return new BytePointerData (bytes, 0);
		
	}
	
	
	@:to @:noCompletion public static function toUInt8Array (bytePointer:BytePointer):UInt8Array {
		
		#if (js && !display)
		return new UInt8Array (bytePointer.bytes.getData (), Std.int (bytePointer.offset / 8));
		#else
		return new UInt8Array (bytePointer.bytes, Std.int (bytePointer.offset / 8));
		#end
		
	}
	
	
	@:to @:noCompletion public static function toUInt8ClampedArray (bytePointer:BytePointer):UInt8ClampedArray {
		
		#if (js && !display)
		return new UInt8ClampedArray (bytePointer.bytes.getData (), Std.int (bytePointer.offset / 8));
		#else
		return new UInt8ClampedArray (bytePointer.bytes, Std.int (bytePointer.offset / 8));
		#end
		
	}
	
	
	@:to @:noCompletion public static function toInt8Array (bytePointer:BytePointer):Int8Array {
		
		#if (js && !display)
		return new Int8Array (bytePointer.bytes.getData (), Std.int (bytePointer.offset / 8));
		#else
		return new Int8Array (bytePointer.bytes, Std.int (bytePointer.offset / 8));
		#end
		
	}
	
	
	@:to @:noCompletion public static function toUInt16Array (bytePointer:BytePointer):UInt16Array {
		
		#if (js && !display)
		return new UInt16Array (bytePointer.bytes.getData (), Std.int (bytePointer.offset / 16));
		#else
		return new UInt16Array (bytePointer.bytes, Std.int (bytePointer.offset / 16));
		#end
		
	}
	
	
	@:to @:noCompletion public static function toInt16Array (bytePointer:BytePointer):Int16Array {
		
		#if (js && !display)
		return new Int16Array (bytePointer.bytes.getData (), Std.int (bytePointer.offset / 16));
		#else
		return new Int16Array (bytePointer.bytes, Std.int (bytePointer.offset / 16));
		#end
		
	}
	
	
	@:to @:noCompletion public static function toUInt32Array (bytePointer:BytePointer):UInt32Array {
		
		#if (js && !display)
		return new UInt32Array (bytePointer.bytes.getData (), Std.int (bytePointer.offset / 32));
		#else
		return new UInt32Array (bytePointer.bytes, Std.int (bytePointer.offset / 32));
		#end
		
	}
	
	
	@:to @:noCompletion public static function toInt32Array (bytePointer:BytePointer):Int32Array {
		
		#if (js && !display)
		return new Int32Array (bytePointer.bytes.getData (), Std.int (bytePointer.offset / 32));
		#else
		return new Int32Array (bytePointer.bytes, Std.int (bytePointer.offset / 32));
		#end
		
	}
	
	
	@:to @:noCompletion public static function toFloat32Array (bytePointer:BytePointer):Float32Array {
		
		#if (js && !display)
		return new Float32Array (bytePointer.bytes.getData (), Std.int (bytePointer.offset / 32));
		#else
		return new Float32Array (bytePointer.bytes, Std.int (bytePointer.offset / 32));
		#end
		
	}
	
	
	@:to @:noCompletion public static function toFloat64Array (bytePointer:BytePointer):Float64Array {
		
		#if (js && !display)
		return new Float64Array (bytePointer.bytes.getData (), Std.int (bytePointer.offset / 64));
		#else
		return new Float64Array (bytePointer.bytes, Std.int (bytePointer.offset / 64));
		#end
		
	}
	
	
}


@:noCompletion @:dox(hide) class BytePointerData {
	
	
	public var bytes:Bytes;
	public var offset:Int;
	
	
	public function new (bytes:Bytes, offset:Int) {
		
		this.bytes = bytes;
		this.offset = offset;
		
	}
	
	
}