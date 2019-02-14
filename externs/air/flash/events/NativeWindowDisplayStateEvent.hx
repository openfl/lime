package flash.events;

extern class NativeWindowDisplayStateEvent extends Event
{
	var afterDisplayState(default, never):String;
	var beforeDisplayState(default, never):String;
	function new(type:String, bubbles:Bool = true, cancelable:Bool = false, beforeDisplayState:String = "", afterDisplayState:String = ""):Void;
	static var DISPLAY_STATE_CHANGE(default, never):String;
	static var DISPLAY_STATE_CHANGING(default, never):String;
}
