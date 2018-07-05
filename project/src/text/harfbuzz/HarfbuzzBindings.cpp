#include <hx/CFFIPrime.h>
#include <math/Vector2.h>
#include <system/CFFIPointer.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <hb.h>
#include <hb-ft.h>
#include <map>
#include <text/Font.h>


namespace lime {
	
	
	value lime_hb_blob_create (double data, int length, int memoryMode) {
		
		hb_blob_t* blob = hb_blob_create ((const char*)(uintptr_t)data, length, (hb_memory_mode_t)memoryMode, 0, 0);
		return CFFIPointer (blob);
		
	}
	
	
	value lime_hb_blob_create_sub_blob (value parent, int offset, int length) {
		
		hb_blob_t* blob = hb_blob_create_sub_blob ((hb_blob_t*)val_data (parent), offset, length);
		return CFFIPointer (blob);
		
	}
	
	
	double lime_hb_blob_get_data (value blob) {
		
		unsigned int length = 0;
		return (uintptr_t)hb_blob_get_data ((hb_blob_t*)val_data (blob), &length);
		
	}
	
	
	double lime_hb_blob_get_data_writable (value blob) {
		
		unsigned int length = 0;
		return (uintptr_t)hb_blob_get_data ((hb_blob_t*)val_data (blob), &length);
		
	}
	
	
	value lime_hb_blob_get_empty () {
		
		hb_blob_t* blob = hb_blob_get_empty ();
		return CFFIPointer (blob);
		
	}
	
	
	int lime_hb_blob_get_length (value blob) {
		
		return hb_blob_get_length ((hb_blob_t*)val_data (blob));
		
	}
	
	
	bool lime_hb_blob_is_immutable (value blob) {
		
		return hb_blob_is_immutable ((hb_blob_t*)val_data (blob));
		
	}
	
	
	void lime_hb_blob_make_immutable (value blob) {
		
		hb_blob_make_immutable ((hb_blob_t*)val_data (blob));
		
	}
	
	
	void lime_hb_buffer_add (value buffer, int codepoint, int cluster) {
		
		hb_buffer_add ((hb_buffer_t*)val_data (buffer), (hb_codepoint_t)codepoint, cluster);
		
	}
	
	
	void lime_hb_buffer_add_codepoints (value buffer, double text, int textLength, int itemOffset, int itemLength) {
		
		hb_buffer_add_codepoints ((hb_buffer_t*)val_data (buffer), (const hb_codepoint_t*)(uintptr_t)text, textLength, itemOffset, itemLength);
		
	}
	
	
	void lime_hb_buffer_add_utf8 (value buffer, HxString text, int itemOffset, int itemLength) {
		
		hb_buffer_add_utf8 ((hb_buffer_t*)val_data (buffer), text.c_str (), text.length, itemOffset, itemLength);
		
	}
	
	
	void lime_hb_buffer_add_utf16 (value buffer, double text, int textLength, int itemOffset, int itemLength) {
		
		hb_buffer_add_utf16 ((hb_buffer_t*)val_data (buffer), (const uint16_t*)(uintptr_t)text, textLength, itemOffset, itemLength);
		
	}
	
	
	void lime_hb_buffer_add_utf32 (value buffer, double text, int textLength, int itemOffset, int itemLength) {
		
		hb_buffer_add_utf32 ((hb_buffer_t*)val_data (buffer), (const uint32_t*)(uintptr_t)text, textLength, itemOffset, itemLength);
		
	}
	
	
	bool lime_hb_buffer_allocation_successful (value buffer) {
		
		return hb_buffer_allocation_successful ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	void lime_hb_buffer_clear_contents (value buffer) {
		
		hb_buffer_clear_contents ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	value lime_hb_buffer_create () {
		
		hb_buffer_t* buffer = hb_buffer_create ();
		return CFFIPointer (buffer);
		
	}
	
	
	int lime_hb_buffer_get_cluster_level (value buffer) {
		
		return hb_buffer_get_cluster_level ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	int lime_hb_buffer_get_content_type (value buffer) {
		
		return hb_buffer_get_content_type ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	int lime_hb_buffer_get_direction (value buffer) {
		
		return hb_buffer_get_direction ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	value lime_hb_buffer_get_empty () {
		
		hb_buffer_t* buffer = hb_buffer_get_empty ();
		return CFFIPointer (buffer);
		
	}
	
	
	int lime_hb_buffer_get_flags (value buffer) {
		
		return hb_buffer_get_flags ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	struct HBGlyphInfo {
		
		int codepoint;
		int mask;
		int cluster;
		
	};
	
	
	value lime_hb_buffer_get_glyph_infos (value buffer, value bytes) {
		
		unsigned int length = 0;
		hb_glyph_info_t* info = hb_buffer_get_glyph_infos ((hb_buffer_t*)val_data (buffer), &length);
		
		if (length > 0) {
			
			Bytes _bytes = Bytes (bytes);
			_bytes.Resize (length * sizeof (HBGlyphInfo));
			
			HBGlyphInfo* glyphInfo = (HBGlyphInfo*)_bytes.b;
			
			for (int i = 0; i < length; i++, info++, glyphInfo++) {
				
				glyphInfo->codepoint = info->codepoint;
				glyphInfo->mask = info->mask;
				glyphInfo->cluster = info->cluster;
				
			}
			
			return _bytes.Value (bytes);
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	struct HBGlyphPosition {
		
		int xAdvance;
		int yAdvance;
		int xOffset;
		int yOffset;
		
	};
	
	
	value lime_hb_buffer_get_glyph_positions (value buffer, value bytes) {
		
		unsigned int length = 0;
		hb_glyph_position_t* positions = hb_buffer_get_glyph_positions ((hb_buffer_t*)val_data (buffer), &length);
		
		if (length > 0) {
			
			Bytes _bytes = Bytes (bytes);
			_bytes.Resize (length * sizeof (HBGlyphPosition));
			
			HBGlyphPosition* glyphPosition = (HBGlyphPosition*)_bytes.b;
			
			for (int i = 0; i < length; i++, positions++, glyphPosition++) {
				
				glyphPosition->xAdvance = positions->x_advance;
				glyphPosition->yAdvance = positions->y_advance;
				glyphPosition->xOffset = positions->x_offset;
				glyphPosition->yOffset = positions->y_offset;
				
			}
			
			return _bytes.Value (bytes);
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	value lime_hb_buffer_get_language (value buffer) {
		
		hb_language_t language = hb_buffer_get_language ((hb_buffer_t*)val_data (buffer));
		return CFFIPointer (&language);
		
	}
	
	
	int lime_hb_buffer_get_length (value buffer) {
		
		return hb_buffer_get_length ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	int lime_hb_buffer_get_replacement_codepoint (value buffer) {
		
		return hb_buffer_get_replacement_codepoint ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	int lime_hb_buffer_get_script (value buffer) {
		
		return hb_buffer_get_script ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	void lime_hb_buffer_get_segment_properties (value buffer, value props) {
		
		hb_buffer_get_segment_properties ((hb_buffer_t*)val_data (buffer), (hb_segment_properties_t*)val_data (props));
		
	}
	
	
	void lime_hb_buffer_guess_segment_properties (value buffer) {
		
		hb_buffer_guess_segment_properties ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	void lime_hb_buffer_normalize_glyphs (value buffer) {
		
		hb_buffer_normalize_glyphs ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	bool lime_hb_buffer_preallocate (value buffer, int size) {
		
		return hb_buffer_pre_allocate ((hb_buffer_t*)val_data (buffer), size);
		
	}
	
	
	void lime_hb_buffer_reset (value buffer) {
		
		hb_buffer_reset ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	void lime_hb_buffer_reverse (value buffer) {
		
		hb_buffer_reverse ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	void lime_hb_buffer_reverse_clusters (value buffer) {
		
		hb_buffer_reverse_clusters ((hb_buffer_t*)val_data (buffer));
		
	}
	
	
	int lime_hb_buffer_serialize_format_from_string (HxString str) {
		
		return hb_buffer_serialize_format_from_string (str.c_str (), str.length);
		
	}
	
	
	value lime_hb_buffer_serialize_format_to_string (int format) {
		
		const char* result = hb_buffer_serialize_format_to_string ((hb_buffer_serialize_format_t)format);
		
		if (result) return alloc_string (result);
		return alloc_null ();
		
	}
	
	
	value lime_hb_buffer_serialize_list_formats () {
		
		const char** formats = hb_buffer_serialize_list_formats ();
		
		if (formats) {
			
			int length = sizeof (formats) / sizeof (char);
			value result = alloc_array (length);
			
			for (int i = 0; i < length; i++) {
				
				val_array_set_i (result, i, alloc_string (formats[i]));
				
			}
			
			return result;
			
		} else {
			
			return alloc_array (0);
			
		}
		
	}
	
	
	void lime_hb_buffer_set_cluster_level (value buffer, int clusterLevel) {
		
		hb_buffer_set_cluster_level ((hb_buffer_t*)val_data (buffer), (hb_buffer_cluster_level_t)clusterLevel);
		
	}
	
	
	void lime_hb_buffer_set_content_type (value buffer, int contentType) {
		
		hb_buffer_set_content_type ((hb_buffer_t*)val_data (buffer), (hb_buffer_content_type_t)contentType);
		
	}
	
	
	void lime_hb_buffer_set_direction (value buffer, int direction) {
		
		hb_buffer_set_direction ((hb_buffer_t*)val_data (buffer), (hb_direction_t)direction);
		
	}
	
	
	void lime_hb_buffer_set_flags (value buffer, int flags) {
		
		hb_buffer_set_flags ((hb_buffer_t*)val_data (buffer), (hb_buffer_flags_t)flags);
		
	}
	
	
	void lime_hb_buffer_set_language (value buffer, value language) {
		
		hb_buffer_set_language ((hb_buffer_t*)val_data (buffer), *(hb_language_t*)val_data (language));
		
	}
	
	
	bool lime_hb_buffer_set_length (value buffer, int length) {
		
		return hb_buffer_set_length ((hb_buffer_t*)val_data (buffer), length);
		
	}
	
	
	void lime_hb_buffer_set_replacement_codepoint (value buffer, int replacement) {
		
		hb_buffer_set_replacement_codepoint ((hb_buffer_t*)val_data (buffer), (hb_codepoint_t)replacement);
		
	}
	
	
	void lime_hb_buffer_set_script (value buffer, int script) {
		
		script = HB_SCRIPT_COMMON;
		
		// TODO: COMMON is an int32 and doesn't translate properly on Neko
		
		hb_buffer_set_script ((hb_buffer_t*)val_data (buffer), (hb_script_t)script);
		
	}
	
	
	void lime_hb_buffer_set_segment_properties (value buffer, value props) {
		
		hb_buffer_set_segment_properties ((hb_buffer_t*)val_data (buffer), (const hb_segment_properties_t*)val_data (props));
		
	}
	
	
	value lime_hb_face_create (value blob, int index) {
		
		hb_face_t* face = hb_face_create ((hb_blob_t*)val_data (blob), index);
		return CFFIPointer (face);
		
	}
	
	
	value lime_hb_face_get_empty () {
		
		hb_face_t* face = hb_face_get_empty ();
		return CFFIPointer (face);
		
	}
	
	
	int lime_hb_face_get_glyph_count (value face) {
		
		return hb_face_get_glyph_count ((hb_face_t*)val_data (face));
		
	}
	
	
	int lime_hb_face_get_index (value face) {
		
		return hb_face_get_index ((hb_face_t*)val_data (face));
		
	}
	
	
	int lime_hb_face_get_upem (value face) {
		
		return hb_face_get_upem ((hb_face_t*)val_data (face));
		
	}
	
	
	bool lime_hb_face_is_immutable (value face) {
		
		return hb_face_is_immutable ((hb_face_t*)val_data (face));
		
	}
	
	
	void lime_hb_face_make_immutable (value face) {
		
		hb_face_make_immutable ((hb_face_t*)val_data (face));
		
	}
	
	
	value lime_hb_face_reference_blob (value face) {
		
		hb_blob_t* blob = hb_face_reference_blob ((hb_face_t*)val_data (face));
		return CFFIPointer (blob);
		
	}
	
	
	value lime_hb_face_reference_table (value face, int tag) {
		
		hb_blob_t* blob = hb_face_reference_table ((hb_face_t*)val_data (face), (hb_tag_t)tag);
		return CFFIPointer (blob);
		
	}
	
	
	void lime_hb_face_set_glyph_count (value face, int glyphCount) {
		
		hb_face_set_glyph_count ((hb_face_t*)val_data (face), glyphCount);
		
	}
	
	
	void lime_hb_face_set_index (value face, int index) {
		
		hb_face_set_index ((hb_face_t*)val_data (face), index);
		
	}
	
	
	void lime_hb_face_set_upem (value face, int upem) {
		
		hb_face_set_upem ((hb_face_t*)val_data (face), upem);
		
	}
	
	
	value lime_hb_feature_from_string (HxString str) {
		
		hb_feature_t feature;
		
		if (hb_feature_from_string (str.c_str (), str.length, &feature)) {
			
			// TODO;
			return alloc_null ();
			//return CFFIPointer (feature);
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	value lime_hb_feature_to_string (value feature) {
		
		char result[128];
		hb_feature_to_string ((hb_feature_t*)val_data (feature), result, 128);
		return alloc_string (result);
		
	}
	
	
	void lime_hb_font_add_glyph_origin_for_direction (value font, int glyph, int direction, int x, int y) {
		
		hb_font_add_glyph_origin_for_direction ((hb_font_t*)val_data (font), (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);
		
	}
	
	
	value lime_hb_font_create (value face) {
		
		hb_font_t* font = hb_font_create ((hb_face_t*)val_data (face));
		return CFFIPointer (font);
		
	}
	
	
	value lime_hb_font_create_sub_font (value parent) {
		
		hb_font_t* font = hb_font_create_sub_font ((hb_font_t*)val_data (parent));
		return CFFIPointer (font);
		
	}
	
	
	value lime_hb_font_get_empty () {
		
		hb_font_t* font = hb_font_get_empty ();
		return CFFIPointer (font);
		
	}
	
	
	value lime_hb_font_get_face (value font) {
		
		hb_face_t* face = hb_font_get_face ((hb_font_t*)val_data (font));
		return CFFIPointer (face);
		
	}
	
	
	value lime_hb_font_get_glyph_advance_for_direction (value font, int glyph, int direction) {
		
		hb_position_t x;
		hb_position_t y;
		hb_font_get_glyph_advance_for_direction ((hb_font_t*)val_data (font), (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);
		Vector2 result = Vector2 (x, y);
		return result.Value ();
		
	}
	
	
	value lime_hb_font_get_glyph_kerning_for_direction (value font, int firstGlyph, int secondGlyph, int direction) {
		
		hb_position_t x;
		hb_position_t y;
		hb_font_get_glyph_kerning_for_direction ((hb_font_t*)val_data (font), (hb_codepoint_t)firstGlyph, (hb_codepoint_t)secondGlyph, (hb_direction_t)direction, &x, &y);
		Vector2 result = Vector2 (x, y);
		return result.Value ();
		
	}
	
	
	value lime_hb_font_get_glyph_origin_for_direction (value font, int glyph, int direction) {
		
		hb_position_t x;
		hb_position_t y;
		hb_font_get_glyph_origin_for_direction ((hb_font_t*)val_data (font), (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);
		Vector2 result = Vector2 (x, y);
		return result.Value ();
		
	}
	
	
	value lime_hb_font_get_parent (value font) {
		
		hb_font_t* parent = hb_font_get_parent ((hb_font_t*)val_data (font));
		return CFFIPointer (parent);
		
	}
	
	
	value lime_hb_font_get_ppem (value font) {
		
		int xppem = 0;
		int yppem = 0;
		hb_font_get_scale ((hb_font_t*)val_data (font), &xppem, &yppem);
		Vector2 result = Vector2 (xppem, yppem);
		return result.Value ();
		
	}
	
	
	value lime_hb_font_get_scale (value font) {
		
		int xScale = 0;
		int yScale = 0;
		hb_font_get_scale ((hb_font_t*)val_data (font), &xScale, &yScale);
		Vector2 result = Vector2 (xScale, yScale);
		return result.Value ();
		
	}
	
	
	int lime_hb_font_glyph_from_string (value font, HxString s) {
		
		hb_codepoint_t glyph = 0;
		
		if (hb_font_glyph_from_string ((hb_font_t*)val_data (font), s.c_str (), s.length, &glyph)) {
			
			return glyph;
			
		} else {
			
			return -1;
			
		}
		
	}
	
	
	value lime_hb_font_glyph_to_string (value font, int codepoint) {
		
		char result[1024];
		hb_font_glyph_to_string ((hb_font_t*)val_data (font), (hb_codepoint_t)codepoint, result, 1024);
		return alloc_string (result);
		
	}
	
	
	bool lime_hb_font_is_immutable (value font) {
		
		return hb_font_is_immutable ((hb_font_t*)val_data (font));
		
	}
	
	
	void lime_hb_font_make_immutable (value font) {
		
		hb_font_make_immutable ((hb_font_t*)val_data (font));
		
	}
	
	
	void lime_hb_font_set_ppem (value font, int xppem, int yppem) {
		
		hb_font_set_ppem ((hb_font_t*)val_data (font), xppem, yppem);
		
	}
	
	
	void lime_hb_font_set_scale (value font, int xScale, int yScale) {
		
		hb_font_set_scale ((hb_font_t*)val_data (font), xScale, yScale);
		
	}
	
	
	void lime_hb_font_subtract_glyph_origin_for_direction (value font, int glyph, int direction, int x, int y) {
		
		hb_font_subtract_glyph_origin_for_direction ((hb_font_t*)val_data (font), (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);
		
	}
	
	
	value lime_hb_ft_font_create (value font) {
		
		Font* _font = (Font*)val_data (font);
		hb_font_t* __font = hb_ft_font_create ((FT_Face)_font->face, NULL);
		return CFFIPointer (__font);
		
	}
	
	
	value lime_hb_ft_font_create_referenced (value font) {
		
		Font* _font = (Font*)val_data (font);
		hb_font_t* __font = hb_ft_font_create_referenced ((FT_Face)_font->face);
		return CFFIPointer (__font);
		
	}
	
	
	int lime_hb_ft_font_get_load_flags (value font) {
		
		return hb_ft_font_get_load_flags ((hb_font_t*)val_data (font));
		
	}
	
	
	void lime_hb_ft_font_set_load_flags (value font, int loadFlags) {
		
		hb_ft_font_set_load_flags ((hb_font_t*)val_data (font), loadFlags);
		
	}
	
	
	value lime_hb_language_from_string (HxString str) {
		
		hb_language_t language = hb_language_from_string (str.c_str (), str.length);
		return CFFIPointer (&language);
		
	}
	
	
	value lime_hb_language_get_default () {
		
		hb_language_t language = hb_language_get_default ();
		return CFFIPointer (&language);
		
	}
	
	
	value lime_hb_language_to_string (value language) {
		
		hb_language_t* _language = (hb_language_t*)val_data (language);
		const char* result = hb_language_to_string (*_language);
		return alloc_string (result);
		
	}
	
	
	bool lime_hb_segment_properties_equal (value a, value b) {
		
		return hb_segment_properties_equal ((hb_segment_properties_t*)val_data (a), (hb_segment_properties_t*)val_data (b));
		
	}
	
	
	int lime_hb_segment_properties_hash (value p) {
		
		return hb_segment_properties_hash ((hb_segment_properties_t*)val_data (p));
		
	}
	
	
	void lime_hb_set_add (value set, int codepoint) {
		
		hb_set_add ((hb_set_t*)val_data (set), (hb_codepoint_t)codepoint);
		
	}
	
	
	void lime_hb_set_add_range (value set, int first, int last) {
		
		hb_set_add_range ((hb_set_t*)val_data (set), (hb_codepoint_t)first, (hb_codepoint_t)last);
		
	}
	
	
	bool lime_hb_set_allocation_successful (value set) {
		
		return hb_set_allocation_successful ((hb_set_t*)val_data (set));
		
	}
	
	
	void lime_hb_set_clear (value set) {
		
		hb_set_clear ((hb_set_t*)val_data (set));
		
	}
	
	
	value lime_hb_set_create () {
		
		hb_set_t* set = hb_set_create ();
		return CFFIPointer (set);
		
	}
	
	
	void lime_hb_set_del (value set, int codepoint) {
		
		hb_set_del ((hb_set_t*)val_data (set), (hb_codepoint_t)codepoint);
		
	}
	
	
	void lime_hb_set_del_range (value set, int first, int last) {
		
		hb_set_del_range ((hb_set_t*)val_data (set), (hb_codepoint_t)first, (hb_codepoint_t)last);
		
	}
	
	
	value lime_hb_set_get_empty () {
		
		hb_set_t* set = hb_set_get_empty ();
		return CFFIPointer (set);
		
	}
	
	
	int lime_hb_set_get_max (value set) {
		
		return hb_set_get_max ((hb_set_t*)val_data (set));
		
	}
	
	
	int lime_hb_set_get_min (value set) {
		
		return hb_set_get_min ((hb_set_t*)val_data (set));
		
	}
	
	
	int lime_hb_set_get_population (value set) {
		
		return hb_set_get_population ((hb_set_t*)val_data (set));
		
	}
	
	
	bool lime_hb_set_has (value set, int codepoint) {
		
		return hb_set_has ((hb_set_t*)val_data (set), (hb_codepoint_t)codepoint);
		
	}
	
	
	void lime_hb_set_intersect (value set, value other) {
		
		return hb_set_intersect ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));
		
	}
	
	
	void lime_hb_set_invert (value set) {
		
		hb_set_invert ((hb_set_t*)val_data (set));
		
	}
	
	
	bool lime_hb_set_is_empty (value set) {
		
		return hb_set_is_empty ((hb_set_t*)val_data (set));
		
	}
	
	
	bool lime_hb_set_is_equal (value set, value other) {
		
		return hb_set_is_equal ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));
		
	}
	
	
	int lime_hb_set_next (value set) {
		
		hb_codepoint_t codepoint = 0;
		
		if (hb_set_next ((hb_set_t*)val_data (set), &codepoint)) {
			
			return codepoint;
			
		} else {
			
			return -1;
			
		}
		
	}
	
	
	value lime_hb_set_next_range (value set) {
		
		hb_codepoint_t first = 0;
		hb_codepoint_t last = 0;
		
		if (hb_set_next_range ((hb_set_t*)val_data (set), &first, &last)) {
			
			Vector2 result = Vector2 (first, last);
			return result.Value ();
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
	void lime_hb_set_set (value set, value other) {
		
		return hb_set_set ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));
		
	}
	
	
	void lime_hb_set_subtract (value set, value other) {
		
		return hb_set_subtract ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));
		
	}
	
	
	void lime_hb_set_symmetric_difference (value set, value other) {
		
		return hb_set_symmetric_difference ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));
		
	}
	
	
	void lime_hb_set_union (value set, value other) {
		
		return hb_set_union ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));
		
	}
	
	
	void lime_hb_shape (value font, value buffer, value features) {
		
		int length = !val_is_null (features) ? val_array_size (features) : 0;
		double* _features = !val_is_null (features) ? val_array_double (features) : NULL;
		hb_shape ((hb_font_t*)val_data (font), (hb_buffer_t*)val_data (buffer), (const hb_feature_t*)(uintptr_t*)_features, length);
		
	}
	
	
	//hb_blob_destroy
	//hb_blob_get_user_data
	//hb_blob_reference
	//hb_blob_set_user_data
	//hb_buffer_deserialize_glyphs
	//hb_buffer_destroy
	//hb_buffer_get_unicode_funcs
	//hb_buffer_get_user_data
	//hb_buffer_reference
	//hb_buffer_serialize_glyphs
	//hb_buffer_set_unicode_funcs
	//hb_buffer_set_user_data
	//hb_face_create_for_tables
	//hb_face_destroy
	//hb_face_get_user_data
	//hb_face_reference
	//hb_face_set_user_data
	//hb_font_destroy
	//hb_font_get_glyph_contour_point_for_origin
	//hb_font_get_glyph_extents_for_origin
	//hb_font_get_user_data
	//hb_font_reference
	//hb_font_set_user_data
	//hb_ft_face_create
	//hb_ft_face_create_cached
	//hb_ft_face_create_referenced
	//hb_ft_font_create
	//hb_ft_font_get_face
	//hb_ft_font_set_funcs
	//hb_set_destroy
	//hb_set_get_user_data
	//hb_set_reference
	//hb_set_set_user_data
	//hb_shape_full
	
	
	DEFINE_PRIME3 (lime_hb_blob_create);
	DEFINE_PRIME3 (lime_hb_blob_create_sub_blob);
	DEFINE_PRIME1v (lime_hb_blob_get_data);
	DEFINE_PRIME1v (lime_hb_blob_get_data_writable);
	DEFINE_PRIME0 (lime_hb_blob_get_empty);
	DEFINE_PRIME1v (lime_hb_blob_get_length);
	DEFINE_PRIME1v (lime_hb_blob_is_immutable);
	DEFINE_PRIME1v (lime_hb_blob_make_immutable);
	DEFINE_PRIME3v (lime_hb_buffer_add);
	DEFINE_PRIME5v (lime_hb_buffer_add_codepoints);
	DEFINE_PRIME4v (lime_hb_buffer_add_utf8);
	DEFINE_PRIME5v (lime_hb_buffer_add_utf16);
	DEFINE_PRIME5v (lime_hb_buffer_add_utf32);
	DEFINE_PRIME1 (lime_hb_buffer_allocation_successful);
	DEFINE_PRIME1v (lime_hb_buffer_clear_contents);
	DEFINE_PRIME0 (lime_hb_buffer_create);
	DEFINE_PRIME1 (lime_hb_buffer_get_cluster_level);
	DEFINE_PRIME1 (lime_hb_buffer_get_content_type);
	DEFINE_PRIME1 (lime_hb_buffer_get_direction);
	DEFINE_PRIME0 (lime_hb_buffer_get_empty);
	DEFINE_PRIME1 (lime_hb_buffer_get_flags);
	DEFINE_PRIME2 (lime_hb_buffer_get_glyph_infos);
	DEFINE_PRIME2 (lime_hb_buffer_get_glyph_positions);
	DEFINE_PRIME1 (lime_hb_buffer_get_length);
	DEFINE_PRIME1 (lime_hb_buffer_get_replacement_codepoint);
	DEFINE_PRIME1 (lime_hb_buffer_get_script);
	DEFINE_PRIME2v (lime_hb_buffer_get_segment_properties);
	DEFINE_PRIME1 (lime_hb_buffer_get_language);
	DEFINE_PRIME1v (lime_hb_buffer_guess_segment_properties);
	DEFINE_PRIME1v (lime_hb_buffer_normalize_glyphs);
	DEFINE_PRIME2 (lime_hb_buffer_preallocate);
	DEFINE_PRIME1v (lime_hb_buffer_reset);
	DEFINE_PRIME1v (lime_hb_buffer_reverse);
	DEFINE_PRIME1v (lime_hb_buffer_reverse_clusters);
	DEFINE_PRIME1 (lime_hb_buffer_serialize_format_from_string);
	DEFINE_PRIME1 (lime_hb_buffer_serialize_format_to_string);
	DEFINE_PRIME0 (lime_hb_buffer_serialize_list_formats);
	DEFINE_PRIME2v (lime_hb_buffer_set_cluster_level);
	DEFINE_PRIME2v (lime_hb_buffer_set_content_type);
	DEFINE_PRIME2v (lime_hb_buffer_set_direction);
	DEFINE_PRIME2v (lime_hb_buffer_set_flags);
	DEFINE_PRIME2v (lime_hb_buffer_set_language);
	DEFINE_PRIME2 (lime_hb_buffer_set_length);
	DEFINE_PRIME2v (lime_hb_buffer_set_replacement_codepoint);
	DEFINE_PRIME2v (lime_hb_buffer_set_script);
	DEFINE_PRIME2v (lime_hb_buffer_set_segment_properties);
	DEFINE_PRIME2 (lime_hb_face_create);
	DEFINE_PRIME0 (lime_hb_face_get_empty);
	DEFINE_PRIME1 (lime_hb_face_get_glyph_count);
	DEFINE_PRIME1 (lime_hb_face_get_index);
	DEFINE_PRIME1 (lime_hb_face_get_upem);
	DEFINE_PRIME1 (lime_hb_face_is_immutable);
	DEFINE_PRIME1v (lime_hb_face_make_immutable);
	DEFINE_PRIME1 (lime_hb_face_reference_blob);
	DEFINE_PRIME2 (lime_hb_face_reference_table);
	DEFINE_PRIME2v (lime_hb_face_set_index);
	DEFINE_PRIME2v (lime_hb_face_set_glyph_count);
	DEFINE_PRIME2v (lime_hb_face_set_upem);
	DEFINE_PRIME1 (lime_hb_feature_from_string);
	DEFINE_PRIME1 (lime_hb_feature_to_string);
	DEFINE_PRIME5v (lime_hb_font_add_glyph_origin_for_direction);
	DEFINE_PRIME1 (lime_hb_font_create);
	DEFINE_PRIME1 (lime_hb_font_create_sub_font);
	DEFINE_PRIME0 (lime_hb_font_get_empty);
	DEFINE_PRIME1 (lime_hb_font_get_face);
	DEFINE_PRIME3 (lime_hb_font_get_glyph_advance_for_direction);
	DEFINE_PRIME4 (lime_hb_font_get_glyph_kerning_for_direction);
	DEFINE_PRIME3 (lime_hb_font_get_glyph_origin_for_direction);
	DEFINE_PRIME1 (lime_hb_font_get_parent);
	DEFINE_PRIME1 (lime_hb_font_get_ppem);
	DEFINE_PRIME1 (lime_hb_font_get_scale);
	DEFINE_PRIME2 (lime_hb_font_glyph_from_string);
	DEFINE_PRIME2 (lime_hb_font_glyph_to_string);
	DEFINE_PRIME1 (lime_hb_font_is_immutable);
	DEFINE_PRIME1v (lime_hb_font_make_immutable);
	DEFINE_PRIME3v (lime_hb_font_set_ppem);
	DEFINE_PRIME3v (lime_hb_font_set_scale);
	DEFINE_PRIME5v (lime_hb_font_subtract_glyph_origin_for_direction);
	DEFINE_PRIME1 (lime_hb_ft_font_create);
	DEFINE_PRIME1 (lime_hb_ft_font_create_referenced);
	DEFINE_PRIME1 (lime_hb_ft_font_get_load_flags);
	DEFINE_PRIME2v (lime_hb_ft_font_set_load_flags);
	DEFINE_PRIME1 (lime_hb_language_from_string);
	DEFINE_PRIME0 (lime_hb_language_get_default);
	DEFINE_PRIME1 (lime_hb_language_to_string);
	DEFINE_PRIME2 (lime_hb_segment_properties_equal);
	DEFINE_PRIME1v (lime_hb_segment_properties_hash);
	DEFINE_PRIME2v (lime_hb_set_add);
	DEFINE_PRIME3v (lime_hb_set_add_range);
	DEFINE_PRIME1 (lime_hb_set_allocation_successful);
	DEFINE_PRIME1v (lime_hb_set_clear);
	DEFINE_PRIME0 (lime_hb_set_create);
	DEFINE_PRIME2v (lime_hb_set_del);
	DEFINE_PRIME3v (lime_hb_set_del_range);
	DEFINE_PRIME0 (lime_hb_set_get_empty);
	DEFINE_PRIME1 (lime_hb_set_get_max);
	DEFINE_PRIME1 (lime_hb_set_get_min);
	DEFINE_PRIME1 (lime_hb_set_get_population);
	DEFINE_PRIME2 (lime_hb_set_has);
	DEFINE_PRIME2v (lime_hb_set_intersect);
	DEFINE_PRIME1v (lime_hb_set_invert);
	DEFINE_PRIME1 (lime_hb_set_is_empty);
	DEFINE_PRIME2 (lime_hb_set_is_equal);
	DEFINE_PRIME1 (lime_hb_set_next);
	DEFINE_PRIME1 (lime_hb_set_next_range);
	DEFINE_PRIME2v (lime_hb_set_set);
	DEFINE_PRIME2v (lime_hb_set_subtract);
	DEFINE_PRIME2v (lime_hb_set_symmetric_difference);
	DEFINE_PRIME2v (lime_hb_set_union);
	DEFINE_PRIME3v (lime_hb_shape);
	
	
}


extern "C" int lime_harfbuzz_register_prims () {
	
	return 0;
	
}
