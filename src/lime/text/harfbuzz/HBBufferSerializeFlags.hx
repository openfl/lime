package lime.text.harfbuzz;


@:enum abstract HBBufferSerializeFlags(Int) from Int to Int {
	
	public var DEFAULT = 0x00000000u;
	public var NO_CLUSTERS = 0x00000001u;
	public var NO_POSITIONS = 0x00000002u;
	public var NO_GLYPH_NAMES = 0x00000004u;
	
}