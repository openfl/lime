package lime.graphics;


@:enum abstract PixelFormat(Int) from Int to Int from UInt to UInt {
	
	public var RGBA32 = 0;
	public var ARGB32 = 1;
	public var BGRA32 = 2;
	
}