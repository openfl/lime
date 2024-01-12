package lime.graphics;

/**
	An enum containing different pixel encoding formats for image data
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract PixelFormat(Int) from Int to Int from UInt to UInt
{
	/**
		An image encoded in 32-bit RGBA color order
	**/
	public var RGBA32 = 0;

	/**
		An image encoded in 32-bit ARGB color order
	**/
	public var ARGB32 = 1;

	/**
		An image encoded in 32-bit BGRA color order
	**/
	public var BGRA32 = 2;
}
