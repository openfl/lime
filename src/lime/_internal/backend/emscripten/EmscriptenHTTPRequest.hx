package lime._internal.backend.emscripten;

#if emscripten
import haxe.io.Bytes;
import cpp.Pointer;
import cpp.Star;
import lime.app.Future;
import lime.app.Promise;
import lime.graphics.Image;
import lime.net.HTTPRequest._IHTTPRequest;
import lime._internal.backend.emscripten.EmscriptenFetch.EmscriptenFetchAttrType;
import lime._internal.backend.emscripten.EmscriptenFetch.EmscriptenFetchType;
import lime.net.HTTPRequest._HTTPRequestErrorResponse;

@:access(lime.graphics.ImageBuffer)
@:access(lime.graphics.Image)
class EmscriptenHTTPRequest
{
    private static var fetchId:Int = 0;
    private static var activeFetches = new Map<Int, FetchContext>();

    private var binary:Bool;
    private var parent:_IHTTPRequest;
    private var currentFetchId:Int = -1;

    public function new()
    {
    }

    public function cancel():Void
    {
        if (currentFetchId >= 0 && activeFetches.exists(currentFetchId))
        {
            var context = activeFetches.get(currentFetchId);
            if (context != null && context.fetchPtr != null)
            {
                EmscriptenFetch.emscripten_fetch_close(context.fetchPtr);
            }
            activeFetches.remove(currentFetchId);
            currentFetchId = -1;
        }
    }

    public function init(parent:_IHTTPRequest):Void
    {
        this.parent = parent;
    }

    public function loadData(uri:String):Future<Bytes>
    {
        var promise = new Promise<Bytes>();
        binary = true;
        __load(uri, promise, LoadType.BINARY);
        return promise.future;
    }

    public function loadText(uri:String):Future<String>
    {
        var promise = new Promise<String>();
        binary = false;
        __load(uri, promise, LoadType.TEXT);
        return promise.future;
    }

    private function __load(uri:String, promise:Dynamic, loadType:LoadType):Void
    {
        var id = fetchId++;
        currentFetchId = id;

        var context:FetchContext = {
            id: id,
            promise: promise,
            parent: parent,
            loadType: loadType,
            binary: binary,
            fetchPtr: null
        };

        activeFetches.set(id, context);

        var attr:EmscriptenFetchAttrType = untyped __cpp__("{}");
        var attrPtr:Pointer<EmscriptenFetchAttrType> = Pointer.addressOf(attr);
        EmscriptenFetch.emscripten_fetch_attr_init(attrPtr);

        // Set request method
        var method = parent.method != null ? Std.string(parent.method) : "GET";
        untyped __cpp__('strcpy({0}, {1})', attr.requestMethod, method);

        // Set callbacks
        attr.onsuccess = untyped __cpp__("onFetchSuccess");
        attr.onprogress = untyped __cpp__("onFetchProgress");
        attr.onerror = untyped __cpp__("onFetchError");

        // Store fetch ID in userData
        var idPointer:Star<cpp.Int32> = untyped __cpp__('(int*)malloc(sizeof(int))');
        untyped __cpp__('*{0} = {1}', idPointer, id);
        attr.userData = cast idPointer;

        // Set EMSCRIPTEN_FETCH_LOAD_TO_MEMORY
        attr.attributes = 1;

        // Start fetch
        var fetchPtr = EmscriptenFetch.emscripten_fetch(attrPtr, uri);
        context.fetchPtr = fetchPtr;
    }

    @:keep
    private static function onFetchSuccess(fetchPtr:Star<EmscriptenFetchType>):Void
    {
        var fetch:EmscriptenFetchType = Pointer.fromStar(fetchPtr).value;
        var idPointer:Star<cpp.Int32> = cast fetch.userData;
        var id:Int = untyped __cpp__('*(int*){0}', idPointer);

        cpp.Native.free(idPointer);
        fetch.userData = null;

        if (!activeFetches.exists(id))
        {
            EmscriptenFetch.emscripten_fetch_close(Pointer.fromStar(fetchPtr));
            return;
        }

        var context = activeFetches.get(id);
        activeFetches.remove(id);
        if(context == null)
            trace("EmscriptenHTTPRequest.onFetchSuccess: context is null");

        // Process response
        if (context.parent.enableResponseHeaders)
        {
            context.parent.responseHeaders = [];
            // Note: Emscripten Fetch API has limited header access
            // You may need to parse headers from fetch.statusText if available
        }

        context.parent.responseStatus = fetch.status;

        // Create bytes from fetch data
        var bytes:Bytes = null;
        if (fetch.numBytes > 0 && fetch.data != null)
        {
            bytes = Bytes.ofData(cast fetch.data.toUnmanagedArray(fetch.numBytes).copy());
        }
        else
        {
            bytes = Bytes.alloc(0);
        }

        EmscriptenFetch.emscripten_fetch_close(Pointer.fromStar(fetchPtr));

        // Complete promise based on load type
        if (fetch.status >= 200 && fetch.status < 400)
        {
            switch (context.loadType)
            {
                case LoadType.BINARY:
                    cast(context.promise, Promise<Bytes>).complete(bytes);

                case LoadType.TEXT:
                    var text = bytes.getString(0, bytes.length, UTF8);
                    cast(context.promise, Promise<String>).complete(text);

                case LoadType.IMAGE:
                    // For images, we need to decode the bytes
                    var img = new Image();
                    img.__fromBytes(bytes, function(image)
                    {
                        cast(context.promise, Promise<Image>).complete(image);
                    });
            }
        }
        else
        {
            var errorResponse:_HTTPRequestErrorResponse<Any>;
            if(context.loadType == LoadType.BINARY) {
                errorResponse = new _HTTPRequestErrorResponse(fetch.status, bytes);
                cast(context.promise, Promise<Bytes>).error(errorResponse);
            }else {
                errorResponse = new _HTTPRequestErrorResponse(fetch.status, bytes.getString(0, bytes.length, UTF8));
                cast(context.promise, Promise<String>).error(errorResponse);
            }
        }
    }

    @:keep
    private static function onFetchProgress(fetchPtr:Star<EmscriptenFetchType>):Void
    {
        var fetch:EmscriptenFetchType = Pointer.fromStar(fetchPtr).value;
        var idPointer:Star<cpp.Int32> = cast fetch.userData;
        var id:Int = untyped __cpp__('*(int*){0}', idPointer);

        if (activeFetches.exists(id))
        {
            var context = activeFetches.get(id);
            if (fetch.totalBytes > 0)
            {
                if(context.loadType == LoadType.BINARY)
                    cast(context.promise, Promise<Bytes>).progress(fetch.dataOffset + fetch.numBytes, fetch.totalBytes);
                else if(context.loadType == LoadType.TEXT)
                    cast(context.promise, Promise<String>).progress(fetch.dataOffset + fetch.numBytes, fetch.totalBytes);
            }
        }
    }

    @:keep
    private static function onFetchError(fetchPtr:Star<EmscriptenFetchType>):Void
    {
        var fetch:EmscriptenFetchType = Pointer.fromStar(fetchPtr).value;
        var idPointer:Star<cpp.Int32> = cast fetch.userData;
        var id:Int = untyped __cpp__('*(int*){0}', idPointer);

        cpp.Native.free(idPointer);

        if (!activeFetches.exists(id))
        {
            EmscriptenFetch.emscripten_fetch_close(Pointer.fromStar(fetchPtr));
            return;
        }

        var context = activeFetches.get(id);
        activeFetches.remove(id);

        context.parent.responseStatus = fetch.status;

        EmscriptenFetch.emscripten_fetch_close(Pointer.fromStar(fetchPtr));

        var errorResponse = new _HTTPRequestErrorResponse(fetch.status, null);
        if(context.loadType == LoadType.BINARY)
            cast(context.promise, Promise<Bytes>).error(errorResponse);
        else
            cast(context.promise, Promise<String>).error(errorResponse);
    }
}

@:dox(hide)
enum LoadType
{
    BINARY;
    TEXT;
    IMAGE;
}

@:dox(hide)
typedef FetchContext =
{
    var id:Int;
    var promise:Dynamic;
    var parent:_IHTTPRequest;
    var loadType:LoadType;
    var binary:Bool;
    var fetchPtr:Pointer<EmscriptenFetchType>;
}
#end