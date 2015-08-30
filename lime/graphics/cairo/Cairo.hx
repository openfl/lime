package lime.graphics.cairo;


import lime.math.Matrix3;
import lime.math.Vector2;
import lime.system.System;


class Cairo {
	
	
	public static var version (get, null):Int;
	public static var versionString (get, null):String;
	
	public var antialias (get, set):CairoAntialias;
	public var currentPoint (get, never):Vector2;
	public var dash (get, set):Array<Float>;
	public var dashCount (get, never):Int;
	public var fillRule (get, set):CairoFillRule;
	public var fontFace (get, set):CairoFontFace;
	public var fontOptions (get, set):CairoFontOptions;
	public var groupTarget (get, never):CairoSurface;
	public var hasCurrentPoint (get, never):Bool;
	public var lineCap (get, set):CairoLineCap;
	public var lineJoin (get, set):CairoLineJoin;
	public var lineWidth (get, set):Float;
	public var matrix (get, set):Matrix3;
	public var miterLimit (get, set):Float;
	public var operator (get, set):CairoOperator;
	public var referenceCount (get, never):Int;
	public var source (get, set):CairoPattern;
	public var target (get, null):CairoSurface;
	public var tolerance (get, set):Float;
	public var userData:Dynamic;
	
	@:noCompletion private var handle:Dynamic;
	
	
	public function new (surface:CairoSurface = null):Void {
		
		if (surface != null) {
			
			#if lime_cairo
			handle = lime_cairo_create.call (surface);
			#end
			
		}
		
	}
	
	public function recreate (surface:CairoSurface) : Void {
		
		#if lime_cairo
		destroy ();
		handle = lime_cairo_create.call (surface);
		#end
	}
	
	
	public function arc (xc:Float, yc:Float, radius:Float, angle1:Float, angle2:Float):Void {
		
		#if lime_cairo
		lime_cairo_arc.call (handle, xc, yc, radius, angle1, angle2);
		#end
		
	}
	
	
	public function arcNegative (xc:Float, yc:Float, radius:Float, angle1:Float, angle2:Float):Void {
		
		#if lime_cairo
		lime_cairo_arc_negative.call (handle, xc, yc, radius, angle1, angle2);
		#end
		
	}
	
	
	public function clip ():Void {
		
		#if lime_cairo
		lime_cairo_clip.call (handle);
		#end
		
	}
	
	
	public function clipExtents (x1:Float, y1:Float, x2:Float, y2:Float):Void {
		
		#if lime_cairo
		lime_cairo_clip_extents.call (handle, x1, y1, x2, y2);
		#end
		
	}
	
	
	public function clipPreserve ():Void {
		
		#if lime_cairo
		lime_cairo_clip_preserve.call (handle);
		#end
		
	}
	
	
	public function closePath ():Void {
		
		#if lime_cairo
		lime_cairo_close_path.call (handle);
		#end
		
	}
	
	
	public function copyPage ():Void {
		
		#if lime_cairo
		lime_cairo_copy_page.call (handle);
		#end
		
	}
	
	
	public function curveTo (x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float):Void {
		
		#if lime_cairo
		lime_cairo_curve_to.call (handle, x1, y1, x2, y2, x3, y3);
		#end
		
	}
	
	
	public function destroy ():Void {
		
		#if lime_cairo
		lime_cairo_destroy.call (handle);
		#end
		
	}
	
	
	public function fill ():Void {
		
		#if lime_cairo
		lime_cairo_fill.call (handle);
		#end
		
	}
	
	
	public function fillExtents (x1:Float, y1:Float, x2:Float, y2:Float):Void {
		
		#if lime_cairo
		lime_cairo_fill_extents.call (handle, x1, y1, x2, y2);
		#end
		
	}
	
	
	public function fillPreserve ():Void {
		
		#if lime_cairo
		lime_cairo_fill_preserve.call (handle);
		#end
		
	}
	
	
	public function identityMatrix ():Void {
		
		#if lime_cairo
		lime_cairo_identity_matrix.call (handle);
		#end
		
	}
	
	
	public function inClip (x:Float, y:Float):Bool {
		
		#if lime_cairo
		return lime_cairo_in_clip.call (handle, x, y);
		#else
		return false;
		#end
		
	}
	
	
	public function inFill (x:Float, y:Float):Bool {
		
		#if lime_cairo
		return lime_cairo_in_fill.call (handle, x, y);
		#else
		return false;
		#end
		
	}
	
	
	public function inStroke (x:Float, y:Float):Bool {
		
		#if lime_cairo
		return lime_cairo_in_stroke.call (handle, x, y);
		#else
		return false;
		#end
		
	}
	
	
	public function lineTo (x:Float, y:Float):Void {
		
		#if lime_cairo
		lime_cairo_line_to.call (handle, x, y);
		#end
		
	}
	
	
	public function moveTo (x:Float, y:Float):Void {
		
		#if lime_cairo
		lime_cairo_move_to.call (handle, x, y);
		#end
		
	}
	
	
	public function mask (pattern:CairoPattern):Void {
		
		#if lime_cairo
		lime_cairo_mask.call (handle, pattern);
		#end
		
	}
	
	
	public function maskSurface (surface:CairoSurface, x:Float, y:Float):Void {
		
		#if lime_cairo
		lime_cairo_mask_surface.call (handle, surface, x, y);
		#end
		
	}
	
	
	public function newPath ():Void {
		
		#if lime_cairo
		lime_cairo_new_path.call (handle);
		#end
		
	}
	
	
	public function paint ():Void {
		
		#if lime_cairo
		lime_cairo_paint.call (handle);
		#end
		
	}
	
	
	public function paintWithAlpha (alpha:Float):Void {
		
		#if lime_cairo
		lime_cairo_paint_with_alpha.call (handle, alpha);
		#end
		
	}
	
	
	public function popGroup ():CairoPattern {
		
		#if lime_cairo
		return lime_cairo_pop_group.call (handle);
		#else
		return null;
		#end
		
	}
	
	
	public function popGroupToSource ():Void {
		
		#if lime_cairo
		lime_cairo_pop_group_to_source.call (handle);
		#end
		
	}
	
	
	public function pushGroup ():Void {
		
		#if lime_cairo
		lime_cairo_push_group.call (handle);
		#end
		
	}
	
	
	public function pushGroupWithContent (content:CairoContent):Void {
		
		#if lime_cairo
		lime_cairo_push_group_with_content.call (handle, content);
		#end
		
	}
	
	
	public function rectangle (x:Float, y:Float, width:Float, height:Float):Void {
		
		#if lime_cairo
		lime_cairo_rectangle.call (handle, x, y, width, height);
		#end
		
	}
	
	
	public function reference ():Void {
		
		#if lime_cairo
		lime_cairo_reference.call (handle);
		#end
		
	}
	
	
	public function relCurveTo (dx1:Float, dy1:Float, dx2:Float, dy2:Float, dx3:Float, dy3:Float):Void {
		
		#if lime_cairo
		lime_cairo_rel_curve_to.call (handle, dx1, dy1, dx2, dy2, dx3, dy3);
		#end
		
	}
	
	
	public function relLineTo (dx:Float, dy:Float):Void {
		
		#if lime_cairo
		lime_cairo_rel_line_to.call (handle, dx, dy);
		#end
		
	}
	
	
	public function relMoveTo (dx:Float, dy:Float):Void {
		
		#if lime_cairo
		lime_cairo_rel_move_to.call (handle, dx, dy);
		#end
		
	}
	
	
	public function resetClip ():Void {
		
		#if lime_cairo
		lime_cairo_reset_clip.call (handle);
		#end
		
	}
	
	
	public function restore ():Void {
		
		#if lime_cairo
		lime_cairo_restore.call (handle);
		#end
		
	}
	
	
	public function save ():Void {
		
		#if lime_cairo
		lime_cairo_save.call (handle);
		#end
		
	}
	
	
	public function setFontSize (size:Float):Void {
		
		#if lime_cairo
		lime_cairo_set_font_size.call (handle, size);
		#end
		
	}
	
	
	public function setSourceRGB (r:Float, g:Float, b:Float):Void {
		
		#if lime_cairo
		lime_cairo_set_source_rgb.call (handle, r, g, b);
		#end
		
	}
	
	
	public function setSourceRGBA (r:Float, g:Float, b:Float, a:Float):Void {
		
		#if lime_cairo
		lime_cairo_set_source_rgba.call (handle, r, g, b, a);
		#end
		
	}
	
	
	public function setSourceSurface (surface:CairoSurface, x:Float, y:Float):Void {
		
		#if lime_cairo
		lime_cairo_set_source_surface.call (handle, surface, x, y);
		#end
		
	}
	
	
	public function showPage ():Void {
		
		#if lime_cairo
		lime_cairo_show_page.call (handle);
		#end
		
	}
	
	
	public function showText (utf8:String):Void {
		
		#if lime_cairo
		lime_cairo_show_text.call (handle, utf8);
		#end
		
	}
	
	
	public function status ():CairoStatus {
		
		#if lime_cairo
		return lime_cairo_status.call (handle);
		#else
		return cast 0;
		#end
		
	}
	
	
	public function stroke ():Void {
		
		#if lime_cairo
		lime_cairo_stroke.call (handle);
		#end
		
	}
	
	
	public function strokeExtents (x1:Float, y1:Float, x2:Float, y2:Float):Void {
		
		#if lime_cairo
		lime_cairo_stroke_extents.call (handle, x1, y1, x2, y2);
		#end
		
	}
	
	
	public function strokePreserve ():Void {
		
		#if lime_cairo
		lime_cairo_stroke_preserve.call (handle);
		#end
		
	}
	
	
	public function transform (matrix:Matrix3):Void {
		
		#if lime_cairo
		lime_cairo_transform.call (handle, matrix);
		#end
		
	}
	
	public function rotate (amount:Float):Void {
		
		#if lime_cairo
		lime_cairo_rotate.call (handle, amount);
		#end
		
	}
	
	public function scale (x:Float, y:Float):Void {
		
		#if lime_cairo
		lime_cairo_scale.call (handle, x, y);
		#end
		
	}
	
	
	public function translate (x:Float, y:Float):Void {
		
		#if lime_cairo
		lime_cairo_translate.call (handle, x, y);
		#end
		
	}
	
	

	
	
	
	// Get & Set Methods
	
	
	
	
	@:noCompletion private function get_antialias ():CairoAntialias {
		
		#if lime_cairo
		return lime_cairo_get_antialias.call (handle);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_antialias (value:CairoAntialias):CairoAntialias {
		
		#if lime_cairo
		lime_cairo_set_antialias.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_currentPoint ():Vector2 {
		
		#if lime_cairo
		var vec = lime_cairo_get_current_point.call (handle);
		return new Vector2 (vec.x, vec.y);
		#end
		
		return null;
		
	}
	
	
	@:noCompletion private function get_dash ():Array<Float> {
		
		#if lime_cairo
		return lime_cairo_get_dash.call (handle);
		#end
		
		return [];
		
	}
	
	
	@:noCompletion private function set_dash (value:Array<Float>):Array<Float> {
		
		#if lime_cairo
		lime_cairo_set_dash.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_dashCount ():Int {
		
		#if lime_cairo
		return lime_cairo_get_dash_count.call (handle);
		#end
		
		return 0;
		
	}
	
	
	@:noCompletion private function get_fillRule ():CairoFillRule {
		
		#if lime_cairo
		return lime_cairo_get_fill_rule.call (handle);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_fillRule (value:CairoFillRule):CairoFillRule {
		
		#if lime_cairo
		lime_cairo_set_fill_rule.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_fontFace ():CairoFontFace {
		
		#if lime_cairo
		return lime_cairo_get_font_face.call (handle);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_fontFace (value:CairoFontFace):CairoFontFace {
		
		#if lime_cairo
		lime_cairo_set_font_face.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_fontOptions ():CairoFontOptions {
		
		#if lime_cairo
		return lime_cairo_get_font_options.call (handle);
		#else
		return null;
		#end
		
	}
	
	
	@:noCompletion private function set_fontOptions (value:CairoFontOptions):CairoFontOptions {
		
		#if lime_cairo
		lime_cairo_set_font_options.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_groupTarget ():CairoSurface {
		
		#if lime_cairo
		return lime_cairo_get_group_target.call (handle);
		#else
		return cast 0;
		#end
		
	}
	
	
	@:noCompletion private function get_hasCurrentPoint ():Bool {
		
		#if lime_cairo
		return lime_cairo_has_current_point.call (handle);
		#end
		
		return false;
		
	}
	
	
	@:noCompletion private function get_lineCap ():CairoLineCap {
		
		#if lime_cairo
		return lime_cairo_get_line_cap.call (handle);
		#end
		
		return 0;
		
	}
	
	
	@:noCompletion private function set_lineCap (value:CairoLineCap):CairoLineCap {
		
		#if lime_cairo
		lime_cairo_set_line_cap.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_lineJoin ():CairoLineJoin {
		
		#if lime_cairo
		return lime_cairo_get_line_join.call (handle);
		#end
		
		return 0;
		
	}
	
	
	@:noCompletion private function set_lineJoin (value:CairoLineJoin):CairoLineJoin {
		
		#if lime_cairo
		lime_cairo_set_line_join.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_lineWidth ():Float {
		
		#if lime_cairo
		return lime_cairo_get_line_width.call (handle);
		#end
		
		return 0;
		
	}
	
	
	@:noCompletion private function set_lineWidth (value:Float):Float {
		
		#if lime_cairo
		lime_cairo_set_line_width.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_matrix ():Matrix3 {
		
		#if lime_cairo
		var m = lime_cairo_get_matrix.call (handle);
		return new Matrix3 (m.a, m.b, m.c, m.d, m.tx, m.ty);
		#end
		
		return null;
		
	}
	
	
	@:noCompletion private function set_matrix (value:Matrix3):Matrix3 {
		
		#if lime_cairo
		lime_cairo_set_matrix.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_miterLimit ():Float {
		
		#if lime_cairo
		return lime_cairo_get_miter_limit.call (handle);
		#end
		
		return 0;
		
	}
	
	
	@:noCompletion private function set_miterLimit (value:Float):Float {
		
		#if lime_cairo
		lime_cairo_set_miter_limit.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_operator ():CairoOperator {
		
		#if lime_cairo
		return lime_cairo_get_operator.call (handle);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_operator (value:CairoOperator):CairoOperator {
		
		#if lime_cairo
		lime_cairo_set_operator.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_referenceCount ():Int {
		
		#if lime_cairo
		return lime_cairo_get_reference_count.call (handle);
		#else
		return 0;
		#end
		
	}
	
	
	@:noCompletion private function get_source ():CairoPattern {
		
		#if lime_cairo
		return lime_cairo_get_source.call (handle);
		#end
		
		return cast 0;
		
	}
	
	
	@:noCompletion private function set_source (value:CairoPattern):CairoPattern {
		
		#if lime_cairo
		lime_cairo_set_source.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	@:noCompletion private function get_target ():CairoSurface {
		
		#if lime_cairo
		return lime_cairo_get_target.call (handle);
		#else
		return cast 0;
		#end
		
	}
	
	
	@:noCompletion private function get_tolerance ():Float {
		
		#if lime_cairo
		return lime_cairo_get_tolerance.call (handle);
		#else
		return 0;
		#end
		
	}
	
	
	@:noCompletion private function set_tolerance (value:Float):Float {
		
		#if lime_cairo
		lime_cairo_set_tolerance.call (handle, value);
		#end
		
		return value;
		
	}
	
	
	private static function get_version ():Int {
		
		#if lime_cairo
		return lime_cairo_version.call ();
		#else
		return 0;
		#end
		
	}
	
	
	private static function get_versionString ():String {
		
		#if lime_cairo
		return lime_cairo_version_string.call ();
		#else
		return "";
		#end
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if lime_cairo
	private static var lime_cairo_arc = System.loadPrime ("lime", "lime_cairo_arc", "ddddddv");
	private static var lime_cairo_arc_negative = System.loadPrime ("lime", "lime_cairo_arc_negative", "ddddddv");
	private static var lime_cairo_clip = System.loadPrime ("lime", "lime_cairo_clip", "dv");
	private static var lime_cairo_clip_preserve = System.loadPrime ("lime", "lime_cairo_clip_preserve", "dv");
	private static var lime_cairo_clip_extents = System.loadPrime ("lime", "lime_cairo_clip_extents", "dddddv");
	private static var lime_cairo_close_path = System.loadPrime ("lime", "lime_cairo_close_path", "dv");
	private static var lime_cairo_copy_page = System.loadPrime ("lime", "lime_cairo_copy_page", "dv");
	private static var lime_cairo_create = System.loadPrime ("lime", "lime_cairo_create", "dd");
	private static var lime_cairo_curve_to = System.loadPrime ("lime", "lime_cairo_curve_to", "dddddddv");
	private static var lime_cairo_destroy = System.loadPrime ("lime", "lime_cairo_destroy", "dv");
	private static var lime_cairo_fill = System.loadPrime ("lime", "lime_cairo_fill", "dv");
	private static var lime_cairo_fill_extents = System.loadPrime ("lime", "lime_cairo_fill_extents", "dddddv");
	private static var lime_cairo_fill_preserve = System.loadPrime ("lime", "lime_cairo_fill_preserve", "dv");
	private static var lime_cairo_get_antialias = System.loadPrime ("lime", "lime_cairo_get_antialias", "di");
	private static var lime_cairo_get_current_point = System.loadPrime ("lime", "lime_cairo_get_current_point", "do");
	private static var lime_cairo_get_dash = System.loadPrime ("lime", "lime_cairo_get_dash", "do");
	private static var lime_cairo_get_dash_count = System.loadPrime ("lime", "lime_cairo_get_dash_count", "di");
	private static var lime_cairo_get_fill_rule = System.loadPrime ("lime", "lime_cairo_get_fill_rule", "di");
	private static var lime_cairo_get_font_face = System.loadPrime ("lime", "lime_cairo_get_font_face", "dd");
	private static var lime_cairo_get_font_options = System.loadPrime ("lime", "lime_cairo_get_font_options", "dd");
	private static var lime_cairo_get_group_target = System.loadPrime ("lime", "lime_cairo_get_group_target", "dd");
	private static var lime_cairo_get_line_cap = System.loadPrime ("lime", "lime_cairo_get_line_cap", "di");
	private static var lime_cairo_get_line_join = System.loadPrime ("lime", "lime_cairo_get_line_join", "di");
	private static var lime_cairo_get_line_width = System.loadPrime ("lime", "lime_cairo_get_line_width", "dd");
	private static var lime_cairo_get_matrix = System.loadPrime ("lime", "lime_cairo_get_matrix", "do");
	private static var lime_cairo_get_miter_limit = System.loadPrime ("lime", "lime_cairo_get_miter_limit", "dd");
	private static var lime_cairo_get_operator = System.loadPrime ("lime", "lime_cairo_get_operator", "di");
	private static var lime_cairo_get_reference_count = System.loadPrime ("lime", "lime_cairo_get_reference_count", "di");
	private static var lime_cairo_get_source = System.loadPrime ("lime", "lime_cairo_get_source", "dd");
	private static var lime_cairo_get_target = System.loadPrime ("lime", "lime_cairo_get_target", "dd");
	private static var lime_cairo_get_tolerance = System.loadPrime ("lime", "lime_cairo_get_tolerance", "dd");
	private static var lime_cairo_has_current_point = System.loadPrime ("lime", "lime_cairo_has_current_point", "db");
	private static var lime_cairo_identity_matrix = System.loadPrime ("lime", "lime_cairo_identity_matrix", "dv");
	private static var lime_cairo_in_clip = System.loadPrime ("lime", "lime_cairo_in_clip", "dddb");
	private static var lime_cairo_in_fill = System.loadPrime ("lime", "lime_cairo_in_fill", "dddb");
	private static var lime_cairo_in_stroke = System.loadPrime ("lime", "lime_cairo_in_stroke", "dddb");
	private static var lime_cairo_line_to = System.loadPrime ("lime", "lime_cairo_line_to", "dddv");
	private static var lime_cairo_mask = System.loadPrime ("lime", "lime_cairo_mask", "ddv");
	private static var lime_cairo_mask_surface = System.loadPrime ("lime", "lime_cairo_mask_surface", "ddddv");
	private static var lime_cairo_move_to = System.loadPrime ("lime", "lime_cairo_move_to", "dddv");
	private static var lime_cairo_new_path = System.loadPrime ("lime", "lime_cairo_new_path", "dv");
	private static var lime_cairo_paint = System.loadPrime ("lime", "lime_cairo_paint", "dv");
	private static var lime_cairo_paint_with_alpha = System.loadPrime ("lime", "lime_cairo_paint_with_alpha", "ddv");
	private static var lime_cairo_pop_group = System.loadPrime ("lime", "lime_cairo_pop_group", "dd");
	private static var lime_cairo_pop_group_to_source = System.loadPrime ("lime", "lime_cairo_pop_group_to_source", "dv");
	private static var lime_cairo_push_group = System.loadPrime ("lime", "lime_cairo_push_group", "dv");
	private static var lime_cairo_push_group_with_content = System.loadPrime ("lime", "lime_cairo_push_group_with_content", "div");
	private static var lime_cairo_rectangle = System.loadPrime ("lime", "lime_cairo_rectangle", "dddddv");
	private static var lime_cairo_reference = System.loadPrime ("lime", "lime_cairo_reference", "dv");
	private static var lime_cairo_rel_curve_to = System.loadPrime ("lime", "lime_cairo_rel_curve_to", "dddddddv");
	private static var lime_cairo_rel_line_to = System.loadPrime ("lime", "lime_cairo_rel_line_to", "dddv");
	private static var lime_cairo_rel_move_to = System.loadPrime ("lime", "lime_cairo_rel_move_to", "dddv");
	private static var lime_cairo_reset_clip = System.loadPrime ("lime", "lime_cairo_reset_clip", "dv");
	private static var lime_cairo_restore = System.loadPrime ("lime", "lime_cairo_restore", "dv");
	private static var lime_cairo_rotate = System.loadPrime ("lime", "lime_cairo_rotate", "ddv");
	private static var lime_cairo_save = System.loadPrime ("lime", "lime_cairo_save", "dv");
	private static var lime_cairo_scale = System.loadPrime ("lime", "lime_cairo_scale", "dddv");
	private static var lime_cairo_set_antialias = System.loadPrime ("lime", "lime_cairo_set_antialias", "div");
	private static var lime_cairo_set_dash = System.loadPrime ("lime", "lime_cairo_set_dash", "dov");
	private static var lime_cairo_set_font_face = System.loadPrime ("lime", "lime_cairo_set_font_face", "ddv");
	private static var lime_cairo_set_font_size = System.loadPrime ("lime", "lime_cairo_set_font_size", "ddv");
	private static var lime_cairo_set_fill_rule = System.loadPrime ("lime", "lime_cairo_set_fill_rule", "div");
	private static var lime_cairo_set_font_options = System.loadPrime ("lime", "lime_cairo_set_font_options", "ddv");
	private static var lime_cairo_set_line_cap = System.loadPrime ("lime", "lime_cairo_set_line_cap", "div");
	private static var lime_cairo_set_line_join = System.loadPrime ("lime", "lime_cairo_set_line_join", "div");
	private static var lime_cairo_set_line_width = System.loadPrime ("lime", "lime_cairo_set_line_width", "ddv");
	private static var lime_cairo_set_matrix = System.loadPrime ("lime", "lime_cairo_set_matrix", "dov");
	private static var lime_cairo_set_miter_limit = System.loadPrime ("lime", "lime_cairo_set_miter_limit", "ddv");
	private static var lime_cairo_set_operator = System.loadPrime ("lime", "lime_cairo_set_operator", "div");
	private static var lime_cairo_set_source = System.loadPrime ("lime", "lime_cairo_set_source", "ddv");
	private static var lime_cairo_set_source_rgb = System.loadPrime ("lime", "lime_cairo_set_source_rgb", "ddddv");
	private static var lime_cairo_set_source_rgba = System.loadPrime ("lime", "lime_cairo_set_source_rgba", "dddddv");
	private static var lime_cairo_set_source_surface = System.loadPrime ("lime", "lime_cairo_set_source_surface", "ddddv");
	private static var lime_cairo_set_tolerance = System.loadPrime ("lime", "lime_cairo_set_tolerance", "ddv");
	private static var lime_cairo_show_page = System.loadPrime ("lime", "lime_cairo_show_page", "dv");
	private static var lime_cairo_show_text = System.loadPrime ("lime", "lime_cairo_show_text", "dsv");
	private static var lime_cairo_status = System.loadPrime ("lime", "lime_cairo_status", "di");
	private static var lime_cairo_stroke = System.loadPrime ("lime", "lime_cairo_stroke", "dv");
	private static var lime_cairo_stroke_extents = System.loadPrime ("lime", "lime_cairo_stroke_extents", "dddddv");
	private static var lime_cairo_stroke_preserve = System.loadPrime ("lime", "lime_cairo_stroke_preserve", "dv");
	private static var lime_cairo_transform = System.loadPrime ("lime", "lime_cairo_transform", "dov");
	private static var lime_cairo_translate = System.loadPrime ("lime", "lime_cairo_translate", "dddv");
	private static var lime_cairo_version = System.loadPrime ("lime", "lime_cairo_version", "i");
	private static var lime_cairo_version_string = System.loadPrime ("lime", "lime_cairo_version_string", "s");
	#end
	
	
}