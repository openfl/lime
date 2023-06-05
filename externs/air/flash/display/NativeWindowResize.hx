package flash.display;

@:native("flash.display.NativeWindowResize")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract NativeWindowResize(String)
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
