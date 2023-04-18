package flash.events;

extern class DNSResolverEvent extends Event
{
	var host:String;
	var resourceRecords:Array<Dynamic>;
	function new(type:String, bubbles:Bool = "false", cancelable:Bool = false, host:String = "", ?resourceRecords:Array<Dynamic>):Void;
	static var LOOKUP(default, never):String;
}
