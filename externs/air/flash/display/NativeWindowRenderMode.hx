package flash.display;

@:native("flash.display.NativeWindowRenderMode")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract NativeWindowRenderMode(String)
{
	var AUTO;
	var CPU;
	var DIRECT;
	var GPU;
}
