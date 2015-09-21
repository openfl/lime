package lime.utils;

#if (js && !display)

    typedef ArrayBufferView = js.html.ArrayBufferView;

#else

class ArrayBufferView {

    public var type = TypedArrayType.None;
    public var buffer:ArrayBuffer;
    public var byteOffset:Int;
    public var byteLength:Int;
    public var length:Int;

            //internal for avoiding switching on types
        var bytesPerElement (default,null) : Int = 0;

    @:allow(lime.utils)
    #if !no_typedarray_inline inline #end
    function new( ?elements:Null<Int> = null, in_type:TypedArrayType) {

        type = in_type;
        bytesPerElement = bytesForType(type);

            //other constructor types use
            //the init calls below
        if(elements != null && elements != 0) {

            if(elements < 0) elements = 0;
            //:note:spec: also has, platform specific max int?
            //elements = min(elements,maxint);

            byteOffset = 0;
            byteLength = toByteLength(elements);
            buffer = new ArrayBuffer( byteLength );
            length = elements;

        }

    } //new

//Constructor helpers

    @:allow(lime.utils)
    #if !no_typedarray_inline inline #end
    function initTypedArray( view:ArrayBufferView ) {

        var srcData = view.buffer;
        var srcLength = view.length;
        var srcByteOffset = view.byteOffset;
        var srcElementSize = view.bytesPerElement;
        var elementSize = bytesPerElement;

                //same species, so just blit the data
                //in other words, it shares the same bytes per element etc
            if(view.type == type) {
                cloneBuffer(srcData, srcByteOffset);
            } else {
                //see :note:1: below use FPHelper!
                throw ("unimplemented");
            }

        byteLength = bytesPerElement * srcLength;
        byteOffset = 0;
        length = srcLength;

        return this;

    } //(typedArray)

    @:allow(lime.utils)
    #if !no_typedarray_inline inline #end
    function initBuffer( in_buffer:ArrayBuffer, ?in_byteOffset:Int = 0, len:Null<Int> = null ) {

        if(in_byteOffset < 0) throw TAError.RangeError;
        if(in_byteOffset % bytesPerElement != 0) throw TAError.RangeError;

        var bufferByteLength = in_buffer.length;
        var elementSize = bytesPerElement;
        var newByteLength = bufferByteLength;

        if( len == null ) {

            newByteLength = bufferByteLength - in_byteOffset;

            if(bufferByteLength % bytesPerElement != 0) throw TAError.RangeError;
            if(newByteLength < 0) throw TAError.RangeError;

        } else {

            newByteLength = len * bytesPerElement;

            var newRange = in_byteOffset + newByteLength;
            if( newRange > bufferByteLength ) throw TAError.RangeError;

        }

        buffer = in_buffer;
        byteOffset = in_byteOffset;
        byteLength = newByteLength;
        length = Std.int(newByteLength / bytesPerElement);

        return this;

    } //(buffer [, byteOffset [, length]])


    @:allow(lime.utils)
    #if !no_typedarray_inline inline #end
    function initArray<T>( array:Array<T> ) {

        byteOffset = 0;
        length = array.length;
        byteLength = toByteLength(length);

        buffer = new ArrayBuffer( byteLength );
        copyFromArray(cast array);

        return this;

    }


//Public shared APIs

    //T is required because it can translate [0,0] as Int array
    #if !no_typedarray_inline inline #end
    public function set<T>( ?view:ArrayBufferView, ?array:Array<T>, offset:Int = 0 ) : Void {

        if(view != null && array == null) {
            buffer.blit( toByteLength(offset), view.buffer, view.byteOffset, view.byteLength );
        } else if(array != null && view == null) {
            copyFromArray(cast array, offset);
        } else {
            throw "Invalid .set call. either view, or array must be not-null.";
        }

    }


//Internal TypedArray api

    #if !no_typedarray_inline inline #end
    function cloneBuffer(src:ArrayBuffer, srcByteOffset:Int = 0) {

        var srcLength = src.length;
        var cloneLength = srcLength - srcByteOffset;

        buffer = new ArrayBuffer( cloneLength );
        buffer.blit( 0, src, srcByteOffset, cloneLength );

    }


    @:generic
    @:allow(lime.utils)
    #if !no_typedarray_inline inline #end
    function subarray<T_subarray>( begin:Int, end:Null<Int> = null ) : T_subarray {

        if (end == null) end == length;
        var len = end - begin;
        var byte_offset = toByteLength(begin);

        var view : ArrayBufferView =
            switch(type) {

                case Int8:
                         new Int8Array(buffer, byte_offset, len);

                case Int16:
                         new Int16Array(buffer, byte_offset, len);

                case Int32:
                         new Int32Array(buffer, byte_offset, len);

                case Uint8:
                         new UInt8Array(buffer, byte_offset, len);

                case Uint8Clamped:
                         new UInt8ClampedArray(buffer, byte_offset, len);

                case Uint16:
                         new UInt16Array(buffer, byte_offset, len);

                case Uint32:
                         new UInt32Array(buffer, byte_offset, len);

                case Float32:
                         new Float32Array(buffer, byte_offset, len);

                case Float64:
                         new Float64Array(buffer, byte_offset, len);

                case None:
                    throw "subarray on a blank ArrayBufferView";
            }

        return cast view;

    }

    #if !no_typedarray_inline inline #end
    function bytesForType( type:TypedArrayType ) : Int {

        return
            switch(type) {

                case Int8:
                     Int8Array.BYTES_PER_ELEMENT;

                case Uint8:
                     UInt8Array.BYTES_PER_ELEMENT;

                case Uint8Clamped:
                     UInt8ClampedArray.BYTES_PER_ELEMENT;

                case Int16:
                     Int16Array.BYTES_PER_ELEMENT;

                case Uint16:
                     UInt16Array.BYTES_PER_ELEMENT;

                case Int32:
                     Int32Array.BYTES_PER_ELEMENT;

                case Uint32:
                     UInt32Array.BYTES_PER_ELEMENT;

                case Float32:
                     Float32Array.BYTES_PER_ELEMENT;

                case Float64:
                     Float64Array.BYTES_PER_ELEMENT;

                case _: 1;
            }

    }

        #if !no_typedarray_inline inline #end
        function toString() {
            
            if (this == null) return null;
            
            var name =
                switch(type) {
                    case Int8: 'Int8Array';
                    case Uint8: 'UInt8Array';
                    case Uint8Clamped: 'UInt8ClampedArray';
                    case Int16: 'Int16Array';
                    case Uint16: 'UInt16Array';
                    case Int32: 'Int32Array';
                    case Uint32: 'UInt32Array';
                    case Float32: 'Float32Array';
                    case Float64: 'Float64Array';
                    case _: 'ArrayBufferView';
                }

            return name + ' [byteLength:${this.byteLength}, length:${this.length}]';

        } //toString

    #if !no_typedarray_inline inline #end
    function toByteLength( elemCount:Int ) : Int {

        return elemCount * bytesPerElement;

    }

//Non-spec

    #if !no_typedarray_inline #end
    function copyFromArray(array:Array<Float>, offset : Int = 0 ) {

        //Ideally, native semantics could be used, like cpp.NativeArray.blit
        var i = 0, len = array.length;

        switch(type) {
            case Int8:
                while(i<len) {
                    var pos = (offset+i)*bytesPerElement;
                    ArrayBufferIO.setInt8(buffer,
                        pos, Std.int(array[i]));
                    ++i;
                }
            case Int16:
                while(i<len) {
                    var pos = (offset+i)*bytesPerElement;
                    ArrayBufferIO.setInt16(buffer,
                        pos, Std.int(array[i]));
                    ++i;
                }
            case Int32:
                while(i<len) {
                    var pos = (offset+i)*bytesPerElement;
                    ArrayBufferIO.setInt32(buffer,
                        pos, Std.int(array[i]));
                    ++i;
                }
            case Uint8:
                while(i<len) {
                    var pos = (offset+i)*bytesPerElement;
                    ArrayBufferIO.setUint8(buffer,
                        pos, Std.int(array[i]));
                    ++i;
                }
            case Uint16:
                while(i<len) {
                    var pos = (offset+i)*bytesPerElement;
                    ArrayBufferIO.setUint16(buffer,
                        pos, Std.int(array[i]));
                    ++i;
                }
            case Uint32:
                while(i<len) {
                    var pos = (offset+i)*bytesPerElement;
                    ArrayBufferIO.setUint32(buffer,
                        pos, Std.int(array[i]));
                    ++i;
                }
            case Uint8Clamped:
                while(i<len) {
                    var pos = (offset+i)*bytesPerElement;
                    ArrayBufferIO.setUint8Clamped(buffer,
                        pos, Std.int(array[i]));
                    ++i;
                }
            case Float32:
                while(i<len) {
                    var pos = (offset+i)*bytesPerElement;
                    ArrayBufferIO.setFloat32(buffer,
                        pos, array[i]);
                    ++i;
                }
            case Float64:
                while(i<len) {
                    var pos = (offset+i)*bytesPerElement;
                    ArrayBufferIO.setFloat64(buffer,
                        pos, array[i]);
                    ++i;
                }

            case None:
                throw "copyFromArray on a base type ArrayBuffer";

        }

    }

} //ArrayBufferView

#end //!js

@:noCompletion @:dox(hide)  enum TAError {
    RangeError;
}

@:noCompletion @:dox(hide)  @:enum
private abstract TypedArrayType(Int) from Int to Int {
    var None            = 0;
    var Int8            = 1;
    var Int16           = 2;
    var Int32           = 3;
    var Uint8           = 4;
    var Uint8Clamped    = 5;
    var Uint16          = 6;
    var Uint32          = 7;
    var Float32         = 8;
    var Float64         = 9;
}

#if (!js || display)

@:noCompletion @:dox(hide) class ArrayBufferIO {

    #if !no_typedarray_inline inline #end
    public static function getInt8( buffer:ArrayBuffer, byteOffset:Int ) : Int {

        #if cpp
            return untyped __global__.__hxcpp_memory_get_byte(buffer.getData(), byteOffset);
        #else
            var val:Int = buffer.get(byteOffset);
            return ((val & 0x80) != 0) ?(val - 0x100) : val;
        #end

    }

    #if !no_typedarray_inline inline #end
    public static function setInt8( buffer:ArrayBuffer, byteOffset:Int, value:Int ) {

        #if cpp
            untyped __global__.__hxcpp_memory_set_byte(buffer.getData(), byteOffset, value);
        #elseif neko
            untyped __dollar__sset(buffer.b, byteOffset, value & 0xff);
        #else
            buffer.set(byteOffset, value);
        #end

        return value;

    }

    #if !no_typedarray_inline inline #end
    public static function getUint8( buffer:ArrayBuffer, byteOffset:Int ) : Null<UInt> {

        #if cpp
            return untyped __global__.__hxcpp_memory_get_byte(buffer.getData(), byteOffset) & 0xff;
        #else
            return buffer.get( byteOffset );
        #end

    }

    #if !no_typedarray_inline inline #end
    public static function setUint8Clamped( buffer:ArrayBuffer, byteOffset:Int, value:UInt ) : UInt {

        return setUint8( buffer, byteOffset, _clamp(value) );

    }

    #if !no_typedarray_inline inline #end
    public static function setUint8( buffer:ArrayBuffer, byteOffset:Int, value:UInt ) : UInt {

        #if cpp
            untyped __global__.__hxcpp_memory_set_byte(buffer.getData(), byteOffset, value);
        #else
            buffer.set( byteOffset, value );
        #end

        return value;

    }

    public static  function getInt16( buffer:ArrayBuffer, byteOffset:Int, littleEndian:Bool=true ) : Int {

        #if cpp
            untyped return __global__.__hxcpp_memory_get_i16(buffer.getData(), byteOffset);
        #else
            var ch1 = buffer.get(byteOffset    );
            var ch2 = buffer.get(byteOffset + 1);

            var val =
                if(littleEndian)
                    ((ch2 << 8) | ch1) else
                    ((ch1 << 8) | ch2);

            return
                ((val & 0x8000) != 0) ?
                    ( val - 0x10000 ) : ( val );
        #end

    }

    public static function setInt16( buffer:ArrayBuffer, byteOffset:Int, value:Int, littleEndian:Bool=true ) {

        #if cpp
            untyped __global__.__hxcpp_memory_set_i16(buffer.getData(), byteOffset, value);
        #elseif neko
            untyped var b = buffer.b;
            if(littleEndian) {
                untyped __dollar__sset(b, byteOffset  , (value     ) & 0xff);
                untyped __dollar__sset(b, byteOffset+1, (value >> 8) & 0xff);
            } else {
                untyped __dollar__sset(b, byteOffset  , (value >> 8) & 0xff);
                untyped __dollar__sset(b, byteOffset+1, (value     ) & 0xff);
            }
        #else
            if(littleEndian) {
                buffer.set(byteOffset  , (value     ) & 0xff);
                buffer.set(byteOffset+1, (value >> 8) & 0xff);
            } else {
                buffer.set(byteOffset  , (value >> 8) & 0xff);
                buffer.set(byteOffset+1, (value     ) & 0xff);
            }
        #end


        return value;

    }

    #if !no_typedarray_inline inline #end
    public static function getUint16( buffer:ArrayBuffer, byteOffset:Int, littleEndian:Bool=true ) : Null<UInt> {

        #if cpp
            untyped return __global__.__hxcpp_memory_get_ui16(buffer.getData(), byteOffset) & 0xffff;
        #else

            var ch1 = buffer.get(byteOffset    );
            var ch2 = buffer.get(byteOffset + 1);

            return
                if(littleEndian)
                    ((ch2 << 8) | ch1) else
                    ((ch1 << 8) | ch2);

        #end

    }

    #if !no_typedarray_inline inline #end
    public static function setUint16( buffer:ArrayBuffer, byteOffset:Int, value:UInt, littleEndian:Bool=true ) : UInt {

        #if cpp
            untyped __global__.__hxcpp_memory_set_ui16(buffer.getData(), byteOffset, value);
        #else
            setInt16(buffer, byteOffset, value, littleEndian);
        #end

        return value;

    }

    #if !no_typedarray_inline inline #end
    public static function getInt32( buffer:ArrayBuffer, byteOffset:Int, littleEndian:Bool=true ) : Int {

        #if cpp
            untyped return __global__.__hxcpp_memory_get_i32(buffer.getData(), byteOffset);
        #else
            #if (haxe_ver >= 3.2)
                return buffer.getInt32(byteOffset);
            #else

                var ch1 = getInt8(buffer, byteOffset  );
                var ch2 = getInt8(buffer, byteOffset+1);
                var ch3 = getInt8(buffer, byteOffset+2);
                var ch4 = getInt8(buffer, byteOffset+3);

                return
                    littleEndian ?
                        (ch4 << 24) |(ch3 << 16) |(ch2 << 8) | ch1  //littleEndian
                      : (ch1 << 24) |(ch2 << 16) |(ch3 << 8) | ch4; //bigEndian

            #end //3.1.3
        #end

    }

    #if !no_typedarray_inline inline #end
    public static function setInt32( buffer:ArrayBuffer, byteOffset:Int, value:Int, littleEndian:Bool=true ) {

        #if cpp
            untyped __global__.__hxcpp_memory_set_i32(buffer.getData(), byteOffset, value);
        #else
            #if ((haxe_ver >= 3.2) && !neko) // causes error on some int values?
                buffer.setInt32(byteOffset,value);
            #else
                if (littleEndian) {
                    setInt8(buffer, byteOffset  , value      );
                    setInt8(buffer, byteOffset+1, value >>  8);
                    setInt8(buffer, byteOffset+2, value >> 16);
                    setInt8(buffer, byteOffset+3, value >> 24);
                } else {
                    setInt8(buffer, byteOffset  , value >> 24);
                    setInt8(buffer, byteOffset+1, value >> 16);
                    setInt8(buffer, byteOffset+2, value >>  8);
                    setInt8(buffer, byteOffset+3, value      );
                }
            #end //3.1.3.
        #end

        return value;

    }

    #if !no_typedarray_inline inline #end
    public static function getUint32( buffer:ArrayBuffer, byteOffset:Int, littleEndian:Bool=true ) : Null<UInt> {

        #if cpp
            untyped return __global__.__hxcpp_memory_get_ui32(buffer.getData(), byteOffset);
        #else
            return getInt32( buffer, byteOffset, littleEndian );
        #end

    }

    #if !no_typedarray_inline inline #end
    public static function setUint32( buffer:ArrayBuffer, byteOffset:Int, value:UInt, littleEndian:Bool=true ) : UInt {

        #if cpp
            untyped __global__.__hxcpp_memory_set_ui32(buffer.getData(), byteOffset, value);
        #else
            setInt32( buffer, byteOffset, value );
        #end

        return value;

    }

    #if !no_typedarray_inline inline #end
    public static function getFloat32( buffer:ArrayBuffer, byteOffset:Int, littleEndian:Bool=true ) : Float {

        #if cpp
            untyped return __global__.__hxcpp_memory_get_float(buffer.getData(), byteOffset);
        #else
            return buffer.getFloat( byteOffset );
        #end

    }

    #if !no_typedarray_inline inline #end
    public static function setFloat32( buffer:ArrayBuffer, byteOffset:Int, value:Float, littleEndian:Bool=true ) : Float {

        #if cpp
            untyped __global__.__hxcpp_memory_set_float(buffer.getData(), byteOffset, value);
        #else
            buffer.setFloat( byteOffset, value );
        #end

        return value;

    }

    #if !no_typedarray_inline inline #end
    public static function getFloat64( buffer:ArrayBuffer, byteOffset:Int, littleEndian:Bool=true ) : Float {

        #if cpp
            untyped return __global__.__hxcpp_memory_get_double(buffer.getData(), byteOffset);
        #else
            return buffer.getDouble( byteOffset );
        #end

    }

    #if !no_typedarray_inline inline #end
    public static function setFloat64( buffer:ArrayBuffer, byteOffset:Int, value:Float, littleEndian:Bool=true ) : Float {

        #if cpp
            untyped __global__.__hxcpp_memory_set_double(buffer.getData(), byteOffset, value);
        #else
            buffer.setDouble( byteOffset, value );
        #end

        return value;

    }

//Internal

    #if !no_typedarray_inline inline #end
    //clamp a Int to a 0-255 Uint8 (for Uint8Clamped array)
    static function _clamp(_in:Float) : Int {

        var _out = Std.int(_in);
        _out = _out > 255 ? 255 : _out;
        return _out < 0 ? 0 : _out;

    } //_clamp

}

#else

    //#error "ArrayBufferIO is not used on js target, use DataView instead"

#end //!js
