package flash.events;

extern class SQLUpdateEvent extends Event
{
	var rowID(default, never):Float;
	var table(default, never):String;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, ?table:String, rowID:Float = 0.0):Void;
	static var DELETE(default, never):String;
	static var INSERT(default, never):String;
	static var UPDATE(default, never):String;
}
