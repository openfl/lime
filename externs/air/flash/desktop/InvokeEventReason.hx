package flash.desktop;

@:native("flash.desktop.InvokeEventReason")
@:enum extern abstract InvokeEventReason(String)
{
	var LOGIN;
	var NOTIFICATION;
	var OPEN_URL;
	var STANDARD;
}
