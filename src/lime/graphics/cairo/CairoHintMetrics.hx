package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
@:enum abstract CairoHintMetrics(Int) from Int to Int from UInt to UInt
{
	public var DEFAULT = 0;
	public var OFF = 1;
	public var ON = 2;
}
#end
