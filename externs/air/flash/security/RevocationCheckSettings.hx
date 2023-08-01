package flash.security;

@:native("flash.security.RevocationCheckSettings")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract RevocationCheckSettings(String)
{
	var ALWAYS_REQUIRED;
	var BEST_EFFORT;
	var NEVER;
	var REQUIRED_IF_AVAILABLE;
}
