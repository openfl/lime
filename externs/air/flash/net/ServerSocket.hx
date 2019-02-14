package flash.net;

extern class ServerSocket extends flash.events.EventDispatcher
{
	var bound(default, never):Bool;
	var listening(default, never):Bool;
	var localAddress(default, never):String;
	var localPort(default, never):Int;
	function new():Void;
	function bind(localPort:Int = 0, localAddress:String = "0.0.0.0"):Void;
	function close():Void;
	function listen(backlog:Int = 0):Void;
	static var isSupported(default, never):Bool;
}
