package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract CairoSubpixelOrder(Int) from Int to Int from UInt to UInt
{
	public var DEFAULT = 0;
	public var RGB = 1;
	public var BGR = 2;
	public var VRGB = 3;
	public var VBGR = 4;
}
#end
