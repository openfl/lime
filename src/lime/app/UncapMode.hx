package lime.app;

/**
	Controls how aggressively Lime uncaps the frame loop.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract UncapMode(String) to String
{
	/** Keep normal frame-rate limiting behavior enabled. **/
	var Off = "off";

	/** Relax frame throttling while preserving the normal event pump structure. **/
	var Soft = "soft";

	/** Remove frame throttling as aggressively as possible. **/
	var Hard = "hard";
}
