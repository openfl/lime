package lime.graphics.cairo;


@:enum abstract CairoLineJoin(Int) from Int to Int from UInt to UInt {
	
	public var MITER = 0;
	public var ROUND = 1;
	public var BEVEL = 2;
	
}