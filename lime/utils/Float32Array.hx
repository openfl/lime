package lime.utils;

//import lime.utils.compat.Matrix3D;

class Float32Array extends ArrayBufferView implements ArrayAccess<Float> {
    
    public var BYTES_PER_ELEMENT (default, null) : Int;
    public var length (default, null) : Int;
    
    public function new( bufferOrArray:Dynamic, start:Int = 0, length:Null<Int> = null ) {
        
        BYTES_PER_ELEMENT = 4;

        if (Std.is(bufferOrArray, Int)) {
            
            super(Std.int(bufferOrArray) << 2);
            this.length = bufferOrArray;
            
        } else if (Std.is(bufferOrArray, Array)) {

            var floats:Array<Float> = bufferOrArray;
            this.length = (length != null) ? length : floats.length - start;
            super(this.length << 2);
            
            #if !cpp
            buffer.position = 0;
            #end
            
            for (i in 0...this.length) {
                
                #if cpp
                untyped __global__.__hxcpp_memory_set_float(bytes, (i << 2), floats[i + start]);
                #else
                buffer.writeFloat(floats[i + start]);
                #end
                
            }
            
        } else if (Std.is(bufferOrArray, Float32Array)) {

            var floats:Float32Array = bufferOrArray;
            this.length = (length != null) ? length : floats.length - start;
            super(this.length << 2);
            
            #if !cpp
            buffer.position = 0;
            #end
            
            for (i in 0...this.length) {
                
                #if cpp
                untyped __global__.__hxcpp_memory_set_float(bytes, (i << 2), floats[i + start]);
                #else
                buffer.writeFloat(floats[i + start]);
                #end
                
            }
            
        } else {

            super(bufferOrArray, start, (length != null) ? length << 2 : null);
            
            if ((byteLength & 0x03) > 0) {
                throw "Invalid array size";
            }
            
            this.length = byteLength >> 2;
            
            if ((this.length << 2) != byteLength) {
                throw "Invalid length multiple";
            }

        }
        
    } //new

    public function set( bufferOrArray:Dynamic, offset:Int = 0 ) {

        if (Std.is(bufferOrArray, Array)) {

            var floats:Array<Float> = bufferOrArray;

            for (i in 0...floats.length) {
                setFloat32((i + offset) << 2, floats[i]);
            }
        
        } else if (Std.is(bufferOrArray, Float32Array)) {

            var floats:Float32Array = bufferOrArray;

            for (i in 0...floats.length) {
                setFloat32((i + offset) << 2, floats[i]);
            }

        } else {

            throw "Invalid input buffer";

        }

    } //set

    public function subarray( start:Int, end:Null<Int> = null ) : Float32Array {

        end = (end == null) ? length : end;
        return new Float32Array(buffer, start << 2, end - start);

    } //subarray
    
    /*public static function fromMatrix( matrix:Matrix3D ) : Float32Array {

        return new Float32Array(matrix.rawData);

    } //fromMatrix*/
    
    @:noCompletion @:keep inline public function __get( index:Int ):Float { return getFloat32(index << 2); }
    @:noCompletion @:keep inline public function __set( index:Int, value:Float ) { setFloat32(index << 2, value); }
    
} //Float32Array
