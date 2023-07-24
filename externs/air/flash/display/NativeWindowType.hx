package flash.display;

@:native("flash.display.NativeWindowType")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract NativeWindowType(String)
{
	var LIGHTWEIGHT;
	var NORMAL;
	var UTILITY;
}
