package lime.graphics.cairo;


@:enum abstract CairoExtend(Int) from Int to Int from UInt to UInt {
	
	public var NONE = 0;
	public var REPEAT = 1;
	public var REFLECT = 2;
	public var PAD = 3;
	
}