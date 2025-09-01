package lime.net.oauth;

#if (haxe_ver >= 4.0) enum #else @:enum #end abstract OAuthVersion(String)
{
	var V1 = "1.0";
	var V2 = "2.0";
}
