package flash.display;

@:native("flash.display.NativeWindowSystemChrome")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract NativeWindowSystemChrome(String)
{
	var ALTERNATE = "alternate";
	var NONE = "none";
	var STANDARD = "standard";
}
