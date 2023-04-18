package flash.events;

extern class NativeWindowBoundsEvent extends Event
{
	var afterBounds(default, never):flash.geom.Rectangle;
	var beforeBounds(default, never):flash.geom.Rectangle;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, ?beforeBounds:flash.geom.Rectangle, ?afterBounds:flash.geom.Rectangle):Void;
	static var MOVE(default, never):String;
	static var MOVING(default, never):String;
	static var RESIZE(default, never):String;
	static var RESIZING(default, never):String;
}
