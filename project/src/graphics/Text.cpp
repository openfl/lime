#include <graphics/Font.h>
#include <graphics/Text.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <hb-ft.h>


namespace lime {

	Text::Text (hb_tag_t direction, const char *script, const char *language) {

		if (strlen(script) != 4) return;

		hb_script_t tag = (hb_script_t)HB_TAG (script[0], script[1], script[2], script[3]);

		buffer = hb_buffer_create ();
		hb_buffer_set_direction (buffer, (hb_direction_t)direction);
		hb_buffer_set_script (buffer, tag);
		hb_buffer_set_language (buffer, hb_language_from_string (language, strlen (language)));

	}

	Text::~Text () {

		hb_buffer_reset (buffer);
		hb_buffer_destroy (buffer);

	}

	value Text::FromString (Font *font, size_t size, const char *text) {

		font->SetSize (size);

		// layout the text
		int len = strlen (text);
		hb_buffer_add_utf8 (buffer, text, len, 0, len);
		hb_font_t *hb_font = hb_ft_font_create (font->face, NULL);
		hb_shape (hb_font, buffer, NULL, 0);

		unsigned int glyph_count;
		hb_glyph_info_t *glyph_info = hb_buffer_get_glyph_infos (buffer, &glyph_count);
		hb_glyph_position_t *glyph_pos = hb_buffer_get_glyph_positions (buffer, &glyph_count);
		hb_direction_t direction = hb_buffer_get_direction (buffer);

		float hres = 100;
		value pos_info = alloc_array (glyph_count);
		int posIndex = 0;

		for (int i = 0; i < glyph_count; i++) {

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
