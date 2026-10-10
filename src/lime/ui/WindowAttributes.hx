package lime.ui;

import lime.app.FrameOptions;
import lime.app.FrameProfile;
import lime.graphics.RenderContextAttributes;

typedef WindowAttributes =
{
	@:optional public var allowHighDPI:Bool;
	@:optional public var alwaysOnTop:Bool;
	@:optional public var borderless:Bool;
	@:optional public var context:RenderContextAttributes;
	// @:optional public var display:Int;
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
	@:optional public var skipTaskbar:Bool;
	@:optional public var transparent:Bool;
	@:optional public var utility:Bool;
	@:optional public var popupMenu:Bool;
	@:optional public var tooltip:Bool;
	@:optional public var title:String;
	@:optional public var width:Int;
	@:optional public var x:Int;
	@:optional public var y:Int;
}
