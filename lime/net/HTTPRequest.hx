package lime.net;


import haxe.io.Bytes;
import haxe.macro.Compiler;
import lime.app.Event;
import lime.app.Future;
import lime.app.Promise;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


#if display

class HTTPRequest<T> {

#else

#if !macro
@:genericBuild(lime._macros.HTTPRequestMacro.build())
#end
class HTTPRequest<T> extends AbstractHTTPRequest<T> {}


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

private class AbstractHTTPRequest<T> implements _IHTTPRequest {
	
#end
	
	public var contentType:String;
	public var data:Bytes;
	public var enableResponseHeaders:Bool;
	public var followRedirects:Bool;
	public var formData:Map<String, Dynamic>;
	public var headers:Array<HTTPRequestHeader>;
	public var method:HTTPRequestMethod;
	public var responseData:T;
	public var responseHeaders:Array<HTTPRequestHeader>;
	public var responseStatus:Int;
	public var timeout:Int;
	public var uri:String;
	public var userAgent:String;
	public var withCredentials:Bool;
	
	#if !display
	private var backend:HTTPRequestBackend;
	#end
	
	
	public function new (uri:String = null) {
		
		this.uri = uri;
		
		contentType = "application/x-www-form-urlencoded";
		followRedirects = true;
		enableResponseHeaders = false;
		formData = new Map ();
		headers = [];
		method = GET;
		timeout = #if lime_default_timeout Std.parseInt (Compiler.getDefine ("lime-default-timeout")) #else 30000 #end;
		withCredentials = false;
		
		#if !display
		backend = new HTTPRequestBackend ();
		backend.init (this);
		#end
		
	}
	
	
	public function cancel ():Void {
		
		#if !display
		backend.cancel ();
		#end
		
	}
	
	
	public function load (uri:String = null):Future<T> {
		
		return null;
		
	}
	
	
}


#if !display


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

class _HTTPRequest_Bytes<T> extends AbstractHTTPRequest<T> {
	
	
	public function new (uri:String = null) {
		
		super (uri);
		
	}
	
	
	private function fromBytes (bytes:Bytes):T {
		
		return cast bytes;
		
	}
	
	
	public override function load (uri:String = null):Future<T> {
		
		if (uri != null) {
			
			this.uri = uri;
			
		}
		
		var promise = new Promise<T> ();
		var future = backend.loadData (this.uri);
		
		future.onProgress (promise.progress);
		future.onError (promise.error);
		
		future.onComplete (function (bytes) {
			
			responseData = fromBytes (bytes);
			promise.complete (responseData);
			
		});
		
		return promise.future;
		
	}
	
	
}


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

class _HTTPRequest_String<T> extends AbstractHTTPRequest<T> {
	
	
	public function new (uri:String = null) {
		
		super (uri);
		
	}
	
	
	public override function load (uri:String = null):Future<T> {
		
		if (uri != null) {
			
			this.uri = uri;
			
		}
		
		var promise = new Promise<T> ();
		var future = backend.loadText (this.uri);
		
		future.onProgress (promise.progress);
		future.onError (promise.error);
		
		future.onComplete (function (text) {
			
			responseData = cast text;
			promise.complete (responseData);
			
		});
		
		return promise.future;
		
	}
	
	
}


interface _IHTTPRequest {
	
	public var contentType:String;
	public var data:haxe.io.Bytes;
	public var enableResponseHeaders:Bool;
	public var followRedirects:Bool;
	public var formData:Map<String, Dynamic>;
	public var headers:Array<HTTPRequestHeader>;
	public var method:HTTPRequestMethod;
	//public var responseData:T;
	public var responseHeaders:Array<HTTPRequestHeader>;
	public var responseStatus:Int;
	public var timeout:Int;
	public var uri:String;
	public var userAgent:String;
	public var withCredentials:Bool;
	
	public function cancel ():Void;
	
}


#if flash
private typedef HTTPRequestBackend = lime._backend.flash.FlashHTTPRequest;
#elseif (js && html5)
private typedef HTTPRequestBackend = lime._backend.html5.HTML5HTTPRequest;
#else
private typedef HTTPRequestBackend = lime._backend.native.NativeHTTPRequest;
#end
#end
