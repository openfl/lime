package lime.app;

/**
	Selects the timer precision used for frame pacing.

	Native targets only; see `FrameProfile`.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract TimePrecision(String) to String
{
	/** Use Lime's default precision, which is high resolution in every profile. **/
	var AUTO = "auto";

	/** Time frames in whole milliseconds, so each starts on one, up to a millisecond after it is due. **/
	var MILLISECOND = "millisecond";

	/** Use higher precision timing when it is available. **/
	var HIGH_RESOLUTION = "highResolution";
}
