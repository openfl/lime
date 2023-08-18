package flash.display;

@:native("flash.display.NativeWindowResize")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract NativeWindowResize(String)
{
	var BOTTOM = "bottom";
	var BOTTOM_LEFT = "bottomLeft";
	var BOTTOM_RIGHT = "bottomRight";
	var LEFT = "left";
	var NONE = "none";
	var RIGHT = "right";
	var TOP = "top";
	var TOP_LEFT = "topLeft";
	var TOP_RIGHT = "topRight";
}
