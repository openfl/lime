package lime.ui;

import haxe.Int64;

/**
	The system's own window behind a `Window`, as `Window.nativeHandle` gives it,
	for native code that works with the window directly.

	`type` says which windowing system it belongs to, which on Linux is only
	known once the application is running. Addresses are `Int64`s, as not all of
	them fit in a `Float`.

	The handle is borrowed: Lime owns the window, and nothing here should close
	it.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class WindowHandle
{
	/**
		The connection to the display, for the systems that have one, or `0`.
	**/
	public var display(default, null):Int64;

	/**
		The windowing system the window belongs to.
	**/
	public var type(default, null):WindowHandleType;

	/**
		The window, in the form `type` says.
	**/
	public var window(default, null):Int64;

	@:noCompletion private function new(type:WindowHandleType, window:Int64, display:Int64)
	{
		this.type = type;
		this.window = window;
		this.display = display;
	}
}
