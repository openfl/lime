package lime.graphics.cairo;


import lime.math.Matrix3;
import lime.math.Vector2;
import lime.system.CFFI;


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
		var vec:Dynamic = lime_cairo_get_current_point.call (handle);
		return new Vector2 (vec.x, vec.y);
		#end
		
		return null;
		
	}
	
	
	@:noCompletion private function get_dash ():Array<Float> {
		
		#if lime_cairo
		var result:Dynamic = lime_cairo_get_dash.call (handle);
		return result;
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
		var m:Dynamic = lime_cairo_get_matrix.call (handle);
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
	private static var lime_cairo_arc = new CFFI<Float->Float->Float->Float->Float->Float->Void> ("lime", "lime_cairo_arc");
	private static var lime_cairo_arc_negative = new CFFI<Float->Float->Float->Float->Float->Float->Void> ("lime", "lime_cairo_arc_negative");
	private static var lime_cairo_clip = new CFFI<Float->Void> ("lime", "lime_cairo_clip");
	private static var lime_cairo_clip_preserve = new CFFI<Float->Void> ("lime", "lime_cairo_clip_preserve");
	private static var lime_cairo_clip_extents = new CFFI<Float->Float->Float->Float->Float->Void> ("lime", "lime_cairo_clip_extents");
	private static var lime_cairo_close_path = new CFFI<Float->Void> ("lime", "lime_cairo_close_path");
	private static var lime_cairo_copy_page = new CFFI<Float->Void> ("lime", "lime_cairo_copy_page");
	private static var lime_cairo_create = new CFFI<Float->Float> ("lime", "lime_cairo_create");
	private static var lime_cairo_curve_to = new CFFI<Float->Float->Float->Float->Float->Float->Float->Void> ("lime", "lime_cairo_curve_to");
	private static var lime_cairo_destroy = new CFFI<Float->Void> ("lime", "lime_cairo_destroy");
	private static var lime_cairo_fill = new CFFI<Float->Void> ("lime", "lime_cairo_fill");
	private static var lime_cairo_fill_extents = new CFFI<Float->Float->Float->Float->Float->Void> ("lime", "lime_cairo_fill_extents");
	private static var lime_cairo_fill_preserve = new CFFI<Float->Void> ("lime", "lime_cairo_fill_preserve");
	private static var lime_cairo_get_antialias = new CFFI<Float->Int> ("lime", "lime_cairo_get_antialias");
	private static var lime_cairo_get_current_point = new CFFI<Float->Dynamic> ("lime", "lime_cairo_get_current_point");
	private static var lime_cairo_get_dash = new CFFI<Float->Dynamic> ("lime", "lime_cairo_get_dash");
	private static var lime_cairo_get_dash_count = new CFFI<Float->Int> ("lime", "lime_cairo_get_dash_count");
	private static var lime_cairo_get_fill_rule = new CFFI<Float->Int> ("lime", "lime_cairo_get_fill_rule");
	private static var lime_cairo_get_font_face = new CFFI<Float->Float> ("lime", "lime_cairo_get_font_face");
	private static var lime_cairo_get_font_options = new CFFI<Float->Float> ("lime", "lime_cairo_get_font_options");
	private static var lime_cairo_get_group_target = new CFFI<Float->Float> ("lime", "lime_cairo_get_group_target");
	private static var lime_cairo_get_line_cap = new CFFI<Float->Int> ("lime", "lime_cairo_get_line_cap");
	private static var lime_cairo_get_line_join = new CFFI<Float->Int> ("lime", "lime_cairo_get_line_join");
	private static var lime_cairo_get_line_width = new CFFI<Float->Float> ("lime", "lime_cairo_get_line_width");
	private static var lime_cairo_get_matrix = new CFFI<Float->Dynamic> ("lime", "lime_cairo_get_matrix");
	private static var lime_cairo_get_miter_limit = new CFFI<Float->Float> ("lime", "lime_cairo_get_miter_limit");
	private static var lime_cairo_get_operator = new CFFI<Float->Int> ("lime", "lime_cairo_get_operator");
	private static var lime_cairo_get_reference_count = new CFFI<Float->Int> ("lime", "lime_cairo_get_reference_count");
	private static var lime_cairo_get_source = new CFFI<Float->Float> ("lime", "lime_cairo_get_source");
	private static var lime_cairo_get_target = new CFFI<Float->Float> ("lime", "lime_cairo_get_target");
	private static var lime_cairo_get_tolerance = new CFFI<Float->Float> ("lime", "lime_cairo_get_tolerance");
	private static var lime_cairo_has_current_point = new CFFI<Float->Bool> ("lime", "lime_cairo_has_current_point");
	private static var lime_cairo_identity_matrix = new CFFI<Float->Void> ("lime", "lime_cairo_identity_matrix");
	private static var lime_cairo_in_clip = new CFFI<Float->Float->Float->Bool> ("lime", "lime_cairo_in_clip");
	private static var lime_cairo_in_fill = new CFFI<Float->Float->Float->Bool> ("lime", "lime_cairo_in_fill");
	private static var lime_cairo_in_stroke = new CFFI<Float->Float->Float->Bool> ("lime", "lime_cairo_in_stroke");
	private static var lime_cairo_line_to = new CFFI<Float->Float->Float->Void> ("lime", "lime_cairo_line_to");
	private static var lime_cairo_mask = new CFFI<Float->Float->Void> ("lime", "lime_cairo_mask");
	private static var lime_cairo_mask_surface = new CFFI<Float->Float->Float->Float->Void> ("lime", "lime_cairo_mask_surface");
	private static var lime_cairo_move_to = new CFFI<Float->Float->Float->Void> ("lime", "lime_cairo_move_to");
	private static var lime_cairo_new_path = new CFFI<Float->Void> ("lime", "lime_cairo_new_path");
	private static var lime_cairo_paint = new CFFI<Float->Void> ("lime", "lime_cairo_paint");
	private static var lime_cairo_paint_with_alpha = new CFFI<Float->Float->Void> ("lime", "lime_cairo_paint_with_alpha");
	private static var lime_cairo_pop_group = new CFFI<Float->Float> ("lime", "lime_cairo_pop_group");
	private static var lime_cairo_pop_group_to_source = new CFFI<Float->Void> ("lime", "lime_cairo_pop_group_to_source");
	private static var lime_cairo_push_group = new CFFI<Float->Void> ("lime", "lime_cairo_push_group");
	private static var lime_cairo_push_group_with_content = new CFFI<Float->Int->Void> ("lime", "lime_cairo_push_group_with_content");
	private static var lime_cairo_rectangle = new CFFI<Float->Float->Float->Float->Float->Void> ("lime", "lime_cairo_rectangle");
	private static var lime_cairo_reference = new CFFI<Float->Void> ("lime", "lime_cairo_reference");
	private static var lime_cairo_rel_curve_to = new CFFI<Float->Float->Float->Float->Float->Float->Float->Void> ("lime", "lime_cairo_rel_curve_to");
	private static var lime_cairo_rel_line_to = new CFFI<Float->Float->Float->Void> ("lime", "lime_cairo_rel_line_to");
	private static var lime_cairo_rel_move_to = new CFFI<Float->Float->Float->Void> ("lime", "lime_cairo_rel_move_to");
	private static var lime_cairo_reset_clip = new CFFI<Float->Void> ("lime", "lime_cairo_reset_clip");
	private static var lime_cairo_restore = new CFFI<Float->Void> ("lime", "lime_cairo_restore");
	private static var lime_cairo_rotate = new CFFI<Float->Float->Void> ("lime", "lime_cairo_rotate");
	private static var lime_cairo_save = new CFFI<Float->Void> ("lime", "lime_cairo_save");
	private static var lime_cairo_scale = new CFFI<Float->Float->Float->Void> ("lime", "lime_cairo_scale");
	private static var lime_cairo_set_antialias = new CFFI<Float->Int->Void> ("lime", "lime_cairo_set_antialias");
	private static var lime_cairo_set_dash = new CFFI<Float->Dynamic->Void> ("lime", "lime_cairo_set_dash");
	private static var lime_cairo_set_font_face = new CFFI<Float->Float->Void> ("lime", "lime_cairo_set_font_face");
	private static var lime_cairo_set_font_size = new CFFI<Float->Float->Void> ("lime", "lime_cairo_set_font_size");
	private static var lime_cairo_set_fill_rule = new CFFI<Float->Int->Void> ("lime", "lime_cairo_set_fill_rule");
	private static var lime_cairo_set_font_options = new CFFI<Float->Float->Void> ("lime", "lime_cairo_set_font_options");
	private static var lime_cairo_set_line_cap = new CFFI<Float->Int->Void> ("lime", "lime_cairo_set_line_cap");
	private static var lime_cairo_set_line_join = new CFFI<Float->Int->Void> ("lime", "lime_cairo_set_line_join");
	private static var lime_cairo_set_line_width = new CFFI<Float->Float->Void> ("lime", "lime_cairo_set_line_width");
	private static var lime_cairo_set_matrix = new CFFI<Float->Dynamic->Void> ("lime", "lime_cairo_set_matrix");
	private static var lime_cairo_set_miter_limit = new CFFI<Float->Float->Void> ("lime", "lime_cairo_set_miter_limit");
	private static var lime_cairo_set_operator = new CFFI<Float->Int->Void> ("lime", "lime_cairo_set_operator");
	private static var lime_cairo_set_source = new CFFI<Float->Float->Void> ("lime", "lime_cairo_set_source");
	private static var lime_cairo_set_source_rgb = new CFFI<Float->Float->Float->Float->Void> ("lime", "lime_cairo_set_source_rgb");
	private static var lime_cairo_set_source_rgba = new CFFI<Float->Float->Float->Float->Float->Void> ("lime", "lime_cairo_set_source_rgba");
	private static var lime_cairo_set_source_surface = new CFFI<Float->Float->Float->Float->Void> ("lime", "lime_cairo_set_source_surface");
	private static var lime_cairo_set_tolerance = new CFFI<Float->Float->Void> ("lime", "lime_cairo_set_tolerance");
	private static var lime_cairo_show_page = new CFFI<Float->Void> ("lime", "lime_cairo_show_page");
	private static var lime_cairo_show_text = new CFFI<Float->String->Void> ("lime", "lime_cairo_show_text");
	private static var lime_cairo_status = new CFFI<Float->Int> ("lime", "lime_cairo_status");
	private static var lime_cairo_stroke = new CFFI<Float->Void> ("lime", "lime_cairo_stroke");
	private static var lime_cairo_stroke_extents = new CFFI<Float->Float->Float->Float->Float->Void> ("lime", "lime_cairo_stroke_extents");
	private static var lime_cairo_stroke_preserve = new CFFI<Float->Void> ("lime", "lime_cairo_stroke_preserve");
	private static var lime_cairo_transform = new CFFI<Float->Dynamic->Void> ("lime", "lime_cairo_transform");
	private static var lime_cairo_translate = new CFFI<Float->Float->Float->Void> ("lime", "lime_cairo_translate");
	private static var lime_cairo_version = new CFFI<Void->Int> ("lime", "lime_cairo_version");
	private static var lime_cairo_version_string = new CFFI<Void->String> ("lime", "lime_cairo_version_string");
	#end
	
	
}