package flash.display;

extern class NativeWindowInitOptions
{
	var maximizable:Bool;
	var minimizable:Bool;
	var owner:NativeWindow;
	var renderMode:NativeWindowRenderMode;
	var resizable:Bool;
	var systemChrome:NativeWindowSystemChrome;
	var transparent:Bool;
	var type:NativeWindowType;
	function new():Void;
}
