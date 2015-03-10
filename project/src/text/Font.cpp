#include <text/Font.h>
#include <graphics/ImageBuffer.h>
#include <system/System.h>

#include <algorithm>
#include <list>
#include <vector>

#ifdef LIME_FREETYPE
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_BITMAP_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include FT_GLYPH_H
#include FT_OUTLINE_H
#endif


namespace {
	
	
	enum {
		
		PT_MOVE = 1,
		PT_LINE = 2,
		PT_CURVE = 3
		
	};
	
	
	struct point {
		
		int x, y;
		unsigned char type;
		
		point () { }
		point (int x, int y, unsigned char type) : x (x), y (y), type (type) { }
		
	};
	
	
	struct glyph {
		
		FT_ULong char_code;
		FT_Vector advance;
		FT_Glyph_Metrics metrics;
		int index, x, y;
		std::vector<int> pts;
		
		glyph () : x (0), y (0) { }
		
	};
	
	
	struct kerning {
		
		int l_glyph, r_glyph;
		int x, y;
		
		kerning () { }
		kerning (int l, int r, int x, int y) : l_glyph (l), r_glyph (r), x (x), y (y) { }
		
	};
	
	
	struct glyph_sort_predicate {
		
		bool operator () (const glyph* g1, const glyph* g2) const {
			
			return g1->char_code < g2->char_code;
			
		}
		
	};
	
	
	typedef const FT_Vector *FVecPtr;
	
	
	int outline_move_to (FVecPtr to, void *user) {
		
		glyph *g = static_cast<glyph*> (user);
		
		g->pts.push_back (PT_MOVE);
		g->pts.push_back (to->x);
		g->pts.push_back (to->y);
		
		g->x = to->x;
		g->y = to->y;
		
		return 0;
		
	}
	
	
	int outline_line_to (FVecPtr to, void *user) {
		
		glyph *g = static_cast<glyph*> (user);
		
		g->pts.push_back (PT_LINE);
		g->pts.push_back (to->x - g->x);
		g->pts.push_back (to->y - g->y);
		
		g->x = to->x;
		g->y = to->y;
		
		return 0;
		
	}
	
	
	int outline_conic_to (FVecPtr ctl, FVecPtr to, void *user) {
		
		glyph *g = static_cast<glyph*> (user);
		
		g->pts.push_back (PT_CURVE);
		g->pts.push_back (ctl->x - g->x);
		g->pts.push_back (ctl->y - g->y);
		g->pts.push_back (to->x - ctl->x);
		g->pts.push_back (to->y - ctl->y);
		
		g->x = to->x;
		g->y = to->y;
		
		return 0;
		
	}
	
	
	int outline_cubic_to (FVecPtr ctl1, FVecPtr ctl2, FVecPtr to, void *user) {
		
		// Cubic curves are not supported, we need to approximate to a quadratic
		// TODO: divide into multiple curves
		
		glyph *g = static_cast<glyph*> (user);
		
		FT_Vector ctl;
		ctl.x = (-0.25 * g->x) + (0.75 * ctl1->x) + (0.75 * ctl2->x) + (-0.25 * to->x);
		ctl.y = (-0.25 * g->y) + (0.75 * ctl1->y) + (0.75 * ctl2->y) + (-0.25 * to->y);
		
		g->pts.push_back (PT_CURVE);
		g->pts.push_back (ctl.x - g->x);
		g->pts.push_back (ctl.y - g->y);
		g->pts.push_back (to->x - ctl.x);
		g->pts.push_back (to->y - ctl.y);
		
		g->x = to->x;
		g->y = to->y;
		
		return 0;
		
	}
	
	
}


namespace lime {
	
	
	static int id_charCode;
	static int id_codepoint;
	static int id_glyphIndex;
	static int id_height;
	static int id_horizontalAdvance;
	static int id_horizontalBearingX;
	static int id_horizontalBearingY;
	static int id_offset;
	static int id_size;
	static int id_verticalAdvance;
	static int id_verticalBearingX;
	static int id_verticalBearingY;
	static int id_width;
	static int id_x;
	static int id_y;
	static bool init = false;
	
	
	static void initialize () {
		
		if (!init) {
			
			id_width = val_id ("width");
			id_height = val_id ("height");
			id_x = val_id ("x");
			id_y = val_id ("y");
			id_offset = val_id ("offset");
			id_size = val_id ("size");
			id_codepoint = val_id ("codepoint");
			
			id_charCode = val_id ("charCode");
			id_glyphIndex = val_id ("glyphIndex");
			id_horizontalAdvance = val_id ("horizontalAdvance");
			id_horizontalBearingX = val_id ("horizontalBearingX");
			id_horizontalBearingY = val_id ("horizontalBearingY");
			id_verticalAdvance = val_id ("verticalAdvance");
			id_verticalBearingX = val_id ("verticalBearingX");
			id_verticalBearingY = val_id ("verticalBearingY");
			
			init = true;
			
		}
		
	}
	
	
	Font::Font (void* face) {
		
		this->face = face;
		
		if (face) {
			
			/* Set charmap
			 *
			 * See http://www.microsoft.com/typography/otspec/name.htm for a list of
			 * some possible platform-encoding pairs.  We're interested in 0-3 aka 3-1
			 * - UCS-2.  Otherwise, fail. If a font has some unicode map, but lacks
			 * UCS-2 - it is a broken or irrelevant font. What exactly Freetype will
			 * select on face load (it promises most wide unicode, and if that will be
			 * slower that UCS-2 - left as an excercise to check.
			 */
			for (int i = 0; i < ((FT_Face)face)->num_charmaps; i++) {
				
				FT_UShort pid = ((FT_Face)face)->charmaps[i]->platform_id;
				FT_UShort eid = ((FT_Face)face)->charmaps[i]->encoding_id;
				
				if (((pid == 0) && (eid == 3)) || ((pid == 3) && (eid == 1))) {
					
					FT_Set_Charmap ((FT_Face)face, ((FT_Face)face)->charmaps[i]);
					
				}
				
			}
			
		}
		
	}
	
	
	Font::Font (Resource *resource, int faceIndex) {
		
		if (resource) {
			
			int error;
			FT_Library library;
			
			error = FT_Init_FreeType (&library);
			
			if (error) {
				
				printf ("Could not initialize FreeType\n");
				
			} else {
				
				FT_Face face;
				FILE_HANDLE *file = NULL;
				
				if (resource->path) {
					
					file = lime::fopen (resource->path, "rb");
					
					if (file->isFile ()) {
						
						error = FT_New_Face (library, resource->path, faceIndex, &face);
						
					} else {
						
						ByteArray data = ByteArray (resource->path);
						unsigned char *buffer = (unsigned char*)malloc (data.Size ());
						memcpy (buffer, data.Bytes (), data.Size ());
						error = FT_New_Memory_Face (library, buffer, data.Size (), faceIndex, &face);
						
					}
					
				} else {
					
					unsigned char *buffer = (unsigned char*)malloc (resource->data->Size ());
					memcpy (buffer, resource->data->Bytes (), resource->data->Size ());
					error = FT_New_Memory_Face (library, buffer, resource->data->Size (), faceIndex, &face);
					
				}
				
				if (file) {
					
					lime::fclose (file);
					
				}
				
				if (error == FT_Err_Unknown_File_Format) {
					
					printf ("Invalid font type\n");
					
				} else if (error) {
					
					printf ("Failed to load font face %s\n", resource->path);
					
				} else {
					
					this->face = face;
					
					/* Set charmap
					 *
					 * See http://www.microsoft.com/typography/otspec/name.htm for a list of
					 * some possible platform-encoding pairs.  We're interested in 0-3 aka 3-1
					 * - UCS-2.  Otherwise, fail. If a font has some unicode map, but lacks
					 * UCS-2 - it is a broken or irrelevant font. What exactly Freetype will
					 * select on face load (it promises most wide unicode, and if that will be
					 * slower that UCS-2 - left as an excercise to check.
					 */
					for (int i = 0; i < ((FT_Face)face)->num_charmaps; i++) {
						
						FT_UShort pid = ((FT_Face)face)->charmaps[i]->platform_id;
						FT_UShort eid = ((FT_Face)face)->charmaps[i]->encoding_id;
						
						if (((pid == 0) && (eid == 3)) || ((pid == 3) && (eid == 1))) {
							
							FT_Set_Charmap ((FT_Face)face, ((FT_Face)face)->charmaps[i]);
							
						}
						
					}
					
				}
				
			}
			
		}
		
	}
	
	
	Font::~Font () {
		
		if (face) {
			
			//FT_Done_Face ((FT_Face)face);
			
		}
		
	}
	
	
	value Font::CreateImages (int fontSize, GlyphSet *glyphSet, ImageBuffer *image) {
		
		initialize ();
		
		std::list<FT_ULong> charCodes = std::list<FT_ULong> ();
		
		if (!glyphSet->glyphs.empty ()) {
			
			FT_ULong charCode;
			
			for (unsigned int i = 0; i < glyphSet->glyphs.length (); i++) {
				
				charCodes.push_back (glyphSet->glyphs[i]);
				
			}
			
		}
		
		GlyphRange range;
		
		for (int i = 0; i < glyphSet->ranges.size (); i++) {
			
			range = glyphSet->ranges[i];
			
			if (range.start == 0 && range.end == -1) {
				
				FT_UInt glyphIndex;
				FT_ULong charCode = FT_Get_First_Char ((FT_Face)face, &glyphIndex);
				
				while (glyphIndex != 0) {
					
					charCodes.push_back (charCode);
					charCode = FT_Get_Next_Char ((FT_Face)face, charCode, &glyphIndex);
					
				}
				
			} else {
				
				unsigned long end = range.end;
				
				FT_ULong charCode = range.start;
				FT_UInt glyphIndex = FT_Get_Char_Index ((FT_Face)face, charCode);
				
				while (charCode <= end || end < 0) {
					
					if (glyphIndex > 0) {
						
						charCodes.push_back (charCode);
						
					}
					
					glyphIndex = -1;
					charCode = FT_Get_Next_Char ((FT_Face)face, charCode, &glyphIndex);
					
					if (glyphIndex == 0) {
						
						break;
						
					}
					
				}
				
			}
			
		}
		
		charCodes.unique ();
		
		image->Resize (128, 128, 1);
		int x = 0, y = 0, maxRows = 0;
		unsigned char *bytes = image->data->Bytes ();
		
		value rects = alloc_array (charCodes.size ());
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
		
		FT_Set_Char_Size ((FT_Face)face, 0, (int)(fontSize*64), (int)(hdpi * hres), vdpi);
		FT_Set_Transform ((FT_Face)face, &matrix, NULL);
		FT_UInt glyphIndex;
		FT_ULong charCode;
		
		for (std::list<FT_ULong>::iterator it = charCodes.begin (); it != charCodes.end (); it++) {
			
			charCode = (*it);
			glyphIndex = FT_Get_Char_Index ((FT_Face)face, charCode);
			
			FT_Load_Glyph ((FT_Face)face, glyphIndex, FT_LOAD_FORCE_AUTOHINT | FT_LOAD_DEFAULT);
			
			if (FT_Render_Glyph (((FT_Face)face)->glyph, FT_RENDER_MODE_NORMAL) != 0) continue;
			
			FT_Bitmap bitmap = ((FT_Face)face)->glyph->bitmap;
			
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
				it = charCodes.begin ();
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
			alloc_field (offset, id_x, alloc_int (((FT_Face)face)->glyph->bitmap_left));
			alloc_field (offset, id_y, alloc_int (((FT_Face)face)->glyph->bitmap_top));
			alloc_field (v, id_offset, offset);
			
			alloc_field (v, id_charCode, alloc_int (charCode));
			alloc_field (v, id_glyphIndex, alloc_int (glyphIndex));
			//alloc_field (v, id_size, alloc_int ((*it).size));
			val_array_set_i (rects, rectsIndex++, v);
			
			x += bitmap.width + 1;
			
			if (bitmap.rows > maxRows) {
				
				maxRows = bitmap.rows;
				
			}
			
		}
		
		return rects;
		
	}
	
	
	value Font::Decompose (int em) {
		
		int result, i, j;
		
		FT_Set_Char_Size ((FT_Face)face, em, em, 72, 72);
		
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
		
		char_code = FT_Get_First_Char ((FT_Face)face, &glyph_index);
		
		while (glyph_index != 0) {
			
			if (FT_Load_Glyph ((FT_Face)face, glyph_index, FT_LOAD_NO_BITMAP | FT_LOAD_FORCE_AUTOHINT | FT_LOAD_DEFAULT) == 0) {
				
				glyph *g = new glyph;
				result = FT_Outline_Decompose (&((FT_Face)face)->glyph->outline, &ofn, g);
				
				if (result == 0) {
					
					g->index = glyph_index;
					g->char_code = char_code;
					g->metrics = ((FT_Face)face)->glyph->metrics;
					glyphs.push_back (g);
					
				} else {
					
					delete g;
					
				}
				
			}
			
			char_code = FT_Get_Next_Char ((FT_Face)face, char_code, &glyph_index);
			
		}
		
		// Ascending sort by character codes
		std::sort (glyphs.begin (), glyphs.end (), glyph_sort_predicate ());
		
		std::vector<kerning>  kern;
		if (FT_HAS_KERNING (((FT_Face)face))) {
			
			int n = glyphs.size ();
			FT_Vector v;
			
			for (i = 0; i < n; i++) {
				
				int  l_glyph = glyphs[i]->index;
				
				for (j = 0; j < n; j++) {
					
					int r_glyph = glyphs[j]->index;
					
					FT_Get_Kerning ((FT_Face)face, l_glyph, r_glyph, FT_KERNING_DEFAULT, &v);
					
					if (v.x != 0 || v.y != 0) {
						
						kern.push_back (kerning (i, j, v.x, v.y));
						
					}
					
				}
				
			}
			
		}
		
		int num_glyphs = glyphs.size ();
		
		Font font = Font (face);
		wchar_t* family_name = font.GetFamilyName ();
		
		value ret = alloc_empty_object ();
		alloc_field (ret, val_id ("has_kerning"), alloc_bool (FT_HAS_KERNING (((FT_Face)face))));
		alloc_field (ret, val_id ("is_fixed_width"), alloc_bool (FT_IS_FIXED_WIDTH (((FT_Face)face))));
		alloc_field (ret, val_id ("has_glyph_names"), alloc_bool (FT_HAS_GLYPH_NAMES (((FT_Face)face))));
		alloc_field (ret, val_id ("is_italic"), alloc_bool (((FT_Face)face)->style_flags & FT_STYLE_FLAG_ITALIC));
		alloc_field (ret, val_id ("is_bold"), alloc_bool (((FT_Face)face)->style_flags & FT_STYLE_FLAG_BOLD));
		alloc_field (ret, val_id ("num_glyphs"), alloc_int (num_glyphs));
		alloc_field (ret, val_id ("family_name"), family_name == NULL ? alloc_string (((FT_Face)face)->family_name) : alloc_wstring (family_name));
		alloc_field (ret, val_id ("style_name"), alloc_string (((FT_Face)face)->style_name));
		alloc_field (ret, val_id ("em_size"), alloc_int (((FT_Face)face)->units_per_EM));
		alloc_field (ret, val_id ("ascend"), alloc_int (((FT_Face)face)->ascender));
		alloc_field (ret, val_id ("descend"), alloc_int (((FT_Face)face)->descender));
		alloc_field (ret, val_id ("height"), alloc_int (((FT_Face)face)->height));
		
		delete family_name;
		
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
		if (FT_HAS_KERNING (((FT_Face)face))) {
			
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
	
	
	int Font::GetAscender () {
		
		return ((FT_Face)face)->ascender;
		
	}
	
	
	int Font::GetDescender () {
		
		return ((FT_Face)face)->descender;
		
	}
	
	
	wchar_t *Font::GetFamilyName () {
		
		#ifdef LIME_FREETYPE
		
		wchar_t *family_name = NULL;
		FT_SfntName sfnt_name;
		FT_UInt num_sfnt_names, sfnt_name_index;
		int len, i;
		
		if (FT_IS_SFNT (((FT_Face)face))) {
			
			num_sfnt_names = FT_Get_Sfnt_Name_Count ((FT_Face)face);
			sfnt_name_index = 0;
			
			while (sfnt_name_index < num_sfnt_names) {
				
				if (!FT_Get_Sfnt_Name ((FT_Face)face, sfnt_name_index++, (FT_SfntName *)&sfnt_name) && sfnt_name.name_id == TT_NAME_ID_FULL_NAME) {
					
					if (sfnt_name.platform_id == TT_PLATFORM_MACINTOSH) {
						
						len = sfnt_name.string_len;
						family_name = new wchar_t[len + 1];
						mbstowcs (&family_name[0], &reinterpret_cast<const char*>(sfnt_name.string)[0], len);
						family_name[len] = L'\0';
						return family_name;
						
					} else if ((sfnt_name.platform_id == TT_PLATFORM_MICROSOFT) && (sfnt_name.encoding_id == TT_MS_ID_UNICODE_CS)) {
						
						len = sfnt_name.string_len / 2;
						family_name = (wchar_t*)malloc ((len + 1) * sizeof (wchar_t));
						
						for (i = 0; i < len; i++) {
							
							family_name[i] = ((wchar_t)sfnt_name.string[i * 2 + 1]) | (((wchar_t)sfnt_name.string[i * 2]) << 8);
							
						}
						
						family_name[len] = L'\0';
						return family_name;
						
					}
					
				}
				
			}
			
		}
		
		#endif
		
		return NULL;
		
	}
	
	
	void GetGlyphMetrics_Push (FT_Face face, FT_ULong charCode, FT_UInt glyphIndex, value glyphList) {
		
		if (FT_Load_Glyph (face, glyphIndex, FT_LOAD_NO_BITMAP | FT_LOAD_FORCE_AUTOHINT | FT_LOAD_DEFAULT) == 0) {
			
			value metrics = alloc_empty_object ();
			
			alloc_field (metrics, id_charCode, alloc_int (charCode));
			alloc_field (metrics, id_glyphIndex, alloc_int (glyphIndex));
			alloc_field (metrics, id_height, alloc_int (((FT_Face)face)->glyph->metrics.height));
			alloc_field (metrics, id_horizontalBearingX, alloc_int (((FT_Face)face)->glyph->metrics.horiBearingX));
			alloc_field (metrics, id_horizontalBearingY, alloc_int (((FT_Face)face)->glyph->metrics.horiBearingY));
			alloc_field (metrics, id_horizontalAdvance, alloc_int (((FT_Face)face)->glyph->metrics.horiAdvance));
			alloc_field (metrics, id_verticalBearingX, alloc_int (((FT_Face)face)->glyph->metrics.vertBearingX));
			alloc_field (metrics, id_verticalBearingY, alloc_int (((FT_Face)face)->glyph->metrics.vertBearingY));
			alloc_field (metrics, id_verticalAdvance, alloc_int (((FT_Face)face)->glyph->metrics.vertAdvance));
			
			val_array_push (glyphList, metrics);
			
		}
		
	}
	
	
	value Font::GetGlyphMetrics (GlyphSet *glyphSet) {
		
		initialize ();
		
		value glyphList = alloc_array (0);
		
		if (!glyphSet->glyphs.empty ()) {
			
			FT_ULong charCode;
			
			for (unsigned int i = 0; i < glyphSet->glyphs.length (); i++) {
				
				charCode = glyphSet->glyphs[i];
				GetGlyphMetrics_Push ((FT_Face)face, charCode, FT_Get_Char_Index ((FT_Face)face, charCode), glyphList);
				
			}
			
		}
		
		GlyphRange range;
		
		for (int i = 0; i < glyphSet->ranges.size (); i++) {
			
			range = glyphSet->ranges[i];
			
			if (range.start == 0 && range.end == -1) {
				
				FT_UInt glyphIndex;
				FT_ULong charCode = FT_Get_First_Char ((FT_Face)face, &glyphIndex);
				
				while (glyphIndex != 0) {
					
					GetGlyphMetrics_Push ((FT_Face)face, charCode, glyphIndex, glyphList);
					charCode = FT_Get_Next_Char ((FT_Face)face, charCode, &glyphIndex);
					
				}
				
			} else {
				
				unsigned long end = range.end;
				
				FT_ULong charCode = range.start;
				FT_UInt glyphIndex = FT_Get_Char_Index ((FT_Face)face, charCode);
				
				while (charCode <= end || end < 0) {
					
					if (glyphIndex > 0) {
						
						GetGlyphMetrics_Push ((FT_Face)face, charCode, glyphIndex, glyphList);
						
					}
					
					glyphIndex = -1;
					charCode = FT_Get_Next_Char ((FT_Face)face, charCode, &glyphIndex);
					
					if (glyphIndex == 0) {
						
						break;
						
					}
					
				}
				
			}
			
		}
		
		return glyphList;
		
	}
	
	
	int Font::GetHeight () {
		
		return ((FT_Face)face)->height;
		
	}
	
	
	int Font::GetNumGlyphs () {
		
		return ((FT_Face)face)->num_glyphs;
		
	}
	
	
	int Font::GetUnderlinePosition () {
		
		return ((FT_Face)face)->underline_position;
		
	}
	
	
	int Font::GetUnderlineThickness () {
		
		return ((FT_Face)face)->underline_thickness;
		
	}
	
	
	int Font::GetUnitsPerEM () {
		
		return ((FT_Face)face)->units_per_EM;
		
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
		
		FT_Set_Char_Size ((FT_Face)face, 0, (int)(size*64), (int)(hdpi * hres), vdpi);
		FT_Set_Transform ((FT_Face)face, &matrix, NULL);
		
		mSize = size;
		
	}
	
	
}
