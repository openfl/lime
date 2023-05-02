package flash.security;

@:native("flash.security.SignatureStatus")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract SignatureStatus(String)
{
	var INVALID;
	var UNKNOWN;
	var VALID;
}
