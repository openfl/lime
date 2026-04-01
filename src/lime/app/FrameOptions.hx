package lime.app;

/**
	Advanced frame pacing overrides that can be combined with a
	frame profile.
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
