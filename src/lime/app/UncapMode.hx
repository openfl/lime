package lime.app;

/**
	Controls how aggressively Lime uncaps the frame loop.

	An uncapped loop ignores the frame rate cap. With vertical sync on,
	frames still wait for the display, so turn `Application.vsyncMode` off as
	well to render as fast as possible.

	Native targets only; see `FrameProfile`.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract UncapMode(String) to String
{
	/**
		Keep the frame rate cap, unless the frame profile is
		`FrameProfile.UNCAPPED`, which uncaps the loop as `SOFT` does.
	**/
	var OFF = "off";

	/**
		Ignore the frame rate cap, starting each frame as soon as the last one
		ends. Events are still handled the usual way between frames.
	**/
	var SOFT = "soft";

	/**
		Ignore the frame rate cap and also skip the usual event handling
		between frames, polling for events instead. This uses the most CPU.
	**/
	var HARD = "hard";
}
