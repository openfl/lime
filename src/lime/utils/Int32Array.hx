package lime.utils;

#if (js && !display)

    @:forward
    abstract Int32Array(js.html.Int32Array)
        from js.html.Int32Array
        to js.html.Int32Array {

        public inline static var BYTES_PER_ELEMENT : Int = 4;

        @:generic
        public inline function new<T>(
            ?elements:Int,
            ?array:Array<T>,
            #if openfl ?vector:openfl.Vector<Int>, #end
            ?view:ArrayBufferView,
            ?buffer:ArrayBuffer, ?byteoffset:Int = 0, ?len:Null<Int>
        ) {
            if(elements != null) {
                this = new js.html.Int32Array( elements );
            } else if(array != null) {
                this = new js.html.Int32Array( untyped array );
            #if (openfl && commonjs) } else if(vector != null) { this = new js.html.Int32Array( untyped (vector) );
            #elseif openfl } else if(vector != null) { this = new js.html.Int32Array( untyped untyped (vector).__array ); #end
            } else if(view != null) {
                this = new js.html.Int32Array( untyped view );
            } else if(buffer != null) {
                if(len == null) {
                    this = new js.html.Int32Array( buffer, byteoffset );
                } else {
                    this = new js.html.Int32Array( buffer, byteoffset, len );
                }
            } else {
                this = null;
            }
        }

        @:arrayAccess @:extern inline function __set(idx:Int, val:Int) : Int return this[idx] = val;
        @:arrayAccess @:extern inline function __get(idx:Int) : Int return this[idx];


            //non spec haxe conversions
        inline public static function fromBytes( bytes:haxe.io.Bytes, ?byteOffset:Int=0, ?len:Int ) : Int32Array {
            if(byteOffset == null) return new js.html.Int32Array(cast bytes.getData());
            if(len == null) return new js.html.Int32Array(cast bytes.getData(), byteOffset);
            return new js.html.Int32Array(cast bytes.getData(), byteOffset, len);
        }

        inline public function toBytes() : haxe.io.Bytes {
            return @:privateAccess new haxe.io.Bytes( cast new js.html.Uint8Array(this.buffer) );
        }

        inline function toString() return this != null ? 'Int32Array [byteLength:${this.byteLength}, length:${this.length}]' : null;

    }

#else

    import lime.utils.ArrayBufferView;

    @:forward
    abstract Int32Array(ArrayBufferView) from ArrayBufferView to ArrayBufferView {

        public inline static var BYTES_PER_ELEMENT : Int = 4;

        public var length (get, never):Int;

        @:generic
        public inline function new<T>(
            ?elements:Int,
            ?buffer:ArrayBuffer,
            ?array:Array<T>,
            #if openfl ?vector:openfl.Vector<Int>, #end
            ?view:ArrayBufferView,
            ?byteoffset:Int = 0, ?len:Null<Int>
        ) {

            if(elements != null) {
                this = new ArrayBufferView( elements, Int32 );
            } else if(array != null) {
                this = new ArrayBufferView(0, Int32).initArray(array);
            #if openfl } else if(vector != null) { this = new ArrayBufferView(0, Int32).initArray(untyped (vector).__array); #end
            } else if(view != null) {
                this = new ArrayBufferView(0, Int32).initTypedArray(view);
            } else if(buffer != null) {
                this = new ArrayBufferView(0, Int32).initBuffer(buffer, byteoffset, len);
            } else {
                throw "Invalid constructor arguments for Int32Array";
            }
        }

    //Public API

        public inline function subarray( begin:Int, end:Null<Int> = null) : Int32Array return this.subarray(begin, end);


            //non spec haxe conversions
        inline public static function fromBytes( bytes:haxe.io.Bytes, ?byteOffset:Int=0, ?len:Int ) : Int32Array {
            return new Int32Array(bytes, byteOffset, len);
        }

        inline public function toBytes() : haxe.io.Bytes {
            return this.buffer;
        }

    //Internal

        inline function get_length() return this.length;


        @:noCompletion
        @:arrayAccess @:extern
        public inline function __get(idx:Int) {
            return ArrayBufferIO.getInt32(this.buffer, this.byteOffset+(idx*BYTES_PER_ELEMENT));
        }

        @:noCompletion
        @:arrayAccess @:extern
        public inline function __set(idx:Int, val:Int) {
            ArrayBufferIO.setInt32(this.buffer, this.byteOffset+(idx*BYTES_PER_ELEMENT), val);
            return val;
        }

        inline function toString() return this != null ? 'Int32Array [byteLength:${this.byteLength}, length:${this.length}]' : null;

    }

#end //!js