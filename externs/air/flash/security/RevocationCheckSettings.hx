package flash.security;

@:native("flash.security.RevocationCheckSettings")
@:enum extern abstract RevocationCheckSettings(String)
{
	var ALWAYS_REQUIRED;
	var BEST_EFFORT;
	var NEVER;
	var REQUIRED_IF_AVAILABLE;
}
