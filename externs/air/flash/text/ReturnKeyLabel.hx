package flash.text;

@:native("flash.text.ReturnKeyLabel")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract ReturnKeyLabel(String)
{
	var DEFAULT;
	var DONE;
	var GO;
	var NEXT;
	var SEARCH;
}
