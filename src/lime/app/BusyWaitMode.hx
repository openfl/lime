package lime.app;

/**
	Controls whether Lime may busy-wait near frame deadlines.

	Native targets only; see `FrameProfile`.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract BusyWaitMode(String) to String
{
	/** Use Lime's default busy-wait behavior for the active profile. **/
	var AUTO = "auto";

	/** Disable busy-waiting and favor lower CPU usage. **/
	var OFF = "off";

	/** Allow busy-waiting for tighter frame pacing. **/
	var ON = "on";
}
