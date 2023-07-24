package flash.display;

@:native("flash.display.NativeWindowSystemChrome")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract NativeWindowSystemChrome(String)
{
	var ALTERNATE;
	var NONE;
	var STANDARD;
}
