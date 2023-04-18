package flash.notifications;

extern class RemoteNotifier extends flash.events.EventDispatcher
{
	function new():Void;
	function subscribe(?options:RemoteNotifierSubscribeOptions):Void;
	function unsubscribe():Void;
	static var supportedNotificationStyles(default, never):flash.Vector<NotificationStyle>;
}
