package lime.utils;
#if js
typedef ArrayBufferView = js.html.ArrayBufferView;
#else


import lime.utils.ByteArray;
import lime.utils.IMemoryRange;

#if cpp
import haxe.io.BytesData;
#end


@:generic class ArrayBufferView implements IMemoryRange {
	
	
	public var buffer (default, null):ByteArray;
	public var byteOffset (default, null):Int;
	public var byteLength (default, null):Int;
	
	#if cpp
	private var bytes:BytesData;
	#end
	
	
	public function new #if !java <T> #end (lengthOrBuffer:#if !java T #else Dynamic #end, byteOffset:UInt = 0, length:Null<Int> = null) {
		
		if (Std.is (lengthOrBuffer, Int)) {
			
			byteLength = Std.int (cast lengthOrBuffer);
			this.byteOffset = 0;
			
			buffer = new ArrayBuffer (#if !flash byteLength #end);
			
			#if flash
			for (i in 0...byteLength) { buffer.writeByte (0); }
			buffer.position = 0;
			#end
			
		} else {
			
			buffer = cast lengthOrBuffer;
			
			if (buffer == null) {
				
				throw "Invalid input buffer";
				
			}
			
			this.byteOffset = byteOffset;
			
			if (byteOffset > buffer.length) {
				
				throw "Invalid starting position";
				
			}
			
			if (length == null) {
				
				byteLength = buffer.length - byteOffset;
				
			} else {
				
				byteLength = length;
				
				if (byteLength + byteOffset > buffer.length) {
					
					throw "Invalid buffer length";
					
				}
				
			}
			
		}
		
		#if flash
		buffer.endian = flash.utils.Endian.LITTLE_ENDIAN;
		#else
		buffer.bigEndian = false;
		#end
		
		#if cpp
		bytes = buffer.getData ();
		#end
		
	}
	
	
	public function getByteBuffer ():ByteArray {
		
		return buffer;
		
	}
	
	
	public inline function getFloat32 (position:Int):Float {
		
		#if cpp
		untyped return __global__.__hxcpp_memory_get_float (bytes, position + byteOffset);
		#else
		buffer.position = position + byteOffset;
		return buffer.readFloat ();
		#end
		
	}
	
	
	public inline function getInt8 (position:Int):Int {
		
		#if cpp
		return untyped __global__.__hxcpp_memory_get_byte (bytes, position + byteOffset);
		#else
		buffer.position = position + byteOffset;
		return buffer.readByte ();
		#end
		
	}
	
	
	public inline function getInt16 (position:Int):Int {
		
		#if cpp
		untyped return __global__.__hxcpp_memory_get_i16 (bytes, position + byteOffset);
		#else
		buffer.position = position + byteOffset;
		return buffer.readShort ();
		#end
		
	}
	
	
	public inline function getInt32 (position:Int):Int {
		
		#if cpp
		untyped return __global__.__hxcpp_memory_get_i32 (bytes, position + byteOffset);
		#else
		buffer.position = position + byteOffset;
		return buffer.readInt ();
		#end
		
	}
	
	
	public function getLength ():Int {
		
		return byteLength;
		
	}
	
	
	public function getStart ():Int {
		
		return byteOffset;
		
	}
	
	
	public inline function getUInt8 (position:Int):Int {
		
		#if cpp
		return untyped __global__.__hxcpp_memory_get_byte (bytes, position + byteOffset) & 0xff;
		#else
		buffer.position = position + byteOffset;
		return buffer.readUnsignedByte ();
		#end
		
	}
	
	
	public inline function getUInt16 (position:Int):Int {
		
		#if cpp
		untyped return __global__.__hxcpp_memory_get_ui16 (bytes, position + byteOffset) & 0xffff;
		#else
		buffer.position = position + byteOffset;
		return buffer.readUnsignedShort ();
		#end
		
	}
	
	
	public inline function getUInt32 (position:Int):Int {
		
		#if cpp
		untyped return __global__.__hxcpp_memory_get_ui32 (bytes, position + byteOffset);
		#else
		buffer.position = position + byteOffset;
		return buffer.readUnsignedInt ();
		#end
		
	}
	
	
	public inline function setFloat32 (position:Int, value:Float):Void {
		
		#if cpp
		untyped __global__.__hxcpp_memory_set_float (bytes, position + byteOffset, value);
		#else
		buffer.position = position + byteOffset;
		buffer.writeFloat (value);
		#end
		
	}
	
	
	public inline function setInt8 (position:Int, value:Int):Void {
		
		#if cpp
		untyped __global__.__hxcpp_memory_set_byte (bytes, position + byteOffset, value);
		#else
		buffer.position = position + byteOffset;
		buffer.writeByte (value);
		#end
		
	}
	
	
	public inline function setInt16 (position:Int, value:Int):Void {
		
		#if cpp
		untyped __global__.__hxcpp_memory_set_i16 (bytes, position + byteOffset, value);
		#else
		buffer.position = position + byteOffset;
		buffer.writeShort (Std.int (value));
		#end
		
	}
	
	
	public inline function setInt32 (position:Int, value:Int):Void {
		
		#if cpp
		untyped __global__.__hxcpp_memory_set_i32 (bytes, position + byteOffset, value);
		#else
		buffer.position = position + byteOffset;
		buffer.writeInt (Std.int (value));
		#end
		
	}
	
	
	public inline function setUInt8 (position:Int, value:Int):Void {
		
		#if cpp
		untyped __global__.__hxcpp_memory_set_byte (bytes, position + byteOffset, value);
		#else
		buffer.position = position + byteOffset;
		buffer.writeByte (value);
		#end
		
	}
	
	
	
	public inline function setUInt16 (position:Int, value:Int):Void {
		
		#if cpp
		untyped __global__.__hxcpp_memory_set_ui16 (bytes, position + byteOffset, value);
		#else
		buffer.position = position + byteOffset;
		buffer.writeShort (Std.int (value));
		#end
		
	}
	
	
	
	public inline function setUInt32 (position:Int, value:Int):Void {
		
		#if cpp
		untyped __global__.__hxcpp_memory_set_ui32 (bytes, position + byteOffset, value);
		#else
		buffer.position = position + byteOffset;
		buffer.writeUnsignedInt (Std.int (value));
		#end
		
	}
	
	
}


#end