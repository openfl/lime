package flash.sensors;

extern class DeviceRotation extends flash.events.EventDispatcher
{
	var muted(default, never):Bool;
	function new():Void;
	function setRequestedUpdateInterval(interval:Float):Void;
	static var isSupported(default, never):Bool;
}
