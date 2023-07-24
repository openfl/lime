package flash.text;

@:native("flash.text.SoftKeyboardType")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract SoftKeyboardType(String)
{
	var CONTACT;
	var DEFAULT;
	var EMAIL;
	var NUMBER;
	var PUNCTUATION;
	var URL;
}
