package flash.errors;

extern class SQLError extends flash.errors.Error
{
	var detailArguments(default, never):Array<String>;
	var detailID(default, never):Int;
	var details(default, never):String;
	var operation(default, never):SQLErrorOperation;
	function new(operation:SQLErrorOperation, ?details:String = "", ?message:String = "", ?id:Int = 0, ?detailID:Int = -1, ?detailArgs:Array<Dynamic>):Void;
	function toString():String;
}
