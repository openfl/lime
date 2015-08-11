package lime.utils;

#if (js && !display)

    @:forward
    @:arrayAccess
    abstract Int8Array(js.html.Int8Array)
        from js.html.Int8Array
        to js.html.Int8Array {

        public inline static var BYTES_PER_ELEMENT : Int = 1;

        @:generic
        public inline function new<T>(
            ?elements:Int,
            ?array:Array<T>,
            ?view:ArrayBufferView,
            ?buffer:ArrayBuffer, ?byteoffset:Int = 0, ?len:Null<Int>
        ) {
            if(elements != null) {
                this = new js.html.Int8Array( elements );
            } else if(array != null) {
                this = new js.html.Int8Array( untyped array );
            } else if(view != null) {
                this = new js.html.Int8Array( untyped view );
            } else if(buffer != null) {
                if(len == null) {
                    this = new js.html.Int8Array( buffer, byteoffset );
                } else {
                    this = new js.html.Int8Array( buffer, byteoffset, len );
                }
            } else {
                this = null;
            }
        }

        @:arrayAccess inline function __set(idx:Int, val:Int) return this[idx] = val;
        @:arrayAccess inline function __get(idx:Int) : Int return this[idx];


            //non spec haxe conversions
        public static function fromBytes( bytes:haxe.io.Bytes, ?byteOffset:Int=0, ?len:Int ) : Int8Array {
            return new js.html.Int8Array(cast bytes.getData(), byteOffset, len);
        }

        public function toBytes() : haxe.io.Bytes {
            #if (haxe_ver < 3.2)
            return @:privateAccess new haxe.io.Bytes( this.byteLength, cast new js.html.Uint8Array(this.buffer) );
            #else
                return @:privateAccess new haxe.io.Bytes( cast new js.html.Uint8Array(this.buffer) );
            #end
    }

        function toString() return this != null ? 'Int8Array [byteLength:${this.byteLength}, length:${this.length}]' : null;

    }

#else

    import lime.utils.ArrayBufferView;

@:forward()
@:arrayAccess
abstract Int8Array(ArrayBufferView) from ArrayBufferView to ArrayBufferView {

    public inline static var BYTES_PER_ELEMENT : Int = 1;

    public var length (get, never):Int;

        @:generic
        public inline function new<T>(
            ?elements:Int,
            ?array:Array<T>,
            ?view:ArrayBufferView,
            ?buffer:ArrayBuffer, ?byteoffset:Int = 0, ?len:Null<Int>
        ) {

            if(elements != null) {
                this = new ArrayBufferView( elements, Int8 );
            } else if(array != null) {
                this = new ArrayBufferView(0, Int8).initArray(array);
            } else if(view != null) {
                this = new ArrayBufferView(0, Int8).initTypedArray(view);
            } else if(buffer != null) {
                this = new ArrayBufferView(0, Int8).initBuffer(buffer, byteoffset, len);
            } else {
                throw "Invalid constructor arguments for Int8Array";
            }
        }

//Public API

    public inline function subarray( begin:Int, end:Null<Int> = null) : Int8Array return this.subarray(begin, end);


            //non spec haxe conversions
        public static function fromBytes( bytes:haxe.io.Bytes, ?byteOffset:Int=0, ?len:Int ) : Int8Array {
            if(byteOffset == null) return new Int8Array(cast bytes.getData());
            if(len == null) return new Int8Array(cast bytes.getData(), byteOffset);
            return new Int8Array(cast bytes.getData(), byteOffset, len);
        }

        public function toBytes() : haxe.io.Bytes {
            return this.buffer;
        }

//Internal

    inline function get_length() return this.length;


    @:noCompletion
    @:arrayAccess
    public inline function __get(idx:Int) {
        return ArrayBufferIO.getInt8(this.buffer, this.byteOffset+idx);
    }

    @:noCompletion
    @:arrayAccess
    public inline function __set(idx:Int, val:Int) {
        return ArrayBufferIO.setInt8(this.buffer, this.byteOffset+idx, val);
    }

        function toString() return this != null ? 'Int8Array [byteLength:${this.byteLength}, length:${this.length}]' : null;

}

#end //!js