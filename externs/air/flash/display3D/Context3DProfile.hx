package flash.display3D;

@:native("flash.display3D.Context3DProfile")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract Context3DProfile(String)
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
