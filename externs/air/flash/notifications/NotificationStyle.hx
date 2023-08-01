package flash.notifications;

@:native("flash.notifications.NotificationStyle")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract NotificationStyle(String)
{
	var ALERT;
	var BADGE;
	var SOUND;
}
