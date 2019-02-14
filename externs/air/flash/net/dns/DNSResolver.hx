package flash.net.dns;

extern class DNSResolver extends flash.events.EventDispatcher
{
	function new():Void;
	function lookup(host:String, recordType:Class<Dynamic>):Void;
	static var isSupported(default, never):Bool;
}
