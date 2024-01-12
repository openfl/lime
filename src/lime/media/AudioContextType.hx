package lime.media;

#if (haxe_ver >= 4.0) enum #else @:enum #end abstract AudioContextType(String) from String to String
{
	var FLASH = "flash";
	var HTML5 = "html5";
	var OPENAL = "openal";
	var WEB = "web";
	var CUSTOM = "custom";
}
