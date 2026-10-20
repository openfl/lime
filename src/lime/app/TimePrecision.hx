package lime.app;

/**
	Selects the timer precision used for frame pacing.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract TimePrecision(String) to String
{
	/** Use Lime's default precision for the active profile and platform. **/
	var Auto = "auto";

	/** Use millisecond precision timing. **/
	var Millisecond = "millisecond";

	/** Use higher precision timing when it is available. **/
	var HighResolution = "highResolution";
}
