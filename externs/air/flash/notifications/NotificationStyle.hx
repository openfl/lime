package flash.notifications;

@:native("flash.notifications.NotificationStyle")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract NotificationStyle(String)
{
	var ALERT = "alert";
	var BADGE = "badge";
	var SOUND = "sound";
}
