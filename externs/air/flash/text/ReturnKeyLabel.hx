package flash.text;

@:native("flash.text.ReturnKeyLabel")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract ReturnKeyLabel(String)
{
	var DEFAULT;
	var DONE;
	var GO;
	var NEXT;
	var SEARCH;
}
