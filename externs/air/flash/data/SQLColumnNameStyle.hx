package flash.data;

@:native("flash.data.SQLColumnNameStyle")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract SQLColumnNameStyle(String)
{
	var DEFAULT;
	var LONG;
	var SHORT;
}
