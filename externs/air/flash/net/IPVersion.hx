package flash.net;

@:native("flash.net.IPVersion")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract IPVersion(String)
{
	var IPV4;
	var IPV6;
}
