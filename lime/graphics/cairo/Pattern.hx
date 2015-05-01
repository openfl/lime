package lime.graphics.cairo;


import lime.IncludePaths;
import lime.graphics.cairo.Surface;


@:enum abstract Extend(Int) {

	// must match cairo_extend_t in cairo.h
	var None    = 0;
	var Repeat  = 1;
	var Reflect = 2;
	var Pad     = 3;

}


@:enum abstract Filter(Int) {

	// must match cairo_filter_t in cairo.h
	var Fast     = 0;
	var Good     = 1;
	var Best     = 2;
	var Nearest  = 3;
	var Bilinear = 4;
	var Gaussian = 5;

}


@:include("graphics/cairo/CairoPattern.h")
@:native("cpp::Struct<lime::CairoPattern>")
extern class Pattern {

	@:native("lime::CairoPattern::createForSurface")
	public static function createForSurface (surface:Surface):Pattern;

	public function destroy ():Void;

	public function setExtend (extend:Extend):Void;
	public function setFilter (filter:Filter):Void;
	public function setMatrix (xx:Float, yx:Float, xy:Float, yy:Float, x0:Float, y0:Float):Void;
	
}
