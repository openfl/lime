package lime.app;

/**
	Selects the requested vertical-sync behavior for rendering.
**/
enum abstract VSyncMode(String) from String to String
{
	/** Disable vertical sync. **/
	var Off = "off";

	/** Request standard vertical sync. **/
	var On = "on";

	/** Request adaptive vertical sync when the platform supports it. **/
	var Adaptive = "adaptive";

	/** Let Lime choose the best available sync behavior with fallbacks. **/
	var Auto = "auto";
}
