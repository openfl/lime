package flash.text;

@:native("flash.text.AutoCapitalize")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract AutoCapitalize(String)
{
	var ALL;
	var NONE;
	var SENTENCE;
	var WORD;
}
