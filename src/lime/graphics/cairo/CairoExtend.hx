package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract CairoExtend(Int) from Int to Int from UInt to UInt
{
	public var NONE = 0;
	public var REPEAT = 1;
	public var REFLECT = 2;
	public var PAD = 3;
}
#end
