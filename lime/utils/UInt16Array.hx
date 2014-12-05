package lime.utils;
#if js
typedef UInt16Array = js.html.Uint16Array;
#else


@:generic class UInt16Array extends ArrayBufferView implements ArrayAccess<Int> {
	
	
	public static inline var BYTES_PER_ELEMENT = 2;
	
	public var length (default, null):Int;
	
	
	public function new #if !java <T> #end (bufferOrArray:#if !java T #else Dynamic #end, start:Int = 0, length:Null<Int> = null) {
		
		if (Std.is (bufferOrArray, Int)) {
			
			super (Std.int (cast bufferOrArray) << 1);
			
			this.length = cast bufferOrArray;
			
		} else if (Std.is (bufferOrArray, Array)) {
			
			var ints:Array<Int> = cast bufferOrArray;
			this.length = (length != null) ? length : ints.length - start;
			
			super (this.length << 1);
			
			#if !cpp
			buffer.position = 0;
			#end
			
			for (i in 0...this.length) {
				
				#if cpp
				untyped __global__.__hxcpp_memory_set_ui16 (bytes, (i << 1), ints[i + start]);
				#else
				buffer.writeShort (ints[i + start]);
				#end
				
			}
			
		} else if (Std.is (bufferOrArray, UInt16Array)) {
			
			var ints:UInt16Array = cast bufferOrArray;
			this.length = (length != null) ? length : ints.length - start;
			
			super (this.length << 1);
			
			#if !cpp
			buffer.position = 0;
			#end
			
			for (i in 0...this.length) {
				
				#if cpp
				untyped __global__.__hxcpp_memory_set_i16 (bytes, (i << 1), ints[i + start]);
				#else
				buffer.writeShort (ints[i + start]);
				#end
				
			}
			
		} else {
			
			super (bufferOrArray, start, (length != null) ? length << 1 : null);
			
			if ((byteLength & 0x01) > 0) {
				
				throw "Invalid array size";
				
			}
			
			this.length = byteLength >> 1;
			
			if ((this.length << 1) != byteLength) {
				
				throw "Invalid length multiple";
				
			}
			
		}
		
	}
	
	
	public function set #if !java <T> #end (bufferOrArray:#if !java T #else Dynamic #end, offset:Int = 0):Void {
		
		if (Std.is (bufferOrArray, Array)) {
			
			var ints:Array<Int> = cast bufferOrArray;
			
			for (i in 0...ints.length) {
				
				setUInt16 ((i + offset) << 1, ints[i]);
				
			}
			
		} else if (Std.is (bufferOrArray, UInt16Array)) {

			var ints:UInt16Array = cast bufferOrArray;

			for (i in 0...ints.length) {
				
				setUInt16 ((i + offset) << 1, ints[i]);
				
			}
			
		} else {
			
			throw "Invalid input buffer";
			
		}
		
	}
	
	
	public function subarray (start:Int, end:Null<Int> = null):UInt16Array {
		
		end = (end == null) ? length : end;
		return new UInt16Array (buffer, start << 1, end - start);
		
	}
	
	
	@:noCompletion @:keep inline public function __get (index:Int):Int { return getUInt16 (index << 1); }
	@:noCompletion @:keep inline public function __set (index:Int, value:Int) { setUInt16 (index << 1, value); }
	
	
}


#end