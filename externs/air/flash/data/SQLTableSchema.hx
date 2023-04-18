package flash.data;

extern class SQLTableSchema extends SQLSchema
{
	var columns(default, never):Array<SQLColumnSchema>;
	function new(database:String, name:String, sql:String, columns:Array<SQLColumnSchema>):Void;
}
