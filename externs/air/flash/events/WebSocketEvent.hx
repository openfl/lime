package flash.events;

extern class WebSocketEvent extends Event
{
	var data(default, never):flash.utils.ByteArray;
	var format(default, never):UInt;
	var stringData(default, never):String;
	function new(type:String, format:UInt, data:flash.utils.ByteArray):Void;
	static var DATA(default, never):String;
}
