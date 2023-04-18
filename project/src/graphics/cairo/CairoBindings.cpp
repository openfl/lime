#include <cairo.h>
#include <cairo-ft.h>
#include <map>
#include <math/Matrix3.h>
#include <math/Vector2.h>
#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <system/Mutex.h>
#include <system/ValuePointer.h>
#include <text/Font.h>


namespace lime {


	static int id_index;
	static int id_x;
	static int id_y;
	static bool init = false;
	cairo_user_data_key_t userData;
	std::map<void*, void*> cairoObjects;
	Mutex cairoObjects_Mutex;


	struct HL_CairoGlyph {

		hl_type* t;
		int index;
		double x;
		double y;

	};


	void gc_cairo (value handle) {

		if (!val_is_null (handle)) {

			cairo_t* cairo = (cairo_t*)val_data (handle);
			cairoObjects_Mutex.Lock ();
			cairoObjects.erase (cairo);
			cairoObjects_Mutex.Unlock ();
			cairo_destroy (cairo);

		}

	}


	void hl_gc_cairo (HL_CFFIPointer* handle) {

		cairo_t* cairo = (cairo_t*)handle->ptr;
		handle->ptr = 0;
		cairoObjects_Mutex.Lock ();
		cairoObjects.erase (cairo);
		cairoObjects_Mutex.Unlock ();
		cairo_destroy (cairo);

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


	void hl_gc_cairo_font_face (HL_CFFIPointer* handle) {

		cairo_font_face_t* face = (cairo_font_face_t*)handle->ptr;
		handle->ptr = 0;
		cairoObjects_Mutex.Lock ();
		cairoObjects.erase (face);
		cairoObjects_Mutex.Unlock ();
		cairo_font_face_destroy (face);

	}


	void gc_cairo_font_options (value handle) {

		if (!val_is_null (handle)) {

			cairo_font_options_t* options = (cairo_font_options_t*)val_data (handle);
			cairo_font_options_destroy (options);

		}

	}


	void hl_gc_cairo_font_options (HL_CFFIPointer* handle) {

		cairo_font_options_t* options = (cairo_font_options_t*)handle->ptr;
		handle->ptr = 0;
		cairo_font_options_destroy (options);

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


	void hl_gc_cairo_pattern (HL_CFFIPointer* handle) {

		cairo_pattern_t* pattern = (cairo_pattern_t*)handle->ptr;
		handle->ptr = 0;
		cairoObjects_Mutex.Lock ();
		cairoObjects.erase (pattern);
		cairoObjects_Mutex.Unlock ();
		cairo_pattern_destroy (pattern);

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


	void hl_gc_cairo_surface (HL_CFFIPointer* handle) {

		cairo_surface_t* surface = (cairo_surface_t*)handle->ptr;
		handle->ptr = 0;
		cairoObjects_Mutex.Lock ();
		cairoObjects.erase (surface);
		cairoObjects_Mutex.Unlock ();
		cairo_surface_destroy (surface);

	}


	void gc_user_data (void* data) {

		ValuePointer* reference = (ValuePointer*)data;
		delete reference;

	}


	void lime_cairo_arc (value handle, double xc, double yc, double radius, double angle1, double angle2) {

		cairo_arc ((cairo_t*)val_data (handle), xc, yc, radius, angle1, angle2);

	}


	HL_PRIM void HL_NAME(hl_cairo_arc) (HL_CFFIPointer* handle, double xc, double yc, double radius, double angle1, double angle2) {

		cairo_arc ((cairo_t*)handle->ptr, xc, yc, radius, angle1, angle2);

	}


	void lime_cairo_arc_negative (value handle, double xc, double yc, double radius, double angle1, double angle2) {

		cairo_arc_negative ((cairo_t*)val_data (handle), xc, yc, radius, angle1, angle2);

	}


	HL_PRIM void HL_NAME(hl_cairo_arc_negative) (HL_CFFIPointer* handle, double xc, double yc, double radius, double angle1, double angle2) {

		cairo_arc_negative ((cairo_t*)handle->ptr, xc, yc, radius, angle1, angle2);

	}


	void lime_cairo_clip (value handle) {

		cairo_clip ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_clip) (HL_CFFIPointer* handle) {

		cairo_clip ((cairo_t*)handle->ptr);

	}


	void lime_cairo_clip_extents (value handle, double x1, double y1, double x2, double y2) {

		cairo_clip_extents ((cairo_t*)val_data (handle), &x1, &y1, &x2, &y2);

	}


	HL_PRIM void HL_NAME(hl_cairo_clip_extents) (HL_CFFIPointer* handle, double x1, double y1, double x2, double y2) {

		cairo_clip_extents ((cairo_t*)handle->ptr, &x1, &y1, &x2, &y2);

	}


	void lime_cairo_clip_preserve (value handle) {

		cairo_clip_preserve ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_clip_preserve) (HL_CFFIPointer* handle) {

		cairo_clip_preserve ((cairo_t*)handle->ptr);

	}


	void lime_cairo_close_path (value handle) {

		cairo_close_path ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_close_path) (HL_CFFIPointer* handle) {

		cairo_close_path ((cairo_t*)handle->ptr);

	}


	void lime_cairo_copy_page (value handle) {

		cairo_copy_page ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_copy_page) (HL_CFFIPointer* handle) {

		cairo_copy_page ((cairo_t*)handle->ptr);

	}


	value lime_cairo_create (value surface) {

		cairo_t* cairo = cairo_create ((cairo_surface_t*)val_data (surface));

		value object = CFFIPointer (cairo, gc_cairo);
		cairoObjects_Mutex.Lock ();
		cairoObjects[cairo] = object;
		cairoObjects_Mutex.Unlock ();
		return object;

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_create) (HL_CFFIPointer* surface) {

		cairo_t* cairo = cairo_create ((cairo_surface_t*)surface->ptr);

		HL_CFFIPointer* object = HLCFFIPointer (cairo, (hl_finalizer)hl_gc_cairo);
		cairoObjects_Mutex.Lock ();
		cairoObjects[cairo] = object;
		cairoObjects_Mutex.Unlock ();
		return object;

	}


	void lime_cairo_curve_to (value handle, double x1, double y1, double x2, double y2, double x3, double y3) {

		cairo_curve_to ((cairo_t*)val_data (handle), x1, y1, x2, y2, x3, y3);

	}


	HL_PRIM void HL_NAME(hl_cairo_curve_to) (HL_CFFIPointer* handle, double x1, double y1, double x2, double y2, double x3, double y3) {

		cairo_curve_to ((cairo_t*)handle->ptr, x1, y1, x2, y2, x3, y3);

	}


	void lime_cairo_fill (value handle) {

		cairo_fill ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_fill) (HL_CFFIPointer* handle) {

		cairo_fill ((cairo_t*)handle->ptr);

	}


	void lime_cairo_fill_extents (value handle, double x1, double y1, double x2, double y2) {

		cairo_fill_extents ((cairo_t*)val_data (handle), &x1, &y1, &x2, &y2);

	}


	HL_PRIM void HL_NAME(hl_cairo_fill_extents) (HL_CFFIPointer* handle, double x1, double y1, double x2, double y2) {

		cairo_fill_extents ((cairo_t*)handle->ptr, &x1, &y1, &x2, &y2);

	}


	void lime_cairo_fill_preserve (value handle) {

		cairo_fill_preserve ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_fill_preserve) (HL_CFFIPointer* handle) {

		cairo_fill_preserve ((cairo_t*)handle->ptr);

	}


	int lime_cairo_font_face_status (value handle) {

		return cairo_font_face_status ((cairo_font_face_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_font_face_status) (HL_CFFIPointer* handle) {

		return cairo_font_face_status ((cairo_font_face_t*)handle->ptr);

	}


	value lime_cairo_font_options_create () {

		cairo_font_options_t* options = cairo_font_options_create ();
		return CFFIPointer (options, gc_cairo_font_options);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_font_options_create) () {

		cairo_font_options_t* options = cairo_font_options_create ();
		return HLCFFIPointer (options, (hl_finalizer)hl_gc_cairo_font_options);

	}


	int lime_cairo_font_options_get_antialias (value handle) {

		return cairo_font_options_get_antialias ((cairo_font_options_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_font_options_get_antialias) (HL_CFFIPointer* handle) {

		return cairo_font_options_get_antialias ((cairo_font_options_t*)handle->ptr);

	}


	int lime_cairo_font_options_get_hint_metrics (value handle) {

		return cairo_font_options_get_hint_metrics ((cairo_font_options_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_font_options_get_hint_metrics) (HL_CFFIPointer* handle) {

		return cairo_font_options_get_hint_metrics ((cairo_font_options_t*)handle->ptr);

	}


	int lime_cairo_font_options_get_hint_style (value handle) {

		return cairo_font_options_get_hint_style ((cairo_font_options_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_font_options_get_hint_style) (HL_CFFIPointer* handle) {

		return cairo_font_options_get_hint_style ((cairo_font_options_t*)handle->ptr);

	}


	int lime_cairo_font_options_get_subpixel_order (value handle) {

		return cairo_font_options_get_subpixel_order ((cairo_font_options_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_font_options_get_subpixel_order) (HL_CFFIPointer* handle) {

		return cairo_font_options_get_subpixel_order ((cairo_font_options_t*)handle->ptr);

	}


	void lime_cairo_font_options_set_antialias (value handle, int v) {

		cairo_font_options_set_antialias ((cairo_font_options_t*)val_data (handle), (cairo_antialias_t)v);

	}


	HL_PRIM void HL_NAME(hl_cairo_font_options_set_antialias) (HL_CFFIPointer* handle, int v) {

		cairo_font_options_set_antialias ((cairo_font_options_t*)handle->ptr, (cairo_antialias_t)v);

	}


	void lime_cairo_font_options_set_hint_metrics (value handle, int v) {

		cairo_font_options_set_hint_metrics ((cairo_font_options_t*)val_data (handle), (cairo_hint_metrics_t)v);

	}


	HL_PRIM void HL_NAME(hl_cairo_font_options_set_hint_metrics) (HL_CFFIPointer* handle, int v) {

		cairo_font_options_set_hint_metrics ((cairo_font_options_t*)handle->ptr, (cairo_hint_metrics_t)v);

	}


	void lime_cairo_font_options_set_hint_style (value handle, int v) {

		cairo_font_options_set_hint_style ((cairo_font_options_t*)val_data (handle), (cairo_hint_style_t)v);

	}


	HL_PRIM void HL_NAME(hl_cairo_font_options_set_hint_style) (HL_CFFIPointer* handle, int v) {

		cairo_font_options_set_hint_style ((cairo_font_options_t*)handle->ptr, (cairo_hint_style_t)v);

	}


	void lime_cairo_font_options_set_subpixel_order (value handle, int v) {

		cairo_font_options_set_subpixel_order ((cairo_font_options_t*)val_data (handle), (cairo_subpixel_order_t)v);

	}


	HL_PRIM void HL_NAME(hl_cairo_font_options_set_subpixel_order) (HL_CFFIPointer* handle, int v) {

		cairo_font_options_set_subpixel_order ((cairo_font_options_t*)handle->ptr, (cairo_subpixel_order_t)v);

	}


	value lime_cairo_ft_font_face_create (value face, int flags) {

		#ifdef LIME_FREETYPE
		Font* font = (Font*)val_data (face);
		cairo_font_face_t* cairoFont = cairo_ft_font_face_create_for_ft_face ((FT_Face)font->face, flags);

		ValuePointer* fontReference = new ValuePointer (face);
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


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_ft_font_face_create) (HL_CFFIPointer* face, int flags) {

		#ifdef LIME_FREETYPE
		Font* font = (Font*)face->ptr;
		cairo_font_face_t* cairoFont = cairo_ft_font_face_create_for_ft_face ((FT_Face)font->face, flags);

		ValuePointer* fontReference = new ValuePointer ((vobj*)face);
		cairo_font_face_set_user_data (cairoFont, &userData, fontReference, gc_user_data);

		HL_CFFIPointer* object = HLCFFIPointer (cairoFont, (hl_finalizer)hl_gc_cairo_font_face);
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


	HL_PRIM int HL_NAME(hl_cairo_get_antialias) (HL_CFFIPointer* handle) {

		return cairo_get_antialias ((cairo_t*)handle->ptr);

	}


	value lime_cairo_get_current_point (value handle) {

		double x, y;
		cairo_get_current_point ((cairo_t*)val_data (handle), &x, &y);
		Vector2 vec2 = Vector2 (x, y);
		return vec2.Value ();

	}


	HL_PRIM Vector2* HL_NAME(hl_cairo_get_current_point) (HL_CFFIPointer* handle, Vector2* out) {

		cairo_get_current_point ((cairo_t*)handle->ptr, &out->x, &out->y);
		return out;

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


	HL_PRIM varray* HL_NAME(hl_cairo_get_dash) (HL_CFFIPointer* handle) {

		int length = cairo_get_dash_count ((cairo_t*)handle->ptr);
		varray* result = hl_alloc_array (&hlt_f64, length);
		double offset;

		cairo_get_dash ((cairo_t*)handle->ptr, hl_aptr (result, double), &offset);

		return result;


	}


	int lime_cairo_get_dash_count (value handle) {

		return cairo_get_dash_count ((cairo_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_get_dash_count) (HL_CFFIPointer* handle) {

		return cairo_get_dash_count ((cairo_t*)handle->ptr);

	}


	int lime_cairo_get_fill_rule (value handle) {

		return cairo_get_fill_rule ((cairo_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_get_fill_rule) (HL_CFFIPointer* handle) {

		return cairo_get_fill_rule ((cairo_t*)handle->ptr);

	}


	value lime_cairo_get_font_face (value handle) {

		cairo_font_face_t* face = cairo_get_font_face ((cairo_t*)val_data (handle));

		if (cairoObjects.find (face) != cairoObjects.end ()) {

			return (value)cairoObjects[face];

		} else {

			cairo_font_face_reference (face);

			value object = CFFIPointer (face, gc_cairo_font_face);
			cairoObjects_Mutex.Lock ();
			cairoObjects[face] = object;
			cairoObjects_Mutex.Unlock ();
			return object;

		}

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_get_font_face) (HL_CFFIPointer* handle) {

		cairo_font_face_t* face = cairo_get_font_face ((cairo_t*)handle->ptr);

		if (cairoObjects.find (face) != cairoObjects.end ()) {

			return (HL_CFFIPointer*)cairoObjects[face];

		} else {

			cairo_font_face_reference (face);

			HL_CFFIPointer* object = HLCFFIPointer (face, (hl_finalizer)hl_gc_cairo_font_face);
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


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_get_font_options) (HL_CFFIPointer* handle) {

		cairo_font_options_t* options = 0;
		cairo_get_font_options ((cairo_t*)handle->ptr, options);
		return HLCFFIPointer (options, (hl_finalizer)hl_gc_cairo_font_options);

	}


	value lime_cairo_get_group_target (value handle) {

		cairo_surface_t* surface = cairo_get_group_target ((cairo_t*)val_data (handle));

		if (cairoObjects.find (surface) != cairoObjects.end ()) {

			return (value)cairoObjects[surface];

		} else {

			cairo_surface_reference (surface);

			value object = CFFIPointer (surface, gc_cairo_surface);
			cairoObjects_Mutex.Lock ();
			cairoObjects[surface] = object;
			cairoObjects_Mutex.Unlock ();
			return object;

		}

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_get_group_target) (HL_CFFIPointer* handle) {

		cairo_surface_t* surface = cairo_get_group_target ((cairo_t*)handle->ptr);

		if (cairoObjects.find (surface) != cairoObjects.end ()) {

			return (HL_CFFIPointer*)cairoObjects[surface];

		} else {

			cairo_surface_reference (surface);

			HL_CFFIPointer* object = HLCFFIPointer (surface, (hl_finalizer)hl_gc_cairo_surface);
			cairoObjects_Mutex.Lock ();
			cairoObjects[surface] = object;
			cairoObjects_Mutex.Unlock ();
			return object;

		}

	}


	int lime_cairo_get_line_cap (value handle) {

		return cairo_get_line_cap ((cairo_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_get_line_cap) (HL_CFFIPointer* handle) {

		return cairo_get_line_cap ((cairo_t*)handle->ptr);

	}


	int lime_cairo_get_line_join (value handle) {

		return cairo_get_line_join ((cairo_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_get_line_join) (HL_CFFIPointer* handle) {

		return cairo_get_line_join ((cairo_t*)handle->ptr);

	}


	double lime_cairo_get_line_width (value handle) {

		return cairo_get_line_width ((cairo_t*)val_data (handle));

	}


	HL_PRIM double HL_NAME(hl_cairo_get_line_width) (HL_CFFIPointer* handle) {

		return cairo_get_line_width ((cairo_t*)handle->ptr);

	}


	value lime_cairo_get_matrix (value handle) {

		cairo_matrix_t cm;
		cairo_get_matrix ((cairo_t*)val_data (handle), &cm);
		Matrix3 mat3 = Matrix3 (cm.xx, cm.yx, cm.xy, cm.yy, cm.x0, cm.y0);
		return mat3.Value ();

	}


	HL_PRIM Matrix3* HL_NAME(hl_cairo_get_matrix) (HL_CFFIPointer* handle, Matrix3* out) {

		// cairo_matrix_t cm;
		// cairo_get_matrix ((cairo_t*)handle->ptr, &cm);
		// out->a = cm.xx;
		// out->b = cm.yx;
		// out->c = cm.xy;
		// out->d = cm.yy;
		// out->tx = cm.x0;
		// out->ty = cm.y0;
		cairo_get_matrix ((cairo_t*)handle->ptr, (cairo_matrix_t*)&out->a);
		return out;

	}


	double lime_cairo_get_miter_limit (value handle) {

		return cairo_get_miter_limit ((cairo_t*)val_data (handle));

	}


	HL_PRIM double HL_NAME(hl_cairo_get_miter_limit) (HL_CFFIPointer* handle) {

		return cairo_get_miter_limit ((cairo_t*)handle->ptr);

	}


	int lime_cairo_get_operator (value handle) {

		return cairo_get_operator ((cairo_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_get_operator) (HL_CFFIPointer* handle) {

		return cairo_get_operator ((cairo_t*)handle->ptr);

	}


	value lime_cairo_get_source (value handle) {

		cairo_pattern_t* pattern = cairo_get_source ((cairo_t*)val_data (handle));

		if (cairoObjects.find (pattern) != cairoObjects.end ()) {

			return (value)cairoObjects[pattern];

		} else {

			cairo_pattern_reference (pattern);

			value object = CFFIPointer (pattern, gc_cairo_pattern);
			cairoObjects_Mutex.Lock ();
			cairoObjects[pattern] = object;
			cairoObjects_Mutex.Unlock ();
			return object;

		}

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_get_source) (HL_CFFIPointer* handle) {

		cairo_pattern_t* pattern = cairo_get_source ((cairo_t*)handle->ptr);

		if (cairoObjects.find (pattern) != cairoObjects.end ()) {

			return (HL_CFFIPointer*)cairoObjects[pattern];

		} else {

			cairo_pattern_reference (pattern);

			HL_CFFIPointer* object = HLCFFIPointer (pattern, (hl_finalizer)hl_gc_cairo_pattern);
			cairoObjects_Mutex.Lock ();
			cairoObjects[pattern] = object;
			cairoObjects_Mutex.Unlock ();
			return object;

		}

	}


	value lime_cairo_get_target (value handle) {

		cairo_surface_t* surface = cairo_get_target ((cairo_t*)val_data (handle));

		if (cairoObjects.find (surface) != cairoObjects.end ()) {

			return (value)cairoObjects[surface];

		} else {

			cairo_surface_reference (surface);

			value object = CFFIPointer (surface, gc_cairo_surface);
			cairoObjects_Mutex.Lock ();
			cairoObjects[surface] = object;
			cairoObjects_Mutex.Unlock ();
			return object;

		}

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_get_target) (HL_CFFIPointer* handle) {

		cairo_surface_t* surface = cairo_get_target ((cairo_t*)handle->ptr);

		if (cairoObjects.find (surface) != cairoObjects.end ()) {

			return (HL_CFFIPointer*)cairoObjects[surface];

		} else {

			cairo_surface_reference (surface);

			HL_CFFIPointer* object = HLCFFIPointer (surface, (hl_finalizer)hl_gc_cairo_surface);
			cairoObjects_Mutex.Lock ();
			cairoObjects[surface] = object;
			cairoObjects_Mutex.Unlock ();
			return object;

		}

	}


	double lime_cairo_get_tolerance (value handle) {

		return cairo_get_tolerance ((cairo_t*)val_data (handle));

	}


	HL_PRIM double HL_NAME(hl_cairo_get_tolerance) (HL_CFFIPointer* handle) {

		return cairo_get_tolerance ((cairo_t*)handle->ptr);

	}


	bool lime_cairo_has_current_point (value handle) {

		return cairo_has_current_point ((cairo_t*)val_data (handle));

	}


	HL_PRIM bool HL_NAME(hl_cairo_has_current_point) (HL_CFFIPointer* handle) {

		return cairo_has_current_point ((cairo_t*)handle->ptr);

	}


	void lime_cairo_identity_matrix (value handle) {

		cairo_identity_matrix ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_identity_matrix) (HL_CFFIPointer* handle) {

		cairo_identity_matrix ((cairo_t*)handle->ptr);

	}


	value lime_cairo_image_surface_create (int format, int width, int height) {

		cairo_surface_t* surface = cairo_image_surface_create ((cairo_format_t)format, width, height);

		value object = CFFIPointer (surface, gc_cairo_surface);
		cairoObjects_Mutex.Lock ();
		cairoObjects[surface] = object;
		cairoObjects_Mutex.Unlock ();
		return object;

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_image_surface_create) (int format, int width, int height) {

		cairo_surface_t* surface = cairo_image_surface_create ((cairo_format_t)format, width, height);

		HL_CFFIPointer* object = HLCFFIPointer (surface, (hl_finalizer)hl_gc_cairo_surface);
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


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_image_surface_create_for_data) (double data, int format, int width, int height, int stride) {

		cairo_surface_t* surface = cairo_image_surface_create_for_data ((unsigned char*)(uintptr_t)data, (cairo_format_t)format, width, height, stride);

		HL_CFFIPointer* object = HLCFFIPointer (surface, (hl_finalizer)hl_gc_cairo_surface);
		cairoObjects_Mutex.Lock ();
		cairoObjects[surface] = object;
		cairoObjects_Mutex.Unlock ();
		return object;

	}


	double lime_cairo_image_surface_get_data (value handle) {

		return (uintptr_t)cairo_image_surface_get_data ((cairo_surface_t*)val_data (handle));

	}


	HL_PRIM double HL_NAME(hl_cairo_image_surface_get_data) (HL_CFFIPointer* handle) {

		return (uintptr_t)cairo_image_surface_get_data ((cairo_surface_t*)handle->ptr);

	}


	int lime_cairo_image_surface_get_format (value handle) {

		return (int)cairo_image_surface_get_format ((cairo_surface_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_image_surface_get_format) (HL_CFFIPointer* handle) {

		return (int)cairo_image_surface_get_format ((cairo_surface_t*)handle->ptr);

	}


	int lime_cairo_image_surface_get_height (value handle) {

		return cairo_image_surface_get_height ((cairo_surface_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_image_surface_get_height) (HL_CFFIPointer* handle) {

		return cairo_image_surface_get_height ((cairo_surface_t*)handle->ptr);

	}


	int lime_cairo_image_surface_get_stride (value handle) {

		return cairo_image_surface_get_stride ((cairo_surface_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_image_surface_get_stride) (HL_CFFIPointer* handle) {

		return cairo_image_surface_get_stride ((cairo_surface_t*)handle->ptr);

	}


	int lime_cairo_image_surface_get_width (value handle) {

		return cairo_image_surface_get_width ((cairo_surface_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_image_surface_get_width) (HL_CFFIPointer* handle) {

		return cairo_image_surface_get_width ((cairo_surface_t*)handle->ptr);

	}


	bool lime_cairo_in_clip (value handle, double x, double y) {

		return cairo_in_clip ((cairo_t*)val_data (handle), x, y);

	}


	HL_PRIM bool HL_NAME(hl_cairo_in_clip) (HL_CFFIPointer* handle, double x, double y) {

		return cairo_in_clip ((cairo_t*)handle->ptr, x, y);

	}


	bool lime_cairo_in_fill (value handle, double x, double y) {

		return cairo_in_fill ((cairo_t*)val_data (handle), x, y);

	}


	HL_PRIM bool HL_NAME(hl_cairo_in_fill) (HL_CFFIPointer* handle, double x, double y) {

		return cairo_in_fill ((cairo_t*)handle->ptr, x, y);

	}


	bool lime_cairo_in_stroke (value handle, double x, double y) {

		return cairo_in_stroke ((cairo_t*)val_data (handle), x, y);

	}


	HL_PRIM bool HL_NAME(hl_cairo_in_stroke) (HL_CFFIPointer* handle, double x, double y) {

		return cairo_in_stroke ((cairo_t*)handle->ptr, x, y);

	}


	void lime_cairo_line_to (value handle, double x, double y) {

		cairo_line_to ((cairo_t*)val_data (handle), x, y);

	}


	HL_PRIM void HL_NAME(hl_cairo_line_to) (HL_CFFIPointer* handle, double x, double y) {

		cairo_line_to ((cairo_t*)handle->ptr, x, y);

	}


	void lime_cairo_mask (value handle, value pattern) {

		cairo_mask ((cairo_t*)val_data (handle), (cairo_pattern_t*)val_data (pattern));

	}


	HL_PRIM void HL_NAME(hl_cairo_mask) (HL_CFFIPointer* handle, HL_CFFIPointer* pattern) {

		cairo_mask ((cairo_t*)handle->ptr, (cairo_pattern_t*)pattern->ptr);

	}


	void lime_cairo_mask_surface (value handle, value surface, double x, double y) {

		cairo_mask_surface ((cairo_t*)val_data (handle), (cairo_surface_t*)val_data (surface), x, y);

	}


	HL_PRIM void HL_NAME(hl_cairo_mask_surface) (HL_CFFIPointer* handle, HL_CFFIPointer* surface, double x, double y) {

		cairo_mask_surface ((cairo_t*)handle->ptr, (cairo_surface_t*)surface->ptr, x, y);

	}


	void lime_cairo_move_to (value handle, double x, double y) {

		cairo_move_to ((cairo_t*)val_data (handle), x, y);

	}


	HL_PRIM void HL_NAME(hl_cairo_move_to) (HL_CFFIPointer* handle, double x, double y) {

		cairo_move_to ((cairo_t*)handle->ptr, x, y);

	}


	void lime_cairo_new_path (value handle) {

		cairo_new_path ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_new_path) (HL_CFFIPointer* handle) {

		cairo_new_path ((cairo_t*)handle->ptr);

	}


	void lime_cairo_paint (value handle) {

		cairo_paint ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_paint) (HL_CFFIPointer* handle) {

		cairo_paint ((cairo_t*)handle->ptr);

	}


	void lime_cairo_paint_with_alpha (value handle, double alpha) {

		cairo_paint_with_alpha ((cairo_t*)val_data (handle), alpha);

	}


	HL_PRIM void HL_NAME(hl_cairo_paint_with_alpha) (HL_CFFIPointer* handle, double alpha) {

		cairo_paint_with_alpha ((cairo_t*)handle->ptr, alpha);

	}


	void lime_cairo_pattern_add_color_stop_rgb (value handle, double offset, double red, double green, double blue) {

		cairo_pattern_add_color_stop_rgb ((cairo_pattern_t*)val_data (handle), offset, red, green, blue);

	}


	HL_PRIM void HL_NAME(hl_cairo_pattern_add_color_stop_rgb) (HL_CFFIPointer* handle, double offset, double red, double green, double blue) {

		cairo_pattern_add_color_stop_rgb ((cairo_pattern_t*)handle->ptr, offset, red, green, blue);

	}


	void lime_cairo_pattern_add_color_stop_rgba (value handle, double offset, double red, double green, double blue, double alpha) {

		cairo_pattern_add_color_stop_rgba ((cairo_pattern_t*)val_data (handle), offset, red, green, blue, alpha);

	}


	HL_PRIM void HL_NAME(hl_cairo_pattern_add_color_stop_rgba) (HL_CFFIPointer* handle, double offset, double red, double green, double blue, double alpha) {

		cairo_pattern_add_color_stop_rgba ((cairo_pattern_t*)handle->ptr, offset, red, green, blue, alpha);

	}


	value lime_cairo_pattern_create_for_surface (value surface) {

		cairo_pattern_t* pattern = cairo_pattern_create_for_surface ((cairo_surface_t*)val_data (surface));

		value object = CFFIPointer (pattern, gc_cairo_pattern);
		cairoObjects_Mutex.Lock ();
		cairoObjects[pattern] = object;
		cairoObjects_Mutex.Unlock ();
		return object;

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_pattern_create_for_surface) (HL_CFFIPointer* surface) {

		cairo_pattern_t* pattern = cairo_pattern_create_for_surface ((cairo_surface_t*)surface->ptr);

		HL_CFFIPointer* object = HLCFFIPointer (pattern, (hl_finalizer)hl_gc_cairo_pattern);
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


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_pattern_create_linear) (double x0, double y0, double x1, double y1) {

		cairo_pattern_t* pattern = cairo_pattern_create_linear (x0, y0, x1, y1);

		HL_CFFIPointer* object = HLCFFIPointer (pattern, (hl_finalizer)hl_gc_cairo_pattern);
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


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_pattern_create_radial) (double cx0, double cy0, double radius0, double cx1, double cy1, double radius1) {

		cairo_pattern_t* pattern = cairo_pattern_create_radial (cx0, cy0, radius0, cx1, cy1, radius1);

		HL_CFFIPointer* object = HLCFFIPointer (pattern, (hl_finalizer)hl_gc_cairo_pattern);
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


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_pattern_create_rgb) (double r, double g, double b) {

		cairo_pattern_t* pattern = cairo_pattern_create_rgb (r, g, b);

		HL_CFFIPointer* object = HLCFFIPointer (pattern, (hl_finalizer)hl_gc_cairo_pattern);
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


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_pattern_create_rgba) (double r, double g, double b, double a) {

		cairo_pattern_t* pattern = cairo_pattern_create_rgba (r, g, b, a);

		HL_CFFIPointer* object = HLCFFIPointer (pattern, (hl_finalizer)hl_gc_cairo_pattern);
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


	HL_PRIM int HL_NAME(hl_cairo_pattern_get_color_stop_count) (HL_CFFIPointer* handle) {

		int count;
		cairo_pattern_get_color_stop_count ((cairo_pattern_t*)handle->ptr, &count);
		return count;

	}


	int lime_cairo_pattern_get_extend (value handle) {

		return cairo_pattern_get_extend ((cairo_pattern_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_pattern_get_extend) (HL_CFFIPointer* handle) {

		return cairo_pattern_get_extend ((cairo_pattern_t*)handle->ptr);

	}


	int lime_cairo_pattern_get_filter (value handle) {

		return cairo_pattern_get_filter ((cairo_pattern_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_pattern_get_filter) (HL_CFFIPointer* handle) {

		return cairo_pattern_get_filter ((cairo_pattern_t*)handle->ptr);

	}


	value lime_cairo_pattern_get_matrix (value handle) {

		cairo_matrix_t cm;
		cairo_pattern_get_matrix ((cairo_pattern_t*)val_data (handle), &cm);
		Matrix3 mat3 = Matrix3 (cm.xx, cm.yx, cm.xy, cm.yy, cm.x0, cm.y0);
		return mat3.Value ();

	}


	HL_PRIM Matrix3* HL_NAME(hl_cairo_pattern_get_matrix) (HL_CFFIPointer* handle, Matrix3* out) {

		// cairo_matrix_t cm;
		// cairo_pattern_get_matrix ((cairo_pattern_t*)handle->ptr, &cm);
		// out->a = cm.xx;
		// out->b = cm.yx;
		// out->c = cm.xy;
		// out->d = cm.yy;
		// out->tx = cm.x0;
		// out->ty = cm.y0;
		cairo_pattern_get_matrix ((cairo_pattern_t*)handle->ptr, (cairo_matrix_t*)&out->a);
		return out;

	}


	void lime_cairo_pattern_set_extend (value handle, int extend) {

		cairo_pattern_set_extend ((cairo_pattern_t*)val_data (handle), (cairo_extend_t)extend);

	}


	HL_PRIM void HL_NAME(hl_cairo_pattern_set_extend) (HL_CFFIPointer* handle, int extend) {

		cairo_pattern_set_extend ((cairo_pattern_t*)handle->ptr, (cairo_extend_t)extend);

	}


	void lime_cairo_pattern_set_filter (value handle, int filter) {

		cairo_pattern_set_filter ((cairo_pattern_t*)val_data (handle), (cairo_filter_t)filter);

	}


	HL_PRIM void HL_NAME(hl_cairo_pattern_set_filter) (HL_CFFIPointer* handle, int filter) {

		cairo_pattern_set_filter ((cairo_pattern_t*)handle->ptr, (cairo_filter_t)filter);

	}


	void lime_cairo_pattern_set_matrix (value handle, value matrix) {

		Matrix3 mat3 = Matrix3 (matrix);

		cairo_matrix_t cm;
		cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);

		cairo_pattern_set_matrix ((cairo_pattern_t*)val_data (handle), &cm);

	}


	HL_PRIM void HL_NAME(hl_cairo_pattern_set_matrix) (HL_CFFIPointer* handle, Matrix3* matrix) {

		// cairo_matrix_t cm;
		// cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);

		// cairo_pattern_set_matrix ((cairo_pattern_t*)handle->ptr, &cm);

		cairo_pattern_set_matrix ((cairo_pattern_t*)handle->ptr, (cairo_matrix_t*)&matrix->a);

	}


	value lime_cairo_pop_group (value handle) {

		cairo_pattern_t* pattern = cairo_pop_group ((cairo_t*)val_data (handle));

		if (cairoObjects.find (pattern) != cairoObjects.end ()) {

			return (value)cairoObjects[pattern];

		} else {

			cairo_pattern_reference (pattern);

			value object = CFFIPointer (pattern, gc_cairo_pattern);
			cairoObjects_Mutex.Lock ();
			cairoObjects[pattern] = object;
			cairoObjects_Mutex.Unlock ();
			return object;

		}

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_cairo_pop_group) (HL_CFFIPointer* handle) {

		cairo_pattern_t* pattern = cairo_pop_group ((cairo_t*)handle->ptr);

		if (cairoObjects.find (pattern) != cairoObjects.end ()) {

			return (HL_CFFIPointer*)cairoObjects[pattern];

		} else {

			cairo_pattern_reference (pattern);

			HL_CFFIPointer* object = HLCFFIPointer (pattern, (hl_finalizer)hl_gc_cairo_pattern);
			cairoObjects_Mutex.Lock ();
			cairoObjects[pattern] = object;
			cairoObjects_Mutex.Unlock ();
			return object;

		}

	}


	void lime_cairo_pop_group_to_source (value handle) {

		cairo_pop_group_to_source ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_pop_group_to_source) (HL_CFFIPointer* handle) {

		cairo_pop_group_to_source ((cairo_t*)handle->ptr);

	}


	void lime_cairo_push_group (value handle) {

		cairo_push_group ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_push_group) (HL_CFFIPointer* handle) {

		cairo_push_group ((cairo_t*)handle->ptr);

	}


	void lime_cairo_push_group_with_content (value handle, int content) {

		cairo_push_group_with_content ((cairo_t*)val_data (handle), (cairo_content_t)content);

	}


	HL_PRIM void HL_NAME(hl_cairo_push_group_with_content) (HL_CFFIPointer* handle, int content) {

		cairo_push_group_with_content ((cairo_t*)handle->ptr, (cairo_content_t)content);

	}


	void lime_cairo_rectangle (value handle, double x, double y, double width, double height) {

		cairo_rectangle ((cairo_t*)val_data (handle), x, y, width, height);

	}


	HL_PRIM void HL_NAME(hl_cairo_rectangle) (HL_CFFIPointer* handle, double x, double y, double width, double height) {

		cairo_rectangle ((cairo_t*)handle->ptr, x, y, width, height);

	}


	void lime_cairo_rel_curve_to (value handle, double dx1, double dy1, double dx2, double dy2, double dx3, double dy3) {

		cairo_rel_curve_to ((cairo_t*)val_data (handle), dx1, dy1, dx2, dy2, dx3, dy3);

	}


	HL_PRIM void HL_NAME(hl_cairo_rel_curve_to) (HL_CFFIPointer* handle, double dx1, double dy1, double dx2, double dy2, double dx3, double dy3) {

		cairo_rel_curve_to ((cairo_t*)handle->ptr, dx1, dy1, dx2, dy2, dx3, dy3);

	}


	void lime_cairo_rel_line_to (value handle, double dx, double dy) {

		cairo_rel_line_to ((cairo_t*)val_data (handle), dx, dy);

	}


	HL_PRIM void HL_NAME(hl_cairo_rel_line_to) (HL_CFFIPointer* handle, double dx, double dy) {

		cairo_rel_line_to ((cairo_t*)handle->ptr, dx, dy);

	}


	void lime_cairo_rel_move_to (value handle, double dx, double dy) {

		cairo_rel_move_to ((cairo_t*)val_data (handle), dx, dy);

	}


	HL_PRIM void HL_NAME(hl_cairo_rel_move_to) (HL_CFFIPointer* handle, double dx, double dy) {

		cairo_rel_move_to ((cairo_t*)handle->ptr, dx, dy);

	}


	void lime_cairo_reset_clip (value handle) {

		cairo_reset_clip ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_reset_clip) (HL_CFFIPointer* handle) {

		cairo_reset_clip ((cairo_t*)handle->ptr);

	}


	void lime_cairo_restore (value handle) {

		cairo_restore ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_restore) (HL_CFFIPointer* handle) {

		cairo_restore ((cairo_t*)handle->ptr);

	}


	void lime_cairo_rotate (value handle, double amount) {

		cairo_rotate ((cairo_t*)val_data (handle), amount);

	}


	HL_PRIM void HL_NAME(hl_cairo_rotate) (HL_CFFIPointer* handle, double amount) {

		cairo_rotate ((cairo_t*)handle->ptr, amount);

	}


	void lime_cairo_save (value handle) {

		cairo_save ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_save) (HL_CFFIPointer* handle) {

		cairo_save ((cairo_t*)handle->ptr);

	}


	void lime_cairo_scale (value handle, double x, double y) {

		cairo_scale ((cairo_t*)val_data (handle), x, y);

	}


	HL_PRIM void HL_NAME(hl_cairo_scale) (HL_CFFIPointer* handle, double x, double y) {

		cairo_scale ((cairo_t*)handle->ptr, x, y);

	}


	void lime_cairo_set_antialias (value handle, int cap) {

		cairo_set_antialias ((cairo_t*)val_data (handle), (cairo_antialias_t)cap);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_antialias) (HL_CFFIPointer* handle, int cap) {

		cairo_set_antialias ((cairo_t*)handle->ptr, (cairo_antialias_t)cap);

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


	HL_PRIM void HL_NAME(hl_cairo_set_dash) (HL_CFFIPointer* handle, varray* dash) {

		cairo_set_dash ((cairo_t*)handle->ptr, hl_aptr (dash, double), dash->size, 0);

	}


	void lime_cairo_set_fill_rule (value handle, int cap) {

		cairo_set_fill_rule ((cairo_t*)val_data (handle), (cairo_fill_rule_t)cap);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_fill_rule) (HL_CFFIPointer* handle, int cap) {

		cairo_set_fill_rule ((cairo_t*)handle->ptr, (cairo_fill_rule_t)cap);

	}


	void lime_cairo_set_font_face (value handle, value face) {

		cairo_set_font_face ((cairo_t*)val_data (handle), (cairo_font_face_t*)val_data (face));

	}


	HL_PRIM void HL_NAME(hl_cairo_set_font_face) (HL_CFFIPointer* handle, HL_CFFIPointer* face) {

		cairo_set_font_face ((cairo_t*)handle->ptr, (cairo_font_face_t*)face->ptr);

	}


	void lime_cairo_set_font_options (value handle, value options) {

		cairo_set_font_options ((cairo_t*)val_data (handle), (cairo_font_options_t*)val_data (options));

	}


	HL_PRIM void HL_NAME(hl_cairo_set_font_options) (HL_CFFIPointer* handle, HL_CFFIPointer* options) {

		cairo_set_font_options ((cairo_t*)handle->ptr, (cairo_font_options_t*)options->ptr);

	}


	void lime_cairo_set_font_size (value handle, double size) {

		cairo_font_face_t* face = cairo_get_font_face ((cairo_t*)val_data (handle));

		if (face) {

			cairo_font_type_t type = cairo_font_face_get_type (face);

			if (type == CAIRO_FONT_TYPE_FT) {

				ValuePointer* fontReference = (ValuePointer*)cairo_font_face_get_user_data (face, &userData);

				if (fontReference) {

					Font* font = (Font*)val_data ((value)fontReference->Get ());
					font->SetSize (size);

				}

			}

		}

		cairo_set_font_size ((cairo_t*)val_data (handle), size);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_font_size) (HL_CFFIPointer* handle, double size) {

		cairo_font_face_t* face = cairo_get_font_face ((cairo_t*)handle->ptr);

		if (face) {

			cairo_font_type_t type = cairo_font_face_get_type (face);

			if (type == CAIRO_FONT_TYPE_FT) {

				ValuePointer* fontReference = (ValuePointer*)cairo_font_face_get_user_data (face, &userData);

				if (fontReference) {

					Font* font = (Font*)((HL_CFFIPointer*)fontReference->Get ())->ptr;
					font->SetSize (size);

				}

			}

		}

		cairo_set_font_size ((cairo_t*)handle->ptr, size);

	}


	void lime_cairo_set_line_cap (value handle, int cap) {

		cairo_set_line_cap ((cairo_t*)val_data (handle), (cairo_line_cap_t)cap);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_line_cap) (HL_CFFIPointer* handle, int cap) {

		cairo_set_line_cap ((cairo_t*)handle->ptr, (cairo_line_cap_t)cap);

	}


	void lime_cairo_set_line_join (value handle, int join) {

		cairo_set_line_join ((cairo_t*)val_data (handle), (cairo_line_join_t)join);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_line_join) (HL_CFFIPointer* handle, int join) {

		cairo_set_line_join ((cairo_t*)handle->ptr, (cairo_line_join_t)join);

	}


	void lime_cairo_set_line_width (value handle, double width) {

		cairo_set_line_width ((cairo_t*)val_data (handle), width);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_line_width) (HL_CFFIPointer* handle, double width) {

		cairo_set_line_width ((cairo_t*)handle->ptr, width);

	}


	void lime_cairo_set_matrix (value handle, double a, double b, double c, double d, double tx, double ty) {

		cairo_matrix_t cm;
		cairo_matrix_init (&cm, a, b, c, d, tx, ty);

		cairo_set_matrix ((cairo_t*)val_data (handle), &cm);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_matrix) (HL_CFFIPointer* handle, Matrix3* matrix) {

		// cairo_matrix_t cm;
		// cairo_matrix_init (&cm, a, b, c, d, tx, ty);

		cairo_set_matrix ((cairo_t*)handle->ptr, (cairo_matrix_t*)&matrix->a);

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


	HL_PRIM void HL_NAME(hl_cairo_set_miter_limit) (HL_CFFIPointer* handle, double miterLimit) {

		cairo_set_miter_limit ((cairo_t*)handle->ptr, miterLimit);

	}


	void lime_cairo_set_operator (value handle, int op) {

		cairo_set_operator ((cairo_t*)val_data (handle), (cairo_operator_t)op);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_operator) (HL_CFFIPointer* handle, int op) {

		cairo_set_operator ((cairo_t*)handle->ptr, (cairo_operator_t)op);

	}


	void lime_cairo_set_source (value handle, value pattern) {

		cairo_set_source ((cairo_t*)val_data (handle), (cairo_pattern_t*)val_data (pattern));

	}


	HL_PRIM void HL_NAME(hl_cairo_set_source) (HL_CFFIPointer* handle, HL_CFFIPointer* pattern) {

		cairo_set_source ((cairo_t*)handle->ptr, (cairo_pattern_t*)pattern->ptr);

	}


	void lime_cairo_set_source_rgb (value handle, double r, double g, double b) {

		cairo_set_source_rgb ((cairo_t*)val_data (handle), r, g, b);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_source_rgb) (HL_CFFIPointer* handle, double r, double g, double b) {

		cairo_set_source_rgb ((cairo_t*)handle->ptr, r, g, b);

	}


	void lime_cairo_set_source_rgba (value handle, double r, double g, double b, double a) {

		cairo_set_source_rgba ((cairo_t*)val_data (handle), r, g, b, a);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_source_rgba) (HL_CFFIPointer* handle, double r, double g, double b, double a) {

		cairo_set_source_rgba ((cairo_t*)handle->ptr, r, g, b, a);

	}


	void lime_cairo_set_source_surface (value handle, value surface, double x, double y) {

		cairo_set_source_surface ((cairo_t*)val_data (handle), (cairo_surface_t*)val_data (surface), x, y);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_source_surface) (HL_CFFIPointer* handle, HL_CFFIPointer* surface, double x, double y) {

		cairo_set_source_surface ((cairo_t*)handle->ptr, (cairo_surface_t*)surface->ptr, x, y);

	}


	void lime_cairo_set_tolerance (value handle, double tolerance) {

		cairo_set_tolerance ((cairo_t*)val_data (handle), tolerance);

	}


	HL_PRIM void HL_NAME(hl_cairo_set_tolerance) (HL_CFFIPointer* handle, double tolerance) {

		cairo_set_tolerance ((cairo_t*)handle->ptr, tolerance);

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


	HL_PRIM void HL_NAME(hl_cairo_show_glyphs) (HL_CFFIPointer* handle, varray* glyphs) {

		const int id_index = hl_hash_utf8 ("index");
		const int id_x = hl_hash_utf8 ("x");
		const int id_y = hl_hash_utf8 ("y");

		int length = glyphs->size;
		HL_CairoGlyph** glyphData = hl_aptr (glyphs, HL_CairoGlyph*);
		cairo_glyph_t* _glyphs = cairo_glyph_allocate (length);

		HL_CairoGlyph* glyph;

		for (int i = 0; i < length; i++) {

			glyph = *glyphData++;
			_glyphs[i].index = glyph->index;
			_glyphs[i].x = glyph->x;
			_glyphs[i].y = glyph->y;

		}

		cairo_show_glyphs ((cairo_t*)handle->ptr, _glyphs, length);
		cairo_glyph_free (_glyphs);

	}


	void lime_cairo_show_page (value handle) {

		cairo_show_page ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_show_page) (HL_CFFIPointer* handle) {

		cairo_show_page ((cairo_t*)handle->ptr);

	}


	void lime_cairo_show_text (value handle, HxString text) {

		cairo_show_text ((cairo_t*)val_data (handle), (char*)text.__s);

	}


	HL_PRIM void HL_NAME(hl_cairo_show_text) (HL_CFFIPointer* handle, hl_vstring* text) {

		cairo_show_text ((cairo_t*)handle->ptr, (char*)hl_to_utf8 ((const uchar*)text->bytes));

	}


	int lime_cairo_status (value handle) {

		return cairo_status ((cairo_t*)val_data (handle));

	}


	HL_PRIM int HL_NAME(hl_cairo_status) (HL_CFFIPointer* handle) {

		return cairo_status ((cairo_t*)handle->ptr);

	}


	void lime_cairo_stroke (value handle) {

		cairo_stroke ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_stroke) (HL_CFFIPointer* handle) {

		cairo_stroke ((cairo_t*)handle->ptr);

	}


	void lime_cairo_stroke_extents (value handle, double x1, double y1, double x2, double y2) {

		cairo_stroke_extents ((cairo_t*)val_data (handle), &x1, &y1, &x2, &y2);

	}


	HL_PRIM void HL_NAME(hl_cairo_stroke_extents) (HL_CFFIPointer* handle, double x1, double y1, double x2, double y2) {

		cairo_stroke_extents ((cairo_t*)handle->ptr, &x1, &y1, &x2, &y2);

	}


	void lime_cairo_stroke_preserve (value handle) {

		cairo_stroke_preserve ((cairo_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_stroke_preserve) (HL_CFFIPointer* handle) {

		cairo_stroke_preserve ((cairo_t*)handle->ptr);

	}


	void lime_cairo_surface_flush (value handle) {

		cairo_surface_flush ((cairo_surface_t*)val_data (handle));

	}


	HL_PRIM void HL_NAME(hl_cairo_surface_flush) (HL_CFFIPointer* handle) {

		cairo_surface_flush ((cairo_surface_t*)handle->ptr);

	}


	void lime_cairo_text_path (value handle, HxString text) {

		cairo_text_path ((cairo_t*)val_data (handle), (char*)text.__s);

	}


	HL_PRIM void HL_NAME(hl_cairo_text_path) (HL_CFFIPointer* handle, hl_vstring* text) {

		cairo_text_path ((cairo_t*)handle->ptr, (char*)hl_to_utf8 ((const uchar*)text->bytes));

	}


	void lime_cairo_transform (value handle, value matrix) {

		Matrix3 mat3 = Matrix3 (matrix);

		cairo_matrix_t cm;
		cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);

		cairo_transform ((cairo_t*)val_data (handle), &cm);

	}


	HL_PRIM void HL_NAME(hl_cairo_transform) (HL_CFFIPointer* handle, Matrix3* matrix) {

		// cairo_matrix_t cm;
		// cairo_matrix_init (&cm, mat3.a, mat3.b, mat3.c, mat3.d, mat3.tx, mat3.ty);

		// cairo_transform ((cairo_t*)handle->ptr, &cm);

		cairo_transform ((cairo_t*)handle->ptr, (cairo_matrix_t*)&matrix->a);

	}


	void lime_cairo_translate (value handle, double x, double y) {

		cairo_translate ((cairo_t*)val_data (handle), x, y);

	}


	HL_PRIM void HL_NAME(hl_cairo_translate) (HL_CFFIPointer* handle, double x, double y) {

		cairo_translate ((cairo_t*)handle->ptr, x, y);

	}


	int lime_cairo_version () {

		return cairo_version ();

	}


	HL_PRIM int HL_NAME(hl_cairo_version) () {

		return cairo_version ();

	}


	HxString lime_cairo_version_string () {

		const char* version = cairo_version_string ();
		return version ? HxString (version) : HxString (0, 0);

	}


	HL_PRIM vbyte* HL_NAME(hl_cairo_version_string) () {

		const char* version = cairo_version_string ();
		int length = strlen (version);
		char* _version = (char*)malloc (length + 1);
		strcpy (_version, version);
		return (vbyte*)_version;

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
	DEFINE_PRIME3 (lime_cairo_image_surface_create);
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


	#define _TCFFIPOINTER _DYN
	#define _TMATRIX3 _OBJ (_F64 _F64 _F64 _F64 _F64 _F64)
	#define _TVECTOR2 _OBJ (_F64 _F64)

	DEFINE_HL_PRIM (_VOID, hl_cairo_arc, _TCFFIPOINTER _F64 _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_arc_negative, _TCFFIPOINTER _F64 _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_clip, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_clip_extents, _TCFFIPOINTER _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_clip_preserve, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_close_path, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_copy_page, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_create, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_curve_to, _TCFFIPOINTER _F64 _F64 _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_fill, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_fill_extents, _TCFFIPOINTER _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_fill_preserve, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_ft_font_face_create, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_I32, hl_cairo_font_face_status, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_font_options_create, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_cairo_font_options_get_antialias, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_font_options_get_subpixel_order, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_font_options_get_hint_style, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_font_options_get_hint_metrics, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_font_options_set_antialias, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_cairo_font_options_set_subpixel_order, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_cairo_font_options_set_hint_style, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_cairo_font_options_set_hint_metrics, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_I32, hl_cairo_get_antialias, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TVECTOR2, hl_cairo_get_current_point, _TCFFIPOINTER _TVECTOR2);
	DEFINE_HL_PRIM (_ARR, hl_cairo_get_dash, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_get_dash_count, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_get_fill_rule, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_get_font_face, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_get_font_options, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_get_group_target, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_get_line_cap, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_get_line_join, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_F64, hl_cairo_get_line_width, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TMATRIX3, hl_cairo_get_matrix, _TCFFIPOINTER _TMATRIX3);
	DEFINE_HL_PRIM (_F64, hl_cairo_get_miter_limit, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_get_operator, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_get_source, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_get_target, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_F64, hl_cairo_get_tolerance, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_cairo_has_current_point, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_identity_matrix, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_image_surface_create, _I32 _I32 _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_image_surface_create_for_data, _F64 _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_F64, hl_cairo_image_surface_get_data, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_image_surface_get_format, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_image_surface_get_height, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_image_surface_get_stride, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_image_surface_get_width, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_cairo_in_clip, _TCFFIPOINTER _F64 _F64);
	DEFINE_HL_PRIM (_BOOL, hl_cairo_in_fill, _TCFFIPOINTER _F64 _F64);
	DEFINE_HL_PRIM (_BOOL, hl_cairo_in_stroke, _TCFFIPOINTER _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_line_to, _TCFFIPOINTER _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_mask, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_mask_surface, _TCFFIPOINTER _TCFFIPOINTER _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_move_to, _TCFFIPOINTER _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_new_path, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_paint, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_paint_with_alpha, _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_pattern_add_color_stop_rgb, _TCFFIPOINTER _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_pattern_add_color_stop_rgba, _TCFFIPOINTER _F64 _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_pattern_create_for_surface, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_pattern_create_linear, _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_pattern_create_radial, _F64 _F64 _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_pattern_create_rgb, _F64 _F64 _F64);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_pattern_create_rgba, _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_I32, hl_cairo_pattern_get_color_stop_count, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_pattern_get_extend, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_cairo_pattern_get_filter, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TMATRIX3, hl_cairo_pattern_get_matrix, _TCFFIPOINTER _TMATRIX3);
	DEFINE_HL_PRIM (_VOID, hl_cairo_pattern_set_extend, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_cairo_pattern_set_filter, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_cairo_pattern_set_matrix, _TCFFIPOINTER _TMATRIX3);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_cairo_pop_group, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_pop_group_to_source, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_push_group, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_push_group_with_content, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_cairo_rectangle, _TCFFIPOINTER _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_rel_curve_to, _TCFFIPOINTER _F64 _F64 _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_rel_line_to, _TCFFIPOINTER _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_rel_move_to, _TCFFIPOINTER _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_reset_clip, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_restore, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_rotate, _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_save, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_scale, _TCFFIPOINTER _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_antialias, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_dash, _TCFFIPOINTER _ARR);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_fill_rule, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_font_face, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_font_size, _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_font_options, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_line_cap, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_line_join, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_line_width, _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_matrix, _TCFFIPOINTER _TMATRIX3);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_miter_limit, _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_operator, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_source, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_source_rgb, _TCFFIPOINTER _F64 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_source_rgba, _TCFFIPOINTER _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_source_surface, _TCFFIPOINTER _TCFFIPOINTER _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_set_tolerance, _TCFFIPOINTER _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_show_glyphs, _TCFFIPOINTER _ARR);
	DEFINE_HL_PRIM (_VOID, hl_cairo_show_page, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_show_text, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_I32, hl_cairo_status, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_stroke, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_stroke_extents, _TCFFIPOINTER _F64 _F64 _F64 _F64);
	DEFINE_HL_PRIM (_VOID, hl_cairo_stroke_preserve, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_surface_flush, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_cairo_text_path, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_VOID, hl_cairo_transform, _TCFFIPOINTER _TMATRIX3);
	DEFINE_HL_PRIM (_VOID, hl_cairo_translate, _TCFFIPOINTER _F64 _F64);
	DEFINE_HL_PRIM (_I32, hl_cairo_version, _NO_ARG);
	DEFINE_HL_PRIM (_BYTES, hl_cairo_version_string, _NO_ARG);


}


extern "C" int lime_cairo_register_prims () {

	return 0;

}