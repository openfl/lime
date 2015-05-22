#include <cairo.h>
#include <cairo-ft.h>
#include <math/Matrix3.h>
#include <math/Vector2.h>
#include <hx/CFFI.h>
#include <text/Font.h>


namespace lime {
	
	void lime_cairo_font_options_destroy (value handle);
	
	value lime_cairo_arc (value *arg, int argCount) {
		
		cairo_arc ((cairo_t*)(intptr_t)val_float (arg[0]), val_number (arg[1]), val_number (arg[2]), val_number (arg[3]), val_number (arg[4]), val_number (arg[5]));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_arc_negative (value *arg, int argCount) {
		
		cairo_arc_negative ((cairo_t*)(intptr_t)val_float (arg[0]), val_number (arg[1]), val_number (arg[2]), val_number (arg[3]), val_number (arg[4]), val_number (arg[5]));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_clip (value handle) {
		
		cairo_clip ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_clip_extents (value handle, value x1, value y1, value x2, value y2) {
		
		double _x1 = val_number (x1);
		double _y1 = val_number (y1);
		double _x2 = val_number (x2);
		double _y2 = val_number (y2);
		
		cairo_clip_extents ((cairo_t*)(intptr_t)val_float (handle), &_x1, &_y1, &_x2, &_y2);
		return alloc_null ();
		
	}
	
	
	value lime_cairo_clip_preserve (value handle) {
		
		cairo_clip_preserve ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_close_path (value handle) {
		
		cairo_close_path ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_copy_page (value handle) {
		
		cairo_copy_page ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_create (value surface) {
		
		return alloc_float ((intptr_t)cairo_create ((cairo_surface_t*)(intptr_t)val_float (surface)));
		
	}
	
	
	value lime_cairo_curve_to (value *arg, int argCount) {
		
		cairo_curve_to ((cairo_t*)(intptr_t)val_float (arg[0]), val_number (arg[1]), val_number (arg[2]), val_number (arg[3]), val_number (arg[4]), val_number (arg[5]), val_number (arg[6]));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_destroy (value handle) {
		
		cairo_destroy ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_fill (value handle) {
		
		cairo_fill ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_fill_extents (value handle, value x1, value y1, value x2, value y2) {
		
		double _x1 = val_number (x1);
		double _y1 = val_number (y1);
		double _x2 = val_number (x2);
		double _y2 = val_number (y2);
		
		cairo_fill_extents ((cairo_t*)(intptr_t)val_float (handle), &_x1, &_y1, &_x2, &_y2);
		return alloc_null ();
		
	}
	
	
	value lime_cairo_fill_preserve (value handle) {
		
		cairo_fill_preserve ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	value lime_cairo_font_face_destroy (value handle) {
		
		cairo_font_face_t* face = (cairo_font_face_t*)(intptr_t)val_float(handle);
		cairo_font_face_destroy( face );
		return alloc_null ();
		
	}
	
	value lime_cairo_font_options_create () {
		
		value options = alloc_float( (intptr_t)cairo_font_options_create() );
		val_gc( options, lime_cairo_font_options_destroy );
		return options;
		
	}
		
	void lime_cairo_font_options_destroy (value handle) {
		
		cairo_font_options_destroy( (cairo_font_options_t*)(intptr_t)val_float (handle) );
		
	}
	
	value lime_cairo_font_options_get_antialias (value handle) {
		
		return alloc_int( cairo_font_options_get_antialias( (cairo_font_options_t*)(intptr_t)val_float (handle) ) );
		
	}
	
	value lime_cairo_font_options_get_subpixel_order (value handle) {
		
		return alloc_int( cairo_font_options_get_subpixel_order( (cairo_font_options_t*)(intptr_t)val_float (handle) ) );
		
	}
	
	value lime_cairo_font_options_get_hint_style (value handle) {
		
		return alloc_int( cairo_font_options_get_hint_style( (cairo_font_options_t*)(intptr_t)val_float (handle) ) );
		
	}
	
	value lime_cairo_font_options_get_hint_metrics (value handle) {
		
		return alloc_int( cairo_font_options_get_hint_metrics( (cairo_font_options_t*)(intptr_t)val_float (handle) ) );
		
	}
	
	value lime_cairo_font_options_set_antialias (value handle, value v) {
		
		cairo_font_options_set_antialias( (cairo_font_options_t*)(intptr_t)val_float (handle), (cairo_antialias_t)val_int( v ) );
		return alloc_null();
		
	}
	
	value lime_cairo_font_options_set_subpixel_order (value handle, value v) {
		
		cairo_font_options_set_subpixel_order( (cairo_font_options_t*)(intptr_t)val_float (handle), (cairo_subpixel_order_t)val_int( v ) );
		return alloc_null();
		
	}
	
	value lime_cairo_font_options_set_hint_style (value handle, value v) {
		
		cairo_font_options_set_hint_style( (cairo_font_options_t*)(intptr_t)val_float (handle), (cairo_hint_style_t)val_int( v ) );
		return alloc_null();
		
	}
	
	value lime_cairo_font_options_set_hint_metrics (value handle, value v) {
		
		cairo_font_options_set_hint_metrics( (cairo_font_options_t*)(intptr_t)val_float (handle), (cairo_hint_metrics_t)val_int( v ) );
		return alloc_null();
		
	}

	value lime_cairo_get_antialias (value handle) {
		
		return alloc_int (cairo_get_antialias ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_get_current_point (value handle) {
		
		double x, y;
		cairo_get_current_point ((cairo_t*)(intptr_t)val_float (handle), &x, &y);
		Vector2 vec2 = Vector2 (x, y);
		return vec2.Value ();
		
	}
	
	
	value lime_cairo_get_dash (value handle) {
		
		int length = cairo_get_dash_count ((cairo_t*)(intptr_t)val_float (handle));
		
		double* dashes = new double[length];
		double offset;
		
		cairo_get_dash ((cairo_t*)(intptr_t)val_float (handle), dashes, &offset);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; i++) {
			
			val_array_set_i (result, i, alloc_float (dashes[i]));
			
		}
		
		delete dashes;
		return result;
		
	}
	
	
	value lime_cairo_get_dash_count (value handle) {
		
		return alloc_int (cairo_get_dash_count ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_get_fill_rule (value handle) {
		
		return alloc_int (cairo_get_fill_rule ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
		
	value lime_cairo_get_font_options (value handle) {
		
		cairo_font_options_t* options = (cairo_font_options_t*)(intptr_t)lime_cairo_font_options_create();
		
		cairo_get_font_options ((cairo_t*)(intptr_t)val_float (handle), options);
		
		return alloc_float ((intptr_t)options);
	}
	
	
	value lime_cairo_get_group_target (value handle) {
		
		return alloc_float ((intptr_t)cairo_get_group_target ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_get_line_cap (value handle) {
		
		return alloc_int (cairo_get_line_cap ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_get_line_join (value handle) {
		
		return alloc_int (cairo_get_line_join ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_get_line_width (value handle) {
		
		return alloc_float (cairo_get_line_width ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_get_matrix (value handle) {
		
		cairo_matrix_t cm;
		cairo_get_matrix ((cairo_t*)(intptr_t)val_float (handle), &cm);
		Matrix3 mat3 = Matrix3 (cm.xx, cm.yx, cm.xy, cm.yy, cm.x0, cm.y0);
		return mat3.Value ();
		
	}
	
	
	value lime_cairo_get_miter_limit (value handle) {
		
		return alloc_float (cairo_get_miter_limit ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_get_operator (value handle) {
		
		return alloc_int (cairo_get_operator ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_get_reference_count (value handle) {
		
		return alloc_int (cairo_get_reference_count ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_get_source (value handle) {
		
		return alloc_float ((intptr_t)cairo_get_source ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_get_target (value handle) {
		
		return alloc_float ((intptr_t)cairo_get_target ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_get_tolerance (value handle) {
		
		return alloc_float (cairo_get_tolerance ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_has_current_point (value handle) {
		
		return alloc_bool (cairo_has_current_point ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_identity_matrix (value handle) {
		
		cairo_identity_matrix ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_image_surface_create (value format, value width, value height) {
		
		return alloc_float ((intptr_t)cairo_image_surface_create ((cairo_format_t)val_int (format), val_int (width), val_int (height)));
		
	}
	
	
	value lime_cairo_image_surface_create_for_data (value data, value format, value width, value height, value stride) {
		
		return alloc_float ((intptr_t)cairo_image_surface_create_for_data ((unsigned char*)(intptr_t)val_float (data), (cairo_format_t)val_int (format), val_int (width), val_int (height), val_int (stride)));
		
	}
	
	
	value lime_cairo_image_surface_get_height (value handle) {
		
		return alloc_int ((intptr_t)cairo_image_surface_get_height ((cairo_surface_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_image_surface_get_width (value handle) {
		
		return alloc_int ((intptr_t)cairo_image_surface_get_width ((cairo_surface_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_in_clip (value handle, value x, value y) {
		
		return alloc_bool (cairo_in_clip ((cairo_t*)(intptr_t)val_float (handle), val_number (x), val_number (y)));
		
	}
	
	
	value lime_cairo_in_fill (value handle, value x, value y) {
		
		return alloc_bool (cairo_in_fill ((cairo_t*)(intptr_t)val_float (handle), val_number (x), val_number (y)));
		
	}
	
	
	value lime_cairo_in_stroke (value handle, value x, value y) {
		
		return alloc_bool (cairo_in_stroke ((cairo_t*)(intptr_t)val_float (handle), val_number (x), val_number (y)));
		
	}
	
	
	value lime_cairo_line_to (value handle, value x, value y) {
		
		cairo_line_to ((cairo_t*)(intptr_t)val_float (handle), val_number (x), val_number (y));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_mask (value handle, value pattern) {
		
		cairo_mask ((cairo_t*)(intptr_t)val_float (handle), (cairo_pattern_t*)(intptr_t)val_float (pattern));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_mask_surface (value handle, value surface, value x, value y) {
		
		cairo_mask_surface ((cairo_t*)(intptr_t)val_float (handle), (cairo_surface_t*)(intptr_t)val_float (surface), val_number (x), val_number (y));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_move_to (value handle, value x, value y) {
		
		cairo_move_to ((cairo_t*)(intptr_t)val_float (handle), val_number (x), val_number (y));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_new_path (value handle) {
		
		cairo_new_path ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_paint (value handle) {
		
		cairo_paint ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_paint_with_alpha (value handle, value alpha) {
		
		cairo_paint_with_alpha ((cairo_t*)(intptr_t)val_float (handle), val_number (alpha));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_pattern_add_color_stop_rgb (value handle, value offset, value red, value green, value blue) {
		
		cairo_pattern_add_color_stop_rgb ((cairo_pattern_t*)(intptr_t)val_float (handle), val_number (offset), val_number (red), val_number (green), val_number (blue));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_pattern_add_color_stop_rgba (value *arg, int argCount) {
		
		cairo_pattern_add_color_stop_rgba ((cairo_pattern_t*)(intptr_t)val_float (arg[0]), val_number (arg[1]), val_number (arg[2]), val_number (arg[3]), val_number (arg[4]), val_number (arg[5]));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_pattern_create_for_surface (value surface) {
		
		return alloc_float ((intptr_t)cairo_pattern_create_for_surface ((cairo_surface_t*)(intptr_t)val_float (surface)));
		
	}
	
	
	value lime_cairo_pattern_create_linear (value x0, value y0, value x1, value y1) {
		
		return alloc_float ((intptr_t)cairo_pattern_create_linear (val_number (x0), val_number (y0), val_number (x1), val_number (y1)));
		
	}
	
	
	value lime_cairo_pattern_create_radial (value *arg, int argCount) {
		
		return alloc_float ((intptr_t)cairo_pattern_create_radial (val_number (arg[0]), val_number (arg[1]), val_number (arg[2]), val_number (arg[3]), val_number (arg[4]), val_number (arg[5])));
		
	}
	
	
	value lime_cairo_pattern_create_rgb (value r, value g, value b) {
		
		return alloc_float ((intptr_t)cairo_pattern_create_rgb (val_number (r), val_number (g), val_number (b)));
		
	}
	
	
	value lime_cairo_pattern_create_rgba (value r, value g, value b, value a) {
		
		return alloc_float ((intptr_t)cairo_pattern_create_rgba (val_number (r), val_number (g), val_number (b), val_number (a)));
		
	}
	
	
	value lime_cairo_pattern_destroy (value handle) {
		
		cairo_pattern_destroy ((cairo_pattern_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_pattern_get_color_stop_count (value handle) {
		
		int count;
		cairo_pattern_get_color_stop_count ((cairo_pattern_t*)(intptr_t)val_float (handle), &count);
		return alloc_int (count);
		
	}
	
	
	value lime_cairo_pattern_get_extend (value handle) {
		
		return alloc_int (cairo_pattern_get_extend ((cairo_pattern_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_pattern_set_extend (value handle, value extend) {
		
		cairo_pattern_set_extend ((cairo_pattern_t*)(intptr_t)val_float (handle), (cairo_extend_t)val_int (extend));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_pattern_get_filter (value handle) {
		
		return alloc_int (cairo_pattern_get_filter ((cairo_pattern_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_pattern_set_filter (value handle, value filter) {
		
		cairo_pattern_set_filter ((cairo_pattern_t*)(intptr_t)val_float (handle), (cairo_filter_t)val_int (filter));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_pattern_get_matrix (value handle) {
		
		cairo_matrix_t cm;
		cairo_pattern_get_matrix ((cairo_pattern_t*)(intptr_t)val_float (handle), &cm);
		Matrix3 mat3 = Matrix3 (cm.xx, cm.yx, cm.xy, cm.yy, cm.x0, cm.y0);
		return mat3.Value ();
		
	}
	
	
	value lime_cairo_pattern_set_matrix (value handle, value matrix) {
		
		Matrix3 mat3 = Matrix3 (matrix);
		
		cairo_matrix_t cm;
		cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);
		
		cairo_pattern_set_matrix ((cairo_pattern_t*)(intptr_t)val_float (handle), &cm);
		return alloc_null ();
		
	}
	
	
	value lime_cairo_pop_group (value handle) {
		
		return alloc_float ((intptr_t)cairo_pop_group ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_pop_group_to_source (value handle) {
		
		cairo_pop_group_to_source ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_push_group (value handle) {
		
		cairo_push_group ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_push_group_with_content (value handle, value content) {
		
		cairo_push_group_with_content ((cairo_t*)(intptr_t)val_float (handle), (cairo_content_t)val_int (content));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_rectangle (value handle, value x, value y, value width, value height) {
		
		cairo_rectangle ((cairo_t*)(intptr_t)val_float (handle), val_number (x), val_number (y), val_number (width), val_number (height));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_reference (value handle) {
		
		cairo_reference ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_rel_curve_to (value *arg, int argCount) {
		
		cairo_rel_curve_to ((cairo_t*)(intptr_t)val_float (arg[0]), val_number (arg[1]), val_number (arg[2]), val_number (arg[3]), val_number (arg[4]), val_number (arg[5]), val_number (arg[6]));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_rel_line_to (value handle, value dx, value dy) {
		
		cairo_rel_line_to ((cairo_t*)(intptr_t)val_float (handle), val_number (dx), val_number (dy));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_rel_move_to (value handle, value dx, value dy) {
		
		cairo_rel_move_to ((cairo_t*)(intptr_t)val_float (handle), val_number (dx), val_number (dy));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_reset_clip (value handle) {
		
		cairo_reset_clip ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_restore (value handle) {
		
		cairo_restore ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_save (value handle) {
		
		cairo_save ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_antialias (value handle, value cap) {
		
		cairo_set_antialias ((cairo_t*)(intptr_t)val_float (handle), (cairo_antialias_t)val_int (cap));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_dash (value handle, value dash) {
		
		int length = val_array_size (dash);
		
		double* dashPattern = new double[length];
		
		for (int i = 0; i < length; i++) {
			
			dashPattern[i] = val_number (val_array_i (dash, i));
			
		}
		
		cairo_set_dash ((cairo_t*)(intptr_t)val_float (handle), dashPattern, length, 0);
		delete dashPattern;
		return alloc_null ();
		
	}
	
	value lime_cairo_set_font_face (value handle, value face) {
		
		cairo_set_font_face ((cairo_t*)(intptr_t)val_float (handle), (cairo_font_face_t*)(intptr_t)val_float (face) );
		return alloc_null ();
		
	}
	
	value lime_cairo_set_font_size (value handle, value size) {
		
		cairo_set_font_size ((cairo_t*)(intptr_t)val_float (handle), val_number(size) );
		return alloc_null ();
		
	}
	
	value lime_cairo_set_font_options (value handle, value options) {
		
		cairo_set_font_options ((cairo_t*)(intptr_t)val_float (handle), (cairo_font_options_t*)(intptr_t)val_float (options) );
		return alloc_null ();
		
	}
	
	value lime_cairo_set_fill_rule (value handle, value cap) {
		
		cairo_set_fill_rule ((cairo_t*)(intptr_t)val_float (handle), (cairo_fill_rule_t)val_int (cap));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_line_cap (value handle, value cap) {
		
		cairo_set_line_cap ((cairo_t*)(intptr_t)val_float (handle), (cairo_line_cap_t)val_int (cap));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_line_join (value handle, value join) {
		
		cairo_set_line_join ((cairo_t*)(intptr_t)val_float (handle), (cairo_line_join_t)val_int (join));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_line_width (value handle, value width) {
		
		cairo_set_line_width ((cairo_t*)(intptr_t)val_float (handle), val_number (width));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_matrix (value handle, value matrix) {
		
		Matrix3 mat3 = Matrix3 (matrix);
		
		cairo_matrix_t cm;
		cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);
		
		cairo_set_matrix ((cairo_t*)(intptr_t)val_float (handle), &cm);
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_miter_limit (value handle, value miterLimit) {
		
		cairo_set_miter_limit ((cairo_t*)(intptr_t)val_float (handle), val_number (miterLimit));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_operator (value handle, value op) {
		
		cairo_set_operator ((cairo_t*)(intptr_t)val_float (handle), (cairo_operator_t)val_int (op));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_source (value handle, value pattern) {
		
		cairo_set_source ((cairo_t*)(intptr_t)val_float (handle), (cairo_pattern_t*)(intptr_t)val_float (pattern));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_source_rgb (value handle, value r, value g, value b) {
		
		cairo_set_source_rgb ((cairo_t*)(intptr_t)val_float (handle), val_number (r), val_number (g), val_number (b));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_source_rgba (value handle, value r, value g, value b, value a) {
		
		cairo_set_source_rgba ((cairo_t*)(intptr_t)val_float (handle), val_number (r), val_number (g), val_number (b), val_number (a));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_source_surface (value handle, value surface, value x, value y) {
		
		cairo_set_source_surface ((cairo_t*)(intptr_t)val_float (handle), (cairo_surface_t*)(intptr_t)val_float (surface), val_number (x), val_number (y));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_set_tolerance (value handle, value tolerance) {
		
		cairo_set_tolerance ((cairo_t*)(intptr_t)val_float (handle), val_number (tolerance));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_show_page (value handle) {
		
		cairo_show_page ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	value lime_cairo_show_text (value handle, value text) {
				
		cairo_show_text( (cairo_t*)(intptr_t)val_float (handle), (char*)val_string(text) );
		return alloc_null ();
		
	}
	
	
	value lime_cairo_status (value handle) {
		
		return alloc_int (cairo_status ((cairo_t*)(intptr_t)val_float (handle)));
		
	}
	
	
	value lime_cairo_stroke (value handle) {
		
		cairo_stroke ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_stroke_extents (value handle, value x1, value y1, value x2, value y2) {
		
		double _x1 = val_number (x1);
		double _y1 = val_number (y1);
		double _x2 = val_number (x2);
		double _y2 = val_number (y2);
		
		cairo_stroke_extents ((cairo_t*)(intptr_t)val_float (handle), &_x1, &_y1, &_x2, &_y2);
		return alloc_null ();
		
	}
	
	
	value lime_cairo_stroke_preserve (value handle) {
		
		cairo_stroke_preserve ((cairo_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_surface_destroy (value handle) {
		
		cairo_surface_destroy ((cairo_surface_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_surface_flush (value handle) {
		
		cairo_surface_flush ((cairo_surface_t*)(intptr_t)val_float (handle));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_transform (value handle, value matrix) {
		
		Matrix3 mat3 = Matrix3 (matrix);
		
		cairo_matrix_t cm;
		cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);
		
		cairo_transform ((cairo_t*)(intptr_t)val_float (handle), &cm);
		return alloc_null ();
		
	}
	
	value lime_cairo_rotate (value handle, value amount) {
		
		cairo_rotate ((cairo_t*)(intptr_t)val_float (handle), val_number (amount));
		return alloc_null ();
		
	}
	
	value lime_cairo_scale (value handle, value x, value y) {
		
		cairo_scale ((cairo_t*)(intptr_t)val_float (handle), val_number (x), val_number (y));
		return alloc_null ();
		
	}
	
	value lime_cairo_translate (value handle, value x, value y) {
		
		cairo_translate ((cairo_t*)(intptr_t)val_float (handle), val_number (x), val_number (y));
		return alloc_null ();
		
	}
	
	
	value lime_cairo_version () {
		
		return alloc_int (cairo_version ());
		
	}
	
	
	value lime_cairo_version_string () {
		
		return alloc_string (cairo_version_string ());
		
	}
	
	#ifdef LIME_FREETYPE
	value lime_cairo_ft_font_face_create_for_ft_face( value face, value flags ) {
		
		Font *font = (Font*)(intptr_t)val_float (face);
		
		return alloc_float ((intptr_t)cairo_ft_font_face_create_for_ft_face( (FT_Face)(font->face), val_int( flags ) ));
		
	}
	#endif
	
	
	DEFINE_PRIM_MULT (lime_cairo_arc);
	DEFINE_PRIM_MULT (lime_cairo_arc_negative);
	DEFINE_PRIM (lime_cairo_clip, 1);
	DEFINE_PRIM (lime_cairo_clip_extents, 5);
	DEFINE_PRIM (lime_cairo_clip_preserve, 1);
	DEFINE_PRIM (lime_cairo_close_path, 1);
	DEFINE_PRIM (lime_cairo_copy_page, 1);
	DEFINE_PRIM (lime_cairo_create, 1);
	DEFINE_PRIM_MULT (lime_cairo_curve_to);
	DEFINE_PRIM (lime_cairo_destroy, 1);
	DEFINE_PRIM (lime_cairo_fill, 1);
	DEFINE_PRIM (lime_cairo_fill_extents, 5);
	DEFINE_PRIM (lime_cairo_fill_preserve, 1);
	DEFINE_PRIM (lime_cairo_ft_font_face_create_for_ft_face, 2);
	DEFINE_PRIM (lime_cairo_font_face_destroy, 1);
	DEFINE_PRIM (lime_cairo_font_options_create, 0);
	DEFINE_PRIM (lime_cairo_font_options_get_antialias, 1);
	DEFINE_PRIM (lime_cairo_font_options_get_subpixel_order, 1);
	DEFINE_PRIM (lime_cairo_font_options_get_hint_style, 1);
	DEFINE_PRIM (lime_cairo_font_options_get_hint_metrics, 1);
	DEFINE_PRIM (lime_cairo_font_options_set_antialias, 2);
	DEFINE_PRIM (lime_cairo_font_options_set_subpixel_order, 2);
	DEFINE_PRIM (lime_cairo_font_options_set_hint_style, 2);
	DEFINE_PRIM (lime_cairo_font_options_set_hint_metrics, 2);
	DEFINE_PRIM (lime_cairo_get_antialias, 1);
	DEFINE_PRIM (lime_cairo_get_current_point, 1);
	DEFINE_PRIM (lime_cairo_get_dash, 1);
	DEFINE_PRIM (lime_cairo_get_dash_count, 1);
	DEFINE_PRIM (lime_cairo_get_fill_rule, 1);
	DEFINE_PRIM (lime_cairo_get_font_options, 1);	
	DEFINE_PRIM (lime_cairo_get_group_target, 1);
	DEFINE_PRIM (lime_cairo_get_line_cap, 1);
	DEFINE_PRIM (lime_cairo_get_line_join, 1);
	DEFINE_PRIM (lime_cairo_get_line_width, 1);
	DEFINE_PRIM (lime_cairo_get_matrix, 1);
	DEFINE_PRIM (lime_cairo_get_miter_limit, 1);
	DEFINE_PRIM (lime_cairo_get_operator, 1);
	DEFINE_PRIM (lime_cairo_get_reference_count, 1);
	DEFINE_PRIM (lime_cairo_get_source, 1);
	DEFINE_PRIM (lime_cairo_get_target, 1);
	DEFINE_PRIM (lime_cairo_get_tolerance, 1);
	DEFINE_PRIM (lime_cairo_has_current_point, 1);
	DEFINE_PRIM (lime_cairo_identity_matrix, 1);
	DEFINE_PRIM (lime_cairo_image_surface_create, 3);
	DEFINE_PRIM (lime_cairo_image_surface_create_for_data, 5);
	DEFINE_PRIM (lime_cairo_image_surface_get_height, 1);
	DEFINE_PRIM (lime_cairo_image_surface_get_width, 1);
	DEFINE_PRIM (lime_cairo_in_clip, 3);
	DEFINE_PRIM (lime_cairo_in_fill, 3);
	DEFINE_PRIM (lime_cairo_in_stroke, 3);
	DEFINE_PRIM (lime_cairo_line_to, 3);
	DEFINE_PRIM (lime_cairo_mask, 2);
	DEFINE_PRIM (lime_cairo_mask_surface, 4);
	DEFINE_PRIM (lime_cairo_move_to, 3);
	DEFINE_PRIM (lime_cairo_new_path, 1);
	DEFINE_PRIM (lime_cairo_paint, 1);
	DEFINE_PRIM (lime_cairo_paint_with_alpha, 2);
	DEFINE_PRIM (lime_cairo_pattern_add_color_stop_rgb, 5);
	DEFINE_PRIM_MULT (lime_cairo_pattern_add_color_stop_rgba);
	DEFINE_PRIM (lime_cairo_pattern_create_for_surface, 1);
	DEFINE_PRIM (lime_cairo_pattern_create_linear, 4);
	DEFINE_PRIM_MULT (lime_cairo_pattern_create_radial);
	DEFINE_PRIM (lime_cairo_pattern_create_rgb, 3);
	DEFINE_PRIM (lime_cairo_pattern_create_rgba, 4);
	DEFINE_PRIM (lime_cairo_pattern_destroy, 1);
	DEFINE_PRIM (lime_cairo_pattern_get_color_stop_count, 1);
	DEFINE_PRIM (lime_cairo_pattern_get_extend, 1);
	DEFINE_PRIM (lime_cairo_pattern_get_filter, 1);
	DEFINE_PRIM (lime_cairo_pattern_get_matrix, 1);
	DEFINE_PRIM (lime_cairo_pattern_set_extend, 2);
	DEFINE_PRIM (lime_cairo_pattern_set_filter, 2);
	DEFINE_PRIM (lime_cairo_pattern_set_matrix, 2);
	DEFINE_PRIM (lime_cairo_pop_group, 1);
	DEFINE_PRIM (lime_cairo_pop_group_to_source, 1);
	DEFINE_PRIM (lime_cairo_push_group, 1);
	DEFINE_PRIM (lime_cairo_push_group_with_content, 2);
	DEFINE_PRIM (lime_cairo_rectangle, 5);
	DEFINE_PRIM (lime_cairo_reference, 1);
	DEFINE_PRIM_MULT (lime_cairo_rel_curve_to);
	DEFINE_PRIM (lime_cairo_rel_line_to, 3);
	DEFINE_PRIM (lime_cairo_rel_move_to, 3);
	DEFINE_PRIM (lime_cairo_reset_clip, 1);
	DEFINE_PRIM (lime_cairo_restore, 1);
	DEFINE_PRIM (lime_cairo_save, 1);
	DEFINE_PRIM (lime_cairo_set_antialias, 2);
	DEFINE_PRIM (lime_cairo_set_dash, 2);
	DEFINE_PRIM (lime_cairo_set_fill_rule, 2);
	DEFINE_PRIM (lime_cairo_set_font_face, 2);
	DEFINE_PRIM (lime_cairo_set_font_size, 2);
	DEFINE_PRIM (lime_cairo_set_font_options, 2);
	DEFINE_PRIM (lime_cairo_set_line_cap, 2);
	DEFINE_PRIM (lime_cairo_set_line_join, 2);
	DEFINE_PRIM (lime_cairo_set_line_width, 2);
	DEFINE_PRIM (lime_cairo_set_matrix, 2);
	DEFINE_PRIM (lime_cairo_set_miter_limit, 2);
	DEFINE_PRIM (lime_cairo_set_operator, 2);
	DEFINE_PRIM (lime_cairo_set_source, 2);
	DEFINE_PRIM (lime_cairo_set_source_rgb, 4);
	DEFINE_PRIM (lime_cairo_set_source_rgba, 5);
	DEFINE_PRIM (lime_cairo_set_source_surface, 4);
	DEFINE_PRIM (lime_cairo_set_tolerance, 2);
	DEFINE_PRIM (lime_cairo_show_page, 1);
	DEFINE_PRIM (lime_cairo_show_text, 2);
	DEFINE_PRIM (lime_cairo_status, 1);
	DEFINE_PRIM (lime_cairo_stroke, 1);
	DEFINE_PRIM (lime_cairo_stroke_extents, 5);
	DEFINE_PRIM (lime_cairo_stroke_preserve, 1);
	DEFINE_PRIM (lime_cairo_surface_destroy, 1);
	DEFINE_PRIM (lime_cairo_surface_flush, 1);
	DEFINE_PRIM (lime_cairo_transform, 2);
	DEFINE_PRIM (lime_cairo_rotate, 2);
	DEFINE_PRIM (lime_cairo_scale, 3);
	DEFINE_PRIM (lime_cairo_translate, 3);
	DEFINE_PRIM (lime_cairo_version, 0);
	DEFINE_PRIM (lime_cairo_version_string, 0);
	
	
}


extern "C" int lime_cairo_register_prims () {
	
	return 0;
	
}