#include <graphics/Font.h>
#include <ft2build.h>
#include FT_FREETYPE_H


typedef struct {

	char c;
	FT_UInt index;
	FT_Pos height;

} GlyphInfo;


namespace lime {


	static int id_x;
	static int id_y;
	static int id_x_offset;
	static int id_y_offset;
	static int id_advance;
	static int id_width;
	static int id_height;
	static int id_char;
	static bool init = false;


	bool CompareGlyph (const GlyphInfo &a, const GlyphInfo &b) {

		return a.height > b.height;

	}


	Font::Font (const char *fontFace) {

		int error;
		FT_Library library;

		error = FT_Init_FreeType (&library);

		if (error) {

			printf ("Could not initialize FreeType\n");

		}

		error = FT_New_Face (library, fontFace, 0, &face);

		if (error == FT_Err_Unknown_File_Format) {

			printf ("Invalid font type\n");

		} else if (error) {

			printf ("Failed to load font face %s\n", fontFace);

		}

	}


	value Font::LoadGlyphs (int size, const char *glyphs, Image *image) {

		if (!init) {

			id_width = val_id ("width");
			id_height = val_id ("height");
			id_x = val_id ("x");
			id_y = val_id ("y");
			id_x_offset = val_id ("xOffset");
			id_y_offset = val_id ("yOffset");
			id_advance = val_id ("advance");
			id_char = val_id ("char");
			init = true;

		}

		std::list<GlyphInfo> glyphList;
		int numGlyphs = strlen (glyphs);
		char c[2] = " ";

		FT_Set_Pixel_Sizes (face, 0, size);

		for (int i = 0; i < numGlyphs; i++) {

			GlyphInfo info;
			info.c = glyphs[i];
			info.index = FT_Get_Char_Index (face, info.c);

			if (FT_Load_Glyph (face, info.index, FT_LOAD_DEFAULT) != 0) continue;
			info.height = face->glyph->metrics.height;

			glyphList.push_back(info);

		}

		glyphList.sort(CompareGlyph);

		image->Resize(128, 128, 1);
		int x = 0, y = 0, maxRows = 0;
		unsigned char *bytes = image->data->Bytes ();

		value rects = alloc_array (glyphList.size());
		int rectsIndex = 0;

		for (std::list<GlyphInfo>::iterator it = glyphList.begin(); it != glyphList.end(); it++) {

			FT_Load_Glyph (face, (*it).index, FT_LOAD_DEFAULT);
			c[0] = (*it).c;

			if (FT_Render_Glyph (face->glyph, FT_RENDER_MODE_NORMAL) != 0) continue;

			FT_Bitmap bitmap = face->glyph->bitmap;

			if (x + bitmap.width > image->width) {

				y += maxRows + 1;
				x = maxRows = 0;

			}

			if (y + bitmap.rows > image->height) {

				if (image->width < image->height) {

					image->width *= 2;

				} else {

					image->height *= 2;

				}

				image->Resize (image->width, image->height, 1);
				rectsIndex = 0;
				it = glyphList.begin ();
				it--;
				x = y = maxRows = 0;
				continue;

			}

			if (image->bpp == 1) {

				image->Blit (bitmap.buffer, x, y, bitmap.width, bitmap.rows);

			} else {

				for (int row = 0; row < bitmap.rows; row++) {

					unsigned char *out = &bytes[((row + y) * image->width + x) * image->bpp];
					const unsigned char *line = &bitmap.buffer[row * bitmap.width]; // scanline
					const unsigned char *const end = line + bitmap.width;

					while (line != end) {

						*out++ = 0xFF;
						*out++ = 0xFF;
						*out++ = 0xFF;
						*out++ = *line;

						line++;

					}

				}

			}

			value v = alloc_empty_object ();
			alloc_field (v, id_x, alloc_int (x));
			alloc_field (v, id_y, alloc_int (y));
			alloc_field (v, id_x_offset, alloc_int (face->glyph->metrics.horiBearingX / 64));
			alloc_field (v, id_y_offset, alloc_int (face->glyph->metrics.horiBearingY / 64));
			alloc_field (v, id_advance, alloc_int (face->glyph->metrics.horiAdvance / 64));
			alloc_field (v, id_width, alloc_int (bitmap.width));
			alloc_field (v, id_height, alloc_int (bitmap.rows));
			alloc_field (v, id_char, alloc_string (c));
			val_array_set_i (rects, rectsIndex++, v);

			x += bitmap.width + 1;

			if (bitmap.rows > maxRows) {

				maxRows = bitmap.rows;

			}

		}

		return rects;

	}


}
