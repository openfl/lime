package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract HBDirection(Int) from Int to Int
{
	public var INVALID = 0;
	public var LTR = 4;
	public var RTL = 5;
	public var TTB = 6;
	public var BTT = 7;
}
#end
