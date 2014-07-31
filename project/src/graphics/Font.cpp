#include <graphics/Font.h>
#include <media/Image.h>
#include <algorithm>

// from http://stackoverflow.com/questions/2948308/how-do-i-read-utf-8-characters-via-a-pointer
#define IS_IN_RANGE(c, f, l)    (((c) >= (f)) && ((c) <= (l)))

unsigned long readNextChar (char*& p)
{
    // TODO: since UTF-8 is a variable-length
    // encoding, you should pass in the input
    // buffer's actual byte length so that you
    // can determine if a malformed UTF-8
    // sequence would exceed the end of the buffer...

    unsigned char c1, c2, *ptr = (unsigned char*) p;
    unsigned long uc = 0;
    int seqlen;

    c1 = ptr[0];

    if ((c1 & 0x80) == 0) {

        uc = (unsigned long) (c1 & 0x7F);
        seqlen = 1;

    } else if ((c1 & 0xE0) == 0xC0) {

        uc = (unsigned long) (c1 & 0x1F);
        seqlen = 2;

    } else if ((c1 & 0xF0) == 0xE0) {

        uc = (unsigned long) (c1 & 0x0F);
        seqlen = 3;

    } else if ((c1 & 0xF8) == 0xF0) {

        uc = (unsigned long) (c1 & 0x07);
        seqlen = 4;

    } else {

        // malformed data, do something !!!
        return (unsigned long) -1;

    }

    for (int i = 1; i < seqlen; ++i) {

        c1 = ptr[i];

        if ((c1 & 0xC0) != 0x80) {

            // malformed data, do something !!!
            return (unsigned long) -1;

        }

    }

    switch (seqlen) {
        case 2:
            c1 = ptr[0];

            if (!IS_IN_RANGE(c1, 0xC2, 0xDF)) {

                // malformed data, do something !!!
                return (unsigned long) -1;

            }

            break;
        case 3:
            c1 = ptr[0];
            c2 = ptr[1];

            if (((c1 == 0xE0) && !IS_IN_RANGE(c2, 0xA0, 0xBF)) ||
                ((c1 == 0xED) && !IS_IN_RANGE(c2, 0x80, 0x9F)) ||
                (!IS_IN_RANGE(c1, 0xE1, 0xEC) && !IS_IN_RANGE(c1, 0xEE, 0xEF))) {

                // malformed data, do something !!!
                return (unsigned long) -1;

            }

            break;
        case 4:
            c1 = ptr[0];
            c2 = ptr[1];

            if (((c1 == 0xF0) && !IS_IN_RANGE(c2, 0x90, 0xBF)) ||
                ((c1 == 0xF4) && !IS_IN_RANGE(c2, 0x80, 0x8F)) ||
                !IS_IN_RANGE(c1, 0xF1, 0xF3)) {

                // malformed data, do something !!!
                return (unsigned long) -1;

            }

            break;
    }

    for (int i = 1; i < seqlen; ++i) {

        uc = ((uc << 6) | (unsigned long)(ptr[i] & 0x3F));

    }

    p += seqlen;
    return uc;
}


namespace lime {


	static int id_x;
	static int id_y;
	static int id_offset;
	static int id_width;
	static int id_height;
	static int id_size;
	static int id_codepoint;
	static bool init = false;


	bool CompareGlyphHeight (const GlyphInfo &a, const GlyphInfo &b) {

		return a.height > b.height;

	}

	bool CompareGlyphCodepoint (const GlyphInfo &a, const GlyphInfo &b) {

		return a.codepoint < b.codepoint && a.size < b.size;

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

		/* Set charmap
		 *
		 * See http://www.microsoft.com/typography/otspec/name.htm for a list of
		 * some possible platform-encoding pairs.  We're interested in 0-3 aka 3-1
		 * - UCS-2.  Otherwise, fail. If a font has some unicode map, but lacks
		 * UCS-2 - it is a broken or irrelevant font. What exactly Freetype will
		 * select on face load (it promises most wide unicode, and if that will be
		 * slower that UCS-2 - left as an excercise to check.
		 */
		for (int i = 0; i < face->num_charmaps; i++) {

			FT_UShort pid = face->charmaps[i]->platform_id;
			FT_UShort eid = face->charmaps[i]->encoding_id;

			if (((pid == 0) && (eid == 3)) || ((pid == 3) && (eid == 1))) {

				FT_Set_Charmap (face, face->charmaps[i]);

			}

		}

	}

	bool Font::InsertCodepoint (unsigned long codepoint) {

		GlyphInfo info;
		info.codepoint = codepoint;
		info.size = mSize;

		// search for duplicates, if any
		std::list<GlyphInfo>::iterator first = glyphList.begin ();
		first = std::lower_bound (first, glyphList.end (), info, CompareGlyphCodepoint);

		// skip duplicates unless they are different sizes
		// if (codepoint < (*first).codepoint ||
		// 	(codepoint == (*first).codepoint && mSize != (*first).size)) {

			info.index = FT_Get_Char_Index (face, codepoint);

			if (FT_Load_Glyph (face, info.index, FT_LOAD_DEFAULT) != 0) return false;
			info.height = face->glyph->metrics.height;

			glyphList.insert (first, info);

			return true;
			
		// }

		return false;

	}

	void Font::SetSize (size_t size) {

		size_t hdpi = 72;
		size_t vdpi = 72;
		size_t hres = 100;
		FT_Matrix matrix = {
			(int)((1.0/hres) * 0x10000L),
			(int)((0.0) * 0x10000L),
			(int)((0.0) * 0x10000L),
			(int)((1.0) * 0x10000L)
		};

		FT_Set_Char_Size (face, 0, (int)(size*64), (int)(hdpi * hres), vdpi);
		FT_Set_Transform (face, &matrix, NULL);

		mSize = size;

	}

	void Font::LoadRange (unsigned long start, unsigned long end) {

		for (unsigned long codepoint = start; codepoint < end; codepoint++) {

			InsertCodepoint (codepoint);

		}

	}


	void Font::LoadGlyphs (const char *glyphs) {

		char *g = (char*)glyphs;

		while (*g != 0) {

			InsertCodepoint (readNextChar (g));

		}

	}

	value Font::RenderToImage (Image *image) {

		if (!init) {

			id_width = val_id ("width");
			id_height = val_id ("height");
			id_x = val_id ("x");
			id_y = val_id ("y");
			id_offset = val_id ("offset");
			id_size = val_id ("size");
			id_codepoint = val_id ("codepoint");
			init = true;

		}

		glyphList.sort (CompareGlyphHeight);

		image->Resize (128, 128, 1);
		int x = 0, y = 0, maxRows = 0;
		unsigned char *bytes = image->data->Bytes ();

		value rects = alloc_array (glyphList.size());
		int rectsIndex = 0;

		size_t hdpi = 72;
		size_t vdpi = 72;
		size_t hres = 100;
		FT_Matrix matrix = {
			(int)((1.0/hres) * 0x10000L),
			(int)((0.0) * 0x10000L),
			(int)((0.0) * 0x10000L),
			(int)((1.0) * 0x10000L)
		};

		for (std::list<GlyphInfo>::iterator it = glyphList.begin(); it != glyphList.end(); it++) {

			// recalculate the character size for each glyph since it will vary
			FT_Set_Char_Size (face, 0, (int)((*it).size*64), (int)(hdpi * hres), vdpi);
			FT_Set_Transform (face, &matrix, NULL);

			FT_Load_Glyph (face, (*it).index, FT_LOAD_DEFAULT);

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
			alloc_field (v, id_width, alloc_int (bitmap.width));
			alloc_field (v, id_height, alloc_int (bitmap.rows));

			value offset = alloc_empty_object ();
			alloc_field (offset, id_x, alloc_int (face->glyph->bitmap_left));
			alloc_field (offset, id_y, alloc_int (face->glyph->bitmap_top));
			alloc_field (v, id_offset, offset);

			alloc_field (v, id_codepoint, alloc_int ((*it).codepoint));
			alloc_field (v, id_size, alloc_int ((*it).size));
			val_array_set_i (rects, rectsIndex++, v);

			x += bitmap.width + 1;

			if (bitmap.rows > maxRows) {

				maxRows = bitmap.rows;

			}

		}

		return rects;

	}


}
