package lime.net;

/**
	The version of the Internet Protocol an address belongs to.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract IPVersion(String) from String to String
{
	var IPV4 = "IPv4";
	var IPV6 = "IPv6";
}
