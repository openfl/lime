package air.net;

extern class WebSocket extends flash.events.EventDispatcher
{
	var closeReason(default, never):Int;
	var protocol:String;
	function new():Void;
	function close(reasonCode:UInt = 1000):Void;
	function connect(url:String, ?protocols:flash.Vector<String>):Void;
	function sendMessage(opcode:UInt, data:Dynamic):Void;
	function startServer(s:flash.net.Socket):Void;
	static var fmtBINARY(default, never):UInt;
	static var fmtCLOSE(default, never):UInt;
	static var fmtPING(default, never):UInt;
	static var fmtPONG(default, never):UInt;
	static var fmtTEXT(default, never):UInt;
}
