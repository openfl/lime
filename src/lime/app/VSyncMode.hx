package lime.app;

enum abstract VSyncMode(String) from String to String
{
	var Off = "off";
	var On = "on";
	var Adaptive = "adaptive";
	var Auto = "auto";
}
