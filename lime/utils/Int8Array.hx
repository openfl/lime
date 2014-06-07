package lime.utils;



class Int8Array extends ArrayBufferView implements ArrayAccess<Int> {
    

    public var BYTES_PER_ELEMENT (default, null) : Int;
    public var length (default, null) : Int;
    

    public function new( bufferOrArray:Dynamic, start:Int = 0, length:Null<Int> = null ) {
        
        BYTES_PER_ELEMENT = 1;
        
        if (Std.is(bufferOrArray, Int)) {
            
            super(Std.int(bufferOrArray));
            this.length = bufferOrArray;
            
        } else if (Std.is(bufferOrArray, Array)) {
            
            var ints:Array<Int> = bufferOrArray;
            this.length = (length != null) ? length : ints.length - start;
            super(this.length);
            
            #if !cpp
            buffer.position = 0;
            #end
            
            for (i in 0...this.length) {
                
                #if cpp
                untyped __global__.__hxcpp_memory_set_byte(bytes, i, ints[i + start]);
                #else
                buffer.writeByte(ints[i + start]);
                #end
                
            }
            
        } else if (Std.is(bufferOrArray, Int8Array)) {

            var ints:Int8Array = bufferOrArray;
            this.length = (length != null) ? length : ints.length - start;
            super(this.length);
            
            #if !cpp
            buffer.position = 0;
            #end
            
            for (i in 0...this.length) {
                
                #if cpp
                untyped __global__.__hxcpp_memory_set_byte(bytes, i, ints[i + start]);
                #else
                buffer.writeByte(ints[i + start]);
                #end
                
            }

        } else {
            
            super(bufferOrArray, start, length);
            this.length = byteLength;
            
        }
        
    } //new

    public function set( bufferOrArray:Dynamic, offset:Int = 0 ) {

        if (Std.is(bufferOrArray, Array)) {

            var ints:Array<Int> = bufferOrArray;

            for (i in 0...ints.length) {
                setInt8(i + offset, ints[i]);
            }
        
        } else if (Std.is(bufferOrArray, Int8Array)) {

            var ints:Int8Array = bufferOrArray;

            for (i in 0...ints.length) {
                setInt8(i + offset, ints[i]);
            }

        } else {

            throw "Invalid input buffer";

        }

    } //set

    public function subarray( start:Int, end:Null<Int> = null ) : Int8Array {

        end = (end == null) ? length : end;
        return new Int8Array(buffer, start, end - start);

    } //subarray
    
    @:noCompletion @:keep inline public function __get( index:Int ):Int { return getInt8(index); }
    @:noCompletion @:keep inline public function __set( index:Int, value:Int ) { setInt8(index, value); }
    
} //Int8Array
