package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
@:enum abstract CairoFillRule(Int) from Int to Int from UInt to UInt
{
	public var WINDING = 0;
	public var EVEN_ODD = 1;
}
#end
