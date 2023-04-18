package flash.events;

extern class ServerSocketConnectEvent extends Event
{
	var socket:flash.net.Socket;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, ?socket:flash.net.Socket):Void;
	static var CONNECT(default, never):String;
}
