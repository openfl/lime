package flash.net;

@:final extern class URLRequest
{
	#if air
	var authenticate:Bool;
	var cacheResponse:Bool;
	#end
	var contentType:String;
	var data:Dynamic;
	var digest:String;
	#if air
	var followRedirects:Bool;
	var idleTimeout:Float;
	var manageCookies:Bool;
	#end
	var method:String;
	var requestHeaders:Array<URLRequestHeader>;
	var url:String;
	#if air
	var useCache:Bool;
	var userAgent:String;
	#end
	function new(?url:String):Void;
	function useRedirectedURL(sourceRequest:URLRequest, wholeURL:Bool = false, ?pattern:Dynamic, ?replace:String):Void;
}
