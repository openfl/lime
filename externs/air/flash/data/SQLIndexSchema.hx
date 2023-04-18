package flash.data;

extern class SQLIndexSchema extends SQLSchema
{
	var table(default, never):String;
	function new(database:String, name:String, sql:String, table:String):Void;
}
