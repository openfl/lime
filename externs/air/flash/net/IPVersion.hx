package flash.net;

@:native("flash.net.IPVersion")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract IPVersion(String)
{
	var IPV4 = "ipv4";
	var IPV6 = "ipv6";
}
