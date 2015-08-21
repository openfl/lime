package lime.utils;

import lime.utils.ArrayBufferView;

#if (js && !display)

    @:forward
    abstract DataView(js.html.DataView)
        from js.html.DataView
        to js.html.DataView {

        public inline function new( buffer:ArrayBuffer, byteOffset:Null<Int> = null, byteLength:Null<Int> = null ) {
            if(byteOffset != null && byteLength == null) this = new js.html.DataView( buffer, byteOffset );
            else if(byteOffset != null && byteLength != null) this = new js.html.DataView( buffer, byteOffset, byteLength);
            else this = new js.html.DataView( buffer );
        }

        #if !no_typedarray_inline inline #end
        public function getInt8( byteOffset:Int ) : Int {
            return this.getInt8( byteOffset);
        }

        #if !no_typedarray_inline inline #end
        public function getInt16( byteOffset:Int, ?littleEndian:Bool = true ) : Int {
            return this.getInt16( byteOffset, littleEndian);
        }

        #if !no_typedarray_inline inline #end
        public function getInt32( byteOffset:Int, ?littleEndian:Bool = true ) : Int {
            return this.getInt32( byteOffset, littleEndian);
        }

        #if !no_typedarray_inline inline #end
        public function getUint8( byteOffset:Int ) : UInt {
            return this.getUint8( byteOffset);
        }

        #if !no_typedarray_inline inline #end
        public function getUint16( byteOffset:Int, ?littleEndian:Bool = true ) : UInt {
            return this.getUint16( byteOffset, littleEndian);
        }

        #if !no_typedarray_inline inline #end
        public function getUint32( byteOffset:Int, ?littleEndian:Bool = true ) : UInt {
            return this.getUint32( byteOffset, littleEndian);
        }

        #if !no_typedarray_inline inline #end
        public function getFloat32( byteOffset:Int, ?littleEndian:Bool = true ) : Float {
            return this.getFloat32( byteOffset, littleEndian);
        }

        #if !no_typedarray_inline inline #end
        public function getFloat64( byteOffset:Int, ?littleEndian:Bool = true ) : Float {
            return this.getFloat64( byteOffset, littleEndian);
        }




        #if !no_typedarray_inline inline #end
        public function setInt8( byteOffset:Int, value:Int ) {
            this.setInt8( byteOffset, value);
        }

        #if !no_typedarray_inline inline #end
        public function setInt16( byteOffset:Int, value:Int, ?littleEndian:Bool = true) {
            this.setInt16( byteOffset, value, littleEndian);
        }

        #if !no_typedarray_inline inline #end
        public function setInt32( byteOffset:Int, value:Int, ?littleEndian:Bool = true) {
            this.setInt32( byteOffset, value, littleEndian);
        }

        #if !no_typedarray_inline inline #end
        public function setUint8( byteOffset:Int, value:UInt ) {
            this.setUint8( byteOffset, value);
        }

        #if !no_typedarray_inline inline #end
        public function setUint16( byteOffset:Int, value:UInt, ?littleEndian:Bool = true) {
            this.setUint16( byteOffset, value, littleEndian);
        }

        #if !no_typedarray_inline inline #end
        public function setUint32( byteOffset:Int, value:UInt, ?littleEndian:Bool = true) {
            this.setUint32( byteOffset, value, littleEndian);
        }

        #if !no_typedarray_inline inline #end
        public function setFloat32( byteOffset:Int, value:Float, ?littleEndian:Bool = true) {
            this.setFloat32( byteOffset, value, littleEndian);
        }

        #if !no_typedarray_inline inline #end
        public function setFloat64( byteOffset:Int, value:Float, ?littleEndian:Bool = true) {
            this.setFloat64( byteOffset, value, littleEndian);
        }

    }


#else

    import lime.utils.ArrayBuffer;

class DataView {

    public var buffer:ArrayBuffer;
    public var byteLength:Int;
    public var byteOffset:Int;

    #if !no_typedarray_inline inline #end
    public function new( buffer:ArrayBuffer, byteOffset:Int = 0, byteLength:Null<Int> = null ) {

        if(byteOffset < 0) throw TAError.RangeError;

        var bufferByteLength = buffer.length;
        var viewByteLength = bufferByteLength - byteOffset;

        if(byteOffset > bufferByteLength) throw TAError.RangeError;

        if(byteLength != null) {

            if(byteLength < 0) throw TAError.RangeError;

            viewByteLength = byteLength;

            if(byteOffset + viewByteLength > bufferByteLength) throw TAError.RangeError;

        }

        this.buffer = buffer;
        this.byteLength = viewByteLength;
        this.byteOffset = byteOffset;

    }


    #if !no_typedarray_inline inline #end
    public function getInt8( byteOffset:Int ) : Int {
        return ArrayBufferIO.getInt8(buffer, byteOffset);
    }

    #if !no_typedarray_inline inline #end
    public function getInt16( byteOffset:Int, ?littleEndian:Bool = true ) : Int {
        return ArrayBufferIO.getInt16(buffer, byteOffset, littleEndian);
    }

    #if !no_typedarray_inline inline #end
    public function getInt32( byteOffset:Int, ?littleEndian:Bool = true ) : Int {
        return ArrayBufferIO.getInt32(buffer, byteOffset, littleEndian);
    }

    #if !no_typedarray_inline inline #end
    public function getUint8( byteOffset:Int ) : UInt {
        return ArrayBufferIO.getUint8(buffer, byteOffset);
    }

    #if !no_typedarray_inline inline #end
    public function getUint16( byteOffset:Int, ?littleEndian:Bool = true ) : UInt {
        return ArrayBufferIO.getUint16(buffer, byteOffset, littleEndian);
    }

    #if !no_typedarray_inline inline #end
    public function getUint32( byteOffset:Int, ?littleEndian:Bool = true ) : UInt {
        return ArrayBufferIO.getUint32(buffer, byteOffset, littleEndian);
    }

    #if !no_typedarray_inline inline #end
    public function getFloat32( byteOffset:Int, ?littleEndian:Bool = true ) : Float {
        return ArrayBufferIO.getFloat32(buffer, byteOffset, littleEndian);
    }

    #if !no_typedarray_inline inline #end
    public function getFloat64( byteOffset:Int, ?littleEndian:Bool = true ) : Float {
        return ArrayBufferIO.getFloat64(buffer, byteOffset, littleEndian);
    }




    #if !no_typedarray_inline inline #end
    public function setInt8( byteOffset:Int, value:Int ) {
        ArrayBufferIO.setInt8(buffer, byteOffset, value);
    }

    #if !no_typedarray_inline inline #end
    public function setInt16( byteOffset:Int, value:Int, ?littleEndian:Bool = true) {
        ArrayBufferIO.setInt16(buffer, byteOffset, value, littleEndian);
    }

    #if !no_typedarray_inline inline #end
    public function setInt32( byteOffset:Int, value:Int, ?littleEndian:Bool = true) {
        ArrayBufferIO.setInt32(buffer, byteOffset, value, littleEndian);
    }

    #if !no_typedarray_inline inline #end
    public function setUint8( byteOffset:Int, value:UInt ) {
        ArrayBufferIO.setUint8(buffer, byteOffset, value);
    }

    #if !no_typedarray_inline inline #end
    public function setUint16( byteOffset:Int, value:UInt, ?littleEndian:Bool = true) {
        ArrayBufferIO.setUint16(buffer, byteOffset, value, littleEndian);
    }

    #if !no_typedarray_inline inline #end
    public function setUint32( byteOffset:Int, value:UInt, ?littleEndian:Bool = true) {
        ArrayBufferIO.setUint32(buffer, byteOffset, value, littleEndian);
    }

    #if !no_typedarray_inline inline #end
    public function setFloat32( byteOffset:Int, value:Float, ?littleEndian:Bool = true) {
        ArrayBufferIO.setFloat32(buffer, byteOffset, value, littleEndian);
    }

    #if !no_typedarray_inline inline #end
    public function setFloat64( byteOffset:Int, value:Float, ?littleEndian:Bool = true) {
        ArrayBufferIO.setFloat64(buffer, byteOffset, value, littleEndian);
    }


}

#end //!js