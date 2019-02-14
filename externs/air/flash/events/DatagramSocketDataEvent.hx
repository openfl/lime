package flash.events;

extern class DatagramSocketDataEvent extends Event
{
	var data:flash.utils.ByteArray;
	var dstAddress:String;
	var dstPort:Int;
	var srcAddress:String;
	var srcPort:Int;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, srcAddress:String = "", srcPort:Int = 0, dstAddress:String = "", dstPort:Int = 0,
		?data:flash.utils.ByteArray):Void;
	static var DATA(default, never):String;
}
