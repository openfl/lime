package flash.events;

extern class ScreenMouseEvent extends MouseEvent {
	var screenX(default,never) : Float;
	var screenY(default,never) : Float;
	function new(type : String, bubbles : Bool=false, cancelable : Bool=false, screenX : Float, screenY : Float, ctrlKey : Bool, altKey : Bool=false, shiftKey : Bool=false, buttonDown : Bool=false, commandKey : Bool=false, controlKey : Bool=false) : Void;
	static var CLICK : String;
	static var MOUSE_DOWN : String;
	static var MOUSE_UP : String;
	static var RIGHT_CLICK : String;
	static var RIGHT_MOUSE_DOWN : String;
	static var RIGHT_MOUSE_UP : String;
}
