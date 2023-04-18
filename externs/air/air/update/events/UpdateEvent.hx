package air.update.events;

extern class UpdateEvent extends flash.events.Event
{
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false):Void;
	static var BEFORE_INSTALL(default, never):String;
	static var CHECK_FOR_UPDATE(default, never):String;
	static var DOWNLOAD_COMPLETE(default, never):String;
	static var DOWNLOAD_START(default, never):String;
	static var INITIALIZED(default, never):String;
}
