package lime.graphics.cairo;


import lime.IncludePaths;
import lime.graphics.cairo.Surface;


@:enum abstract Content(Int) {

	// must match cairo_content_t in cairo.h
	var Color         = 0x1000;
	var Alpha         = 0x2000;
	var ColorAndAlpha = 0x3000;

}


@:enum abstract Operator(Int) {

	// must match cairo_operator_t in cairo.h
	var Clear         = 0;
	var Source        = 1;
	var Over          = 2;
	var In            = 3;
	var Out           = 4;
	var Atop          = 5;
	var Dest          = 6;
	var DestOver      = 7;
	var DestIn        = 8;
	var DestOut       = 9;
	var DestAtop      = 10;
	var Xor           = 11;
	var Add           = 12;
	var Saturate      = 13;
	var Multiply      = 14;
	var Screen        = 15;
	var Overlay       = 16;
	var Darken        = 17;
	var Lighten       = 18;
	var ColorDodge    = 19;
	var ColorBurn     = 20;
	var HardLight     = 21;
	var SoftLight     = 22;
	var Difference    = 23;
	var Exclusion     = 24;
	var HSLHue        = 25;
	var HSLSaturation = 26;
	var HSLColor      = 27;
	var HSLLuminosity = 28;

}


@:enum abstract LineCap(Int) {

	// must match cairo_line_cap_t in cairo.h
	var Butt   = 0;
	var Round  = 1;
	var Square = 2;

}


@:enum abstract LineJoin(Int) {

	// must match cairo_line_join_t in cairo.h
	var Miter = 0;
	var Round = 1;
	var Bevel = 2;

}


@:include("graphics/cairo/CairoContext.h")
@:native("cpp::Struct<lime::CairoContext>")
extern class Context {

	@:native("lime::CairoContext::create")
	public static function create (surface:Surface):Context;

	public function destroy ():Void;

	public function clip ():Void;
	public function closePath ():Void;
	public function fill ():Void;
	public function fillPreserve ():Void;
	public function lineTo (x:Float, y:Float):Void;
	public function moveTo (x:Float, y:Float):Void;
	public function mask (pattern:Pattern):Void;
	public function newPath ():Void;
	public function paint ():Void;
	public function paintWithAlpha (alpha:Float):Void;
	public function pushGroup ():Void;
	public function pushGroupWithContent (content:Content):Void;
	public function popGroup ():Pattern;
	public function popGroupToSource ():Void;
	public function rectangle (x:Float, y:Float, w:Float, h:Float):Void;
	public function resetClip ():Void;
	public function restore ():Void;
	public function save ():Void;
	public function setLineCap (cap:LineCap):Void;
	public function setLineJoin (cap:LineJoin):Void;
	public function setLineWidth (width:Float):Void;
	public function setMatrix (xx:Float, yx:Float, xy:Float, yy:Float, x0:Float, y0:Float):Void;
	public function setMiterLimit (miterLimit:Float):Void;
	public function setOperator (op:Operator):Void;
	public function setSource (pattern:Pattern):Void;
	public function setSourceRGBA (r:Float, g:Float, b:Float, a:Float):Void;
	public function setSourceSurface (surface:Surface, x:Float, y:Float):Void;
	public function stroke ():Void;
	public function strokePreserve ():Void;
	public function transform (xx:Float, yx:Float, xy:Float, yy:Float, x0:Float, y0:Float):Void;
	
}

