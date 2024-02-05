package flash.text;

@:native("flash.text.SoftKeyboardType")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract SoftKeyboardType(String)
{
	var CONTACT = "contact";
	var DEFAULT = "default";
	var EMAIL = "email";
	var NUMBER = "number";
	var PUNCTUATION = "punctuation";
	var URL = "url";
}
