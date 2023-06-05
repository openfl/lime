package flash.display;

@:native("flash.display.StageOrientation")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract StageOrientation(String)
{
	var DEFAULT;
	var ROTATED_LEFT;
	var ROTATED_RIGHT;
	var UNKNOWN;
	var UPSIDE_DOWN;
}
