package lime.utils;
#if js
typedef Int8Array = js.html.Int8Array;
#else


@:generic class Int8Array extends ArrayBufferView implements ArrayAccess<Int> {
	
	
	public static inline var BYTES_PER_ELEMENT = 1;
	
	public var length (default, null):Int;
	
	
	public function new<T> (bufferOrArray:T, start:Int = 0, length:Null<Int> = null) {
		
		if (Std.is (bufferOrArray, Int)) {
			
			super (Std.int (cast bufferOrArray));
			
			this.length = cast bufferOrArray;
			
		} else if (Std.is (bufferOrArray, Array)) {
			
			var ints:Array<Int> = cast bufferOrArray;
			this.length = (length != null) ? length : ints.length - start;
			
			super (this.length);
			
			#if !cpp
			buffer.position = 0;
			#end
			
			for (i in 0...this.length) {
				
				#if cpp
				untyped __global__.__hxcpp_memory_set_byte (bytes, i, ints[i + start]);
				#else
				buffer.writeByte (ints[i + start]);
				#end
				
			}
			
		} else if (Std.is (bufferOrArray, Int8Array)) {
			
			var ints:Int8Array = cast bufferOrArray;
			this.length = (length != null) ? length : ints.length - start;
			
			super (this.length);
			
			#if !cpp
			buffer.position = 0;
			#end
			
			for (i in 0...this.length) {
				
				#if cpp
				untyped __global__.__hxcpp_memory_set_byte (bytes, i, ints[i + start]);
				#else
				buffer.writeByte (ints[i + start]);
				#end
				
			}
			
		} else {
			
			super (bufferOrArray, start, length);
			this.length = byteLength;
			
		}
		
	}
	
	
	public function set<T> (bufferOrArray:T, offset:Int = 0):Void {
		
		if (Std.is(bufferOrArray, Array)) {
			
			var ints:Array<Int> = cast bufferOrArray;
			
			for (i in 0...ints.length) {
				
				setInt8 (i + offset, ints[i]);
				
			}
			
		} else if (Std.is (bufferOrArray, Int8Array)) {
			
			var ints:Int8Array = cast bufferOrArray;
			
			for (i in 0...ints.length) {
				
				setInt8 (i + offset, ints[i]);
				
			}
			
		} else {
			
			throw "Invalid input buffer";
			
		}
		
	}
	
	
	public function subarray (start:Int, end:Null<Int> = null):Int8Array {
		
		end = (end == null) ? length : end;
		return new Int8Array (buffer, start, end - start);
		
	}
	
	
	@:noCompletion @:keep inline public function __get (index:Int):Int { return getInt8 (index); }
	@:noCompletion @:keep inline public function __set (index:Int, value:Int) { setInt8 (index, value); }
	
	
}


#end