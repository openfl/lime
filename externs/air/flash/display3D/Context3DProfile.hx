package flash.display3D;

@:native("flash.display3D.Context3DProfile")
@:enum extern abstract Context3DProfile(String)
{
	var BASELINE;
	var BASELINE_CONSTRAINED;
	var BASELINE_EXTENDED;
	var STANDARD;
	var STANDARD_CONSTRAINED;
	var STANDARD_EXTENDED;
	#if air
	var ENHANCED;
	#end
}
