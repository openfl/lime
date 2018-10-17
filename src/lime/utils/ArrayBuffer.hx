package lime.utils;

#if (js && !doc_gen)

    typedef ArrayBuffer = js.html.ArrayBuffer;

#else

    import haxe.io.Bytes;

    @:forward
    abstract ArrayBuffer(Bytes) from Bytes to Bytes #if doc_gen from Dynamic to Dynamic #end {
        public inline function new( byteLength:Int ) {
            this = Bytes.alloc( byteLength );
        }
    }

#end //!js