package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
@:enum abstract CairoLineCap(Int) from Int to Int from UInt to UInt
{
	public var BUTT = 0;
	public var ROUND = 1;
	public var SQUARE = 2;
}
#end
