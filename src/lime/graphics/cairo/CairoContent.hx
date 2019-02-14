package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
@:enum abstract CairoContent(Int) from Int to Int from UInt to UInt
{
	public var COLOR = 0x1000;
	public var ALPHA = 0x2000;
	public var COLOR_ALPHA = 0x3000;
}
#end
