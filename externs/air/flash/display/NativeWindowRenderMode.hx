package flash.display;

@:native("flash.display.NativeWindowRenderMode")
@:enum extern abstract NativeWindowRenderMode(String)
{
	var AUTO;
	var CPU;
	var DIRECT;
	var GPU;
}
