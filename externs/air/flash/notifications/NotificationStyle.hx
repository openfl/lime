package flash.notifications;

@:native("flash.notifications.NotificationStyle")
@:enum extern abstract NotificationStyle(String)
{
	var ALERT;
	var BADGE;
	var SOUND;
}
