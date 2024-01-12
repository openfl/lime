package flash.display3D;

@:native("flash.display3D.Context3DProfile")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract Context3DProfile(String)
{
	var BASELINE = "baseline";
	var BASELINE_CONSTRAINED = "baselineConstrained";
	var BASELINE_EXTENDED = "baselineExtended";
	var STANDARD = "standard";
	var STANDARD_CONSTRAINED = "standardConstrained";
	var STANDARD_EXTENDED = "standardExtended";
	#if air
	var ENHANCED = "enhanced";
	#end
}
