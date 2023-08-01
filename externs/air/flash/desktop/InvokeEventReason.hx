package flash.desktop;

@:native("flash.desktop.InvokeEventReason")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract InvokeEventReason(String)
{
	var LOGIN;
	var NOTIFICATION;
	var OPEN_URL;
	var STANDARD;
}
