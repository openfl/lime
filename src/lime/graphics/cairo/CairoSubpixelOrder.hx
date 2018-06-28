package lime.graphics.cairo;


@:enum abstract CairoSubpixelOrder(Int) from Int to Int from UInt to UInt {
	
	public var DEFAULT = 0;
	public var RGB = 1;
	public var BGR = 2;
	public var VRGB = 3;
	public var VBGR = 4;
	
}