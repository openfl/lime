package flash.data;

@:native("flash.data.SQLColumnNameStyle")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract SQLColumnNameStyle(String)
{
	var DEFAULT;
	var LONG;
	var SHORT;
}
