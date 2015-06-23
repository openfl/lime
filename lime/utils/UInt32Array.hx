package lime.utils;

#if (js && !display)

    @:forward
    @:arrayAccess
    abstract UInt32Array(js.html.Uint32Array)
        from js.html.Uint32Array
        to js.html.Uint32Array {
		
		public inline static var BYTES_PER_ELEMENT : Int = 4;
		
        @:generic
        public inline function new<T>(
            ?elements:Int,
            ?array:Array<T>,
            ?view:ArrayBufferView,
            ?buffer:ArrayBuffer, ?byteoffset:Int = 0, ?len:Null<Int>
        ) {
            if(elements != null) {
                this = new js.html.Uint32Array( elements );
            } else if(array != null) {
                this = new js.html.Uint32Array( untyped array );
            } else if(view != null) {
                this = new js.html.Uint32Array( untyped view );
            } else if(buffer != null) {
                len = (len == null) ? untyped __js__('undefined') : len;
                this = new js.html.Uint32Array( buffer, byteoffset, len );
            } else {
                this = null;
            }
        }

        @:arrayAccess inline function __set(idx:Int, val:UInt) return this[idx] = val;
        @:arrayAccess inline function __get(idx:Int) : UInt return this[idx];


            //non spec haxe conversions
        public static function fromBytes( bytes:haxe.io.Bytes, ?byteOffset:Int=0, ?len:Int ) : UInt32Array {
            return new js.html.Uint32Array(cast bytes.getData(), byteOffset, len);
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
abstract UInt32Array(ArrayBufferView) from ArrayBufferView to ArrayBufferView {

    public inline static var BYTES_PER_ELEMENT : Int = 4;

    public var length (get, never):Int;

        @:generic
        public inline function new<T>(
            ?elements:Int,
            ?array:Array<T>,
            ?view:ArrayBufferView,
            ?buffer:ArrayBuffer, ?byteoffset:Int = 0, ?len:Null<Int>
        ) {

            if(elements != null) {
                this = new ArrayBufferView( elements, Uint32 );
            } else if(array != null) {
                this = new ArrayBufferView(0, Uint32).initArray(array);
            } else if(view != null) {
                this = new ArrayBufferView(0, Uint32).initTypedArray(view);
            } else if(buffer != null) {
                this = new ArrayBufferView(0, Uint32).initBuffer(buffer, byteoffset, len);
            } else {
                throw "Invalid constructor arguments for Uint32Array";
            }
        }

//Public API

    public inline function subarray( begin:Int, end:Null<Int> = null) : UInt32Array return this.subarray(begin, end);


            //non spec haxe conversions
        public static function fromBytes( bytes:haxe.io.Bytes, ?byteOffset:Int=0, ?len:Int ) : UInt32Array {
            return new UInt32Array(bytes, byteOffset, len);
        }

        public function toBytes() : haxe.io.Bytes {
            return this.buffer;
        }

//Internal

    inline function get_length() return this.length;


    @:noCompletion
    @:arrayAccess
    public inline function __get(idx:Int) {
        return ArrayBufferIO.getUint32(this.buffer, this.byteOffset+(idx*BYTES_PER_ELEMENT));
    }

    @:noCompletion
    @:arrayAccess
    public inline function __set(idx:Int, val:UInt) {
        return ArrayBufferIO.setUint32(this.buffer, this.byteOffset+(idx*BYTES_PER_ELEMENT), val);
    }

}

#end //!js
