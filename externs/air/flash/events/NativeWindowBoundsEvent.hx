package flash.events;

extern class NativeWindowBoundsEvent extends Event {
	var afterBounds(default,never) : flash.geom.Rectangle;
	var beforeBounds(default,never) : flash.geom.Rectangle;
	function new(type : String, bubbles : Bool=false, cancelable : Bool=false, ?beforeBounds : flash.geom.Rectangle, ?afterBounds : flash.geom.Rectangle) : Void;
	static var MOVE : String;
	static var MOVING : String;
	static var RESIZE : String;
	static var RESIZING : String;
}
