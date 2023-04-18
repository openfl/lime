package flash.data;

extern class SQLResult
{
	var complete(default, never):Bool;
	var data(default, never):Array<Dynamic>;
	var lastInsertRowID(default, never):Float;
	var rowsAffected(default, never):Float;
	function new(?data:Array<Dynamic>, ?rowsAffected:Float = 0.0, ?complete:Bool = true, ?rowID:Float = 0.0):Void;
}
