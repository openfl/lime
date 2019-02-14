package flash.errors;

extern class PermissionError extends Error
{
	function new(message:String, id:Int):Void;
	function toString():String;
}
