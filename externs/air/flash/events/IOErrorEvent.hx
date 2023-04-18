package flash.events;

extern class IOErrorEvent extends ErrorEvent
{
	function new(type:String, bubbles:Bool = false, cancelable:Bool = false, ?text:String, id:Int = 0):Void;
	static var DISK_ERROR(default, never):String;
	static var IO_ERROR(default, never):String;
	static var NETWORK_ERROR(default, never):String;
	#if air
	static var STANDARD_ERROR_IO_ERROR(default, never):String;
	static var STANDARD_INPUT_IO_ERROR(default, never):String;
	static var STANDARD_OUTPUT_IO_ERROR(default, never):String;
	#end
	static var VERIFY_ERROR(default, never):String;
}
