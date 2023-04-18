package flash.events;

extern class BrowserInvokeEvent extends Event
{
	var arguments(default, never):Array<Dynamic>;
	var isHTTPS(default, never):Bool;
	var isUserEvent(default, never):Bool;
	var sandboxType(default, never):String;
	var securityDomain(default, never):String;
	function new(type:String, bubbles:Bool, cancelable:Bool, arguments:Array<Dynamic>, sandboxType:String, securityDomain:String, isHTTPS:Bool,
		isUserEvent:Bool):Void;
	static var BROWSER_INVOKE(default, never):String;
}
