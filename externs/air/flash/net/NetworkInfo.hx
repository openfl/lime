package flash.net;

extern class NetworkInfo extends flash.events.EventDispatcher
{
	function new():Void;
	function findInterfaces():flash.Vector<NetworkInterface>;
	static var isSupported(default, never):Bool;
	static var networkInfo(default, never):NetworkInfo;
}
