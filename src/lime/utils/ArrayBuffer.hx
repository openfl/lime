package lime.utils;

#if (js && !display)

    typedef ArrayBuffer = js.html.ArrayBuffer;

#else

    import haxe.io.Bytes;

    @:forward
    abstract ArrayBuffer(Bytes) from Bytes to Bytes {
        public inline function new( byteLength:Int ) {
            this = Bytes.alloc( byteLength );
        }
    }

#end //!js