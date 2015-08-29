#include <cairo.h>
#include <cairo-ft.h>
#include <math/Matrix3.h>
#include <math/Vector2.h>
#include <hx/CFFIPrime.h>
#include <text/Font.h>


namespace lime {
	
	
	void lime_cairo_arc (intptr_t handle, double xc, double yc, double radius, double angle1, double angle2) {
		
		cairo_arc ((cairo_t*)handle, xc, yc, radius, angle1, angle2);
		
	}
	
	
	void lime_cairo_arc_negative (intptr_t handle, double xc, double yc, double radius, double angle1, double angle2) {
		
		cairo_arc_negative ((cairo_t*)handle, xc, yc, radius, angle1, angle2);
		
	}
	
	
	void lime_cairo_clip (intptr_t handle) {
		
		cairo_clip ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_clip_extents (intptr_t handle, double x1, double y1, double x2, double y2) {
		
		cairo_clip_extents ((cairo_t*)handle, &x1, &y1, &x2, &y2);
		
	}
	
	
	void lime_cairo_clip_preserve (intptr_t handle) {
		
		cairo_clip_preserve ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_close_path (intptr_t handle) {
		
		cairo_close_path ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_copy_page (intptr_t handle) {
		
		cairo_copy_page ((cairo_t*)handle);
		
	}
	
	
	intptr_t lime_cairo_create (intptr_t surface) {
		
		return (intptr_t)cairo_create ((cairo_surface_t*)surface);
		
	}
	
	
	void lime_cairo_curve_to (intptr_t handle, double x1, double y1, double x2, double y2, double x3, double y3) {
		
		cairo_curve_to ((cairo_t*)handle, x1, y1, x2, y2, x3, y3);
		
	}
	
	
	void lime_cairo_destroy (intptr_t handle) {
		
		cairo_destroy ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_fill (intptr_t handle) {
		
		cairo_fill ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_fill_extents (intptr_t handle, double x1, double y1, double x2, double y2) {
		
		cairo_fill_extents ((cairo_t*)handle, &x1, &y1, &x2, &y2);
		
	}
	
	
	void lime_cairo_fill_preserve (intptr_t handle) {
		
		cairo_fill_preserve ((cairo_t*)handle);
		
	}
	
	void lime_cairo_font_face_destroy (intptr_t handle) {
		
		cairo_font_face_destroy ((cairo_font_face_t*)handle);
		
	}
	
	
	int lime_cairo_font_face_get_reference_count (intptr_t handle) {
		
		return cairo_font_face_get_reference_count ((cairo_font_face_t*)handle);
		
	}
	
	
	void lime_cairo_font_face_reference (intptr_t handle) {
		
		cairo_font_face_reference ((cairo_font_face_t*)handle);
		
	}
	
	
	int lime_cairo_font_face_status (intptr_t handle) {
		
		return cairo_font_face_status ((cairo_font_face_t*)handle);
		
	}
	
	
	intptr_t lime_cairo_font_options_create () {
		
		return (intptr_t)cairo_font_options_create ();
		
	}
	
	
	void lime_cairo_font_options_destroy (intptr_t handle) {
		
		cairo_font_options_destroy ((cairo_font_options_t*)handle);
		
	}
	
	
	int lime_cairo_font_options_get_antialias (intptr_t handle) {
		
		return cairo_font_options_get_antialias ((cairo_font_options_t*)handle);
		
	}
	
	
	int lime_cairo_font_options_get_hint_metrics (intptr_t handle) {
		
		return cairo_font_options_get_hint_metrics ((cairo_font_options_t*)handle);
		
	}
	
	
	int lime_cairo_font_options_get_hint_style (intptr_t handle) {
		
		return cairo_font_options_get_hint_style ((cairo_font_options_t*)handle);
		
	}
	
	
	int lime_cairo_font_options_get_subpixel_order (intptr_t handle) {
		
		return cairo_font_options_get_subpixel_order ((cairo_font_options_t*)handle);
		
	}
	
	
	void lime_cairo_font_options_set_antialias (intptr_t handle, int v) {
		
		cairo_font_options_set_antialias ((cairo_font_options_t*)handle, (cairo_antialias_t)v);
		
	}
	
	
	void lime_cairo_font_options_set_hint_metrics (intptr_t handle, int v) {
		
		cairo_font_options_set_hint_metrics ((cairo_font_options_t*)handle, (cairo_hint_metrics_t)v);
		
	}
	
	
	void lime_cairo_font_options_set_hint_style (intptr_t handle, int v) {
		
		cairo_font_options_set_hint_style ((cairo_font_options_t*)handle, (cairo_hint_style_t)v);
		
	}
	
	
	void lime_cairo_font_options_set_subpixel_order (intptr_t handle, int v) {
		
		cairo_font_options_set_subpixel_order ((cairo_font_options_t*)handle, (cairo_subpixel_order_t)v);
		
	}
	
	
	intptr_t lime_cairo_ft_font_face_create (double face, int flags) {
		
		#ifdef LIME_FREETYPE
		Font *font = (Font*)(intptr_t)face;
		return (intptr_t)cairo_ft_font_face_create_for_ft_face ((FT_Face)font->face, flags);
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_cairo_get_antialias (intptr_t handle) {
		
		return cairo_get_antialias ((cairo_t*)handle);
		
	}
	
	
	value lime_cairo_get_current_point (intptr_t handle) {
		
		double x, y;
		cairo_get_current_point ((cairo_t*)handle, &x, &y);
		Vector2 vec2 = Vector2 (x, y);
		return vec2.Value ();
		
	}
	
	
	value lime_cairo_get_dash (intptr_t handle) {
		
		int length = cairo_get_dash_count ((cairo_t*)handle);
		
		double* dashes = new double[length];
		double offset;
		
		cairo_get_dash ((cairo_t*)handle, dashes, &offset);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; i++) {
			
			val_array_set_i (result, i, alloc_float (dashes[i]));
			
		}
		
		delete dashes;
		return result;
		
	}
	
	
	int lime_cairo_get_dash_count (intptr_t handle) {
		
		return cairo_get_dash_count ((cairo_t*)handle);
		
	}
	
	
	int lime_cairo_get_fill_rule (intptr_t handle) {
		
		return cairo_get_fill_rule ((cairo_t*)handle);
		
	}
	
	
	intptr_t lime_cairo_get_font_face (intptr_t handle) {
		
		return (intptr_t)cairo_get_font_face ((cairo_t*)handle);
		
	}
	
	
	intptr_t lime_cairo_get_font_options (intptr_t handle) {
		
		cairo_font_options_t *options = 0;
		cairo_get_font_options ((cairo_t*)handle, options);
		return (intptr_t)options;
		
	}
	
	
	intptr_t lime_cairo_get_group_target (intptr_t handle) {
		
		return (intptr_t)cairo_get_group_target ((cairo_t*)handle);
		
	}
	
	
	int lime_cairo_get_line_cap (intptr_t handle) {
		
		return cairo_get_line_cap ((cairo_t*)handle);
		
	}
	
	
	int lime_cairo_get_line_join (intptr_t handle) {
		
		return cairo_get_line_join ((cairo_t*)handle);
		
	}
	
	
	double lime_cairo_get_line_width (intptr_t handle) {
		
		return cairo_get_line_width ((cairo_t*)handle);
		
	}
	
	
	value lime_cairo_get_matrix (intptr_t handle) {
		
		cairo_matrix_t cm;
		cairo_get_matrix ((cairo_t*)handle, &cm);
		Matrix3 mat3 = Matrix3 (cm.xx, cm.yx, cm.xy, cm.yy, cm.x0, cm.y0);
		return mat3.Value ();
		
	}
	
	
	double lime_cairo_get_miter_limit (intptr_t handle) {
		
		return cairo_get_miter_limit ((cairo_t*)handle);
		
	}
	
	
	int lime_cairo_get_operator (intptr_t handle) {
		
		return cairo_get_operator ((cairo_t*)handle);
		
	}
	
	
	int lime_cairo_get_reference_count (intptr_t handle) {
		
		return cairo_get_reference_count ((cairo_t*)handle);
		
	}
	
	
	intptr_t lime_cairo_get_source (intptr_t handle) {
		
		return (intptr_t)cairo_get_source ((cairo_t*)handle);
		
	}
	
	
	intptr_t lime_cairo_get_target (intptr_t handle) {
		
		return (intptr_t)cairo_get_target ((cairo_t*)handle);
		
	}
	
	
	double lime_cairo_get_tolerance (intptr_t handle) {
		
		return cairo_get_tolerance ((cairo_t*)handle);
		
	}
	
	
	bool lime_cairo_has_current_point (intptr_t handle) {
		
		return cairo_has_current_point ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_identity_matrix (intptr_t handle) {
		
		cairo_identity_matrix ((cairo_t*)handle);
		
	}
	
	
	intptr_t lime_cairo_image_surface_create (int format, int width, int height) {
		
		return (intptr_t)cairo_image_surface_create ((cairo_format_t)format, width, height);
		
	}
	
	
	intptr_t lime_cairo_image_surface_create_for_data (intptr_t data, int format, int width, int height, int stride) {
		
		return (intptr_t)cairo_image_surface_create_for_data ((unsigned char*)data, (cairo_format_t)format, width, height, stride);
		
	}
	
	
	intptr_t lime_cairo_image_surface_get_data (intptr_t handle) {
		
		return (intptr_t)cairo_image_surface_get_data ((cairo_surface_t*)handle);
		
	}
	
	
	int lime_cairo_image_surface_get_format (intptr_t handle) {
		
		return (int)cairo_image_surface_get_format ((cairo_surface_t*)handle);
		
	}
	
	
	int lime_cairo_image_surface_get_height (intptr_t handle) {
		
		return cairo_image_surface_get_height ((cairo_surface_t*)handle);
		
	}
	
	
	int lime_cairo_image_surface_get_stride (intptr_t handle) {
		
		return cairo_image_surface_get_stride ((cairo_surface_t*)handle);
		
	}
	
	
	int lime_cairo_image_surface_get_width (intptr_t handle) {
		
		return cairo_image_surface_get_width ((cairo_surface_t*)handle);
		
	}
	
	
	bool lime_cairo_in_clip (intptr_t handle, double x, double y) {
		
		return cairo_in_clip ((cairo_t*)handle, x, y);
		
	}
	
	
	bool lime_cairo_in_fill (intptr_t handle, double x, double y) {
		
		return cairo_in_fill ((cairo_t*)handle, x, y);
		
	}
	
	
	bool lime_cairo_in_stroke (intptr_t handle, double x, double y) {
		
		return cairo_in_stroke ((cairo_t*)handle, x, y);
		
	}
	
	
	void lime_cairo_line_to (intptr_t handle, double x, double y) {
		
		cairo_line_to ((cairo_t*)handle, x, y);
		
	}
	
	
	void lime_cairo_mask (intptr_t handle, intptr_t pattern) {
		
		cairo_mask ((cairo_t*)handle, (cairo_pattern_t*)pattern);
		
	}
	
	
	void lime_cairo_mask_surface (intptr_t handle, intptr_t surface, double x, double y) {
		
		cairo_mask_surface ((cairo_t*)handle, (cairo_surface_t*)surface, x, y);
		
	}
	
	
	void lime_cairo_move_to (intptr_t handle, double x, double y) {
		
		cairo_move_to ((cairo_t*)handle, x, y);
		
	}
	
	
	void lime_cairo_new_path (intptr_t handle) {
		
		cairo_new_path ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_paint (intptr_t handle) {
		
		cairo_paint ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_paint_with_alpha (intptr_t handle, double alpha) {
		
		cairo_paint_with_alpha ((cairo_t*)handle, alpha);
		
	}
	
	
	void lime_cairo_pattern_add_color_stop_rgb (intptr_t handle, double offset, double red, double green, double blue) {
		
		cairo_pattern_add_color_stop_rgb ((cairo_pattern_t*)handle, offset, red, green, blue);
		
	}
	
	
	void lime_cairo_pattern_add_color_stop_rgba (intptr_t handle, double offset, double red, double green, double blue, double alpha) {
		
		cairo_pattern_add_color_stop_rgba ((cairo_pattern_t*)handle, offset, red, green, blue, alpha);
		
	}
	
	
	intptr_t lime_cairo_pattern_create_for_surface (intptr_t surface) {
		
		return (intptr_t)cairo_pattern_create_for_surface ((cairo_surface_t*)surface);
		
	}
	
	
	intptr_t lime_cairo_pattern_create_linear (double x0, double y0, double x1, double y1) {
		
		return (intptr_t)cairo_pattern_create_linear (x0, y0, x1, y1);
		
	}
	
	
	intptr_t lime_cairo_pattern_create_radial (double cx0, double cy0, double radius0, double cx1, double cy1, double radius1) {
		
		return (intptr_t)cairo_pattern_create_radial (cx0, cy0, radius0, cx1, cy1, radius1);
		
	}
	
	
	intptr_t lime_cairo_pattern_create_rgb (double r, double g, double b) {
		
		return (intptr_t)cairo_pattern_create_rgb (r, g, b);
		
	}
	
	
	intptr_t lime_cairo_pattern_create_rgba (double r, double g, double b, double a) {
		
		return (intptr_t)cairo_pattern_create_rgba (r, g, b, a);
		
	}
	
	
	void lime_cairo_pattern_destroy (intptr_t handle) {
		
		cairo_pattern_destroy ((cairo_pattern_t*)handle);
		
	}
	
	
	int lime_cairo_pattern_get_color_stop_count (intptr_t handle) {
		
		int count;
		return cairo_pattern_get_color_stop_count ((cairo_pattern_t*)handle, &count);
		return count;
		
	}
	
	
	int lime_cairo_pattern_get_extend (intptr_t handle) {
		
		return cairo_pattern_get_extend ((cairo_pattern_t*)handle);
		
	}
	
	
	int lime_cairo_pattern_get_filter (intptr_t handle) {
		
		return cairo_pattern_get_filter ((cairo_pattern_t*)handle);
		
	}
	
	
	value lime_cairo_pattern_get_matrix (intptr_t handle) {
		
		cairo_matrix_t cm;
		cairo_pattern_get_matrix ((cairo_pattern_t*)handle, &cm);
		Matrix3 mat3 = Matrix3 (cm.xx, cm.yx, cm.xy, cm.yy, cm.x0, cm.y0);
		return mat3.Value ();
		
	}
	
	
	void lime_cairo_pattern_set_extend (intptr_t handle, int extend) {
		
		cairo_pattern_set_extend ((cairo_pattern_t*)handle, (cairo_extend_t)extend);
		
	}
	
	
	void lime_cairo_pattern_set_filter (intptr_t handle, int filter) {
		
		cairo_pattern_set_filter ((cairo_pattern_t*)handle, (cairo_filter_t)filter);
		
	}
	
	
	void lime_cairo_pattern_set_matrix (intptr_t handle, value matrix) {
		
		Matrix3 mat3 = Matrix3 (matrix);
		
		cairo_matrix_t cm;
		cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);
		
		cairo_pattern_set_matrix ((cairo_pattern_t*)handle, &cm);
		
	}
	
	
	intptr_t lime_cairo_pop_group (intptr_t handle) {
		
		return (intptr_t)cairo_pop_group ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_pop_group_to_source (intptr_t handle) {
		
		cairo_pop_group_to_source ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_push_group (intptr_t handle) {
		
		cairo_push_group ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_push_group_with_content (intptr_t handle, int content) {
		
		cairo_push_group_with_content ((cairo_t*)handle, (cairo_content_t)content);
		
	}
	
	
	void lime_cairo_rectangle (intptr_t handle, double x, double y, double width, double height) {
		
		cairo_rectangle ((cairo_t*)handle, x, y, width, height);
		
	}
	
	
	void lime_cairo_reference (intptr_t handle) {
		
		cairo_reference ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_rel_curve_to (intptr_t handle, double dx1, double dy1, double dx2, double dy2, double dx3, double dy3) {
		
		cairo_rel_curve_to ((cairo_t*)handle, dx1, dy1, dx2, dy2, dx3, dy3);
		
	}
	
	
	void lime_cairo_rel_line_to (intptr_t handle, double dx, double dy) {
		
		cairo_rel_line_to ((cairo_t*)handle, dx, dy);
		
	}
	
	
	void lime_cairo_rel_move_to (intptr_t handle, double dx, double dy) {
		
		cairo_rel_move_to ((cairo_t*)handle, dx, dy);
		
	}
	
	
	void lime_cairo_reset_clip (intptr_t handle) {
		
		cairo_reset_clip ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_restore (intptr_t handle) {
		
		cairo_restore ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_rotate (intptr_t handle, double amount) {
		
		cairo_rotate ((cairo_t*)handle, amount);
		
	}
	
	
	void lime_cairo_save (intptr_t handle) {
		
		cairo_save ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_scale (intptr_t handle, double x, double y) {
		
		cairo_scale ((cairo_t*)handle, x, y);
		
	}
	
	
	void lime_cairo_set_antialias (intptr_t handle, int cap) {
		
		cairo_set_antialias ((cairo_t*)handle, (cairo_antialias_t)cap);
		
	}
	
	
	void lime_cairo_set_dash (intptr_t handle, value dash) {
		
		int length = val_array_size (dash);
		
		double* dashPattern = new double[length];
		
		for (int i = 0; i < length; i++) {
			
			dashPattern[i] = val_number (val_array_i (dash, i));
			
		}
		
		cairo_set_dash ((cairo_t*)handle, dashPattern, length, 0);
		delete dashPattern;
		
	}
	
	
	void lime_cairo_set_font_face (intptr_t handle, intptr_t face) {
		
		cairo_set_font_face ((cairo_t*)handle, (cairo_font_face_t*)face);
		
	}
	
	
	void lime_cairo_set_font_options (intptr_t handle, intptr_t options) {
		
		cairo_set_font_options ((cairo_t*)handle, (cairo_font_options_t*)options);
		
	}
	
	
	void lime_cairo_set_font_size (intptr_t handle, double size) {
		
		cairo_set_font_size ((cairo_t*)handle, size);
		
	}
	
	
	void lime_cairo_set_fill_rule (intptr_t handle, int cap) {
		
		cairo_set_fill_rule ((cairo_t*)handle, (cairo_fill_rule_t)cap);
		
	}
	
	
	void lime_cairo_set_line_cap (intptr_t handle, int cap) {
		
		cairo_set_line_cap ((cairo_t*)handle, (cairo_line_cap_t)cap);
		
	}
	
	
	void lime_cairo_set_line_join (intptr_t handle, int join) {
		
		cairo_set_line_join ((cairo_t*)handle, (cairo_line_join_t)join);
		
	}
	
	
	void lime_cairo_set_line_width (intptr_t handle, double width) {
		
		cairo_set_line_width ((cairo_t*)handle, width);
		
	}
	
	
	void lime_cairo_set_matrix (intptr_t handle, value matrix) {
		
		Matrix3 mat3 = Matrix3 (matrix);
		
		cairo_matrix_t cm;
		cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);
		
		cairo_set_matrix ((cairo_t*)handle, &cm);
		
	}
	
	
	void lime_cairo_set_miter_limit (intptr_t handle, double miterLimit) {
		
		cairo_set_miter_limit ((cairo_t*)handle, miterLimit);
		
	}
	
	
	void lime_cairo_set_operator (intptr_t handle, int op) {
		
		cairo_set_operator ((cairo_t*)handle, (cairo_operator_t)op);
		
	}
	
	
	void lime_cairo_set_source (intptr_t handle, intptr_t pattern) {
		
		cairo_set_source ((cairo_t*)handle, (cairo_pattern_t*)pattern);
		
	}
	
	
	void lime_cairo_set_source_rgb (intptr_t handle, double r, double g, double b) {
		
		cairo_set_source_rgb ((cairo_t*)handle, r, g, b);
		
	}
	
	
	void lime_cairo_set_source_rgba (intptr_t handle, double r, double g, double b, double a) {
		
		cairo_set_source_rgba ((cairo_t*)handle, r, g, b, a);
		
	}
	
	
	void lime_cairo_set_source_surface (intptr_t handle, intptr_t surface, double x, double y) {
		
		cairo_set_source_surface ((cairo_t*)handle, (cairo_surface_t*)surface, x, y);
		
	}
	
	
	void lime_cairo_set_tolerance (intptr_t handle, double tolerance) {
		
		cairo_set_tolerance ((cairo_t*)handle, tolerance);
		
	}
	
	
	void lime_cairo_show_page (intptr_t handle) {
		
		cairo_show_page ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_show_text (intptr_t handle, const char* text) {
		
		cairo_show_text ((cairo_t*)handle, (char*)text);
		
	}
	
	
	int lime_cairo_status (intptr_t handle) {
		
		return cairo_status ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_stroke (intptr_t handle) {
		
		cairo_stroke ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_stroke_extents (intptr_t handle, double x1, double y1, double x2, double y2) {
		
		cairo_stroke_extents ((cairo_t*)handle, &x1, &y1, &x2, &y2);
		
	}
	
	
	void lime_cairo_stroke_preserve (intptr_t handle) {
		
		cairo_stroke_preserve ((cairo_t*)handle);
		
	}
	
	
	void lime_cairo_surface_destroy (intptr_t handle) {
		
		cairo_surface_destroy ((cairo_surface_t*)handle);
		
	}
	
	
	void lime_cairo_surface_flush (intptr_t handle) {
		
		cairo_surface_flush ((cairo_surface_t*)handle);
		
	}
	
	
	void lime_cairo_transform (intptr_t handle, value matrix) {
		
		Matrix3 mat3 = Matrix3 (matrix);
		
		cairo_matrix_t cm;
		cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);
		
		cairo_transform ((cairo_t*)handle, &cm);
		
	}
	
	
	void lime_cairo_translate (intptr_t handle, double x, double y) {
		
		cairo_translate ((cairo_t*)handle, x, y);
		
	}
	
	
	int lime_cairo_version () {
		
		return cairo_version ();
		
	}
	
	
	HxString lime_cairo_version_string () {
		
		return HxString (cairo_version_string ());
		
	}
	
	
	DEFINE_PRIME6v (lime_cairo_arc);
	DEFINE_PRIME6v (lime_cairo_arc_negative);
	DEFINE_PRIME1v (lime_cairo_clip);
	DEFINE_PRIME5v (lime_cairo_clip_extents);
	DEFINE_PRIME1v (lime_cairo_clip_preserve);
	DEFINE_PRIME1v (lime_cairo_close_path);
	DEFINE_PRIME1v (lime_cairo_copy_page);
	DEFINE_PRIME1 (lime_cairo_create);
	DEFINE_PRIME7v (lime_cairo_curve_to);
	DEFINE_PRIME1v (lime_cairo_destroy);
	DEFINE_PRIME1v (lime_cairo_fill);
	DEFINE_PRIME5v (lime_cairo_fill_extents);
	DEFINE_PRIME1v (lime_cairo_fill_preserve);
	DEFINE_PRIME2 (lime_cairo_ft_font_face_create);
	DEFINE_PRIME1v (lime_cairo_font_face_destroy);
	DEFINE_PRIME1 (lime_cairo_font_face_get_reference_count);
	DEFINE_PRIME1v (lime_cairo_font_face_reference);
	DEFINE_PRIME1 (lime_cairo_font_face_status);
	DEFINE_PRIME0 (lime_cairo_font_options_create);
	DEFINE_PRIME1v (lime_cairo_font_options_destroy);
	DEFINE_PRIME1 (lime_cairo_font_options_get_antialias);
	DEFINE_PRIME1 (lime_cairo_font_options_get_subpixel_order);
	DEFINE_PRIME1 (lime_cairo_font_options_get_hint_style);
	DEFINE_PRIME1 (lime_cairo_font_options_get_hint_metrics);
	DEFINE_PRIME2v (lime_cairo_font_options_set_antialias);
	DEFINE_PRIME2v (lime_cairo_font_options_set_subpixel_order);
	DEFINE_PRIME2v (lime_cairo_font_options_set_hint_style);
	DEFINE_PRIME2v (lime_cairo_font_options_set_hint_metrics);
	DEFINE_PRIME1 (lime_cairo_get_antialias);
	DEFINE_PRIME1 (lime_cairo_get_current_point);
	DEFINE_PRIME1 (lime_cairo_get_dash);
	DEFINE_PRIME1 (lime_cairo_get_dash_count);
	DEFINE_PRIME1 (lime_cairo_get_fill_rule);
	DEFINE_PRIME1 (lime_cairo_get_font_face);
	DEFINE_PRIME1 (lime_cairo_get_font_options);
	DEFINE_PRIME1 (lime_cairo_get_group_target);
	DEFINE_PRIME1 (lime_cairo_get_line_cap);
	DEFINE_PRIME1 (lime_cairo_get_line_join);
	DEFINE_PRIME1 (lime_cairo_get_line_width);
	DEFINE_PRIME1 (lime_cairo_get_matrix);
	DEFINE_PRIME1 (lime_cairo_get_miter_limit);
	DEFINE_PRIME1 (lime_cairo_get_operator);
	DEFINE_PRIME1 (lime_cairo_get_reference_count);
	DEFINE_PRIME1 (lime_cairo_get_source);
	DEFINE_PRIME1 (lime_cairo_get_target);
	DEFINE_PRIME1 (lime_cairo_get_tolerance);
	DEFINE_PRIME1 (lime_cairo_has_current_point);
	DEFINE_PRIME1v (lime_cairo_identity_matrix);
	DEFINE_PRIME3v (lime_cairo_image_surface_create);
	DEFINE_PRIME5 (lime_cairo_image_surface_create_for_data);
	DEFINE_PRIME1 (lime_cairo_image_surface_get_data);
	DEFINE_PRIME1 (lime_cairo_image_surface_get_format);
	DEFINE_PRIME1 (lime_cairo_image_surface_get_height);
	DEFINE_PRIME1 (lime_cairo_image_surface_get_stride);
	DEFINE_PRIME1 (lime_cairo_image_surface_get_width);
	DEFINE_PRIME3 (lime_cairo_in_clip);
	DEFINE_PRIME3 (lime_cairo_in_fill);
	DEFINE_PRIME3 (lime_cairo_in_stroke);
	DEFINE_PRIME3v (lime_cairo_line_to);
	DEFINE_PRIME2v (lime_cairo_mask);
	DEFINE_PRIME4v (lime_cairo_mask_surface);
	DEFINE_PRIME3v (lime_cairo_move_to);
	DEFINE_PRIME1v (lime_cairo_new_path);
	DEFINE_PRIME1v (lime_cairo_paint);
	DEFINE_PRIME2v (lime_cairo_paint_with_alpha);
	DEFINE_PRIME5v (lime_cairo_pattern_add_color_stop_rgb);
	DEFINE_PRIME6v (lime_cairo_pattern_add_color_stop_rgba);
	DEFINE_PRIME1 (lime_cairo_pattern_create_for_surface);
	DEFINE_PRIME4 (lime_cairo_pattern_create_linear);
	DEFINE_PRIME6 (lime_cairo_pattern_create_radial);
	DEFINE_PRIME3 (lime_cairo_pattern_create_rgb);
	DEFINE_PRIME4 (lime_cairo_pattern_create_rgba);
	DEFINE_PRIME1v (lime_cairo_pattern_destroy);
	DEFINE_PRIME1 (lime_cairo_pattern_get_color_stop_count);
	DEFINE_PRIME1 (lime_cairo_pattern_get_extend);
	DEFINE_PRIME1 (lime_cairo_pattern_get_filter);
	DEFINE_PRIME1 (lime_cairo_pattern_get_matrix);
	DEFINE_PRIME2v (lime_cairo_pattern_set_extend);
	DEFINE_PRIME2v (lime_cairo_pattern_set_filter);
	DEFINE_PRIME2v (lime_cairo_pattern_set_matrix);
	DEFINE_PRIME1 (lime_cairo_pop_group);
	DEFINE_PRIME1v (lime_cairo_pop_group_to_source);
	DEFINE_PRIME1v (lime_cairo_push_group);
	DEFINE_PRIME2v (lime_cairo_push_group_with_content);
	DEFINE_PRIME5v (lime_cairo_rectangle);
	DEFINE_PRIME1v (lime_cairo_reference);
	DEFINE_PRIME7v (lime_cairo_rel_curve_to);
	DEFINE_PRIME3v (lime_cairo_rel_line_to);
	DEFINE_PRIME3v (lime_cairo_rel_move_to);
	DEFINE_PRIME1v (lime_cairo_reset_clip);
	DEFINE_PRIME1v (lime_cairo_restore);
	DEFINE_PRIME2v (lime_cairo_rotate);
	DEFINE_PRIME1v (lime_cairo_save);
	DEFINE_PRIME3v (lime_cairo_scale);
	DEFINE_PRIME2v (lime_cairo_set_antialias);
	DEFINE_PRIME2v (lime_cairo_set_dash);
	DEFINE_PRIME2v (lime_cairo_set_fill_rule);
	DEFINE_PRIME2v (lime_cairo_set_font_face);
	DEFINE_PRIME2v (lime_cairo_set_font_size);
	DEFINE_PRIME2v (lime_cairo_set_font_options);
	DEFINE_PRIME2v (lime_cairo_set_line_cap);
	DEFINE_PRIME2v (lime_cairo_set_line_join);
	DEFINE_PRIME2v (lime_cairo_set_line_width);
	DEFINE_PRIME2v (lime_cairo_set_matrix);
	DEFINE_PRIME2v (lime_cairo_set_miter_limit);
	DEFINE_PRIME2v (lime_cairo_set_operator);
	DEFINE_PRIME2v (lime_cairo_set_source);
	DEFINE_PRIME4v (lime_cairo_set_source_rgb);
	DEFINE_PRIME5v (lime_cairo_set_source_rgba);
	DEFINE_PRIME4v (lime_cairo_set_source_surface);
	DEFINE_PRIME2v (lime_cairo_set_tolerance);
	DEFINE_PRIME1v (lime_cairo_show_page);
	DEFINE_PRIME2v (lime_cairo_show_text);
	DEFINE_PRIME1 (lime_cairo_status);
	DEFINE_PRIME1v (lime_cairo_stroke);
	DEFINE_PRIME5v (lime_cairo_stroke_extents);
	DEFINE_PRIME1v (lime_cairo_stroke_preserve);
	DEFINE_PRIME1v (lime_cairo_surface_destroy);
	DEFINE_PRIME1v (lime_cairo_surface_flush);
	DEFINE_PRIME2v (lime_cairo_transform);
	DEFINE_PRIME3v (lime_cairo_translate);
	DEFINE_PRIME0 (lime_cairo_version);
	DEFINE_PRIME0 (lime_cairo_version_string);
	
	
}


extern "C" int lime_cairo_register_prims () {
	
	return 0;
	
}