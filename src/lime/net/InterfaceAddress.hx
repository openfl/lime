package lime.net;

/**
	An address assigned to a network interface.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class InterfaceAddress
{
	/**
		The address, as `"192.168.1.20"` or `"fe80::1c2b:3a4d:5e6f:7a8b"`.
	**/
	public var address(default, null):String;

	/**
		The IPv4 broadcast address of the address's network, or `null` for IPv6
		addresses and networks without one.
	**/
	public var broadcast(default, null):String;

	/**
		Whether the address is an IPv4 or IPv6 address.
	**/
	public var ipVersion(default, null):IPVersion;

	/**
		The number of leading bits of the address that name its network, as 24
		for a `255.255.255.0` mask.
	**/
	public var prefixLength(default, null):Int;

	@:noCompletion private function new(address:String, broadcast:String, ipVersion:IPVersion, prefixLength:Int)
	{
		this.address = address;
		this.broadcast = broadcast;
		this.ipVersion = ipVersion;
		this.prefixLength = prefixLength;
	}
}
