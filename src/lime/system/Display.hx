package lime.system;

import lime.math.Rectangle;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Display
{
	/**
	 * The desktop area represented by this display, with the upper-leftmost display at 0,0
	**/
	public var bounds(default, null):Rectangle;

	/**
	 * The current display mode
	**/
	public var currentMode(default, null):DisplayMode;

	public var id(default, null):Int;

	/**
	 * Pixel density of the display
	 */
	public var dpi(default, null):Float;

	/**
	 * The name of the device, such as "Samsung SyncMaster P2350", "iPhone 6", "Oculus Rift DK2", etc.
	**/
	public var name(default, null):String;

	/**
	 * All of the display modes supported by this device
	**/
	public var supportedModes(default, null):Array<DisplayMode>;

	@:noCompletion private function new() {}
}
