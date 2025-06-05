package lime.system;

#if (haxe_ver >= 4.0) enum #else @:enum #end abstract Orientation(Int)
{
	var UNKNOWN = 0;
	var LANDSCAPE = 1;
	var LANDSCAPE_FLIPPED = 2;
	var PORTRAIT = 3;
	var PORTRAIT_FLIPPED = 4;
}