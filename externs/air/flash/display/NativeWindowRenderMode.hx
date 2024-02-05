package flash.display;

@:native("flash.display.NativeWindowRenderMode")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract NativeWindowRenderMode(String)
{
	var AUTO = "auto";
	var CPU = "cpu";
	var DIRECT = "direct";
	var GPU = "gpu";
}
