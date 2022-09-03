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
#if doc_gen
class HTTPRequest<T>
{
#else
#if !macro
@:genericBuild(lime._internal.macros.HTTPRequestMacro.build())
#end
class HTTPRequest<T> extends AbstractHTTPRequest<T> {}

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
private class AbstractHTTPRequest<T> implements _IHTTPRequest
{
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
public var manageCookies:Bool;
#if !doc_gen
@:noCompletion private var __backend:HTTPRequestBackend;
#end

public function new(uri:String = null)
{
	this.uri = uri;

	contentType = "application/x-www-form-urlencoded";
	followRedirects = true;
	enableResponseHeaders = false;
	formData = new Map();
	headers = [];
	method = GET;
	timeout = #if lime_default_timeout Std.parseInt(Compiler.getDefine("lime-default-timeout")) #else 30000 #end;
	withCredentials = false;
	manageCookies = true;

	#if !doc_gen
	__backend = new HTTPRequestBackend();
	__backend.init(this);
	#end
}

public function cancel():Void
{
	#if !doc_gen
	__backend.cancel();
	#end
}

public function load(uri:String = null):Future<T>
{
	return null;
}
}
#if !doc_gen
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:noCompletion class _HTTPRequest_Bytes<T> extends AbstractHTTPRequest<T>
{
	public function new(uri:String = null)
	{
		super(uri);
	}

	@:noCompletion private function fromBytes(bytes:Bytes):T
	{
		return cast bytes;
	}

	public override function load(uri:String = null):Future<T>
	{
		if (uri != null)
		{
			this.uri = uri;
		}

		var promise = new Promise<T>();
		var future = __backend.loadData(this.uri);

		future.onProgress(promise.progress);
		future.onError(promise.error);

		future.onComplete(function(bytes)
		{
			responseData = fromBytes(bytes);
			promise.complete(responseData);
		});

		return promise.future;
	}
}

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:noCompletion class _HTTPRequest_String<T> extends AbstractHTTPRequest<T>
{
	public function new(uri:String = null)
	{
		super(uri);
	}

	public override function load(uri:String = null):Future<T>
	{
		if (uri != null)
		{
			this.uri = uri;
		}

		var promise = new Promise<T>();
		var future = __backend.loadText(this.uri);

		future.onProgress(promise.progress);
		future.onError(promise.error);

		future.onComplete(function(text)
		{
			responseData = cast text;
			promise.complete(responseData);
		});

		return promise.future;
	}
}

@:noCompletion interface _IHTTPRequest
{
	public var contentType:String;
	public var data:haxe.io.Bytes;
	public var enableResponseHeaders:Bool;
	public var followRedirects:Bool;
	public var formData:Map<String, Dynamic>;
	public var headers:Array<HTTPRequestHeader>;
	public var method:HTTPRequestMethod;
	// public var responseData:T;
	public var responseHeaders:Array<HTTPRequestHeader>;
	public var responseStatus:Int;
	public var timeout:Int;
	public var uri:String;
	public var userAgent:String;
	public var withCredentials:Bool;
	public var manageCookies:Bool;
	public function cancel():Void;
}

#if flash
private typedef HTTPRequestBackend = lime._internal.backend.flash.FlashHTTPRequest;
#elseif (js && html5)
private typedef HTTPRequestBackend = lime._internal.backend.html5.HTML5HTTPRequest;
#else
private typedef HTTPRequestBackend = lime._internal.backend.native.NativeHTTPRequest;
#end
#end
