package flash.events;

extern class ProgressEvent extends Event
{
	var bytesLoaded:Float;
	var bytesTotal:Float;
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, bytesLoaded:Float = 0, bytesTotal:Float = 0):Void;
	static var PROGRESS(default, never):String;
	static var SOCKET_DATA(default, never):String;
	#if air
	static var STANDARD_ERROR_DATA(default, never):String;
	static var STANDARD_INPUT_PROGRESS(default, never):String;
	static var STANDARD_OUTPUT_DATA(default, never):String;
	#end
}
