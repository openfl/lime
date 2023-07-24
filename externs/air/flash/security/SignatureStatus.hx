package flash.security;

@:native("flash.security.SignatureStatus")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract SignatureStatus(String)
{
	var INVALID;
	var UNKNOWN;
	var VALID;
}
