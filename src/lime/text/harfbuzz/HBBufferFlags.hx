package lime.text.harfbuzz;


@:enum abstract HBBufferFlags(Int) from Int to Int {
	
	public var DEFAULT = 0x00000000u;
	public var BOT = 0x00000001u;
	public var EOT = 0x00000002u;
	public var PRESERVE_DEFAULT_IGNORABLES = 0x00000004u;
	
}