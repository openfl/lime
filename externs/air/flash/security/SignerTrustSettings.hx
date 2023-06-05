package flash.security;

@:native("flash.security.SignerTrustSettings")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract SignerTrustSettings(String)
{
	var CODE_SIGNING;
	var PLAYLIST_SIGNING;
	var SIGNING;
}
