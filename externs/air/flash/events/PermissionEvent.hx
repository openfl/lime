package flash.events;

@:final extern class PermissionEvent extends Event
{
	var status(default, never):String;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, ?status:String):Void;
	static var PERMISSION_STATUS(default, never):String;
}
