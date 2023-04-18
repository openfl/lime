package flash.events;

extern class NativeDragEvent extends MouseEvent
{
	var allowedActions:flash.desktop.NativeDragOptions;
	var clipboard:flash.desktop.Clipboard;
	var dropAction:String;
	function new(type:String, ?bubbles:Bool = false, ?cancelable:Bool = true, ?localX:Float, ?localY:Float, ?relatedObject:flash.display.InteractiveObject,
		?clipboard:flash.desktop.Clipboard, ?allowedActions:flash.desktop.NativeDragOptions, ?dropAction:String, controlKey:Bool = false, altKey:Bool = false,
		shiftKey:Bool = false, commandKey:Bool = false):Void;
	static var NATIVE_DRAG_COMPLETE(default, never):String;
	static var NATIVE_DRAG_DROP(default, never):String;
	static var NATIVE_DRAG_ENTER(default, never):String;
	static var NATIVE_DRAG_EXIT(default, never):String;
	static var NATIVE_DRAG_OVER(default, never):String;
	static var NATIVE_DRAG_START(default, never):String;
	static var NATIVE_DRAG_UPDATE(default, never):String;
}
