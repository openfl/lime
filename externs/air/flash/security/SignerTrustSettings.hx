package flash.security;

@:native("flash.security.SignerTrustSettings")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract SignerTrustSettings(String)
{
	var CODE_SIGNING;
	var PLAYLIST_SIGNING;
	var SIGNING;
}
