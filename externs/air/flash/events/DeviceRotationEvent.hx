package flash.events;

extern class DeviceRotationEvent extends Event
{
	var pitch:Float;
	var quaternion:Array<Float>;
	var roll:Float;
	var timestamp:Float;
	var yaw:Float;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, timestamp:Float = 0, roll:Float = 0, pitch:Float = 0, yaw:Float = 0,
		?quaternion:Array<Dynamic>):Void;
	static var UPDATE(default, never):String;
}
