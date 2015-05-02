package lime.graphics.cairo;


@:enum abstract CairoLineJoin(Int) from Int to Int {
	
	public var MITER = 0;
	public var ROUND = 1;
	public var BEVEL = 2;
	
}