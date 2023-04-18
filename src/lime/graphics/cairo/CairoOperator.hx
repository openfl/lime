package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
@:enum abstract CairoOperator(Int) from Int to Int from UInt to UInt
{
	public var CLEAR = 0;
	public var SOURCE = 1;
	public var OVER = 2;
	public var IN = 3;
	public var OUT = 4;
	public var ATOP = 5;
	public var DEST = 6;
	public var DEST_OVER = 7;
	public var DEST_IN = 8;
	public var DEST_OUT = 9;
	public var DEST_ATOP = 10;
	public var XOR = 11;
	public var ADD = 12;
	public var SATURATE = 13;
	public var MULTIPLY = 14;
	public var SCREEN = 15;
	public var OVERLAY = 16;
	public var DARKEN = 17;
	public var LIGHTEN = 18;
	public var COLOR_DODGE = 19;
	public var COLOR_BURN = 20;
	public var HARD_LIGHT = 21;
	public var SOFT_LIGHT = 22;
	public var DIFFERENCE = 23;
	public var EXCLUSION = 24;
	public var HSL_HUE = 25;
	public var HSL_SATURATION = 26;
	public var HSL_COLOR = 27;
	public var HSL_LUMINOSITY = 28;
}
#end
