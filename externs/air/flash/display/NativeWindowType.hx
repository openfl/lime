package flash.display;

@:native("flash.display.NativeWindowType")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract NativeWindowType(String)
{
	var LIGHTWEIGHT = "lightweight";
	var NORMAL = "normal";
	var UTILITY = "utility";
}
