package flash.desktop;

@:native("flash.desktop.InvokeEventReason")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract InvokeEventReason(String)
{
	var LOGIN = "login";
	var NOTIFICATION = "notification";
	var OPEN_URL = "openUrl";
	var STANDARD = "standard";
}
