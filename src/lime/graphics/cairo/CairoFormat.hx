package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract CairoFormat(Int) from Int to Int from UInt to UInt
{
	public var INVALID = -1;
	public var ARGB32 = 0;
	public var RGB24 = 1;
	public var A8 = 2;
	public var A1 = 3;
	public var RGB16_565 = 4;
	public var RGB30 = 5;
}
#end
