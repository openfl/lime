package lime.app;

/**
	Advanced frame pacing overrides that can be combined with a
	frame profile. Leaving a field out, or setting it to `Auto` or `Off`,
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
}
