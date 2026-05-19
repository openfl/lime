package lime._internal.backend.emscripten;

#if emscripten
import cpp.Star;
import cpp.Pointer;
import cpp.ConstCharStar;

@:include("emscripten/fetch.h")
@:native
extern class EmscriptenFetch {

    @:native("emscripten_fetch_attr_init")
    public static function emscripten_fetch_attr_init(attr:Pointer<EmscriptenFetchAttrType>):Void;

    @:native("emscripten_fetch")
    public static function emscripten_fetch(attr:Pointer<EmscriptenFetchAttrType>, url:ConstCharStar):Pointer<EmscriptenFetchType>;

    @:native("emscripten_fetch_close")
    public static function emscripten_fetch_close(fetch:Pointer<EmscriptenFetchType>):Void;
}

@:include("emscripten/fetch.h")
@:native("emscripten_fetch_attr_t")
@:structAccess
@:unreflective
extern class EmscriptenFetchAttrType {
    public var requestMethod:ConstCharStar;
    public var onsuccess:Star<EmscriptenFetchType>->Void;
    public var onprogress:Star<EmscriptenFetchType>->Void;
    public var onerror:Star<EmscriptenFetchType>->Void;
    public var attributes:Int;
    public var userData:Star<cpp.Void>;
}

@:include("emscripten/fetch.h")
@:native("emscripten_fetch_t")
@:structAccess
extern class EmscriptenFetchType {
    public var id:Int;
    public var numBytes:Int;
    public var dataOffset:Int;
    public var totalBytes:Int;
    public var url:ConstCharStar;
    public var readyState:Int;
    public var status:Int;
    public var statusText:ConstCharStar;
    public var data:Pointer<cpp.UInt8>;
    public var userData:Star<cpp.Void>;
}
#end