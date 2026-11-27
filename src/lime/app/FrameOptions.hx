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

	/**
		The frames a second while no frame has been asked for with
		`Application.requestFrame()`, for applications that draw only when
		something changes. `0`, the default, keeps frames coming at the frame
		rate, asked for or not.

		With an idle frame rate, the application sleeps between its idle frames.
		Events still wake it at once, and a frame that is asked for comes as soon
		as the frame rate allows. An application that animates asks for a frame
		from each update for as long as it does. A window that is shown,
		restored, resized or uncovered asks for one itself.

		What happens between frames is still heard of on time. A `haxe.Timer`
		fires when it is due, an HTTP request, a `WebSocket`, a `WebView` and the
		main thread's event loop deliver as they would with frames coming, and
		none of them brings a frame: a listener that changes what is drawn asks
		for one. What reports in an update brings its own frame: the work of a
		`lime.system.ThreadPool`, and so of a `lime.app.Future`, a file or an
		asset that was loaded, a `BackgroundWorker` and a `FileWatcher`.

		A rate at or above the frame rate changes nothing. Native targets and
		HTML5.
	**/
	@:optional var idleFrameRate:Float;
}
