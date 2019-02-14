package flash.events;

extern class InvokeEvent extends Event
{
	var arguments(default, never):Array<String>;
	var currentDirectory(default, never):flash.filesystem.File;
	var reason(default, never):flash.desktop.InvokeEventReason;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, ?dir:flash.filesystem.File, ?argv:Array<Dynamic>,
		reason:flash.desktop.InvokeEventReason = flash.desktop.InvokeEventReason.STANDARD):Void;
	static var INVOKE(default, never):String;
}
