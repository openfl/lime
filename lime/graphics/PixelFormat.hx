package lime.graphics;


@:enum abstract PixelFormat(Int) from Int to Int {
	
	public var RGBA = 0;
	public var ARGB = 1;
	public var BGRA = 2;
	
}