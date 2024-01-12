package lime.net.oauth;

#if (haxe_ver >= 4.0) enum #else @:enum #end abstract OAuthSignatureMethod(String)
{
	// var PLAINTEXT = "PLAINTEXT";
	var HMAC_SHA1 = "HMAC-SHA1";
	// var RSA_SHA1 = "RSA-SHA1";
}
