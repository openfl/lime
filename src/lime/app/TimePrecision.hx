package lime.app;

/**
	Selects the timer precision used for frame pacing.

	Native targets only; see `FrameProfile`.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract TimePrecision(String) to String
{
	/** Use Lime's default precision for the active profile and platform. **/
	var AUTO = "auto";

	/** Use millisecond precision timing. **/
	var MILLISECOND = "millisecond";

	/** Use higher precision timing when it is available. **/
	var HIGH_RESOLUTION = "highResolution";
}
