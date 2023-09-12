package flash.data;

@:native("flash.data.SQLCollationType")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract SQLCollationType(String)
{
	var BINARY = "binary";
	var NO_CASE = "noCase";
}
