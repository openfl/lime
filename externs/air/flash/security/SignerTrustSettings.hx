package flash.security;

@:native("flash.security.SignerTrustSettings")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract SignerTrustSettings(String)
{
	var CODE_SIGNING = "codeSigning";
	var PLAYLIST_SIGNING = "playlistSigning";
	var SIGNING = "signing";
}
