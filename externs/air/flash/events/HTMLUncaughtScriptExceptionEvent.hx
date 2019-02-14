package flash.events;

extern class HTMLUncaughtScriptExceptionEvent extends Event
{
	var exceptionValue:Dynamic;
	var stackTrace:Array<{sourceURL:String, line:Float, functionName:String}>;
	function new(exceptionValue:Dynamic):Void;
	static var UNCAUGHT_SCRIPT_EXCEPTION(default, never):String;
}
