package flash.display;

@:native("flash.display.NativeWindowDisplayState")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract NativeWindowDisplayState(String)
{
	var MAXIMIZED;
	var MINIMIZED;
	var NORMAL;
}
