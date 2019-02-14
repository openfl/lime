package flash.data;

extern class SQLSchemaResult
{
	var indices(default, never):Array<SQLIndexSchema>;
	var tables(default, never):Array<SQLTableSchema>;
	var triggers(default, never):Array<SQLTriggerSchema>;
	var views(default, never):Array<SQLViewSchema>;
	function new(tables:Array<SQLTableSchema>, views:Array<SQLViewSchema>, indices:Array<SQLIndexSchema>, triggers:Array<SQLTriggerSchema>):Void;
}
