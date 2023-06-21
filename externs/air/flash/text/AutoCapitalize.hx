package flash.text;

@:native("flash.text.AutoCapitalize")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract AutoCapitalize(String)
{
	var ALL;
	var NONE;
	var SENTENCE;
	var WORD;
}
