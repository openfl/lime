package lime.utils;
#if js
typedef Float32Array = js.html.Float32Array;
#else


@:generic class Float32Array extends ArrayBufferView implements ArrayAccess<Float> {
	
	
	public static inline var BYTES_PER_ELEMENT = 4;
	
	public var length (default, null):Int;
	
	
	public function new #if !java <T> #end (bufferOrArray:#if !java T #else Dynamic #end, start:Int = 0, length:Null<Int> = null) {
		
		#if (openfl && neko && !lime_legacy)
		if (Std.is (bufferOrArray, openfl.Vector.VectorData)) {
			
			var vector:openfl.Vector<Float> = cast bufferOrArray;
			var floats:Array<Float> = vector;
			this.length = (length != #if java 0 #else null #end) ? length : floats.length - start;
			
			super (this.length << 2);
			
			#if !cpp
			buffer.position = 0;
			#end
			
			for (i in 0...this.length) {
				
				#if cpp
				untyped __global__.__hxcpp_memory_set_float (bytes, (i << 2), floats[i + start]);
				#else
				buffer.writeFloat (floats[i + start]);
				#end
				
			}
			
			return;
			
		}
		#end
		
		if (Std.is (bufferOrArray, Int)) {
			
			super (Std.int (cast bufferOrArray) << 2);
			
			this.length = cast bufferOrArray;
			
		} else if (Std.is (bufferOrArray, Array)) {
			
			var floats:Array<Float> = cast bufferOrArray;
			this.length = (length != #if java 0 #else null #end) ? length : floats.length - start;
			
			super (this.length << 2);
			
			#if !cpp
			buffer.position = 0;
			#end
			
			for (i in 0...this.length) {
				
				#if cpp
				untyped __global__.__hxcpp_memory_set_float (bytes, (i << 2), floats[i + start]);
				#else
				buffer.writeFloat (floats[i + start]);
				#end
				
			}
			
		} else if (Std.is (bufferOrArray, Float32Array)) {
			
			var floats:Float32Array = cast bufferOrArray;
			this.length = (length != #if java 0 #else null #end) ? length : floats.length - start;
			
			super (this.length << 2);
			
			#if !cpp
			buffer.position = 0;
			#end
			
			for (i in 0...this.length) {
				
				#if cpp
				untyped __global__.__hxcpp_memory_set_float (bytes, (i << 2), floats[i + start]);
				#else
				buffer.writeFloat (floats[i + start]);
				#end
				
			}
			
		} else {
			
			super (bufferOrArray, start, #if java length #else (length != null ) ? length << 2 : null #end);
			
			if ((byteLength & 0x03) > 0) {
				
				throw "Invalid array size";
				
			}
			
			this.length = byteLength >> 2;
			
			if ((this.length << 2) != byteLength) {
				
				throw "Invalid length multiple";
				
			}
			
		}
		
	}
	
	
	public function set #if !java <T> #end (bufferOrArray:#if !java T #else Dynamic #end, offset:Int = 0):Void {
		
		if (Std.is (bufferOrArray, Array)) {
			
			var floats:Array<Float> = cast bufferOrArray;
			
			for (i in 0...floats.length) {
				
				setFloat32 ((i + offset) << 2, floats[i]);
				
			}
			
		} else if (Std.is (bufferOrArray, Float32Array)) {
			
			var floats:Float32Array = cast bufferOrArray;
			
			for (i in 0...floats.length) {
				
				setFloat32 ((i + offset) << 2, floats[i]);
				
			}
			
		} else {
			
			throw "Invalid input buffer";
			
		}
		
	}
	
	
	public function subarray (start:Int, end:Null<Int> = null):Float32Array {
		
		end = (end == null) ? length : end;
		return new Float32Array (buffer, start << 2, end - start);
		
	}
	
	
	/*public static function fromMatrix (matrix:Matrix3D):Float32Array {
		
		return new Float32Array (matrix.rawData);
		
	}*/
	
	
	@:noCompletion @:keep inline public function __get (index:Int):Float { return getFloat32 (index << 2); }
	@:noCompletion @:keep inline public function __set (index:Int, value:Float) { setFloat32 (index << 2, value); }
	
	
}


#end