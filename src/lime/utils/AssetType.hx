package lime.utils;

#if (haxe_ver >= 4.0) enum #else @:enum #end abstract AssetType(String) to String
{
	var BINARY = "BINARY";
	var FONT = "FONT";
	var IMAGE = "IMAGE";
	var MANIFEST = "MANIFEST";
	var MUSIC = "MUSIC";
	var SOUND = "SOUND";
	var TEMPLATE = "TEMPLATE";
	var TEXT = "TEXT";
}
