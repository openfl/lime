package flash.security;

@:native("flash.security.SignerTrustSettings")
@:enum extern abstract SignerTrustSettings(String)
{
	var CODE_SIGNING;
	var PLAYLIST_SIGNING;
	var SIGNING;
}
