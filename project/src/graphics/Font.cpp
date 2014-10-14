#include <graphics/Font.h>
#include <graphics/ImageBuffer.h>
#include <algorithm>
#include <vector>

// from http://stackoverflow.com/questions/2948308/how-do-i-read-utf-8-characters-via-a-pointer
#define IS_IN_RANGE(c, f, l)	 (((c) >= (f)) && ((c) <= (l)))

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


namespace {
	
	
	enum {
		PT_MOVE = 1,
		PT_LINE = 2,
		PT_CURVE = 3
	};

	struct point {
		int				x, y;
		unsigned char  type;

		point() { }
		point(int x, int y, unsigned char type) : x(x), y(y), type(type) { }
	};
	
	
	struct glyph {
		
		FT_ULong					 char_code;
		FT_Vector					advance;
		FT_Glyph_Metrics		  metrics;
		int							index, x, y;
		std::vector<int>		  pts;
		
		glyph(): x(0), y(0) { }
		
	};
	
	
	struct kerning {
		int							l_glyph, r_glyph;
		int							x, y;

		kerning() { }
		kerning(int l, int r, int x, int y): l_glyph(l), r_glyph(r), x(x), y(y) { }
	};
	
	
	struct glyph_sort_predicate {
		bool operator()(const glyph* g1, const glyph* g2) const {
			return g1->char_code <  g2->char_code;
		}
	};
	
	
	typedef const FT_Vector *FVecPtr;
	
	
	int outline_move_to(FVecPtr to, void *user) {
		glyph		 *g = static_cast<glyph*>(user);

		g->pts.push_back(PT_MOVE);
		g->pts.push_back(to->x);
		g->pts.push_back(to->y);

		g->x = to->x;
		g->y = to->y;
		
		return 0;
	}

	int outline_line_to(FVecPtr to, void *user) {
		glyph		 *g = static_cast<glyph*>(user);

		g->pts.push_back(PT_LINE);
		g->pts.push_back(to->x - g->x);
		g->pts.push_back(to->y - g->y);
		
		g->x = to->x;
		g->y = to->y;
		
		return 0;
	}

	int outline_conic_to(FVecPtr ctl, FVecPtr to, void *user) {
		glyph		 *g = static_cast<glyph*>(user);

		g->pts.push_back(PT_CURVE);
		g->pts.push_back(ctl->x - g->x);
		g->pts.push_back(ctl->y - g->y);
		g->pts.push_back(to->x - ctl->x);
		g->pts.push_back(to->y - ctl->y);
		
		g->x = to->x;
		g->y = to->y;
		
		return 0;
	}

	int outline_cubic_to(FVecPtr, FVecPtr , FVecPtr , void *user) {
		// Cubic curves are not supported
		return 1;
	}

	
	
}


namespace lime {
	
	
	static int id_codepoint;
	static int id_height;
	static int id_offset;
	static int id_size;
	static int id_width;
	static int id_x;
	static int id_y;
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
	
	
	wchar_t *get_familyname_from_sfnt_name(FT_Face face)
	{
		wchar_t *family_name = NULL;
		FT_SfntName sfnt_name;
		FT_UInt num_sfnt_names, sfnt_name_index;
		int len, i;
		
		if (FT_IS_SFNT(face))
		{
			num_sfnt_names = FT_Get_Sfnt_Name_Count(face);
			sfnt_name_index = 0;
			while (sfnt_name_index < num_sfnt_names)
			{
				if (!FT_Get_Sfnt_Name(face, sfnt_name_index++, (FT_SfntName *)&sfnt_name))
				{
					//if((sfnt_name.name_id == TT_NAME_ID_FONT_FAMILY) &&
					if((sfnt_name.name_id == 4) &&
						//(sfnt_name.language_id == GetUserDefaultLCID()) &&
						(sfnt_name.platform_id == TT_PLATFORM_MICROSOFT) &&
						(sfnt_name.encoding_id == TT_MS_ID_UNICODE_CS))
					{
						/* Note that most fonts contains a Unicode charmap using
							TT_PLATFORM_MICROSOFT, TT_MS_ID_UNICODE_CS.
						*/
						
						/* .string :
								Note that its format differs depending on the 
								(platform,encoding) pair. It can be a Pascal String, 
								a UTF-16 one, etc..
								Generally speaking, the string is "not" zero-terminated.
								Please refer to the TrueType specification for details..
								 
							.string_len :
								The length of `string' in bytes.
						*/
						
						len = sfnt_name.string_len / 2;
						family_name = (wchar_t*)malloc((len + 1) * sizeof(wchar_t));
						for(i = 0; i < len; i++)
						{
							family_name[i] = ((wchar_t)sfnt_name.string[i*2 + 1]) | (((wchar_t)sfnt_name.string[i*2]) << 8);
						}
						family_name[len] = 0;
						return family_name;
					}
				}
			}
		}
		
		return NULL;
	}
	
	
	value Font::Decompose (int em) {
		
		int result, i, j;
		
		FT_Set_Char_Size (face, em, em, 72, 72);
		
		std::vector<glyph*> glyphs;
		
		FT_Outline_Funcs ofn =
		{
			outline_move_to,
			outline_line_to,
			outline_conic_to,
			outline_cubic_to,
			0, // shift
			0  // delta
		};
		
		// Import every character in face
		FT_ULong char_code;
		FT_UInt glyph_index;
		
		char_code = FT_Get_First_Char (face, &glyph_index);
		
		while (glyph_index != 0) {
			
			if (FT_Load_Glyph (face, glyph_index, FT_LOAD_FORCE_AUTOHINT | FT_LOAD_DEFAULT) == 0) {
				
				glyph *g = new glyph;
				result = FT_Outline_Decompose (&face->glyph->outline, &ofn, g);
				
				if (result == 0) {
					
					g->index = glyph_index;
					g->char_code = char_code;
					g->metrics = face->glyph->metrics;
					glyphs.push_back (g);
					
				} else {
					
					delete g;
					
				}
				
			}
			
			char_code = FT_Get_Next_Char (face, char_code, &glyph_index);
			
		}
		
		// Ascending sort by character codes
		std::sort (glyphs.begin (), glyphs.end (), glyph_sort_predicate ());
		
		std::vector<kerning>  kern;
		if (FT_HAS_KERNING (face)) {
			
			int n = glyphs.size ();
			FT_Vector v;
			
			for (i = 0; i < n; i++) {
				
				int  l_glyph = glyphs[i]->index;
				
				for (j = 0; j < n; j++) {
					
					int r_glyph = glyphs[j]->index;
					
					FT_Get_Kerning (face, l_glyph, r_glyph, FT_KERNING_DEFAULT, &v);
					
					if (v.x != 0 || v.y != 0) {
						
						kern.push_back (kerning (i, j, v.x, v.y));
						
					}
					
				}
				
			}
			
		}
		
		int num_glyphs = glyphs.size ();
		wchar_t* family_name = get_familyname_from_sfnt_name (face);
		
		value ret = alloc_empty_object ();
		alloc_field (ret, val_id ("has_kerning"), alloc_bool (FT_HAS_KERNING (face)));
		alloc_field (ret, val_id ("is_fixed_width"), alloc_bool (FT_IS_FIXED_WIDTH (face)));
		alloc_field (ret, val_id ("has_glyph_names"), alloc_bool (FT_HAS_GLYPH_NAMES (face)));
		alloc_field (ret, val_id ("is_italic"), alloc_bool (face->style_flags & FT_STYLE_FLAG_ITALIC));
		alloc_field (ret, val_id ("is_bold"), alloc_bool (face->style_flags & FT_STYLE_FLAG_BOLD));
		alloc_field (ret, val_id ("num_glyphs"), alloc_int (num_glyphs));
		alloc_field (ret, val_id ("family_name"), family_name == NULL ? alloc_string (face->family_name) : alloc_wstring (family_name));
		alloc_field (ret, val_id ("style_name"), alloc_string (face->style_name));
		alloc_field (ret, val_id ("em_size"), alloc_int (face->units_per_EM));
		alloc_field (ret, val_id ("ascend"), alloc_int (face->ascender));
		alloc_field (ret, val_id ("descend"), alloc_int (face->descender));
		alloc_field (ret, val_id ("height"), alloc_int (face->height));
		
		// 'glyphs' field
		value neko_glyphs = alloc_array (num_glyphs);
		for (i = 0; i < glyphs.size (); i++) {
			
			glyph *g = glyphs[i];
			int num_points = g->pts.size ();
			
			value points = alloc_array (num_points);
			
			for (j = 0; j < num_points; j++) {
				
				val_array_set_i (points, j, alloc_int (g->pts[j]));
				
			}
			
			value item = alloc_empty_object ();
			val_array_set_i (neko_glyphs, i, item);
			alloc_field (item, val_id ("char_code"), alloc_int (g->char_code));
			alloc_field (item, val_id ("advance"), alloc_int (g->metrics.horiAdvance));
			alloc_field (item, val_id ("min_x"), alloc_int (g->metrics.horiBearingX));
			alloc_field (item, val_id ("max_x"), alloc_int (g->metrics.horiBearingX + g->metrics.width));
			alloc_field (item, val_id ("min_y"), alloc_int (g->metrics.horiBearingY - g->metrics.height));
			alloc_field (item, val_id ("max_y"), alloc_int (g->metrics.horiBearingY));
			alloc_field (item, val_id ("points"), points);
			
			delete g;
			
		}
		
		alloc_field (ret, val_id ("glyphs"), neko_glyphs);
		
		// 'kerning' field
		if (FT_HAS_KERNING (face)) {
			
			value neko_kerning = alloc_array (kern.size ());
			
			for (i = 0; i < kern.size(); i++) {
				
				kerning *k = &kern[i];
				
				value item = alloc_empty_object();
				val_array_set_i (neko_kerning,i,item);
				alloc_field (item, val_id ("left_glyph"), alloc_int (k->l_glyph));
				alloc_field (item, val_id ("right_glyph"), alloc_int (k->r_glyph));
				alloc_field (item, val_id ("x"), alloc_int (k->x));
				alloc_field (item, val_id ("y"), alloc_int (k->y));
				
			}
			
			alloc_field (ret, val_id ("kerning"), neko_kerning);
			
		} else {
			
			alloc_field (ret, val_id ("kerning"), alloc_null ());
			
		}
		
		return ret;
		
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
	
	
	void Font::LoadGlyphs (const char *glyphs) {
		
		char *g = (char*)glyphs;
		
		while (*g != 0) {
			
			InsertCodepoint (readNextChar (g));
			
		}
		
	}
	
	
	void Font::LoadRange (unsigned long start, unsigned long end) {
		
		for (unsigned long codepoint = start; codepoint < end; codepoint++) {
			
			InsertCodepoint (codepoint);
			
		}
		
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
	
	
	value Font::RenderToImage (ImageBuffer *image) {
		
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
		
		value rects = alloc_array (glyphList.size ());
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
		
		for (std::list<GlyphInfo>::iterator it = glyphList.begin (); it != glyphList.end (); it++) {
			
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
			
			alloc_field (v, id_codepoint, alloc_int ((*it).index));
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