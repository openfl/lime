package lime.app;

/**
	Controls whether Lime may busy-wait near frame deadlines.
**/
enum abstract BusyWaitMode(String) to String
{
	/** Use Lime's default busy-wait behavior for the active profile. **/
	var Auto = "auto";

	/** Disable busy-waiting and favor lower CPU usage. **/
	var Off = "off";

	/** Allow busy-waiting for tighter frame pacing. **/
	var On = "on";
}
