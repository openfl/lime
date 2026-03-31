package lime.app;

enum abstract FrameProfile(String) to String
{
	var Balanced = "balanced";
	var Precision = "precision";
	var LowEnergy = "lowEnergy";
	var Uncapped = "uncapped";
}
