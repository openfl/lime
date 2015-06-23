package lime.utils;

#if (js && !display)

    @:forward
    @:arrayAccess
    abstract Float64Array(js.html.Float64Array)
        from js.html.Float64Array
        to js.html.Float64Array {
		
		public inline static var BYTES_PER_ELEMENT : Int = 8;
		
        @:generic
        public inline function new<T>(
            ?elements:Int,
            ?array:Array<T>,
            ?view:ArrayBufferView,
            ?buffer:ArrayBuffer, ?byteoffset:Int = 0, ?len:Null<Int>
        ) {
            if(elements != null) {
                this = new js.html.Float64Array( elements );
            } else if(array != null) {
                this = new js.html.Float64Array( untyped array );
            } else if(view != null) {
                this = new js.html.Float64Array( untyped view );
            } else if(buffer != null) {
                len = (len == null) ? untyped __js__('undefined') : len;
                this = new js.html.Float64Array( buffer, byteoffset, len );
            } else {
                this = null;
            }
        }

        @:arrayAccess inline function __set(idx:Int, val:Float) return this[idx] = val;
        @:arrayAccess inline function __get(idx:Int) : Float return this[idx];


            //non spec haxe conversions
        public static function fromBytes( bytes:haxe.io.Bytes, ?byteOffset:Int=0, ?len:Int ) : Float64Array {
            return new js.html.Float64Array(cast bytes.getData(), byteOffset, len);
        }

        public function toBytes() : haxe.io.Bytes {
            #if ((haxe_ver < 3.2) || nodejs)
            return @:privateAccess new haxe.io.Bytes( this.byteLength, cast new js.html.Uint8Array(this.buffer) );
            #else
                return @:privateAccess new haxe.io.Bytes( cast new js.html.Uint8Array(this.buffer) );
            #end
    }

    }

#else

    import lime.utils.ArrayBufferView;

@:forward()
@:arrayAccess
abstract Float64Array(ArrayBufferView) from ArrayBufferView to ArrayBufferView {

    public inline static var BYTES_PER_ELEMENT : Int = 8;

    public var length (get, never):Int;

        @:generic
        public inline function new<T>(
            ?elements:Int,
            ?array:Array<T>,
            ?view:ArrayBufferView,
            ?buffer:ArrayBuffer, ?byteoffset:Int = 0, ?len:Null<Int>
        ) {

            if(elements != null) {
                this = new ArrayBufferView( elements, Float64 );
            } else if(array != null) {
                this = new ArrayBufferView(0, Float64).initArray(array);
            } else if(view != null) {
                this = new ArrayBufferView(0, Float64).initTypedArray(view);
            } else if(buffer != null) {
                this = new ArrayBufferView(0, Float64).initBuffer(buffer, byteoffset, len);
            } else {
                throw "Invalid constructor arguments for Float64Array";
            }
        }

//Public API

    public inline function subarray( begin:Int, end:Null<Int> = null) : Float64Array return this.subarray(begin, end);


            //non spec haxe conversions
        public static function fromBytes( bytes:haxe.io.Bytes, ?byteOffset:Int=0, ?len:Int ) : Float64Array {
            return new Float64Array(bytes, byteOffset, len);
        }

        public function toBytes() : haxe.io.Bytes {
            return this.buffer;
        }

//Internal

    inline function get_length() return this.length;


    @:noCompletion
    @:arrayAccess
    public inline function __get(idx:Int) : Float {
        return ArrayBufferIO.getFloat64(this.buffer, this.byteOffset+(idx*BYTES_PER_ELEMENT));
    }

    @:noCompletion
    @:arrayAccess
    public inline function __set(idx:Int, val:Float) : Float {
        return ArrayBufferIO.setFloat64(this.buffer, this.byteOffset+(idx*BYTES_PER_ELEMENT), val);
    }

}

#end //!js
