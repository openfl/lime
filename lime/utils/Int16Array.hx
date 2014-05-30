package lime.utils;


#if lime_html5
        
    typedef Int16Array = js.html.Int16Array;

#end //lime_html5

#if lime_native

    class Int16Array extends ArrayBufferView implements ArrayAccess<Int> {
        
        
        static public inline var SBYTES_PER_ELEMENT = 2;
        
        public var BYTES_PER_ELEMENT (default, null):Int;
        public var length (default, null):Int;
        
        
        public function new (bufferOrArray:Dynamic, start:Int = 0, length:Null<Int> = null) {
            
            BYTES_PER_ELEMENT = 2;
            
            if (Std.is (bufferOrArray, Int)) {
                
                super (Std.int (bufferOrArray) << 1);
                
            } else if (Std.is (bufferOrArray, Array)) {
                
                var ints:Array<Int> = bufferOrArray;
                
                if (length != null) {
                    
                    this.length = length;
                    
                } else {
                    
                    this.length = ints.length - start;
                    
                }
                
                super (this.length << 1);
                
                #if !cpp
                buffer.position = 0;
                #end
                
                for (i in 0...this.length) {
                    
                    #if cpp
                    untyped __global__.__hxcpp_memory_set_i16 (bytes, (i << 1), ints[i]);
                    #else
                    buffer.writeShort (ints[i + start]);
                    #end
                    
                }
                
            } else {
                
                super (bufferOrArray, start, length);
                
                if ((byteLength & 0x01) > 0) {
                    
                    throw ("Invalid array size");
                    
                }
                
                this.length = byteLength >> 1;
                
                if ((this.length << 1) != byteLength) {
                    
                    throw "Invalid length multiple";
                    
                }
                
            }
            
        }
        
        
        @:noCompletion @:keep inline public function __get (index:Int):Int { return getInt16 (index << 1); }
        @:noCompletion @:keep inline public function __set (index:Int, value:Int):Void { setInt16 (index << 1, value); }
        
        
    }

#end //lime_native
