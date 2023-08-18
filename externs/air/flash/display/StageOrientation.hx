package flash.display;

@:native("flash.display.StageOrientation")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract StageOrientation(String)
{
	var DEFAULT = "default";
	var ROTATED_LEFT = "rotatedLeft";
	var ROTATED_RIGHT = "rotatedRight";
	var UNKNOWN = "unknown";
	var UPSIDE_DOWN = "upsideDown";
}
