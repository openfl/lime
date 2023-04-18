package air.net;

extern class SocketMonitor extends ServiceMonitor
{
	var host(default, never):String;
	var port(default, never):Int;
	function new(host:String, port:Int):Void;
	private function createSocket():flash.net.Socket;
}
