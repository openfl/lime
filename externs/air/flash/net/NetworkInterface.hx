package flash.net;

extern class NetworkInterface
{
	var active:Bool;
	var addresses:flash.Vector<InterfaceAddress>;
	var displayName:String;
	var hardwareAddress:String;
	var mtu:Int;
	var name:String;
	var parent:NetworkInterface;
	var subInterfaces:flash.Vector<NetworkInterface>;
	function new():Void;
}
