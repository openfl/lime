package flash.events;

@:final extern class RemoteNotificationEvent extends Event
{
	var data(default, never):Dynamic;
	var tokenId(default, never):String;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, ?data:Dynamic, ?tokenId:String):Void;
	static var NOTIFICATION(default, never):String;
	static var TOKEN(default, never):String;
}
