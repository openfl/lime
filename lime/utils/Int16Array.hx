package lime.utils;


class Int16Array extends ArrayBufferView implements ArrayAccess<Int> {
    
    public var BYTES_PER_ELEMENT (default, null) : Int;
    public var length (default, null) : Int;
    
    public function new( bufferOrArray:Dynamic, start:Int = 0, length:Null<Int> = null ) {
        
        BYTES_PER_ELEMENT = 2;
        
        if (Std.is(bufferOrArray, Int)) {
            
            super(Std.int(bufferOrArray) << 1);
            this.length = bufferOrArray;
            
        } else if (Std.is(bufferOrArray, Array)) {
            
            var ints:Array<Int> = bufferOrArray;
            this.length = (length != null) ? length : ints.length - start;
            super(this.length << 1);
            
            #if !cpp
            buffer.position = 0;
            #end
            
            for (i in 0...this.length) {
                
                #if cpp
                untyped __global__.__hxcpp_memory_set_i16(bytes, (i << 1), ints[i + start]);
                #else
                buffer.writeShort(ints[i + start]);
                #end
                
            }
            
        } else if (Std.is(bufferOrArray, Int16Array)) {
            
            var ints:Int16Array = bufferOrArray;
            this.length = (length != null) ? length : ints.length - start;
            super(this.length << 1);
            
            #if !cpp
            buffer.position = 0;
            #end
            
            for (i in 0...this.length) {
                
                #if cpp
                untyped __global__.__hxcpp_memory_set_i16(bytes, (i << 1), ints[i + start]);
                #else
                buffer.writeShort(ints[i + start]);
                #end
                
            }
            
        } else {
            
            super(bufferOrArray, start, (length != null) ? length << 1 : null);
            
            if ((byteLength & 0x01) > 0) {
                throw "Invalid array size";
            }
            
            this.length = byteLength >> 1;
            
            if ((this.length << 1) != byteLength) {
                throw "Invalid length multiple";
            }
            
        }
        
    }

    public function set( bufferOrArray:Dynamic, offset:Int = 0 ) {

        if (Std.is(bufferOrArray, Array)) {

            var ints:Array<Int> = bufferOrArray;

            for (i in 0...ints.length) {
                setInt16((i + offset) << 1, ints[i]);
            }
        
        } else if (Std.is(bufferOrArray, Int16Array)) {

            var ints:Int16Array = bufferOrArray;

            for (i in 0...ints.length) {
                setInt16((i + offset) << 1, ints[i]);
            }

        } else {

            throw "Invalid input buffer";

        }

    }

    public function subarray( start:Int, end:Null<Int> = null ) : Int16Array {

        end = (end == null) ? length : end;
        return new Int16Array(buffer, start << 1, end - start);

    }
    
    @:noCompletion @:keep inline public function __get( index:Int ):Int { return getInt16(index << 1); }
    @:noCompletion @:keep inline public function __set( index:Int, value:Int ) { setInt16(index << 1, value); }

} //Int16Array
