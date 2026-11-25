package lime.app;

/**
	Built-in frame pacing profiles for Lime applications.

	A profile chooses how the native main loop waits between frames: which
	timer it uses and whether it may busy-wait. The `timePrecision` and
	`busyWait` fields of `FrameOptions` override those choices, and its
	`uncapMode` overrides how the `UNCAPPED` profile uncaps the loop.

	The frame rate cap is `Window.frameRate`. Vertical sync, set with
	`Application.vsyncMode`, still holds each frame to the display when it
	is on, whatever the profile.

	Profiles only affect native targets. HTML5 frames follow
	`requestAnimationFrame`, and Flash frames follow the stage frame rate.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract FrameProfile(String) to String
{
	/** A balanced default profile that preserves Lime's existing pacing behavior. **/
	var BALANCED = "balanced";

	/** A profile that favors tighter pacing, using the high-resolution timer. **/
	var PRECISION = "precision";

	/** A profile that favors lower CPU usage over the tightest pacing, never busy-waiting. **/
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
