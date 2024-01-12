package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract HBBufferContentType(Int) from Int to Int
{
	public var INVALID = 0;
	public var UNICODE = 1;
	public var GLYPHS = 2;
}
#end
