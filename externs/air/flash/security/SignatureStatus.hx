package flash.security;

@:native("flash.security.SignatureStatus")
@:enum extern abstract SignatureStatus(String)
{
	var INVALID;
	var UNKNOWN;
	var VALID;
}
