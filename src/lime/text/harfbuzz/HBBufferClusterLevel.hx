package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
@:enum abstract HBBufferClusterLevel(Int) from Int to Int
{
	public var MONOTONE_GRAPHEMES = 0;
	public var MONOTONE_CHARACTERS = 1;
	public var CHARACTERS = 2;
	public var DEFAULT = 0;
}
#end
