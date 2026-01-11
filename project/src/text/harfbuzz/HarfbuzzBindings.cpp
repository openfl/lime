#include <math/Vector2.h>
#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <system/Mutex.h>
#include <text/Font.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <hb.h>
#include <hb-ft.h>
#include <map>


namespace lime {


	struct HBGlyphInfo {

		int codepoint;
		int mask;
		int cluster;

	};

	struct HBGlyphPosition {

		int xAdvance;
		int yAdvance;
		int xOffset;
		int yOffset;

	};


	void gc_hb_blob (value handle) {

		hb_blob_destroy ((hb_blob_t*)val_data (handle));
		val_gc (handle, 0);

	}


	void hl_gc_hb_blob (HL_CFFIPointer* handle) {

		hb_blob_destroy ((hb_blob_t*)handle->ptr);

	}


	void gc_hb_buffer (value handle) {

		hb_buffer_destroy ((hb_buffer_t*)val_data (handle));
		val_gc (handle, 0);

	}


	void hl_gc_hb_buffer (HL_CFFIPointer* handle) {

		hb_buffer_destroy ((hb_buffer_t*)handle->ptr);

	}


	void gc_hb_face (value handle) {

		hb_face_destroy ((hb_face_t*)val_data (handle));
		val_gc (handle, 0);

	}


	void hl_gc_hb_face (HL_CFFIPointer* handle) {

		hb_face_destroy ((hb_face_t*)handle->ptr);

	}


	void gc_hb_font (value handle) {

		hb_font_destroy ((hb_font_t*)val_data (handle));
		val_gc (handle, 0);

	}


	void hl_gc_hb_font (HL_CFFIPointer* handle) {

		hb_font_destroy ((hb_font_t*)handle->ptr);

	}


	void gc_hb_set (value handle) {

		hb_set_destroy ((hb_set_t*)val_data (handle));
		val_gc (handle, 0);

	}


	void hl_gc_hb_set (HL_CFFIPointer* handle) {

		hb_set_destroy ((hb_set_t*)handle->ptr);

	}


	value lime_hb_blob_create (double data, int length, int memoryMode) {

		hb_blob_t* blob = hb_blob_create ((const char*)(uintptr_t)data, length, (hb_memory_mode_t)memoryMode, 0, 0);
		return CFFIPointer (blob, gc_hb_blob);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_blob_create) (double data, int length, int memoryMode) {

		hb_blob_t* blob = hb_blob_create ((const char*)(uintptr_t)data, length, (hb_memory_mode_t)memoryMode, 0, 0);
		return HLCFFIPointer (blob, (hl_finalizer)hl_gc_hb_blob);

	}


	value lime_hb_blob_create_sub_blob (value parent, int offset, int length) {

		hb_blob_t* blob = hb_blob_create_sub_blob ((hb_blob_t*)val_data (parent), offset, length);
		return CFFIPointer (blob, gc_hb_blob);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_blob_create_sub_blob) (HL_CFFIPointer* parent, int offset, int length) {

		hb_blob_t* blob = hb_blob_create_sub_blob ((hb_blob_t*)parent->ptr, offset, length);
		return HLCFFIPointer (blob, (hl_finalizer)hl_gc_hb_blob);

	}


	double lime_hb_blob_get_data (value blob) {

		unsigned int length = 0;
		return (uintptr_t)hb_blob_get_data ((hb_blob_t*)val_data (blob), &length);

	}


	HL_PRIM double HL_NAME(hl_hb_blob_get_data) (HL_CFFIPointer* blob) {

		unsigned int length = 0;
		return (uintptr_t)hb_blob_get_data ((hb_blob_t*)blob->ptr, &length);

	}


	double lime_hb_blob_get_data_writable (value blob) {

		unsigned int length = 0;
		return (uintptr_t)hb_blob_get_data ((hb_blob_t*)val_data (blob), &length);

	}


	HL_PRIM double HL_NAME(hl_hb_blob_get_data_writable) (HL_CFFIPointer* blob) {

		unsigned int length = 0;
		return (uintptr_t)hb_blob_get_data ((hb_blob_t*)blob->ptr, &length);

	}


	value lime_hb_blob_get_empty () {

		hb_blob_t* blob = hb_blob_get_empty ();
		return CFFIPointer (blob, gc_hb_blob);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_blob_get_empty) () {

		hb_blob_t* blob = hb_blob_get_empty ();
		return HLCFFIPointer (blob, (hl_finalizer)hl_gc_hb_blob);

	}


	int lime_hb_blob_get_length (value blob) {

		return hb_blob_get_length ((hb_blob_t*)val_data (blob));

	}


	HL_PRIM int HL_NAME(hl_hb_blob_get_length) (HL_CFFIPointer* blob) {

		return hb_blob_get_length ((hb_blob_t*)blob->ptr);

	}


	bool lime_hb_blob_is_immutable (value blob) {

		return hb_blob_is_immutable ((hb_blob_t*)val_data (blob));

	}


	HL_PRIM bool HL_NAME(hl_hb_blob_is_immutable) (HL_CFFIPointer* blob) {

		return hb_blob_is_immutable ((hb_blob_t*)blob->ptr);

	}


	void lime_hb_blob_make_immutable (value blob) {

		hb_blob_make_immutable ((hb_blob_t*)val_data (blob));

	}


	HL_PRIM void HL_NAME(hl_hb_blob_make_immutable) (HL_CFFIPointer* blob) {

		hb_blob_make_immutable ((hb_blob_t*)blob->ptr);

	}


	void lime_hb_buffer_add (value buffer, int codepoint, int cluster) {

		hb_buffer_add ((hb_buffer_t*)val_data (buffer), (hb_codepoint_t)codepoint, cluster);

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_add) (HL_CFFIPointer* buffer, int codepoint, int cluster) {

		hb_buffer_add ((hb_buffer_t*)buffer->ptr, (hb_codepoint_t)codepoint, cluster);

	}


	void lime_hb_buffer_add_hxstring(value buffer, HxString text, int itemOffset, int itemLength) {

		if (hxs_encoding (text) == hx::StringUtf16) {

			hb_buffer_add_utf16 ((hb_buffer_t*)val_data(buffer), (const uint16_t*)text.c_str (), text.length, itemOffset, itemLength);

		} else {

			hb_buffer_add_utf8 ((hb_buffer_t*)val_data(buffer), text.c_str (), text.length, itemOffset, itemLength);

		}

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_add_hxstring) (HL_CFFIPointer* buffer, hl_vstring* text, int itemOffset, int itemLength) {

		hb_buffer_add_utf16 ((hb_buffer_t*)buffer->ptr, text ? (const uint16_t*)text->bytes : NULL, text ? text->length : 0, itemOffset, itemLength);

	}


	void lime_hb_buffer_add_codepoints (value buffer, double text, int textLength, int itemOffset, int itemLength) {

		hb_buffer_add_codepoints ((hb_buffer_t*)val_data (buffer), (const hb_codepoint_t*)(uintptr_t)text, textLength, itemOffset, itemLength);

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_add_codepoints) (HL_CFFIPointer* buffer, double text, int textLength, int itemOffset, int itemLength) {

		hb_buffer_add_codepoints ((hb_buffer_t*)buffer->ptr, (const hb_codepoint_t*)(uintptr_t)text, textLength, itemOffset, itemLength);

	}


	void lime_hb_buffer_add_utf8 (value buffer, HxString text, int itemOffset, int itemLength) {

		int textLength = text.length;
		if (hxs_encoding (text) == hx::StringUtf16) {
			// hxs_utf8 doesn't give us the length, so treat it as null terminated
			textLength = -1;
		}

		hb_buffer_add_utf8 ((hb_buffer_t*)val_data (buffer), hxs_utf8 (text, nullptr), textLength, itemOffset, itemLength);

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_add_utf8) (HL_CFFIPointer* buffer, hl_vstring* text, int itemOffset, int itemLength) {

		hb_buffer_add_utf8 ((hb_buffer_t*)buffer->ptr, text ? hl_to_utf8 (text->bytes) : NULL, -1, itemOffset, itemLength);

	}


	void lime_hb_buffer_add_utf16 (value buffer, double text, int textLength, int itemOffset, int itemLength) {

		hb_buffer_add_utf16 ((hb_buffer_t*)val_data (buffer), (const uint16_t*)(uintptr_t)text, textLength, itemOffset, itemLength);

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_add_utf16) (HL_CFFIPointer* buffer, double text, int textLength, int itemOffset, int itemLength) {

		hb_buffer_add_utf16 ((hb_buffer_t*)buffer->ptr, (const uint16_t*)(uintptr_t)text, textLength, itemOffset, itemLength);

	}


	void lime_hb_buffer_add_utf32 (value buffer, double text, int textLength, int itemOffset, int itemLength) {

		hb_buffer_add_utf32 ((hb_buffer_t*)val_data (buffer), (const uint32_t*)(uintptr_t)text, textLength, itemOffset, itemLength);

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_add_utf32) (HL_CFFIPointer* buffer, double text, int textLength, int itemOffset, int itemLength) {

		hb_buffer_add_utf32 ((hb_buffer_t*)buffer->ptr, (const uint32_t*)(uintptr_t)text, textLength, itemOffset, itemLength);

	}


	bool lime_hb_buffer_allocation_successful (value buffer) {

		return hb_buffer_allocation_successful ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM bool HL_NAME(hl_hb_buffer_allocation_successful) (HL_CFFIPointer* buffer) {

		return hb_buffer_allocation_successful ((hb_buffer_t*)buffer->ptr);

	}


	void lime_hb_buffer_clear_contents (value buffer) {

		hb_buffer_clear_contents ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_clear_contents) (HL_CFFIPointer* buffer) {

		hb_buffer_clear_contents ((hb_buffer_t*)buffer->ptr);

	}


	value lime_hb_buffer_create () {

		hb_buffer_t* buffer = hb_buffer_create ();
		return CFFIPointer (buffer, gc_hb_buffer);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_buffer_create) () {

		hb_buffer_t* buffer = hb_buffer_create ();
		return HLCFFIPointer (buffer, (hl_finalizer)hl_gc_hb_buffer);

	}


	int lime_hb_buffer_get_cluster_level (value buffer) {

		return hb_buffer_get_cluster_level ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM int HL_NAME(hl_hb_buffer_get_cluster_level) (HL_CFFIPointer* buffer) {

		return hb_buffer_get_cluster_level ((hb_buffer_t*)buffer->ptr);

	}


	int lime_hb_buffer_get_content_type (value buffer) {

		return hb_buffer_get_content_type ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM int HL_NAME(hl_hb_buffer_get_content_type) (HL_CFFIPointer* buffer) {

		return hb_buffer_get_content_type ((hb_buffer_t*)buffer->ptr);

	}


	int lime_hb_buffer_get_direction (value buffer) {

		return hb_buffer_get_direction ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM int HL_NAME(hl_hb_buffer_get_direction) (HL_CFFIPointer* buffer) {

		return hb_buffer_get_direction ((hb_buffer_t*)buffer->ptr);

	}


	value lime_hb_buffer_get_empty () {

		hb_buffer_t* buffer = hb_buffer_get_empty ();
		return CFFIPointer (buffer, gc_hb_buffer);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_buffer_get_empty) () {

		hb_buffer_t* buffer = hb_buffer_get_empty ();
		return HLCFFIPointer (buffer, (hl_finalizer)hl_gc_hb_buffer);

	}


	int lime_hb_buffer_get_flags (value buffer) {

		return hb_buffer_get_flags ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM int HL_NAME(hl_hb_buffer_get_flags) (HL_CFFIPointer* buffer) {

		return hb_buffer_get_flags ((hb_buffer_t*)buffer->ptr);

	}


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


	HL_PRIM Bytes* HL_NAME(hl_hb_buffer_get_glyph_infos) (HL_CFFIPointer* buffer, Bytes* bytes) {

		unsigned int length = 0;
		hb_glyph_info_t* info = hb_buffer_get_glyph_infos ((hb_buffer_t*)buffer->ptr, &length);

		if (length > 0) {

			bytes->Resize (length * sizeof (HBGlyphInfo));

			HBGlyphInfo* glyphInfo = (HBGlyphInfo*)bytes->b;

			for (int i = 0; i < length; i++, info++, glyphInfo++) {

				glyphInfo->codepoint = info->codepoint;
				glyphInfo->mask = info->mask;
				glyphInfo->cluster = info->cluster;

			}

			return bytes;

		} else {

			return NULL;

		}

	}


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


	HL_PRIM Bytes* HL_NAME(hl_hb_buffer_get_glyph_positions) (HL_CFFIPointer* buffer, Bytes* bytes) {

		unsigned int length = 0;
		hb_glyph_position_t* positions = hb_buffer_get_glyph_positions ((hb_buffer_t*)buffer->ptr, &length);

		if (length > 0) {

			bytes->Resize (length * sizeof (HBGlyphPosition));

			HBGlyphPosition* glyphPosition = (HBGlyphPosition*)bytes->b;

			for (int i = 0; i < length; i++, positions++, glyphPosition++) {

				glyphPosition->xAdvance = positions->x_advance;
				glyphPosition->yAdvance = positions->y_advance;
				glyphPosition->xOffset = positions->x_offset;
				glyphPosition->yOffset = positions->y_offset;

			}

			return bytes;

		} else {

			return NULL;

		}

	}


	value lime_hb_buffer_get_language (value buffer) {

		hb_language_t language = hb_buffer_get_language ((hb_buffer_t*)val_data (buffer));
		return CFFIPointer ((void*)language);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_buffer_get_language) (HL_CFFIPointer* buffer) {

		hb_language_t language = hb_buffer_get_language ((hb_buffer_t*)buffer->ptr);
		return HLCFFIPointer ((void*)language);

	}


	int lime_hb_buffer_get_length (value buffer) {

		return hb_buffer_get_length ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM int HL_NAME(hl_hb_buffer_get_length) (HL_CFFIPointer* buffer) {

		return hb_buffer_get_length ((hb_buffer_t*)buffer->ptr);

	}


	int lime_hb_buffer_get_replacement_codepoint (value buffer) {

		return hb_buffer_get_replacement_codepoint ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM int HL_NAME(hl_hb_buffer_get_replacement_codepoint) (HL_CFFIPointer* buffer) {

		return hb_buffer_get_replacement_codepoint ((hb_buffer_t*)buffer->ptr);

	}


	int lime_hb_buffer_get_script (value buffer) {

		return hb_buffer_get_script ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM int HL_NAME(hl_hb_buffer_get_script) (HL_CFFIPointer* buffer) {

		return hb_buffer_get_script ((hb_buffer_t*)buffer->ptr);

	}


	void lime_hb_buffer_get_segment_properties (value buffer, value props) {

		hb_buffer_get_segment_properties ((hb_buffer_t*)val_data (buffer), (hb_segment_properties_t*)val_data (props));

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_get_segment_properties) (HL_CFFIPointer* buffer, HL_CFFIPointer* props) {

		hb_buffer_get_segment_properties ((hb_buffer_t*)buffer->ptr, (hb_segment_properties_t*)props->ptr);

	}


	void lime_hb_buffer_guess_segment_properties (value buffer) {

		hb_buffer_guess_segment_properties ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_guess_segment_properties) (HL_CFFIPointer* buffer) {

		hb_buffer_guess_segment_properties ((hb_buffer_t*)buffer->ptr);

	}


	void lime_hb_buffer_normalize_glyphs (value buffer) {

		hb_buffer_normalize_glyphs ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_normalize_glyphs) (HL_CFFIPointer* buffer) {

		hb_buffer_normalize_glyphs ((hb_buffer_t*)buffer->ptr);

	}


	bool lime_hb_buffer_preallocate (value buffer, int size) {

		return hb_buffer_pre_allocate ((hb_buffer_t*)val_data (buffer), size);

	}


	HL_PRIM bool HL_NAME(hl_hb_buffer_preallocate) (HL_CFFIPointer* buffer, int size) {

		return hb_buffer_pre_allocate ((hb_buffer_t*)buffer->ptr, size);

	}


	void lime_hb_buffer_reset (value buffer) {

		hb_buffer_reset ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_reset) (HL_CFFIPointer* buffer) {

		hb_buffer_reset ((hb_buffer_t*)buffer->ptr);

	}


	void lime_hb_buffer_reverse (value buffer) {

		hb_buffer_reverse ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_reverse) (HL_CFFIPointer* buffer) {

		hb_buffer_reverse ((hb_buffer_t*)buffer->ptr);

	}


	void lime_hb_buffer_reverse_clusters (value buffer) {

		hb_buffer_reverse_clusters ((hb_buffer_t*)val_data (buffer));

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_reverse_clusters) (HL_CFFIPointer* buffer) {

		hb_buffer_reverse_clusters ((hb_buffer_t*)buffer->ptr);

	}


	int lime_hb_buffer_serialize_format_from_string (HxString str) {

		return hb_buffer_serialize_format_from_string (str.c_str (), str.length);

	}


	HL_PRIM int HL_NAME(hl_hb_buffer_serialize_format_from_string) (hl_vstring* str) {

		return hb_buffer_serialize_format_from_string (str ? hl_to_utf8 (str->bytes) : NULL, str ? str->length : 0);

	}


	value lime_hb_buffer_serialize_format_to_string (int format) {

		const char* result = hb_buffer_serialize_format_to_string ((hb_buffer_serialize_format_t)format);

		if (result) return alloc_string (result);
		return alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_hb_buffer_serialize_format_to_string) (int format) {

		const char* result = hb_buffer_serialize_format_to_string ((hb_buffer_serialize_format_t)format);

		if (result) {

			int length = strlen (result);
			char* _result = (char*)malloc (length + 1);
			strcpy (_result, result);
			return (vbyte*)_result;

		}

		return NULL;

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


	HL_PRIM varray* HL_NAME(hl_hb_buffer_serialize_list_formats) () {

		const char** formats = hb_buffer_serialize_list_formats ();

		if (formats) {

			// varray* result = hl_alloc_array (&hlt_byte, )
			// hl_aptr (result, const char*) = formats;

			// TODO

			return NULL;

		} else {

			return NULL;

		}

	}


	void lime_hb_buffer_set_cluster_level (value buffer, int clusterLevel) {

		hb_buffer_set_cluster_level ((hb_buffer_t*)val_data (buffer), (hb_buffer_cluster_level_t)clusterLevel);

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_set_cluster_level) (HL_CFFIPointer* buffer, int clusterLevel) {

		hb_buffer_set_cluster_level ((hb_buffer_t*)buffer->ptr, (hb_buffer_cluster_level_t)clusterLevel);

	}


	void lime_hb_buffer_set_content_type (value buffer, int contentType) {

		hb_buffer_set_content_type ((hb_buffer_t*)val_data (buffer), (hb_buffer_content_type_t)contentType);

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_set_content_type) (HL_CFFIPointer* buffer, int contentType) {

		hb_buffer_set_content_type ((hb_buffer_t*)buffer->ptr, (hb_buffer_content_type_t)contentType);

	}


	void lime_hb_buffer_set_direction (value buffer, int direction) {

		hb_buffer_set_direction ((hb_buffer_t*)val_data (buffer), (hb_direction_t)direction);

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_set_direction) (HL_CFFIPointer* buffer, int direction) {

		hb_buffer_set_direction ((hb_buffer_t*)buffer->ptr, (hb_direction_t)direction);

	}


	void lime_hb_buffer_set_flags (value buffer, int flags) {

		hb_buffer_set_flags ((hb_buffer_t*)val_data (buffer), (hb_buffer_flags_t)flags);

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_set_flags) (HL_CFFIPointer* buffer, int flags) {

		hb_buffer_set_flags ((hb_buffer_t*)buffer->ptr, (hb_buffer_flags_t)flags);

	}


	void lime_hb_buffer_set_language (value buffer, value language) {

		hb_buffer_set_language ((hb_buffer_t*)val_data (buffer), (hb_language_t)val_data (language));

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_set_language) (HL_CFFIPointer* buffer, HL_CFFIPointer* language) {

		hb_buffer_set_language ((hb_buffer_t*)buffer->ptr, (hb_language_t)language->ptr);

	}


	bool lime_hb_buffer_set_length (value buffer, int length) {

		return hb_buffer_set_length ((hb_buffer_t*)val_data (buffer), length);

	}


	HL_PRIM bool HL_NAME(hl_hb_buffer_set_length) (HL_CFFIPointer* buffer, int length) {

		return hb_buffer_set_length ((hb_buffer_t*)buffer->ptr, length);

	}


	void lime_hb_buffer_set_replacement_codepoint (value buffer, int replacement) {

		hb_buffer_set_replacement_codepoint ((hb_buffer_t*)val_data (buffer), (hb_codepoint_t)replacement);

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_set_replacement_codepoint) (HL_CFFIPointer* buffer, int replacement) {

		hb_buffer_set_replacement_codepoint ((hb_buffer_t*)buffer->ptr, (hb_codepoint_t)replacement);

	}


	void lime_hb_buffer_set_script (value buffer, int script) {

		if (script == -1) script = HB_SCRIPT_COMMON; // Workaround for Neko
		// TODO: COMMON is an int32 and doesn't translate properly on Neko

		hb_buffer_set_script ((hb_buffer_t*)val_data (buffer), (hb_script_t)script);

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_set_script) (HL_CFFIPointer* buffer, int script) {

		hb_buffer_set_script ((hb_buffer_t*)buffer->ptr, (hb_script_t)script);

	}


	void lime_hb_buffer_set_segment_properties (value buffer, value props) {

		hb_buffer_set_segment_properties ((hb_buffer_t*)val_data (buffer), (const hb_segment_properties_t*)val_data (props));

	}


	HL_PRIM void HL_NAME(hl_hb_buffer_set_segment_properties) (HL_CFFIPointer* buffer, HL_CFFIPointer* props) {

		hb_buffer_set_segment_properties ((hb_buffer_t*)buffer->ptr, (const hb_segment_properties_t*)props->ptr);

	}


	value lime_hb_face_create (value blob, int index) {

		hb_face_t* face = hb_face_create ((hb_blob_t*)val_data (blob), index);
		return CFFIPointer (face, gc_hb_face);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_face_create) (HL_CFFIPointer* blob, int index) {

		hb_face_t* face = hb_face_create ((hb_blob_t*)blob->ptr, index);
		return HLCFFIPointer (face, (hl_finalizer)hl_gc_hb_face);

	}


	value lime_hb_face_get_empty () {

		hb_face_t* face = hb_face_get_empty ();
		return CFFIPointer (face, gc_hb_face);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_face_get_empty) () {

		hb_face_t* face = hb_face_get_empty ();
		return HLCFFIPointer (face, (hl_finalizer)hl_gc_hb_face);

	}


	int lime_hb_face_get_glyph_count (value face) {

		return hb_face_get_glyph_count ((hb_face_t*)val_data (face));

	}


	HL_PRIM int HL_NAME(hl_hb_face_get_glyph_count) (HL_CFFIPointer* face) {

		return hb_face_get_glyph_count ((hb_face_t*)face->ptr);

	}


	int lime_hb_face_get_index (value face) {

		return hb_face_get_index ((hb_face_t*)val_data (face));

	}


	HL_PRIM int HL_NAME(hl_hb_face_get_index) (HL_CFFIPointer* face) {

		return hb_face_get_index ((hb_face_t*)face->ptr);

	}


	int lime_hb_face_get_upem (value face) {

		return hb_face_get_upem ((hb_face_t*)val_data (face));

	}


	HL_PRIM int HL_NAME(hl_hb_face_get_upem) (HL_CFFIPointer* face) {

		return hb_face_get_upem ((hb_face_t*)face->ptr);

	}


	bool lime_hb_face_is_immutable (value face) {

		return hb_face_is_immutable ((hb_face_t*)val_data (face));

	}


	HL_PRIM bool HL_NAME(hl_hb_face_is_immutable) (HL_CFFIPointer* face) {

		return hb_face_is_immutable ((hb_face_t*)face->ptr);

	}


	void lime_hb_face_make_immutable (value face) {

		hb_face_make_immutable ((hb_face_t*)val_data (face));

	}


	HL_PRIM void HL_NAME(hl_hb_face_make_immutable) (HL_CFFIPointer* face) {

		hb_face_make_immutable ((hb_face_t*)face->ptr);

	}


	value lime_hb_face_reference_blob (value face) {

		hb_blob_t* blob = hb_face_reference_blob ((hb_face_t*)val_data (face));

		// TODO: Should this be managed differently?
		return CFFIPointer (blob, gc_hb_blob);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_face_reference_blob) (HL_CFFIPointer* face) {

		hb_blob_t* blob = hb_face_reference_blob ((hb_face_t*)face->ptr);

		// TODO: Should this be managed differently?
		return HLCFFIPointer (blob, (hl_finalizer)hl_gc_hb_blob);

	}


	value lime_hb_face_reference_table (value face, int tag) {

		hb_blob_t* blob = hb_face_reference_table ((hb_face_t*)val_data (face), (hb_tag_t)tag);
		return CFFIPointer (blob, gc_hb_blob);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_face_reference_table) (HL_CFFIPointer* face, int tag) {

		hb_blob_t* blob = hb_face_reference_table ((hb_face_t*)face->ptr, (hb_tag_t)tag);
		return HLCFFIPointer (blob, (hl_finalizer)hl_gc_hb_blob);

	}


	void lime_hb_face_set_glyph_count (value face, int glyphCount) {

		hb_face_set_glyph_count ((hb_face_t*)val_data (face), glyphCount);

	}


	HL_PRIM void HL_NAME(hl_hb_face_set_glyph_count) (HL_CFFIPointer* face, int glyphCount) {

		hb_face_set_glyph_count ((hb_face_t*)face->ptr, glyphCount);

	}


	void lime_hb_face_set_index (value face, int index) {

		hb_face_set_index ((hb_face_t*)val_data (face), index);

	}


	HL_PRIM void HL_NAME(hl_hb_face_set_index) (HL_CFFIPointer* face, int index) {

		hb_face_set_index ((hb_face_t*)face->ptr, index);

	}


	void lime_hb_face_set_upem (value face, int upem) {

		hb_face_set_upem ((hb_face_t*)val_data (face), upem);

	}


	HL_PRIM void HL_NAME(hl_hb_face_set_upem) (HL_CFFIPointer* face, int upem) {

		hb_face_set_upem ((hb_face_t*)face->ptr, upem);

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


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_feature_from_string) (hl_vstring* str) {

		hb_feature_t feature;

		if (hb_feature_from_string (str ? hl_to_utf8 (str->bytes) : NULL, str ? str->length : 0, &feature)) {

			// TODO;
			return NULL;
			//return CFFIPointer (feature);

		} else {

			return NULL;

		}

	}


	value lime_hb_feature_to_string (value feature) {

		char result[128];
		hb_feature_to_string ((hb_feature_t*)val_data (feature), result, 128);
		return alloc_string (result);

	}


	HL_PRIM vbyte* HL_NAME(hl_hb_feature_to_string) (HL_CFFIPointer* feature) {

		char* result = (char*)malloc (128);
		hb_feature_to_string ((hb_feature_t*)feature->ptr, result, 128);

		int length = strlen (result);
		char* _result = (char*)malloc (length + 1);
		strcpy (_result, result);
		return (vbyte*)_result;

	}


	void lime_hb_font_add_glyph_origin_for_direction (value font, int glyph, int direction, int x, int y) {

		hb_font_add_glyph_origin_for_direction ((hb_font_t*)val_data (font), (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);

	}


	HL_PRIM void HL_NAME(hl_hb_font_add_glyph_origin_for_direction) (HL_CFFIPointer* font, int glyph, int direction, int x, int y) {

		hb_font_add_glyph_origin_for_direction ((hb_font_t*)font->ptr, (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);

	}


	value lime_hb_font_create (value face) {

		hb_font_t* font = hb_font_create ((hb_face_t*)val_data (face));
		return CFFIPointer (font, gc_hb_font);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_font_create) (HL_CFFIPointer* face) {

		hb_font_t* font = hb_font_create ((hb_face_t*)face->ptr);
		return HLCFFIPointer (font, (hl_finalizer)hl_gc_hb_font);

	}


	value lime_hb_font_create_sub_font (value parent) {

		hb_font_t* font = hb_font_create_sub_font ((hb_font_t*)val_data (parent));
		return CFFIPointer (font, gc_hb_font);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_font_create_sub_font) (HL_CFFIPointer* parent) {

		hb_font_t* font = hb_font_create_sub_font ((hb_font_t*)parent->ptr);
		return HLCFFIPointer (font, (hl_finalizer)hl_gc_hb_font);

	}


	value lime_hb_font_get_empty () {

		hb_font_t* font = hb_font_get_empty ();
		return CFFIPointer (font, gc_hb_font);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_font_get_empty) () {

		hb_font_t* font = hb_font_get_empty ();
		return HLCFFIPointer (font, (hl_finalizer)hl_gc_hb_font);

	}


	value lime_hb_font_get_face (value font) {

		hb_face_t* face = hb_font_get_face ((hb_font_t*)val_data (font));
		return CFFIPointer (face, gc_hb_face);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_font_get_face) (HL_CFFIPointer* font) {

		// TODO: Manage memory differently here?

		hb_face_t* face = hb_font_get_face ((hb_font_t*)font->ptr);
		return HLCFFIPointer (face, (hl_finalizer)hl_gc_hb_face);

	}


	value lime_hb_font_get_glyph_advance_for_direction (value font, int glyph, int direction) {

		hb_position_t x;
		hb_position_t y;
		hb_font_get_glyph_advance_for_direction ((hb_font_t*)val_data (font), (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);
		Vector2 result = Vector2 (x, y);
		return result.Value ();

	}


	HL_PRIM Vector2* HL_NAME(hl_hb_font_get_glyph_advance_for_direction) (HL_CFFIPointer* font, int glyph, int direction, Vector2* out) {

		hb_position_t x;
		hb_position_t y;
		hb_font_get_glyph_advance_for_direction ((hb_font_t*)font->ptr, (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);
		out->x = x;
		out->y = y;
		return out;

	}


	value lime_hb_font_get_glyph_kerning_for_direction (value font, int firstGlyph, int secondGlyph, int direction) {

		hb_position_t x;
		hb_position_t y;
		hb_font_get_glyph_kerning_for_direction ((hb_font_t*)val_data (font), (hb_codepoint_t)firstGlyph, (hb_codepoint_t)secondGlyph, (hb_direction_t)direction, &x, &y);
		Vector2 result = Vector2 (x, y);
		return result.Value ();

	}


	HL_PRIM Vector2* HL_NAME(hl_hb_font_get_glyph_kerning_for_direction) (HL_CFFIPointer* font, int firstGlyph, int secondGlyph, int direction, Vector2* out) {

		hb_position_t x;
		hb_position_t y;
		hb_font_get_glyph_kerning_for_direction ((hb_font_t*)font->ptr, (hb_codepoint_t)firstGlyph, (hb_codepoint_t)secondGlyph, (hb_direction_t)direction, &x, &y);
		out->x = x;
		out->y = y;
		return out;

	}


	value lime_hb_font_get_glyph_origin_for_direction (value font, int glyph, int direction) {

		hb_position_t x;
		hb_position_t y;
		hb_font_get_glyph_origin_for_direction ((hb_font_t*)val_data (font), (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);
		Vector2 result = Vector2 (x, y);
		return result.Value ();

	}


	HL_PRIM Vector2* HL_NAME(hl_hb_font_get_glyph_origin_for_direction) (HL_CFFIPointer* font, int glyph, int direction, Vector2* out) {

		hb_position_t x;
		hb_position_t y;
		hb_font_get_glyph_origin_for_direction ((hb_font_t*)font->ptr, (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);
		out->x = x;
		out->y = y;
		return out;

	}


	value lime_hb_font_get_parent (value font) {

		hb_font_t* parent = hb_font_get_parent ((hb_font_t*)val_data (font));
		return CFFIPointer (parent, gc_hb_font);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_font_get_parent) (HL_CFFIPointer* font) {

		// Manage memory differently here?

		hb_font_t* parent = hb_font_get_parent ((hb_font_t*)font->ptr);
		return HLCFFIPointer (parent, (hl_finalizer)hl_gc_hb_font);

	}


	value lime_hb_font_get_ppem (value font) {

		int xppem = 0;
		int yppem = 0;
		hb_font_get_scale ((hb_font_t*)val_data (font), &xppem, &yppem);
		Vector2 result = Vector2 (xppem, yppem);
		return result.Value ();

	}


	HL_PRIM Vector2* HL_NAME(hl_hb_font_get_ppem) (HL_CFFIPointer* font, Vector2* out) {

		int xppem = 0;
		int yppem = 0;
		hb_font_get_scale ((hb_font_t*)font->ptr, &xppem, &yppem);
		out->x = xppem;
		out->y = yppem;
		return out;

	}


	value lime_hb_font_get_scale (value font) {

		int xScale = 0;
		int yScale = 0;
		hb_font_get_scale ((hb_font_t*)val_data (font), &xScale, &yScale);
		Vector2 result = Vector2 (xScale, yScale);
		return result.Value ();

	}


	HL_PRIM Vector2* HL_NAME(hl_hb_font_get_scale) (HL_CFFIPointer* font, Vector2* out) {

		int xScale = 0;
		int yScale = 0;
		hb_font_get_scale ((hb_font_t*)font->ptr, &xScale, &yScale);
		out->x = xScale;
		out->y = yScale;
		return out;

	}


	int lime_hb_font_glyph_from_string (value font, HxString s) {

		hb_codepoint_t glyph = 0;

		if (hb_font_glyph_from_string ((hb_font_t*)val_data (font), s.c_str (), s.length, &glyph)) {

			return glyph;

		} else {

			return -1;

		}

	}


	HL_PRIM int HL_NAME(hl_hb_font_glyph_from_string) (HL_CFFIPointer* font, hl_vstring* s) {

		hb_codepoint_t glyph = 0;

		if (hb_font_glyph_from_string ((hb_font_t*)font->ptr, s ? hl_to_utf8 (s->bytes) : NULL, s ? s->length : 0, &glyph)) {

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


	HL_PRIM vbyte* HL_NAME(hl_hb_font_glyph_to_string) (HL_CFFIPointer* font, int codepoint) {

		char* result = (char*)malloc (1024);
		hb_font_glyph_to_string ((hb_font_t*)font->ptr, (hb_codepoint_t)codepoint, result, 1024);

		int length = strlen (result);
		char* _result = (char*)malloc (length + 1);
		strcpy (_result, result);
		return (vbyte*)_result;

	}


	bool lime_hb_font_is_immutable (value font) {

		return hb_font_is_immutable ((hb_font_t*)val_data (font));

	}


	HL_PRIM bool HL_NAME(hl_hb_font_is_immutable) (HL_CFFIPointer* font) {

		return hb_font_is_immutable ((hb_font_t*)font->ptr);

	}


	void lime_hb_font_make_immutable (value font) {

		hb_font_make_immutable ((hb_font_t*)val_data (font));

	}


	HL_PRIM void HL_NAME(hl_hb_font_make_immutable) (HL_CFFIPointer* font) {

		hb_font_make_immutable ((hb_font_t*)font->ptr);

	}


	void lime_hb_font_set_ppem (value font, int xppem, int yppem) {

		hb_font_set_ppem ((hb_font_t*)val_data (font), xppem, yppem);

	}


	HL_PRIM void HL_NAME(hl_hb_font_set_ppem) (HL_CFFIPointer* font, int xppem, int yppem) {

		hb_font_set_ppem ((hb_font_t*)font->ptr, xppem, yppem);

	}


	void lime_hb_font_set_scale (value font, int xScale, int yScale) {

		hb_font_set_scale ((hb_font_t*)val_data (font), xScale, yScale);

	}


	HL_PRIM void HL_NAME(hl_hb_font_set_scale) (HL_CFFIPointer* font, int xScale, int yScale) {

		hb_font_set_scale ((hb_font_t*)font->ptr, xScale, yScale);

	}


	void lime_hb_font_subtract_glyph_origin_for_direction (value font, int glyph, int direction, int x, int y) {

		hb_font_subtract_glyph_origin_for_direction ((hb_font_t*)val_data (font), (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);

	}


	HL_PRIM void HL_NAME(hl_hb_font_subtract_glyph_origin_for_direction) (HL_CFFIPointer* font, int glyph, int direction, int x, int y) {

		hb_font_subtract_glyph_origin_for_direction ((hb_font_t*)font->ptr, (hb_codepoint_t)glyph, (hb_direction_t)direction, &x, &y);

	}


	value lime_hb_ft_font_create (value font) {

		Font* _font = (Font*)val_data (font);
		hb_font_t* __font = hb_ft_font_create ((FT_Face)_font->face, NULL);
		return CFFIPointer (__font, gc_hb_font);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_ft_font_create) (HL_CFFIPointer* font) {

		Font* _font = (Font*)font->ptr;
		hb_font_t* __font = hb_ft_font_create ((FT_Face)_font->face, NULL);
		return HLCFFIPointer (__font, (hl_finalizer)hl_gc_hb_font);

	}


	value lime_hb_ft_font_create_referenced (value font) {

		Font* _font = (Font*)val_data (font);
		hb_font_t* __font = hb_ft_font_create_referenced ((FT_Face)_font->face);
		return CFFIPointer (__font, gc_hb_font);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_ft_font_create_referenced) (HL_CFFIPointer* font) {

		Font* _font = (Font*)font->ptr;
		hb_font_t* __font = hb_ft_font_create_referenced ((FT_Face)_font->face);
		return HLCFFIPointer (__font, (hl_finalizer)hl_gc_hb_font);

	}


	int lime_hb_ft_font_get_load_flags (value font) {

		return hb_ft_font_get_load_flags ((hb_font_t*)val_data (font));

	}


	HL_PRIM int HL_NAME(hl_hb_ft_font_get_load_flags) (HL_CFFIPointer* font) {

		return hb_ft_font_get_load_flags ((hb_font_t*)font->ptr);

	}


	void lime_hb_ft_font_set_load_flags (value font, int loadFlags) {

		hb_ft_font_set_load_flags ((hb_font_t*)val_data (font), loadFlags);

	}


	HL_PRIM void HL_NAME(hl_hb_ft_font_set_load_flags) (HL_CFFIPointer* font, int loadFlags) {

		hb_ft_font_set_load_flags ((hb_font_t*)font->ptr, loadFlags);

	}


	value lime_hb_language_from_string (HxString str) {

		hb_language_t language = hb_language_from_string (str.c_str (), str.length);
		return CFFIPointer ((void*)language);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_language_from_string) (hl_vstring* str) {

		hb_language_t language = hb_language_from_string (str ? hl_to_utf8 (str->bytes) : NULL, str ? str->length : 0);
		return HLCFFIPointer ((void*)language);

	}


	value lime_hb_language_get_default () {

		hb_language_t language = hb_language_get_default ();
		return CFFIPointer ((void*)language);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_language_get_default) () {

		hb_language_t language = hb_language_get_default ();
		return HLCFFIPointer ((void*)language);

	}


	value lime_hb_language_to_string (value language) {

		hb_language_t _language = (hb_language_t)val_data (language);
		const char* result = hb_language_to_string (_language);
		return alloc_string (result);

	}


	HL_PRIM vbyte* HL_NAME(hl_hb_language_to_string) (HL_CFFIPointer* language) {

		hb_language_t _language = (hb_language_t)language->ptr;
		const char* result = hb_language_to_string (_language);

		int length = strlen (result);
		char* _result = (char*)malloc (length + 1);
		strcpy (_result, result);
		return (vbyte*)_result;

	}


	bool lime_hb_segment_properties_equal (value a, value b) {

		return hb_segment_properties_equal ((hb_segment_properties_t*)val_data (a), (hb_segment_properties_t*)val_data (b));

	}


	HL_PRIM bool HL_NAME(hl_hb_segment_properties_equal) (HL_CFFIPointer* a, HL_CFFIPointer* b) {

		return hb_segment_properties_equal ((hb_segment_properties_t*)a->ptr, (hb_segment_properties_t*)b->ptr);

	}


	int lime_hb_segment_properties_hash (value p) {

		return hb_segment_properties_hash ((hb_segment_properties_t*)val_data (p));

	}


	HL_PRIM int HL_NAME(hl_hb_segment_properties_hash) (HL_CFFIPointer* p) {

		return hb_segment_properties_hash ((hb_segment_properties_t*)p->ptr);

	}


	void lime_hb_set_add (value set, int codepoint) {

		hb_set_add ((hb_set_t*)val_data (set), (hb_codepoint_t)codepoint);

	}


	HL_PRIM void HL_NAME(hl_hb_set_add) (HL_CFFIPointer* set, int codepoint) {

		hb_set_add ((hb_set_t*)set->ptr, (hb_codepoint_t)codepoint);

	}


	void lime_hb_set_add_range (value set, int first, int last) {

		hb_set_add_range ((hb_set_t*)val_data (set), (hb_codepoint_t)first, (hb_codepoint_t)last);

	}


	HL_PRIM void HL_NAME(hl_hb_set_add_range) (HL_CFFIPointer* set, int first, int last) {

		hb_set_add_range ((hb_set_t*)set->ptr, (hb_codepoint_t)first, (hb_codepoint_t)last);

	}


	bool lime_hb_set_allocation_successful (value set) {

		return hb_set_allocation_successful ((hb_set_t*)val_data (set));

	}


	HL_PRIM bool HL_NAME(hl_hb_set_allocation_successful) (HL_CFFIPointer* set) {

		return hb_set_allocation_successful ((hb_set_t*)set->ptr);

	}


	void lime_hb_set_clear (value set) {

		hb_set_clear ((hb_set_t*)val_data (set));

	}


	HL_PRIM void HL_NAME(hl_hb_set_clear) (HL_CFFIPointer* set) {

		hb_set_clear ((hb_set_t*)set->ptr);

	}


	value lime_hb_set_create () {

		hb_set_t* set = hb_set_create ();
		return CFFIPointer (set, gc_hb_set);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_set_create) () {

		hb_set_t* set = hb_set_create ();
		return HLCFFIPointer (set, (hl_finalizer)hl_gc_hb_set);

	}


	void lime_hb_set_del (value set, int codepoint) {

		hb_set_del ((hb_set_t*)val_data (set), (hb_codepoint_t)codepoint);

	}


	HL_PRIM void HL_NAME(hl_hb_set_del) (HL_CFFIPointer* set, int codepoint) {

		hb_set_del ((hb_set_t*)set->ptr, (hb_codepoint_t)codepoint);

	}


	void lime_hb_set_del_range (value set, int first, int last) {

		hb_set_del_range ((hb_set_t*)val_data (set), (hb_codepoint_t)first, (hb_codepoint_t)last);

	}


	HL_PRIM void HL_NAME(hl_hb_set_del_range) (HL_CFFIPointer* set, int first, int last) {

		hb_set_del_range ((hb_set_t*)set->ptr, (hb_codepoint_t)first, (hb_codepoint_t)last);

	}


	value lime_hb_set_get_empty () {

		hb_set_t* set = hb_set_get_empty ();
		return CFFIPointer (set, gc_hb_set);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_hb_set_get_empty) () {

		hb_set_t* set = hb_set_get_empty ();
		return HLCFFIPointer (set, (hl_finalizer)hl_gc_hb_set);

	}


	int lime_hb_set_get_max (value set) {

		return hb_set_get_max ((hb_set_t*)val_data (set));

	}


	HL_PRIM int HL_NAME(hl_hb_set_get_max) (HL_CFFIPointer* set) {

		return hb_set_get_max ((hb_set_t*)set->ptr);

	}


	int lime_hb_set_get_min (value set) {

		return hb_set_get_min ((hb_set_t*)val_data (set));

	}


	HL_PRIM int HL_NAME(hl_hb_set_get_min) (HL_CFFIPointer* set) {

		return hb_set_get_min ((hb_set_t*)set->ptr);

	}


	int lime_hb_set_get_population (value set) {

		return hb_set_get_population ((hb_set_t*)val_data (set));

	}


	HL_PRIM int HL_NAME(hl_hb_set_get_population) (HL_CFFIPointer* set) {

		return hb_set_get_population ((hb_set_t*)set->ptr);

	}


	bool lime_hb_set_has (value set, int codepoint) {

		return hb_set_has ((hb_set_t*)val_data (set), (hb_codepoint_t)codepoint);

	}


	HL_PRIM bool HL_NAME(hl_hb_set_has) (HL_CFFIPointer* set, int codepoint) {

		return hb_set_has ((hb_set_t*)set->ptr, (hb_codepoint_t)codepoint);

	}


	void lime_hb_set_intersect (value set, value other) {

		return hb_set_intersect ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));

	}


	HL_PRIM void HL_NAME(hl_hb_set_intersect) (HL_CFFIPointer* set, HL_CFFIPointer* other) {

		return hb_set_intersect ((hb_set_t*)set->ptr, (hb_set_t*)other->ptr);

	}


	void lime_hb_set_invert (value set) {

		hb_set_invert ((hb_set_t*)val_data (set));

	}


	HL_PRIM void HL_NAME(hl_hb_set_invert) (HL_CFFIPointer* set) {

		hb_set_invert ((hb_set_t*)set->ptr);

	}


	bool lime_hb_set_is_empty (value set) {

		return hb_set_is_empty ((hb_set_t*)val_data (set));

	}


	HL_PRIM bool HL_NAME(hl_hb_set_is_empty) (HL_CFFIPointer* set) {

		return hb_set_is_empty ((hb_set_t*)set->ptr);

	}


	bool lime_hb_set_is_equal (value set, value other) {

		return hb_set_is_equal ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));

	}


	HL_PRIM bool HL_NAME(hl_hb_set_is_equal) (HL_CFFIPointer* set, HL_CFFIPointer* other) {

		return hb_set_is_equal ((hb_set_t*)set->ptr, (hb_set_t*)other->ptr);

	}


	int lime_hb_set_next (value set) {

		hb_codepoint_t codepoint = 0;

		if (hb_set_next ((hb_set_t*)val_data (set), &codepoint)) {

			return codepoint;

		} else {

			return -1;

		}

	}


	HL_PRIM int HL_NAME(hl_hb_set_next) (HL_CFFIPointer* set) {

		hb_codepoint_t codepoint = 0;

		if (hb_set_next ((hb_set_t*)set->ptr, &codepoint)) {

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


	HL_PRIM Vector2* HL_NAME(hl_hb_set_next_range) (HL_CFFIPointer* set, Vector2* out) {

		hb_codepoint_t first = 0;
		hb_codepoint_t last = 0;

		if (hb_set_next_range ((hb_set_t*)set->ptr, &first, &last)) {

			out->x = first;
			out->y = last;
			return out;

		} else {

			return NULL;

		}

	}


	void lime_hb_set_set (value set, value other) {

		return hb_set_set ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));

	}


	HL_PRIM void HL_NAME(hl_hb_set_set) (HL_CFFIPointer* set, HL_CFFIPointer* other) {

		return hb_set_set ((hb_set_t*)set->ptr, (hb_set_t*)other->ptr);

	}


	void lime_hb_set_subtract (value set, value other) {

		return hb_set_subtract ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));

	}


	HL_PRIM void HL_NAME(hl_hb_set_subtract) (HL_CFFIPointer* set, HL_CFFIPointer* other) {

		return hb_set_subtract ((hb_set_t*)set->ptr, (hb_set_t*)other->ptr);

	}


	void lime_hb_set_symmetric_difference (value set, value other) {

		return hb_set_symmetric_difference ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));

	}


	HL_PRIM void HL_NAME(hl_hb_set_symmetric_difference) (HL_CFFIPointer* set, HL_CFFIPointer* other) {

		return hb_set_symmetric_difference ((hb_set_t*)set->ptr, (hb_set_t*)other->ptr);

	}


	void lime_hb_set_union (value set, value other) {

		return hb_set_union ((hb_set_t*)val_data (set), (hb_set_t*)val_data (other));

	}


	HL_PRIM void HL_NAME(hl_hb_set_union) (HL_CFFIPointer* set, HL_CFFIPointer* other) {

		return hb_set_union ((hb_set_t*)set->ptr, (hb_set_t*)other->ptr);

	}


	void lime_hb_shape (value font, value buffer, value features) {

		int length = !val_is_null (features) ? val_array_size (features) : 0;
		double* _features = !val_is_null (features) ? val_array_double (features) : NULL;
		hb_shape ((hb_font_t*)val_data (font), (hb_buffer_t*)val_data (buffer), (const hb_feature_t*)(uintptr_t*)_features, length);

	}


	HL_PRIM void HL_NAME(hl_hb_shape) (HL_CFFIPointer* font, HL_CFFIPointer* buffer, hl_varray* features) {

		int length = features ? features->size : 0;
		double* _features = features ? hl_aptr (features, double) : NULL;
		hb_shape ((hb_font_t*)font->ptr, (hb_buffer_t*)buffer->ptr, (const hb_feature_t*)(uintptr_t*)_features, length);

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
	DEFINE_PRIME1 (lime_hb_blob_get_data);
	DEFINE_PRIME1 (lime_hb_blob_get_data_writable);
	DEFINE_PRIME0 (lime_hb_blob_get_empty);
	DEFINE_PRIME1 (lime_hb_blob_get_length);
	DEFINE_PRIME1 (lime_hb_blob_is_immutable);
	DEFINE_PRIME1v (lime_hb_blob_make_immutable);
	DEFINE_PRIME3v (lime_hb_buffer_add);
	DEFINE_PRIME4v (lime_hb_buffer_add_hxstring);
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
	DEFINE_PRIME1 (lime_hb_buffer_get_language);
	DEFINE_PRIME1 (lime_hb_buffer_get_length);
	DEFINE_PRIME1 (lime_hb_buffer_get_replacement_codepoint);
	DEFINE_PRIME1 (lime_hb_buffer_get_script);
	DEFINE_PRIME2v (lime_hb_buffer_get_segment_properties);
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
	DEFINE_PRIME1 (lime_hb_segment_properties_hash);
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


	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN
	#define _TVECTOR2 _OBJ (_F64 _F64)


	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_blob_create, _F64 _I32 _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_blob_create_sub_blob, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_F64, hl_hb_blob_get_data, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_F64, hl_hb_blob_get_data_writable, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_blob_get_empty, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_hb_blob_get_length, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_hb_blob_is_immutable, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_blob_make_immutable, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_add, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_add_hxstring, _TCFFIPOINTER _STRING _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_add_codepoints, _TCFFIPOINTER _F64 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_add_utf8, _TCFFIPOINTER _STRING _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_add_utf16, _TCFFIPOINTER _F64 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_add_utf32, _TCFFIPOINTER _F64 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_hb_buffer_allocation_successful, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_clear_contents, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_buffer_create, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_hb_buffer_get_cluster_level, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_buffer_get_content_type, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_buffer_get_direction, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_buffer_get_empty, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_hb_buffer_get_flags, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TBYTES, hl_hb_buffer_get_glyph_infos, _TCFFIPOINTER _TBYTES);
	DEFINE_HL_PRIM (_TBYTES, hl_hb_buffer_get_glyph_positions, _TCFFIPOINTER _TBYTES);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_buffer_get_language, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_buffer_get_length, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_buffer_get_replacement_codepoint, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_buffer_get_script, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_get_segment_properties, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_guess_segment_properties, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_normalize_glyphs, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_hb_buffer_preallocate, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_reset, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_reverse, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_reverse_clusters, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_buffer_serialize_format_from_string, _STRING);
	DEFINE_HL_PRIM (_BYTES, hl_hb_buffer_serialize_format_to_string, _I32);
	DEFINE_HL_PRIM (_ARR, hl_hb_buffer_serialize_list_formats, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_set_cluster_level, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_set_content_type, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_set_direction, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_set_flags, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_set_language, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_hb_buffer_set_length, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_set_replacement_codepoint, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_set_script, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_buffer_set_segment_properties, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_face_create, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_face_get_empty, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_hb_face_get_glyph_count, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_face_get_index, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_face_get_upem, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_hb_face_is_immutable, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_face_make_immutable, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_face_reference_blob, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_face_reference_table, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_face_set_glyph_count, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_face_set_index, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_face_set_upem, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_feature_from_string, _STRING);
	DEFINE_HL_PRIM (_BYTES, hl_hb_feature_to_string, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_font_add_glyph_origin_for_direction, _TCFFIPOINTER _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_font_create, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_font_create_sub_font, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_font_get_empty, _NO_ARG);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_font_get_face, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TVECTOR2, hl_hb_font_get_glyph_advance_for_direction, _TCFFIPOINTER _I32 _I32 _TVECTOR2);
	DEFINE_HL_PRIM (_TVECTOR2, hl_hb_font_get_glyph_kerning_for_direction, _TCFFIPOINTER _I32 _I32 _I32 _TVECTOR2);
	DEFINE_HL_PRIM (_TVECTOR2, hl_hb_font_get_glyph_origin_for_direction, _TCFFIPOINTER _I32 _I32 _TVECTOR2);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_font_get_parent, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TVECTOR2, hl_hb_font_get_ppem, _TCFFIPOINTER _TVECTOR2);
	DEFINE_HL_PRIM (_TVECTOR2, hl_hb_font_get_scale, _TCFFIPOINTER _TVECTOR2);
	DEFINE_HL_PRIM (_I32, hl_hb_font_glyph_from_string, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_BYTES, hl_hb_font_glyph_to_string, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_BOOL, hl_hb_font_is_immutable, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_font_make_immutable, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_font_set_ppem, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_font_set_scale, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_font_subtract_glyph_origin_for_direction, _TCFFIPOINTER _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_ft_font_create, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_ft_font_create_referenced, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_ft_font_get_load_flags, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_ft_font_set_load_flags, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_language_from_string, _STRING);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_language_get_default, _NO_ARG);
	DEFINE_HL_PRIM (_BYTES, hl_hb_language_to_string, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_hb_segment_properties_equal, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_segment_properties_hash, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_set_add, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_set_add_range, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_hb_set_allocation_successful, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_set_clear, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_set_create, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_hb_set_del, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_set_del_range, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_hb_set_get_empty, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_hb_set_get_max, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_set_get_min, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_set_get_population, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_hb_set_has, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_hb_set_intersect, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_set_invert, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_hb_set_is_empty, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_hb_set_is_equal, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_I32, hl_hb_set_next, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TVECTOR2, hl_hb_set_next_range, _TCFFIPOINTER _TVECTOR2);
	DEFINE_HL_PRIM (_VOID, hl_hb_set_set, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_set_subtract, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_set_symmetric_difference, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_set_union, _TCFFIPOINTER _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_hb_shape, _TCFFIPOINTER _TCFFIPOINTER _ARR);


}


extern "C" int lime_harfbuzz_register_prims () {

	return 0;

}
