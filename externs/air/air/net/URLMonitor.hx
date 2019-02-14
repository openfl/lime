package air.net;

extern class URLMonitor extends ServiceMonitor
{
	var acceptableStatusCodes:Array<Dynamic>;
	var urlRequest(default, never):flash.net.URLRequest;
	function new(urlRequest:flash.net.URLRequest, ?acceptableStatusCodes:Array<Dynamic>):Void;
}
