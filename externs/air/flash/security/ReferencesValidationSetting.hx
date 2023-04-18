package flash.security;

@:native("flash.security.ReferencesValidationSetting")
@:enum extern abstract ReferencesValidationSetting(String)
{
	var NEVER;
	var VALID_IDENTITY;
	var VALID_OR_UNKNOWN_IDENTITY;
}
