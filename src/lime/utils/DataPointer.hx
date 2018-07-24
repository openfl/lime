package lime.utils;


import haxe.io.BytesData;
import haxe.io.Bytes;
import lime.system.CFFIPointer;
import lime.utils.Bytes in LimeBytes;

#if (lime_cffi && !macro)
import lime._internal.backend.native.NativeCFFI;
@:access(lime._internal.backend.native.NativeCFFI)
#end


abstract DataPointer(DataPointerType) to DataPointerType {


	@:noCompletion private function new (data:DataPointerType) {

		this = data;

	}


	@:from @:noCompletion private static function fromInt (value:Int):DataPointer {

		#if (lime_cffi && !macro)
		var float:Float = value;
		return new DataPointer (float);
		#elseif (js && !doc_gen)
		return new DataPointer (new DataPointerObject (value));
		#else
		return null;
		#end

	}


	@:from @:noCompletion private static function fromFloat (value:Float):DataPointer {

		#if (lime_cffi && !macro)
		return new DataPointer (value);
		#elseif (js && !doc_gen)
		return new DataPointer (new DataPointerObject (Std.int (value)));
		#else
		return null;
		#end

	}


	@:from @:noCompletion public static function fromBytesPointer (pointer:BytePointer):DataPointer {

		#if (lime_cffi && !macro)
		if (pointer == null || pointer.bytes == null) return cast 0;
		var data:Float = NativeCFFI.lime_bytes_get_data_pointer_offset (pointer.bytes, pointer.offset);
		return new DataPointer (data);
		#elseif (js && !doc_gen)
		return new DataPointer (new DataPointerObject (null, pointer.bytes.getData (), pointer.offset));
		#else
		return null;
		#end

	}


	@:from @:noCompletion public static function fromArrayBufferView (arrayBufferView:ArrayBufferView):DataPointer {

		#if (lime_cffi && !js && !macro)
		if (arrayBufferView == null) return cast 0;
		var data:Float = NativeCFFI.lime_bytes_get_data_pointer_offset (arrayBufferView.buffer, arrayBufferView.byteOffset);
		return new DataPointer (data);
		#elseif (js && !doc_gen)
		return new DataPointer (new DataPointerObject (arrayBufferView));
		#else
		return null;
		#end

	}


	@:from @:noCompletion public static function fromArrayBuffer (buffer:ArrayBuffer):DataPointer {

		#if (lime_cffi && !macro)
		if (buffer == null) return cast 0;
		return fromBytes (buffer);
		#elseif (js && !doc_gen)
		return new DataPointer (new DataPointerObject (buffer));
		#else
		return null;
		#end

	}


	@:from @:noCompletion public static function fromBytes (bytes:Bytes):DataPointer {

		#if (lime_cffi && !macro)
		if (bytes == null) return cast 0;
		var data:Float = NativeCFFI.lime_bytes_get_data_pointer (bytes);
		return new DataPointer (data);
		#elseif (js && !doc_gen)
		return fromArrayBuffer (bytes.getData ());
		#else
		return null;
		#end

	}


	@:from @:noCompletion public static function fromBytesData (bytesData:BytesData):DataPointer {

		#if (lime_cffi && !macro)
		if (bytesData == null) return cast 0;
		return fromBytes (Bytes.ofData (bytesData));
		#elseif (js && !doc_gen)
		return fromArrayBuffer (bytesData);
		#else
		return null;
		#end

	}


	@:from @:noCompletion public static function fromLimeBytes (bytes:LimeBytes):DataPointer {

		return fromBytes (bytes);

	}


	#if !lime_doc_gen
	@:from @:noCompletion public static function fromCFFIPointer (pointer:CFFIPointer):DataPointer {

		#if (lime_cffi && !macro)
		if (pointer == null) return cast 0;
		return new DataPointer (pointer.get ());
		#else
		return null;
		#end

	}
	#end


	public static function fromFile (path:String):DataPointer {

		#if (lime_cffi && !macro)
		return fromBytes (LimeBytes.fromFile (path));
		#else
		return null;
		#end

	}


	#if (js && html5 && !doc_gen)
	@:dox(hide) @:noCompletion public function toBufferOrBufferView (?length:Int):Dynamic {

		var data:DataPointerObject = this;
		untyped __js__ ("if (!data) return null");

		switch (data.type) {

			case BUFFER_VIEW:

				if (length == null) length = data.bufferView.byteLength;

				if (data.offset == 0 && length == data.bufferView.byteLength) {

					return data.bufferView;

				} else {

					return new UInt8Array (data.bufferView.buffer, data.bufferView.byteOffset + data.offset, length);

				}

			case BUFFER:

				if (length == null) length = data.buffer.byteLength;

				if (data.offset == 0 && length == data.buffer.byteLength) {

					return data.buffer;

				} else {

					return new UInt8Array (data.buffer, data.offset, length);

				}

			default:

				return null;

		}

	}


	@:dox(hide) @:noCompletion public function toBufferView (?length:Int):Dynamic {

		var data:DataPointerObject = this;
		untyped __js__ ("if (!data) return null");

		switch (data.type) {

			case BUFFER_VIEW:

				if (length == null) length = data.bufferView.byteLength;

				if (data.offset == 0 && length == data.bufferView.byteLength) {

					return data.bufferView;

				} else {

					return new UInt8Array (data.bufferView.buffer, data.bufferView.byteOffset + data.offset, length);

				}

			case BUFFER:

				if (length == null) length = data.buffer.byteLength;
				return new UInt8Array (data.buffer, data.offset, length);

			default:

				return null;

		}

	}


	@:dox(hide) @:noCompletion public function toFloat32Array (?length:Int):Float32Array {

		var data:DataPointerObject = this;
		untyped __js__ ("if (!data) return null");

		switch (data.type) {

			case BUFFER_VIEW:

				if (length == null) length = data.bufferView.byteLength;
				if (data.offset == 0 && length == data.bufferView.byteLength && untyped __js__ ("data.bufferView.constructor == Float32Array")) {

					return cast data.bufferView;

				} else {

					if (length > data.bufferView.byteLength) length = data.bufferView.byteLength;
					return new Float32Array (data.bufferView.buffer, data.bufferView.byteOffset + data.offset, Std.int (length / Float32Array.BYTES_PER_ELEMENT));

				}

			case BUFFER:

				if (length == null) length = data.buffer.byteLength;
				return new Float32Array (data.buffer, data.offset, Std.int (length / Float32Array.BYTES_PER_ELEMENT));

			default:

				return null;

		}

	}


	@:dox(hide) @:noCompletion public function toInt32Array (?length:Int):Int32Array {

		var data:DataPointerObject = this;
		untyped __js__ ("if (!data) return null");

		switch (data.type) {

			case BUFFER_VIEW:

				if (length == null) length = data.bufferView.byteLength;
				if (data.offset == 0 && length == data.bufferView.byteLength && untyped __js__ ("data.bufferView.constructor == Int32Array")) {

					return cast data.bufferView;

				} else {

					return new Int32Array (data.bufferView.buffer, data.bufferView.byteOffset + data.offset, Std.int (length / Int32Array.BYTES_PER_ELEMENT));

				}

			case BUFFER:

				if (length == null) length = data.buffer.byteLength;
				return new Int32Array (data.buffer, data.offset, Std.int (length / Int32Array.BYTES_PER_ELEMENT));

			default:

				return null;

		}

	}


	@:dox(hide) @:noCompletion public function toUInt8Array (?length:Int):UInt8Array {

		var data:DataPointerObject = this;
		untyped __js__ ("if (!data) return null");

		switch (data.type) {

			case BUFFER_VIEW:

				if (length == null) length = data.bufferView.byteLength;
				if (data.offset == 0 && length == data.bufferView.byteLength && untyped __js__ ("data.bufferView.constructor == Uint8Array")) {

					return cast data.bufferView;

				} else {

					return new UInt8Array (data.bufferView.buffer, data.bufferView.byteOffset + data.offset, length);

				}

			case BUFFER:

				if (length == null) length = data.buffer.byteLength;
				return new UInt8Array (data.buffer, data.offset, length);

			default:

				return null;

		}

	}


	@:dox(hide) @:noCompletion public function toUInt32Array (?length:Int):UInt32Array {

		var data:DataPointerObject = this;
		untyped __js__ ("if (!data) return null");

		switch (data.type) {

			case BUFFER_VIEW:

				if (length == null) length = data.bufferView.byteLength;
				if (data.offset == 0 && length == data.bufferView.byteLength && untyped __js__ ("data.bufferView.constructor == Uint32Array")) {

					return cast data.bufferView;

				} else {

					return new UInt32Array (data.bufferView.buffer, data.bufferView.byteOffset + data.offset, Std.int (length / UInt32Array.BYTES_PER_ELEMENT));

				}

			case BUFFER:

				if (length == null) length = data.buffer.byteLength;
				return new UInt32Array (data.buffer, data.offset, Std.int (length / UInt32Array.BYTES_PER_ELEMENT));

			default:

				return null;

		}

	}


	@:dox(hide) @:noCompletion public function toValue ():Int {

		var data:DataPointerObject = this;
		untyped __js__ ("if (!data) return 0");
		untyped __js__ ("if (typeof data === 'number') return data");

		switch (data.type) {

			case VALUE:

				return data.offset;

			default:

				return 0;

		}

	}
	#end


	private static function __withOffset (data:DataPointer, offset:Int):DataPointer {

		#if (lime_cffi && !macro)
		if (data == 0) return cast 0;
		var data:Float = NativeCFFI.lime_data_pointer_offset (data, offset);
		return new DataPointer (data);
		#else
		return null;
		#end

	}


	@:noCompletion @:op(A == B) private static inline function equals (a:DataPointer, b:Int):Bool { return (a:Float) == b; }
	@:noCompletion @:op(A == B) private static inline function equalsPointer (a:DataPointer, b:DataPointer):Bool { return (a:Float) == (b:Float); }
	@:noCompletion @:op(A > B) private static inline function greaterThan (a:DataPointer, b:Int):Bool { return (a:Float) > b; }
	#if !lime_doc_gen
	@:noCompletion @:op(A > B) private static inline function greaterThanPointer (a:DataPointer, b:CFFIPointer):Bool { return (a:Float) > b; }
	#end
	@:noCompletion @:op(A >= B) private static inline function greaterThanOrEqual (a:DataPointer, b:Int):Bool { return (a:Float) >= b; }
	#if !lime_doc_gen
	@:noCompletion @:op(A >= B) private static inline function greaterThanOrEqualPointer (a:DataPointer, b:CFFIPointer):Bool { return (a:Float) >= b; }
	#end
	@:noCompletion @:op(A < B) private static inline function lessThan (a:DataPointer, b:Int):Bool { return (a:Float) < b; }
	#if !lime_doc_gen
	@:noCompletion @:op(A < B) private static inline function lessThanPointer (a:DataPointer, b:CFFIPointer):Bool { return (a:Float) < b; }
	#end
	@:noCompletion @:op(A <= B) private static inline function lessThanOrEqual (a:DataPointer, b:Int):Bool { return (a:Float) <= b; }
	#if !lime_doc_gen
	@:noCompletion @:op(A <= B) private static inline function lessThanOrEqualPointer (a:DataPointer, b:CFFIPointer):Bool { return (a:Float) <= b; }
	#end
	@:noCompletion @:op(A != B) private static inline function notEquals (a:DataPointer, b:Int):Bool { return (a:Float) != b; }
	@:noCompletion @:op(A != B) private static inline function notEqualsPointer (a:DataPointer, b:DataPointer):Bool { return (a:Float) != (b:Float); }
	@:noCompletion @:op(A + B) private static inline function plus (a:DataPointer, b:Int):DataPointer { return __withOffset (a, b); }
	@:noCompletion @:op(A + B) private static inline function plusPointer (a:DataPointer, b:DataPointer):DataPointer { return  __withOffset (a, Std.int ((b:Float))); }
	@:noCompletion @:op(A - B) private static inline function minus (a:DataPointer, b:Int):DataPointer { return __withOffset (a, -b); }
	@:noCompletion @:op(A - B) private static inline function minusPointer (a:DataPointer, b:DataPointer):DataPointer { return __withOffset (a, -Std.int ((b:Float))); }


}


#if (lime_cffi && !js)
private typedef DataPointerType = Float;
#else
private typedef DataPointerType = Dynamic;

@:dox(hide) class DataPointerObject {


	public var buffer:ArrayBuffer;
	public var bufferView:ArrayBufferView;
	public var offset:Int;
	public var type:DataPointerObjectType;


	public function new (?bufferView:ArrayBufferView, ?buffer:ArrayBuffer, offset:Int = 0) {

		if (bufferView != null) {

			this.bufferView = bufferView;
			type = BUFFER_VIEW;

		} else if (buffer != null) {

			this.buffer = buffer;
			type = BUFFER;

		} else {

			type = VALUE;

		}

		this.offset = offset;

	}


}

@:dox(hide) enum DataPointerObjectType {

	BUFFER;
	BUFFER_VIEW;
	VALUE;

}
#end