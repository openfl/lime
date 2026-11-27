package lime.app;

/**
	Built-in frame pacing profiles for Lime applications.

	A profile chooses how the native main loop waits between frames: whether
	it may busy-wait and, on Windows, how often input may wake it. The
	`timePrecision` and `busyWait` fields of `FrameOptions` override its timer
	and its busy-waiting, and its `uncapMode` overrides how the `UNCAPPED`
	profile uncaps the loop.

	In every profile, the events that reached the application before a frame
	are handled before it.

	The frame rate cap is `Window.frameRate`. Vertical sync, set with
	`Application.vsyncMode`, still holds each frame to the display when it
	is on, whatever the profile.

	Profiles only affect native targets. HTML5 frames follow
	`requestAnimationFrame`, and Flash frames follow the stage frame rate.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract FrameProfile(String) to String
{
	/**
		The default profile. The application sleeps until each frame is due. On
		Windows, input that comes while it does wakes it at most once every 2
		milliseconds.
	**/
	var BALANCED = "balanced";

	/**
		A profile that favors the tightest pacing. It busy-waits for the last
		millisecond before each frame, and input wakes it as it comes.
	**/
	var PRECISION = "precision";

	/**
		A profile that favors lower CPU usage over the tightest pacing. It never
		busy-waits, and on Windows input wakes it at most once every 8 milliseconds.
	**/
	var LOW_ENERGY = "lowEnergy";

	/**
		A profile for uncapped or benchmark-style rendering. It ignores the
		frame rate cap and starts each frame as soon as the last one ends, as
		`UncapMode.SOFT` does, unless `FrameOptions.uncapMode` asks for
		`UncapMode.HARD`. With vertical sync on, frames still wait for the
		display.
	**/
	var UNCAPPED = "uncapped";
}
