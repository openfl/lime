package lime.utils;
#if js
typedef Int32Array = js.html.Int32Array;
#else


@:generic class Int32Array extends ArrayBufferView implements ArrayAccess<Int> {
	
	
	public static inline var BYTES_PER_ELEMENT = 4;
	
	public var length (default, null):Int;
	
	
	public function new<T> (bufferOrArray:T, start:Int = 0, length:Null<Int> = null) {
		
		if (Std.is (bufferOrArray, Int)) {
			
			super (Std.int (cast bufferOrArray) << 2);
			
			this.length = cast bufferOrArray;
			
		} else if (Std.is (bufferOrArray, Array)) {
			
			var ints:Array<Int> = cast bufferOrArray;
			this.length = (length != null) ? length : ints.length - start;
			
			super (this.length << 2);
			
			#if !cpp
			buffer.position = 0;
			#end
			
			for (i in 0...this.length) {
				
				#if cpp
				untyped __global__.__hxcpp_memory_set_i32 (bytes, (i << 2), ints[i + start]);
				#else
				buffer.writeInt (ints[i + start]);
				#end
				
			}
			
		} else if (Std.is (bufferOrArray, Int32Array)) {
			
			var ints:Int32Array = cast bufferOrArray;
			this.length = (length != null) ? length : ints.length - start;
			
			super (this.length << 2);
			
			#if !cpp
			buffer.position = 0;
			#end
			
			for (i in 0...this.length) {
				
				#if cpp
				untyped __global__.__hxcpp_memory_set_i32(bytes, (i << 2), ints[i + start]);
				#else
				buffer.writeInt(ints[i + start]);
				#end
				
			}
			
		} else {
			
			super (bufferOrArray, start, (length != null) ? length << 2 : null);
			
			if ((byteLength & 0x03) > 0) {
				
				throw "Invalid array size";
				
			}
			
			this.length = byteLength >> 2;
			
			if ((this.length << 2) != byteLength) {
				
				throw "Invalid length multiple";
				
			}
			
		}
		
	}
	
	
	public function set<T> (bufferOrArray:T, offset:Int = 0):Void {
		
		if (Std.is (bufferOrArray, Array)) {
			
			var ints:Array<Int> = cast bufferOrArray;
			
			for (i in 0...ints.length) {
				
				setInt32 ((i + offset) << 2, ints[i]);
				
			}
			
		} else if (Std.is (bufferOrArray, Int32Array)) {
			
			var ints:Int32Array = cast bufferOrArray;
			
			for (i in 0...ints.length) {
				
				setInt32 ((i + offset) << 2, ints[i]);
				
			}
			
		} else {
			
			throw "Invalid input buffer";
			
		}
		
	}
	
	
	public function subarray (start:Int, end:Null<Int> = null):Int32Array {
		
		end = (end == null) ? length : end;
		return new Int32Array (buffer, start << 2, end - start);
		
	}
	
	
	@:noCompletion @:keep inline public function __get (index:Int):Int { return getInt32 (index << 2); }
	@:noCompletion @:keep inline public function __set (index:Int, value:Int) { setInt32 (index << 2, value); }
	
	
}


#end