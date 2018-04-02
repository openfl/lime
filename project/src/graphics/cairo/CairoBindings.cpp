#include <cairo.h>
#include <cairo-ft.h>
#include <map>
#include <math/Matrix3.h>
#include <math/Vector2.h>
#include <hx/CFFIPrime.h>
#include <system/CFFIPointer.h>
#include <system/Mutex.h>
#include <text/Font.h>


namespace lime {
	
	
	static int id_index;
	static int id_x;
	static int id_y;
	static bool init = false;
	cairo_user_data_key_t userData;
	std::map<void*, value> cairoObjects;
	Mutex cairoObjects_Mutex;
	
	
	void gc_cairo (value handle) {
		
		if (!val_is_null (handle)) {
			
			cairo_t* cairo = (cairo_t*)val_data (handle);
			cairoObjects_Mutex.Lock ();
			cairoObjects.erase (cairo);
			cairoObjects_Mutex.Unlock ();
			cairo_destroy (cairo);
			
		}
		
	}
	
	
	void gc_cairo_font_face (value handle) {
		
		if (!val_is_null (handle)) {
			
			cairo_font_face_t* face = (cairo_font_face_t*)val_data (handle);
			cairoObjects_Mutex.Lock ();
			cairoObjects.erase (face);
			cairoObjects_Mutex.Unlock ();
			cairo_font_face_destroy (face);
			
		}
		
	}
	
	
	void gc_cairo_font_options (value handle) {
		
		if (!val_is_null (handle)) {
			
			cairo_font_options_t* options = (cairo_font_options_t*)val_data (handle);
			cairo_font_options_destroy (options);
			
		}
		
	}
	
	
	void gc_cairo_pattern (value handle) {
		
		if (!val_is_null (handle)) {
			
			cairo_pattern_t* pattern = (cairo_pattern_t*)val_data (handle);
			cairoObjects_Mutex.Lock ();
			cairoObjects.erase (pattern);
			cairoObjects_Mutex.Unlock ();
			cairo_pattern_destroy (pattern);
			
		}
		
	}
	
	
	void gc_cairo_surface (value handle) {
		
		if (!val_is_null (handle)) {
			
			cairo_surface_t* surface = (cairo_surface_t*)val_data (handle);
			cairoObjects_Mutex.Lock ();
			cairoObjects.erase (surface);
			cairoObjects_Mutex.Unlock ();
			cairo_surface_destroy (surface);
			
		}
		
	}
	
	
	void gc_user_data (void* data) {
		
		AutoGCRoot* reference = (AutoGCRoot*)data;
		delete reference;
		
	}
	
	
	void lime_cairo_arc (value handle, double xc, double yc, double radius, double angle1, double angle2) {
		
		cairo_arc ((cairo_t*)val_data (handle), xc, yc, radius, angle1, angle2);
		
	}
	
	
	void lime_cairo_arc_negative (value handle, double xc, double yc, double radius, double angle1, double angle2) {
		
		cairo_arc_negative ((cairo_t*)val_data (handle), xc, yc, radius, angle1, angle2);
		
	}
	
	
	void lime_cairo_clip (value handle) {
		
		cairo_clip ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_clip_extents (value handle, double x1, double y1, double x2, double y2) {
		
		cairo_clip_extents ((cairo_t*)val_data (handle), &x1, &y1, &x2, &y2);
		
	}
	
	
	void lime_cairo_clip_preserve (value handle) {
		
		cairo_clip_preserve ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_close_path (value handle) {
		
		cairo_close_path ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_copy_page (value handle) {
		
		cairo_copy_page ((cairo_t*)val_data (handle));
		
	}
	
	
	value lime_cairo_create (value surface) {
		
		cairo_t* cairo = cairo_create ((cairo_surface_t*)val_data (surface));
		
		value object = CFFIPointer (cairo, gc_cairo);
		cairoObjects_Mutex.Lock ();
		cairoObjects[cairo] = object;
		cairoObjects_Mutex.Unlock ();
		return object;
		
	}
	
	
	void lime_cairo_curve_to (value handle, double x1, double y1, double x2, double y2, double x3, double y3) {
		
		cairo_curve_to ((cairo_t*)val_data (handle), x1, y1, x2, y2, x3, y3);
		
	}
	
	
	void lime_cairo_fill (value handle) {
		
		cairo_fill ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_fill_extents (value handle, double x1, double y1, double x2, double y2) {
		
		cairo_fill_extents ((cairo_t*)val_data (handle), &x1, &y1, &x2, &y2);
		
	}
	
	
	void lime_cairo_fill_preserve (value handle) {
		
		cairo_fill_preserve ((cairo_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_font_face_status (value handle) {
		
		return cairo_font_face_status ((cairo_font_face_t*)val_data (handle));
		
	}
	
	
	value lime_cairo_font_options_create () {
		
		cairo_font_options_t* options = cairo_font_options_create ();
		return CFFIPointer (options, gc_cairo_font_options);
		
	}
	
	
	int lime_cairo_font_options_get_antialias (value handle) {
		
		return cairo_font_options_get_antialias ((cairo_font_options_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_font_options_get_hint_metrics (value handle) {
		
		return cairo_font_options_get_hint_metrics ((cairo_font_options_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_font_options_get_hint_style (value handle) {
		
		return cairo_font_options_get_hint_style ((cairo_font_options_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_font_options_get_subpixel_order (value handle) {
		
		return cairo_font_options_get_subpixel_order ((cairo_font_options_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_font_options_set_antialias (value handle, int v) {
		
		cairo_font_options_set_antialias ((cairo_font_options_t*)val_data (handle), (cairo_antialias_t)v);
		
	}
	
	
	void lime_cairo_font_options_set_hint_metrics (value handle, int v) {
		
		cairo_font_options_set_hint_metrics ((cairo_font_options_t*)val_data (handle), (cairo_hint_metrics_t)v);
		
	}
	
	
	void lime_cairo_font_options_set_hint_style (value handle, int v) {
		
		cairo_font_options_set_hint_style ((cairo_font_options_t*)val_data (handle), (cairo_hint_style_t)v);
		
	}
	
	
	void lime_cairo_font_options_set_subpixel_order (value handle, int v) {
		
		cairo_font_options_set_subpixel_order ((cairo_font_options_t*)val_data (handle), (cairo_subpixel_order_t)v);
		
	}
	
	
	value lime_cairo_ft_font_face_create (value face, int flags) {
		
		#ifdef LIME_FREETYPE
		Font* font = (Font*)val_data (face);
		cairo_font_face_t* cairoFont = cairo_ft_font_face_create_for_ft_face ((FT_Face)font->face, flags);
		
		AutoGCRoot* fontReference = new AutoGCRoot (face);
		cairo_font_face_set_user_data (cairoFont, &userData, fontReference, gc_user_data);
		
		value object = CFFIPointer (cairoFont, gc_cairo_font_face);
		cairoObjects_Mutex.Lock ();
		cairoObjects[cairoFont] = object;
		cairoObjects_Mutex.Unlock ();
		return object;
		#else
		return 0;
		#endif
		
	}
	
	
	int lime_cairo_get_antialias (value handle) {
		
		return cairo_get_antialias ((cairo_t*)val_data (handle));
		
	}
	
	
	value lime_cairo_get_current_point (value handle) {
		
		double x, y;
		cairo_get_current_point ((cairo_t*)val_data (handle), &x, &y);
		Vector2 vec2 = Vector2 (x, y);
		return vec2.Value ();
		
	}
	
	
	value lime_cairo_get_dash (value handle) {
		
		int length = cairo_get_dash_count ((cairo_t*)val_data (handle));
		
		double* dashes = new double[length];
		double offset;
		
		cairo_get_dash ((cairo_t*)val_data (handle), dashes, &offset);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; i++) {
			
			val_array_set_i (result, i, alloc_float (dashes[i]));
			
		}
		
		delete[] dashes;
		return result;
		
	}
	
	
	int lime_cairo_get_dash_count (value handle) {
		
		return cairo_get_dash_count ((cairo_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_get_fill_rule (value handle) {
		
		return cairo_get_fill_rule ((cairo_t*)val_data (handle));
		
	}
	
	
	value lime_cairo_get_font_face (value handle) {
		
		cairo_font_face_t* face = cairo_get_font_face ((cairo_t*)val_data (handle));
		
		if (cairoObjects.find (face) != cairoObjects.end ()) {
			
			return cairoObjects[face];
			
		} else {
			
			cairo_font_face_reference (face);
			
			value object = CFFIPointer (face, gc_cairo_font_face);
			cairoObjects_Mutex.Lock ();
			cairoObjects[face] = object;
			cairoObjects_Mutex.Unlock ();
			return object;
			
		}
		
	}
	
	
	value lime_cairo_get_font_options (value handle) {
		
		cairo_font_options_t* options = 0;
		cairo_get_font_options ((cairo_t*)val_data (handle), options);
		return CFFIPointer (options, gc_cairo_font_options);
		
	}
	
	
	value lime_cairo_get_group_target (value handle) {
		
		cairo_surface_t* surface = cairo_get_group_target ((cairo_t*)val_data (handle));
		
		if (cairoObjects.find (surface) != cairoObjects.end ()) {
			
			return cairoObjects[surface];
			
		} else {
			
			cairo_surface_reference (surface);
			
			value object = CFFIPointer (surface, gc_cairo_surface);
			cairoObjects_Mutex.Lock ();
			cairoObjects[surface] = object;
			cairoObjects_Mutex.Unlock ();
			return object;
			
		}
		
	}
	
	
	int lime_cairo_get_line_cap (value handle) {
		
		return cairo_get_line_cap ((cairo_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_get_line_join (value handle) {
		
		return cairo_get_line_join ((cairo_t*)val_data (handle));
		
	}
	
	
	double lime_cairo_get_line_width (value handle) {
		
		return cairo_get_line_width ((cairo_t*)val_data (handle));
		
	}
	
	
	value lime_cairo_get_matrix (value handle) {
		
		cairo_matrix_t cm;
		cairo_get_matrix ((cairo_t*)val_data (handle), &cm);
		Matrix3 mat3 = Matrix3 (cm.xx, cm.yx, cm.xy, cm.yy, cm.x0, cm.y0);
		return mat3.Value ();
		
	}
	
	
	double lime_cairo_get_miter_limit (value handle) {
		
		return cairo_get_miter_limit ((cairo_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_get_operator (value handle) {
		
		return cairo_get_operator ((cairo_t*)val_data (handle));
		
	}
	
	
	value lime_cairo_get_source (value handle) {
		
		cairo_pattern_t* pattern = cairo_get_source ((cairo_t*)val_data (handle));
		
		if (cairoObjects.find (pattern) != cairoObjects.end ()) {
			
			return cairoObjects[pattern];
			
		} else {
			
			cairo_pattern_reference (pattern);
			
			value object = CFFIPointer (pattern, gc_cairo_pattern);
			cairoObjects_Mutex.Lock ();
			cairoObjects[pattern] = object;
			cairoObjects_Mutex.Unlock ();
			return object;
			
		}
		
	}
	
	
	value lime_cairo_get_target (value handle) {
		
		cairo_surface_t* surface = cairo_get_target ((cairo_t*)val_data (handle));
		
		if (cairoObjects.find (surface) != cairoObjects.end ()) {
			
			return cairoObjects[surface];
			
		} else {
			
			cairo_surface_reference (surface);
			
			value object = CFFIPointer (surface, gc_cairo_surface);
			cairoObjects_Mutex.Lock ();
			cairoObjects[surface] = object;
			cairoObjects_Mutex.Unlock ();
			return object;
			
		}
		
	}
	
	
	double lime_cairo_get_tolerance (value handle) {
		
		return cairo_get_tolerance ((cairo_t*)val_data (handle));
		
	}
	
	
	bool lime_cairo_has_current_point (value handle) {
		
		return cairo_has_current_point ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_identity_matrix (value handle) {
		
		cairo_identity_matrix ((cairo_t*)val_data (handle));
		
	}
	
	
	value lime_cairo_image_surface_create (int format, int width, int height) {
		
		cairo_surface_t* surface = cairo_image_surface_create ((cairo_format_t)format, width, height);
		
		value object = CFFIPointer (surface, gc_cairo_surface);
		cairoObjects_Mutex.Lock ();
		cairoObjects[surface] = object;
		cairoObjects_Mutex.Unlock ();
		return object;
		
	}
	
	
	value lime_cairo_image_surface_create_for_data (double data, int format, int width, int height, int stride) {
		
		cairo_surface_t* surface = cairo_image_surface_create_for_data ((unsigned char*)(uintptr_t)data, (cairo_format_t)format, width, height, stride);
		
		value object = CFFIPointer (surface, gc_cairo_surface);
		cairoObjects_Mutex.Lock ();
		cairoObjects[surface] = object;
		cairoObjects_Mutex.Unlock ();
		return object;
		
	}
	
	
	double lime_cairo_image_surface_get_data (value handle) {
		
		return (uintptr_t)cairo_image_surface_get_data ((cairo_surface_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_image_surface_get_format (value handle) {
		
		return (int)cairo_image_surface_get_format ((cairo_surface_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_image_surface_get_height (value handle) {
		
		return cairo_image_surface_get_height ((cairo_surface_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_image_surface_get_stride (value handle) {
		
		return cairo_image_surface_get_stride ((cairo_surface_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_image_surface_get_width (value handle) {
		
		return cairo_image_surface_get_width ((cairo_surface_t*)val_data (handle));
		
	}
	
	
	bool lime_cairo_in_clip (value handle, double x, double y) {
		
		return cairo_in_clip ((cairo_t*)val_data (handle), x, y);
		
	}
	
	
	bool lime_cairo_in_fill (value handle, double x, double y) {
		
		return cairo_in_fill ((cairo_t*)val_data (handle), x, y);
		
	}
	
	
	bool lime_cairo_in_stroke (value handle, double x, double y) {
		
		return cairo_in_stroke ((cairo_t*)val_data (handle), x, y);
		
	}
	
	
	void lime_cairo_line_to (value handle, double x, double y) {
		
		cairo_line_to ((cairo_t*)val_data (handle), x, y);
		
	}
	
	
	void lime_cairo_mask (value handle, value pattern) {
		
		cairo_mask ((cairo_t*)val_data (handle), (cairo_pattern_t*)val_data (pattern));
		
	}
	
	
	void lime_cairo_mask_surface (value handle, value surface, double x, double y) {
		
		cairo_mask_surface ((cairo_t*)val_data (handle), (cairo_surface_t*)val_data (surface), x, y);
		
	}
	
	
	void lime_cairo_move_to (value handle, double x, double y) {
		
		cairo_move_to ((cairo_t*)val_data (handle), x, y);
		
	}
	
	
	void lime_cairo_new_path (value handle) {
		
		cairo_new_path ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_paint (value handle) {
		
		cairo_paint ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_paint_with_alpha (value handle, double alpha) {
		
		cairo_paint_with_alpha ((cairo_t*)val_data (handle), alpha);
		
	}
	
	
	void lime_cairo_pattern_add_color_stop_rgb (value handle, double offset, double red, double green, double blue) {
		
		cairo_pattern_add_color_stop_rgb ((cairo_pattern_t*)val_data (handle), offset, red, green, blue);
		
	}
	
	
	void lime_cairo_pattern_add_color_stop_rgba (value handle, double offset, double red, double green, double blue, double alpha) {
		
		cairo_pattern_add_color_stop_rgba ((cairo_pattern_t*)val_data (handle), offset, red, green, blue, alpha);
		
	}
	
	
	value lime_cairo_pattern_create_for_surface (value surface) {
		
		cairo_pattern_t* pattern = cairo_pattern_create_for_surface ((cairo_surface_t*)val_data (surface));
		
		value object = CFFIPointer (pattern, gc_cairo_pattern);
		cairoObjects_Mutex.Lock ();
		cairoObjects[pattern] = object;
		cairoObjects_Mutex.Unlock ();
		return object;
		
	}
	
	
	value lime_cairo_pattern_create_linear (double x0, double y0, double x1, double y1) {
		
		cairo_pattern_t* pattern = cairo_pattern_create_linear (x0, y0, x1, y1);
		
		value object = CFFIPointer (pattern, gc_cairo_pattern);
		cairoObjects_Mutex.Lock ();
		cairoObjects[pattern] = object;
		cairoObjects_Mutex.Unlock ();
		return object;
		
	}
	
	
	value lime_cairo_pattern_create_radial (double cx0, double cy0, double radius0, double cx1, double cy1, double radius1) {
		
		cairo_pattern_t* pattern = cairo_pattern_create_radial (cx0, cy0, radius0, cx1, cy1, radius1);
		
		value object = CFFIPointer (pattern, gc_cairo_pattern);
		cairoObjects_Mutex.Lock ();
		cairoObjects[pattern] = object;
		cairoObjects_Mutex.Unlock ();
		return object;
		
	}
	
	
	value lime_cairo_pattern_create_rgb (double r, double g, double b) {
		
		cairo_pattern_t* pattern = cairo_pattern_create_rgb (r, g, b);
		
		value object = CFFIPointer (pattern, gc_cairo_pattern);
		cairoObjects_Mutex.Lock ();
		cairoObjects[pattern] = object;
		cairoObjects_Mutex.Unlock ();
		return object;
		
	}
	
	
	value lime_cairo_pattern_create_rgba (double r, double g, double b, double a) {
		
		cairo_pattern_t* pattern = cairo_pattern_create_rgba (r, g, b, a);
		
		value object = CFFIPointer (pattern, gc_cairo_pattern);
		cairoObjects_Mutex.Lock ();
		cairoObjects[pattern] = object;
		cairoObjects_Mutex.Unlock ();
		return object;
		
	}
	
	
	int lime_cairo_pattern_get_color_stop_count (value handle) {
		
		int count;
		cairo_pattern_get_color_stop_count ((cairo_pattern_t*)val_data (handle), &count);
		return count;
		
	}
	
	
	int lime_cairo_pattern_get_extend (value handle) {
		
		return cairo_pattern_get_extend ((cairo_pattern_t*)val_data (handle));
		
	}
	
	
	int lime_cairo_pattern_get_filter (value handle) {
		
		return cairo_pattern_get_filter ((cairo_pattern_t*)val_data (handle));
		
	}
	
	
	value lime_cairo_pattern_get_matrix (value handle) {
		
		cairo_matrix_t cm;
		cairo_pattern_get_matrix ((cairo_pattern_t*)val_data (handle), &cm);
		Matrix3 mat3 = Matrix3 (cm.xx, cm.yx, cm.xy, cm.yy, cm.x0, cm.y0);
		return mat3.Value ();
		
	}
	
	
	void lime_cairo_pattern_set_extend (value handle, int extend) {
		
		cairo_pattern_set_extend ((cairo_pattern_t*)val_data (handle), (cairo_extend_t)extend);
		
	}
	
	
	void lime_cairo_pattern_set_filter (value handle, int filter) {
		
		cairo_pattern_set_filter ((cairo_pattern_t*)val_data (handle), (cairo_filter_t)filter);
		
	}
	
	
	void lime_cairo_pattern_set_matrix (value handle, value matrix) {
		
		Matrix3 mat3 = Matrix3 (matrix);
		
		cairo_matrix_t cm;
		cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);
		
		cairo_pattern_set_matrix ((cairo_pattern_t*)val_data (handle), &cm);
		
	}
	
	
	value lime_cairo_pop_group (value handle) {
		
		cairo_pattern_t* pattern = cairo_pop_group ((cairo_t*)val_data (handle));
		
		if (cairoObjects.find (pattern) != cairoObjects.end ()) {
			
			return cairoObjects[pattern];
			
		} else {
			
			cairo_pattern_reference (pattern);
			
			value object = CFFIPointer (pattern, gc_cairo_pattern);
			cairoObjects_Mutex.Lock ();
			cairoObjects[pattern] = object;
			cairoObjects_Mutex.Unlock ();
			return object;
			
		}
		
	}
	
	
	void lime_cairo_pop_group_to_source (value handle) {
		
		cairo_pop_group_to_source ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_push_group (value handle) {
		
		cairo_push_group ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_push_group_with_content (value handle, int content) {
		
		cairo_push_group_with_content ((cairo_t*)val_data (handle), (cairo_content_t)content);
		
	}
	
	
	void lime_cairo_rectangle (value handle, double x, double y, double width, double height) {
		
		cairo_rectangle ((cairo_t*)val_data (handle), x, y, width, height);
		
	}
	
	
	void lime_cairo_rel_curve_to (value handle, double dx1, double dy1, double dx2, double dy2, double dx3, double dy3) {
		
		cairo_rel_curve_to ((cairo_t*)val_data (handle), dx1, dy1, dx2, dy2, dx3, dy3);
		
	}
	
	
	void lime_cairo_rel_line_to (value handle, double dx, double dy) {
		
		cairo_rel_line_to ((cairo_t*)val_data (handle), dx, dy);
		
	}
	
	
	void lime_cairo_rel_move_to (value handle, double dx, double dy) {
		
		cairo_rel_move_to ((cairo_t*)val_data (handle), dx, dy);
		
	}
	
	
	void lime_cairo_reset_clip (value handle) {
		
		cairo_reset_clip ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_restore (value handle) {
		
		cairo_restore ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_rotate (value handle, double amount) {
		
		cairo_rotate ((cairo_t*)val_data (handle), amount);
		
	}
	
	
	void lime_cairo_save (value handle) {
		
		cairo_save ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_scale (value handle, double x, double y) {
		
		cairo_scale ((cairo_t*)val_data (handle), x, y);
		
	}
	
	
	void lime_cairo_set_antialias (value handle, int cap) {
		
		cairo_set_antialias ((cairo_t*)val_data (handle), (cairo_antialias_t)cap);
		
	}
	
	
	void lime_cairo_set_dash (value handle, value dash) {
		
		int length = val_array_size (dash);
		
		double* dashPattern = new double[length];
		
		for (int i = 0; i < length; i++) {
			
			dashPattern[i] = val_number (val_array_i (dash, i));
			
		}
		
		cairo_set_dash ((cairo_t*)val_data (handle), dashPattern, length, 0);
		delete[] dashPattern;
		
	}
	
	
	void lime_cairo_set_fill_rule (value handle, int cap) {
		
		cairo_set_fill_rule ((cairo_t*)val_data (handle), (cairo_fill_rule_t)cap);
		
	}
	
	
	void lime_cairo_set_font_face (value handle, value face) {
		
		cairo_set_font_face ((cairo_t*)val_data (handle), (cairo_font_face_t*)val_data (face));
		
	}
	
	
	void lime_cairo_set_font_options (value handle, value options) {
		
		cairo_set_font_options ((cairo_t*)val_data (handle), (cairo_font_options_t*)val_data (options));
		
	}
	
	
	void lime_cairo_set_font_size (value handle, double size) {
		
		cairo_font_face_t* face = cairo_get_font_face ((cairo_t*)val_data (handle));
		
		if (face) {
			
			cairo_font_type_t type = cairo_font_face_get_type (face);
			
			if (type == CAIRO_FONT_TYPE_FT) {
				
				AutoGCRoot* fontReference = (AutoGCRoot*)cairo_font_face_get_user_data (face, &userData);
				
				if (fontReference) {
					
					Font* font = (Font*)val_data (fontReference->get ());
					font->SetSize (size);
					
				}
				
			}
			
		}
		
		cairo_set_font_size ((cairo_t*)val_data (handle), size);
		
	}
	
	
	void lime_cairo_set_line_cap (value handle, int cap) {
		
		cairo_set_line_cap ((cairo_t*)val_data (handle), (cairo_line_cap_t)cap);
		
	}
	
	
	void lime_cairo_set_line_join (value handle, int join) {
		
		cairo_set_line_join ((cairo_t*)val_data (handle), (cairo_line_join_t)join);
		
	}
	
	
	void lime_cairo_set_line_width (value handle, double width) {
		
		cairo_set_line_width ((cairo_t*)val_data (handle), width);
		
	}
	
	
	void lime_cairo_set_matrix (value handle, double a, double b, double c, double d, double tx, double ty) {
		
		cairo_matrix_t cm;
		cairo_matrix_init (&cm, a, b, c, d, tx, ty);
		
		cairo_set_matrix ((cairo_t*)val_data (handle), &cm);
		
	}
	
	
	/*void lime_cairo_set_matrix (value handle, value matrix) {
		
		Matrix3 mat3 = Matrix3 (matrix);
		
		cairo_matrix_t cm;
		cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);
		
		cairo_set_matrix ((cairo_t*)val_data (handle), &cm);
		
	}*/
	
	
	void lime_cairo_set_miter_limit (value handle, double miterLimit) {
		
		cairo_set_miter_limit ((cairo_t*)val_data (handle), miterLimit);
		
	}
	
	
	void lime_cairo_set_operator (value handle, int op) {
		
		cairo_set_operator ((cairo_t*)val_data (handle), (cairo_operator_t)op);
		
	}
	
	
	void lime_cairo_set_source (value handle, value pattern) {
		
		cairo_set_source ((cairo_t*)val_data (handle), (cairo_pattern_t*)val_data (pattern));
		
	}
	
	
	void lime_cairo_set_source_rgb (value handle, double r, double g, double b) {
		
		cairo_set_source_rgb ((cairo_t*)val_data (handle), r, g, b);
		
	}
	
	
	void lime_cairo_set_source_rgba (value handle, double r, double g, double b, double a) {
		
		cairo_set_source_rgba ((cairo_t*)val_data (handle), r, g, b, a);
		
	}
	
	
	void lime_cairo_set_source_surface (value handle, value surface, double x, double y) {
		
		cairo_set_source_surface ((cairo_t*)val_data (handle), (cairo_surface_t*)val_data (surface), x, y);
		
	}
	
	
	void lime_cairo_set_tolerance (value handle, double tolerance) {
		
		cairo_set_tolerance ((cairo_t*)val_data (handle), tolerance);
		
	}
	
	
	void lime_cairo_show_glyphs (value handle, value glyphs) {
		
		if (!init) {
			
			id_index = val_id ("index");
			id_x = val_id ("x");
			id_y = val_id ("y");
			
		}
		
		int length = val_array_size (glyphs);
		cairo_glyph_t* _glyphs = cairo_glyph_allocate (length);
		
		value glyph;
		
		for (int i = 0; i < length; i++) {
			
			glyph = val_array_i (glyphs, i);
			_glyphs[i].index = val_int (val_field (glyph, id_index));
			_glyphs[i].x = val_number (val_field (glyph, id_x));
			_glyphs[i].y = val_number (val_field (glyph, id_y));
			
		}
		
		cairo_show_glyphs ((cairo_t*)val_data (handle), _glyphs, length);
		cairo_glyph_free (_glyphs);
		
	}
	
	
	void lime_cairo_show_page (value handle) {
		
		cairo_show_page ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_show_text (value handle, HxString text) {
		
		cairo_show_text ((cairo_t*)val_data (handle), (char*)text.__s);
		
	}
	
	
	int lime_cairo_status (value handle) {
		
		return cairo_status ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_stroke (value handle) {
		
		cairo_stroke ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_stroke_extents (value handle, double x1, double y1, double x2, double y2) {
		
		cairo_stroke_extents ((cairo_t*)val_data (handle), &x1, &y1, &x2, &y2);
		
	}
	
	
	void lime_cairo_stroke_preserve (value handle) {
		
		cairo_stroke_preserve ((cairo_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_surface_flush (value handle) {
		
		cairo_surface_flush ((cairo_surface_t*)val_data (handle));
		
	}
	
	
	void lime_cairo_text_path (value handle, HxString text) {
		
		cairo_text_path ((cairo_t*)val_data (handle), (char*)text.__s);
		
	}
	
	
	void lime_cairo_transform (value handle, value matrix) {
		
		Matrix3 mat3 = Matrix3 (matrix);
		
		cairo_matrix_t cm;
		cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);
		
		cairo_transform ((cairo_t*)val_data (handle), &cm);
		
	}
	
	
	void lime_cairo_translate (value handle, double x, double y) {
		
		cairo_translate ((cairo_t*)val_data (handle), x, y);
		
	}
	
	
	int lime_cairo_version () {
		
		return cairo_version ();
		
	}
	
	
	HxString lime_cairo_version_string () {
		
		const char* version = cairo_version_string ();
		return version ? HxString (version) : HxString (0, 0);
		
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
	DEFINE_PRIME1v (lime_cairo_fill);
	DEFINE_PRIME5v (lime_cairo_fill_extents);
	DEFINE_PRIME1v (lime_cairo_fill_preserve);
	DEFINE_PRIME2 (lime_cairo_ft_font_face_create);
	DEFINE_PRIME1 (lime_cairo_font_face_status);
	DEFINE_PRIME0 (lime_cairo_font_options_create);
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
	DEFINE_PRIME7v (lime_cairo_set_matrix);
	//DEFINE_PRIME2v (lime_cairo_set_matrix);
	DEFINE_PRIME2v (lime_cairo_set_miter_limit);
	DEFINE_PRIME2v (lime_cairo_set_operator);
	DEFINE_PRIME2v (lime_cairo_set_source);
	DEFINE_PRIME4v (lime_cairo_set_source_rgb);
	DEFINE_PRIME5v (lime_cairo_set_source_rgba);
	DEFINE_PRIME4v (lime_cairo_set_source_surface);
	DEFINE_PRIME2v (lime_cairo_set_tolerance);
	DEFINE_PRIME2v (lime_cairo_show_glyphs);
	DEFINE_PRIME1v (lime_cairo_show_page);
	DEFINE_PRIME2v (lime_cairo_show_text);
	DEFINE_PRIME1 (lime_cairo_status);
	DEFINE_PRIME1v (lime_cairo_stroke);
	DEFINE_PRIME5v (lime_cairo_stroke_extents);
	DEFINE_PRIME1v (lime_cairo_stroke_preserve);
	DEFINE_PRIME1v (lime_cairo_surface_flush);
	DEFINE_PRIME2v (lime_cairo_text_path);
	DEFINE_PRIME2v (lime_cairo_transform);
	DEFINE_PRIME3v (lime_cairo_translate);
	DEFINE_PRIME0 (lime_cairo_version);
	DEFINE_PRIME0 (lime_cairo_version_string);
	
	
}


extern "C" int lime_cairo_register_prims () {
	
	return 0;
	
}