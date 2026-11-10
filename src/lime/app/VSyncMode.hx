package lime.app;

/**
	Selects the requested vertical-sync behavior for rendering.

	Native targets only; see `FrameProfile`.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract VSyncMode(String) from String to String
{
	/** Disable vertical sync. **/
	var OFF = "off";

	/** Request standard vertical sync. **/
	var ON = "on";

	/** Request adaptive vertical sync when the platform supports it. **/
	var ADAPTIVE = "adaptive";

	/** Let Lime choose the best available sync behavior with fallbacks. **/
	var AUTO = "auto";
}
