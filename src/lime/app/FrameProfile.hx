package lime.app;

/**
	Built-in frame pacing profiles for Lime applications.
**/
@:enum abstract FrameProfile(String) to String
{
	/** A balanced default profile that preserves Lime's existing pacing behavior. **/
	var Balanced = "balanced";

	/** A profile that favors tighter pacing and high-resolution timing. **/
	var Precision = "precision";

	/** A profile that favors lower CPU usage over the tightest pacing. **/
	var LowEnergy = "lowEnergy";

	/** A profile intended for explicit uncapped or benchmark-style rendering. **/
	var Uncapped = "uncapped";
}
