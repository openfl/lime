package lime.system;

import lime.app.Event;
import lime.math.Rectangle;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Display
{
	/**
		Dispatched when a display is connected, with the display.

		Display IDs are their positions in the system's list of displays, so the
		IDs of other displays may change too. Read them again with
		`System.getDisplay()`.

		Dispatched on native desktop targets.
	**/
	public static var onConnect(default, null) = new Event<Display->Void>();

	/**
		Dispatched when a display is disconnected, with the ID it had.

		Display IDs are their positions in the system's list of displays, so the
		IDs of other displays may change too. Read them again with
		`System.getDisplay()`.

		Dispatched on native desktop targets.
	**/
	public static var onDisconnect(default, null) = new Event<Int->Void>();

	/**
		Dispatched with a display's ID when it moves, as the displays are arranged
		or the primary display changes. Its `bounds` are then out of date; read it
		again with `System.getDisplay()`.

		Dispatched on native desktop targets.
	**/
	public static var onMove(default, null) = new Event<Int->Void>();

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
	 * Orientation of the display
	 */
	public var orientation(default, null):Orientation;

	/**
	 * The name of the device, such as "Samsung SyncMaster P2350", "iPhone 6", "Oculus Rift DK2", etc.
	**/
	public var name(default, null):String;

	/**
	 * All of the display modes supported by this device
	**/
	public var supportedModes(default, null):Array<DisplayMode>;

	/**
		The area within the display's `bounds` where it is safe to render
		content without being obscured by notches, holes, or other display
		cutouts.
	**/
	public var safeArea(default, null):Rectangle;

	@:noCompletion private function new() {}
}
