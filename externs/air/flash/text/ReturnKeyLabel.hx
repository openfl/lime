package flash.text;

@:native("flash.text.ReturnKeyLabel")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract ReturnKeyLabel(String)
{
	var DEFAULT = "default";
	var DONE = "done";
	var GO = "go";
	var NEXT = "next";
	var SEARCH = "search";
}
