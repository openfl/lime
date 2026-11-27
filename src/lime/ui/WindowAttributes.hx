package lime.ui;

import lime.app.FrameOptions;
import lime.app.FrameProfile;
import lime.graphics.RenderContextAttributes;
import lime.system.DisplayMode;

typedef WindowAttributes =
{
	@:optional public var allowHighDPI:Bool;
	@:optional public var alwaysOnTop:Bool;
	/** Preferred native window appearance; omitted attributes retain platform defaults. **/
	@:optional public var appearance:WindowAppearance;
	@:optional public var borderless:Bool;
	@:optional public var context:RenderContextAttributes;
	/**
		The display to open the window on, as an index of `System.getDisplay()`. The window is centered
		on it unless `x` and `y` are given, and a fullscreen window fills it. A display that isn't
		connected opens the window on the primary display. Desktop native targets only.
	**/
	@:optional public var display:Int;

	/**
		The display mode for exclusive fullscreen, such as one of `display.supportedModes`. With
		`fullscreen`, the window opens in exclusive fullscreen at this mode. Without it, this is the
		mode the window uses when it goes fullscreen, as setting `Window.displayMode` does. Desktop
		native targets only.
	**/
	@:optional public var displayMode:DisplayMode;
	@:optional public var element:#if (js && html5 && !doc_gen) js.html.Element #else Dynamic #end;

	/**
		The desired frame rate in frames-per-second for this window.
		On native targets, the first window created will seed the
		shared application frame pacing value.
	**/
	@:optional public var frameRate:Float;

	/**
		Advanced frame pacing overrides for the application loop created
		alongside this window.
	**/
	@:optional public var frameOptions:FrameOptions;

	/**
		The frame pacing profile to use when this window is created.
		On native targets, the first window created will seed the
		shared application frame profile.
	**/
	@:optional public var frameProfile:FrameProfile;

	@:optional public var fullscreen:Bool;
	@:optional public var height:Int;
	@:optional public var hidden:Bool;
	@:optional public var maximized:Bool;
	@:optional public var minimized:Bool;
	@:optional public var parameters:Dynamic;
	@:optional public var resizable:Bool;
	@:optional public var transparent:Bool;
	@:optional public var title:String;
	@:optional public var width:Int;

	/**
		The position of the window's left edge on the desktop, which spans every display. Without
		it, the window is centered on its display.
	**/
	@:optional public var x:Int;

	/**
		The position of the window's top edge on the desktop, which spans every display. Without
		it, the window is centered on its display.
	**/
	@:optional public var y:Int;
}
