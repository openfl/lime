#include <graphics/Font.h>
#include <graphics/Text.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include <hb-ft.h>


namespace lime {

	Text::Text (hb_tag_t direction, const char *script, const char *language) {

		if (strlen(script) != 4) return;

		buffer = hb_buffer_create ();
		hb_buffer_set_direction (buffer, (hb_direction_t)direction);
		hb_buffer_set_script (buffer, (hb_script_t)HB_TAG (script[0], script[1], script[2], script[3]));
		hb_buffer_set_language (buffer, hb_language_from_string (language, strlen (language)));

	}

	Text::~Text () {

		hb_buffer_destroy (buffer);

	}

	void Text::fromString (Font *font, const char *text) {

		// layout the text
		size_t len = strlen (text);
		hb_buffer_add_utf8 (buffer, text, len, 0, len);
		hb_font_t *hb_font = hb_ft_font_create (font->face, NULL);
		hb_shape (hb_font, buffer, NULL, 0);

		unsigned int glyph_count;
		hb_glyph_info_t *glyph_info = hb_buffer_get_glyph_infos (buffer, &glyph_count);
		hb_glyph_position_t *glyph_pos = hb_buffer_get_glyph_positions (buffer, &glyph_count);

		float hres = 16.0;

		for (int i = 0; i < glyph_count; i++) {

			int codepoint = glyph_info[i].codepoint;
			float x_advance = glyph_pos[i].x_advance / (float)(hres * 64);
            float x_offset = glyph_pos[i].x_offset / (float)(hres * 64);
            float y_advance = glyph_pos[i].y_advance / (float)(64);
            float y_offset = glyph_pos[i].y_offset / (float)(64);

		}

		hb_font_destroy (hb_font);

	}

}
