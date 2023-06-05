package flash.notifications;

@:native("flash.notifications.NotificationStyle")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract NotificationStyle(String)
{
	var ALERT;
	var BADGE;
	var SOUND;
}
