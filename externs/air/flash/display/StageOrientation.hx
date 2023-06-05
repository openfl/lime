package flash.display;

@:native("flash.display.StageOrientation")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract StageOrientation(String)
{
	var DEFAULT;
	var ROTATED_LEFT;
	var ROTATED_RIGHT;
	var UNKNOWN;
	var UPSIDE_DOWN;
}
