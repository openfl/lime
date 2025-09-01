package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract CairoLineJoin(Int) from Int to Int from UInt to UInt
{
	public var MITER = 0;
	public var ROUND = 1;
	public var BEVEL = 2;
}
#end
