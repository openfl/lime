package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
@:enum abstract HBMemoryMode(Int) from Int to Int
{
	public var DUPLICATE = 0;
	public var READONLY = 1;
	public var WRITABLE = 2;
	public var READONLY_MAY_MAKE_WRITABLE = 3;
}
#end
