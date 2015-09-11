package lime.graphics.cairo;


@:enum abstract CairoHintStyle(Int) from Int to Int from UInt to UInt {
	
	public var DEFAULT = 0;
	public var NONE = 1;
	public var SLIGHT = 2;
	public var MEDIUM = 3;
	public var FULL = 4;
	
}