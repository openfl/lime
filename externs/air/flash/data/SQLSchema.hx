package flash.data;

extern class SQLSchema
{
	var database(default, never):String;
	var name(default, never):String;
	var sql(default, never):String;
	function new(database:String, name:String, sql:String):Void;
}
