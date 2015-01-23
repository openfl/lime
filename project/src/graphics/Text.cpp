#include <graphics/Font.h>
#include <graphics/Text.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <hb-ft.h>


namespace lime {

	Text::Text (hb_tag_t direction, const char *script, const char *language) {

		if (strlen(script) != 4) return;

		mDirection = (hb_direction_t)direction;
		mLanguage = hb_language_from_string (language, strlen (language));
		mScript = hb_script_from_string (script, -1);

		mBuffer = hb_buffer_create ();
		hb_buffer_set_direction (mBuffer, mDirection);
		hb_buffer_set_script (mBuffer, mScript);
		hb_buffer_set_language (mBuffer, mLanguage);

	}

	Text::~Text () {

		hb_buffer_destroy (mBuffer);

	}

	value Text::FromString (Font *font, size_t size, const char *text) {

		font->SetSize (size);

		// reset buffer
		hb_buffer_reset (mBuffer);
		hb_buffer_set_direction (mBuffer, mDirection);
		hb_buffer_set_script (mBuffer, mScript);
		hb_buffer_set_language (mBuffer, mLanguage);

		// layout the text
		hb_buffer_add_utf8 (mBuffer, text, strlen (text), 0, -1);
		hb_font_t *hb_font = hb_ft_font_create (font->face, NULL);
		hb_shape (hb_font, mBuffer, NULL, 0);

		unsigned int glyph_count;
		hb_glyph_info_t *glyph_info = hb_buffer_get_glyph_infos (mBuffer, &glyph_count);
		hb_glyph_position_t *glyph_pos = hb_buffer_get_glyph_positions (mBuffer, &glyph_count);

		float hres = 100;
		value pos_info = alloc_array (glyph_count);
		int posIndex = 0;

		for (int i = 0; i < glyph_count; i++) {

			font->InsertCodepointFromIndex(glyph_info[i].codepoint);
			hb_glyph_position_t pos = glyph_pos[i];

			value obj = alloc_empty_object ();
			alloc_field (obj, val_id ("codepoint"), alloc_float (glyph_info[i].codepoint));

			value advance = alloc_empty_object ();
			alloc_field (advance, val_id ("x"), alloc_float (pos.x_advance / (float)(hres * 64)));
			alloc_field (advance, val_id ("y"), alloc_float (pos.y_advance / (float)64));
			alloc_field (obj, val_id ("advance"), advance);

			value offset = alloc_empty_object ();
			alloc_field (offset, val_id ("x"), alloc_float (pos.x_offset / (float)(hres * 64)));
			alloc_field (offset, val_id ("y"), alloc_float (pos.y_offset / (float)64));
			alloc_field (obj, val_id ("offset"), offset);

			val_array_set_i (pos_info, posIndex++, obj);

		}

		hb_font_destroy (hb_font);

		return pos_info;

	}

}
