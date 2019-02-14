package flash.net;

extern class URLRequestDefaults
{
	static var authenticate:Bool;
	static var cacheResponse:Bool;
	static var followRedirects:Bool;
	static var idleTimeout:Float;
	static var manageCookies:Bool;
	static var useCache:Bool;
	static var userAgent:String;
	static function setLoginCredentialsForHost(hostname:String, user:String, password:String):Dynamic;
}
