package flash.display;

@:native("flash.display.NativeWindowResize")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract NativeWindowResize(String)
{
	var BOTTOM;
	var BOTTOM_LEFT;
	var BOTTOM_RIGHT;
	var LEFT;
	var NONE;
	var RIGHT;
	var TOP;
	var TOP_LEFT;
	var TOP_RIGHT;
}
