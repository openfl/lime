package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
@:enum abstract HBBufferSerializeFlags(Int) from Int to Int
{
	public var DEFAULT = 0x00000000;
	public var NO_CLUSTERS = 0x00000001;
	public var NO_POSITIONS = 0x00000002;
	public var NO_GLYPH_NAMES = 0x00000004;
}
#end
