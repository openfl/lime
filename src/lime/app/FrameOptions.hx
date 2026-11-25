package lime.app;

/**
	Advanced frame pacing overrides that can be combined with a
	frame profile. Leaving a field out, or setting it to `AUTO` or `OFF`,
	keeps what the profile chooses.
**/
typedef FrameOptions =
{
	/** Select the timer precision used for frame pacing. **/
	@:optional var timePrecision:TimePrecision;

	/** Control whether Lime may busy-wait near frame deadlines. **/
	@:optional var busyWait:BusyWaitMode;

	/** Control how aggressively Lime uncaps the render loop. **/
	@:optional var uncapMode:UncapMode;

	/**
		The most frames a second on native desktop targets while every window
		is minimised or hidden, whatever the profile, 30 by default. Events
		still wake the application at once. A rate at or above the frame rate
		changes nothing, and `0` keeps the full rate in the background.
	**/
	@:optional var backgroundFrameRate:Float;
}
