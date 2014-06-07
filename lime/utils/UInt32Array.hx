package lime.utils;


class UInt32Array extends ArrayBufferView implements ArrayAccess<Int> {
    

    public var BYTES_PER_ELEMENT (default, null) : Int;
    public var length (default, null) : Int;
    

    public function new( bufferOrArray:Dynamic, start:Int = 0, length:Null<Int> = null ) {
        
        BYTES_PER_ELEMENT = 4;
        
        if (Std.is(bufferOrArray, Int)) {
            
            super(Std.int(bufferOrArray) << 2);
            this.length = bufferOrArray;
            
        } else if (Std.is(bufferOrArray, Array)) {
            
            var ints:Array<Int> = bufferOrArray;
            this.length = (length != null) ? length : ints.length - start;
            super(this.length << 2);
            
            #if !cpp
            buffer.position = 0;
            #end
            
            for (i in 0...this.length) {
                
                #if cpp
                untyped __global__.__hxcpp_memory_set_ui32(bytes, (i << 2), ints[i + start]);
                #else
                buffer.writeInt(ints[i + start]);
                #end
                
            }
            
        } else if (Std.is(bufferOrArray, UInt32Array)) {
            
            var ints:UInt32Array = bufferOrArray;
            this.length = (length != null) ? length : ints.length - start;
            super(this.length << 2);
            
            #if !cpp
            buffer.position = 0;
            #end
            
            for (i in 0...this.length) {
                
                #if cpp
                untyped __global__.__hxcpp_memory_set_ui32(bytes, (i << 2), ints[i + start]);
                #else
                buffer.writeInt(ints[i + start]);
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

            var ints:Array<Int> = bufferOrArray;

            for (i in 0...ints.length) {
                setUInt32((i + offset) << 2, ints[i]);
            }
        
        } else if (Std.is(bufferOrArray, UInt32Array)) {

            var ints:UInt32Array = bufferOrArray;

            for (i in 0...ints.length) {
                setUInt32((i + offset) << 2, ints[i]);
            }

        } else {

            throw "Invalid input buffer";

        }

    } //set

    public function subarray( start:Int, end:Null<Int> = null ) : UInt32Array {

        end = (end == null) ? length : end;
        return new UInt32Array(buffer, start << 2, end - start);

    } //subarray
    
    @:noCompletion @:keep inline public function __get( index:Int ):Int { return getUInt32(index << 2); }
    @:noCompletion @:keep inline public function __set( index:Int, value:Int ) { setUInt32(index << 2, value); }
    
} //UInt32Array
