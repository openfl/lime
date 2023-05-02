package flash.display;

@:native("flash.display.NativeWindowRenderMode")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract NativeWindowRenderMode(String)
{
	var AUTO;
	var CPU;
	var DIRECT;
	var GPU;
}
