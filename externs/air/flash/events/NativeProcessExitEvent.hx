package flash.events;

extern class NativeProcessExitEvent extends Event
{
	var exitCode:Float;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, ?exitCode:Float):Void;
	static var EXIT(default, never):String;
}
