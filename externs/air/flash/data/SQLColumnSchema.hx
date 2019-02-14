package flash.data;

extern class SQLColumnSchema
{
	var allowNull(default, never):Bool;
	var autoIncrement(default, never):Bool;
	var dataType(default, never):String;
	var defaultCollationType(default, never):SQLCollationType;
	var name(default, never):String;
	var primaryKey(default, never):Bool;
	function new(name:String, primaryKey:Bool, allowNull:Bool, autoIncrement:Bool, dataType:String, defaultCollationType:SQLCollationType):Void;
}
