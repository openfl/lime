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
#include FT_TRUETYPE_TABLES_H
#include FT_GLYPH_H
#include FT_OUTLINE_H
#endif

#ifdef GetGlyphIndices
#undef GetGlyphIndices
#endif


// from http://stackoverflow.com/questions/2948308/how-do-i-read-utf-8-characters-via-a-pointer
#define IS_IN_RANGE(c, f, l) (((c) >= (f)) && ((c) <= (l)))


unsigned long readNextChar (const char*& p)
{
	 // TODO: since UTF-8 is a variable-length
	 // encoding, you should pass in the input
	 // buffer's actual byte length so that you
	 // can determine if a malformed UTF-8
	 // sequence would exceed the end of the buffer...

	 const unsigned char* ptr = (const unsigned char*) p;
	 unsigned char c1, c2;
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
		PT_CURVE = 3,
		PT_CUBIC = 4

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


	int outline_cubic_to (FVecPtr control1, FVecPtr control2, FVecPtr to, void *user) {

		glyph *g = static_cast<glyph*> (user);

		g->pts.push_back (PT_CUBIC);
		g->pts.push_back (control1->x - g->x);
		g->pts.push_back (control1->y - g->y);
		g->pts.push_back (control2->x - control1->x);
		g->pts.push_back (control2->y - control1->y);
		g->pts.push_back (to->x - control2->x);
		g->pts.push_back (to->y - control2->y);

		g->x = to->x;
		g->y = to->y;

		return 0;

	}


}


namespace lime {


	static int id_buffer;
	static int id_charCode;
	static int id_codepoint;
	static int id_height;
	static int id_index;
	static int id_horizontalAdvance;
	static int id_horizontalBearingX;
	static int id_horizontalBearingY;
	static int id_image;
	static int id_offset;
	static int id_offsetX;
	static int id_offsetY;
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

			id_buffer = val_id ("buffer");
			id_charCode = val_id ("charCode");
			id_horizontalAdvance = val_id ("horizontalAdvance");
			id_horizontalBearingX = val_id ("horizontalBearingX");
			id_horizontalBearingY = val_id ("horizontalBearingY");
			id_image = val_id ("image");
			id_index = val_id ("index");
			id_offsetX = val_id ("offsetX");
			id_offsetY = val_id ("offsetY");
			id_verticalAdvance = val_id ("verticalAdvance");
			id_verticalBearingX = val_id ("verticalBearingX");
			id_verticalBearingY = val_id ("verticalBearingY");

			init = true;

		}

	}


	Font::Font (Resource *resource, int faceIndex) {

		this->library = 0;
		this->face = 0;
		this->faceMemory = 0;

		if (resource) {

			int error;
			FT_Library library;

			error = FT_Init_FreeType (&library);

			if (error) {

				printf ("Could not initialize FreeType\n");

			} else {

				FT_Face face;
				FILE_HANDLE *file = NULL;
				unsigned char *faceMemory = NULL;

				if (resource->path) {

					file = lime::fopen (resource->path, "rb");

					if (!file) {

						FT_Done_FreeType (library);
						return;

					}

					if (file->isFile ()) {

						error = FT_New_Face (library, resource->path, faceIndex, &face);

					} else {

						Bytes data;
						data.ReadFile (resource->path);
						faceMemory = (unsigned char*)malloc (data.length);
						memcpy (faceMemory, data.b, data.length);

						lime::fclose (file);
						file = 0;

						error = FT_New_Memory_Face (library, faceMemory, data.length, faceIndex, &face);

					}

				} else {

					faceMemory = (unsigned char*)malloc (resource->data->length);
					memcpy (faceMemory, resource->data->b, resource->data->length);
					error = FT_New_Memory_Face (library, faceMemory, resource->data->length, faceIndex, &face);

				}

				if (file) {

					lime::fclose (file);
					file = 0;

				}

				if (!error) {

					this->library = library;
					this->face = face;
					this->faceMemory = faceMemory;

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

				} else {

					FT_Done_FreeType (library);
					free (faceMemory);

				}

			}

		}

	}


	Font::~Font () {

		if (library) {

			FT_Done_FreeType ((FT_Library)library);
			library = 0;
			face = 0;

		}

		free (faceMemory);
		faceMemory = 0;

	}


	void* Font::Decompose (bool useCFFIValue, int em) {

		int result, i, j;

		FT_Set_Char_Size ((FT_Face)face, em, em, 72, 72);
		FT_Set_Transform ((FT_Face)face, 0, NULL);

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

		wchar_t* family_name = GetFamilyName ();

		#ifdef LIME_FREETYPE_SWF_METRICS

		// this should more closely match how [Embed] works in AS3 when
		// embedding a font in a SWF

		int calculatedAscender = 0;
		int calculatedDescender = 0;
		int calculatedHeight = 0;

		TT_OS2* os2 = (TT_OS2*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_os2);
		TT_HoriHeader* hhea = (TT_HoriHeader*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_hhea);

		if (os2 && os2->version != 0xFFFFU) {

			calculatedAscender = (FT_Short)os2->usWinAscent;
			calculatedDescender = -(FT_Short)os2->usWinDescent;
			calculatedHeight = calculatedAscender - calculatedDescender;

		} else if (hhea) {

			calculatedAscender = hhea->Ascender;
			calculatedDescender = hhea->Descender;
			calculatedHeight = calculatedAscender - calculatedDescender + hhea->Line_Gap;

		} else {

			// should never happen, but let's have a fallback to be safe
			calculatedAscender = ((FT_Face)face)->ascender;
			calculatedDescender = ((FT_Face)face)->descender;
			calculatedHeight = ((FT_Face)face)->height;

		}

		#elif defined(LIME_FREETYPE_LEGACY_METRICS)

		// this is FreeType's font metrics algorithm from 2.9.1
		// it behaves more like SWF than the new algorithm

		TT_OS2* os2 = (TT_OS2*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_os2);
		TT_HoriHeader* hhea = (TT_HoriHeader*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_hhea);

		int calculatedAscender = 0;
		int calculatedDescender = 0;
		int calculatedHeight = 0;

		if (hhea) {

			calculatedAscender = hhea->Ascender;
			calculatedDescender = hhea->Descender;
			calculatedHeight = calculatedAscender - calculatedDescender + hhea->Line_Gap;

		}

        if (!( calculatedAscender || calculatedDescender ))
        {
			if (os2 && os2->version != 0xFFFFU)
			{
				if (os2->sTypoAscender || os2->sTypoDescender)
				{

					calculatedAscender = os2->sTypoAscender;
					calculatedDescender = os2->sTypoDescender;
					calculatedHeight = calculatedAscender - calculatedDescender + os2->sTypoLineGap;

				}
				else
				{

					calculatedAscender = (FT_Short)os2->usWinAscent;
					calculatedDescender = -(FT_Short)os2->usWinDescent;
					calculatedHeight = calculatedAscender - calculatedDescender;

				}
			}
        }

		if (!calculatedAscender || !calculatedDescender) {

			calculatedAscender = ((FT_Face)face)->ascender;
			calculatedDescender = ((FT_Face)face)->descender;
			calculatedHeight = ((FT_Face)face)->height;

		}

		#else

		int calculatedAscender = ((FT_Face)face)->ascender;
		int calculatedDescender = ((FT_Face)face)->descender;
		int calculatedHeight = ((FT_Face)face)->height;

		#endif

		if (useCFFIValue) {

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
			alloc_field (ret, val_id ("ascend"), alloc_int (calculatedAscender));
			alloc_field (ret, val_id ("descend"), alloc_int (calculatedDescender));
			alloc_field (ret, val_id ("height"), alloc_int (calculatedHeight));

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

		} else {

			vdynamic* ret = (vdynamic*)hl_alloc_dynobj ();
			hl_dyn_seti (ret, hl_hash_utf8 ("has_kerning"), &hlt_bool, FT_HAS_KERNING (((FT_Face)face)));
			hl_dyn_seti (ret, hl_hash_utf8 ("is_fixed_width"), &hlt_bool, FT_IS_FIXED_WIDTH (((FT_Face)face)));
			hl_dyn_seti (ret, hl_hash_utf8 ("has_glyph_names"), &hlt_bool, FT_HAS_GLYPH_NAMES (((FT_Face)face)));
			hl_dyn_seti (ret, hl_hash_utf8 ("is_italic"), &hlt_bool, ((FT_Face)face)->style_flags & FT_STYLE_FLAG_ITALIC);
			hl_dyn_seti (ret, hl_hash_utf8 ("is_bold"), &hlt_bool, ((FT_Face)face)->style_flags & FT_STYLE_FLAG_BOLD);
			hl_dyn_seti (ret, hl_hash_utf8 ("num_glyphs"), &hlt_i32, num_glyphs);

			char* _family_name = NULL;

			if (family_name != NULL) {

				int length = std::wcslen (family_name);
				char* result = (char*)malloc (length + 1);
				std::wcstombs (result, family_name, length);
				result[length] = '\0';
				delete family_name;

			} else {

				int length = strlen (((FT_Face)face)->family_name);
				_family_name = (char*)malloc (length + 1);
				strcpy (_family_name, ((FT_Face)face)->family_name);

			}

			char* style_name = (char*)malloc(strlen(((FT_Face)face)->style_name) + 1);
			strcpy(style_name, ((FT_Face)face)->style_name);

			hl_dyn_setp (ret, hl_hash_utf8 ("family_name"), &hlt_bytes, _family_name);
			hl_dyn_setp (ret, hl_hash_utf8 ("style_name"), &hlt_bytes, style_name);
			hl_dyn_seti (ret, hl_hash_utf8 ("em_size"), &hlt_i32, ((FT_Face)face)->units_per_EM);
			hl_dyn_seti (ret, hl_hash_utf8 ("ascend"), &hlt_i32, calculatedAscender);
			hl_dyn_seti (ret, hl_hash_utf8 ("descend"), &hlt_i32, calculatedDescender);
			hl_dyn_seti (ret, hl_hash_utf8 ("height"), &hlt_i32, calculatedHeight);

			// 'glyphs' field
			hl_varray* _glyphs = (hl_varray*)hl_alloc_array (&hlt_dynobj, num_glyphs);
			vdynamic** _glyphsData = hl_aptr (_glyphs, vdynamic*);

			for (i = 0; i < glyphs.size (); i++) {

				glyph *g = glyphs[i];
				int num_points = g->pts.size ();

				hl_varray* points = (hl_varray*)hl_alloc_array (&hlt_i32, num_points);
				int* pointsData = hl_aptr (points, int);

				for (j = 0; j < num_points; j++) {

					*pointsData++ = g->pts[j];

				}

				vdynamic* item = (vdynamic*)hl_alloc_dynobj ();
				*_glyphsData++ = item;
				hl_dyn_seti (item, hl_hash_utf8 ("char_code"), &hlt_i32, g->char_code);
				hl_dyn_seti (item, hl_hash_utf8 ("advance"), &hlt_i32, g->metrics.horiAdvance);
				hl_dyn_seti (item, hl_hash_utf8 ("min_x"), &hlt_i32, g->metrics.horiBearingX);
				hl_dyn_seti (item, hl_hash_utf8 ("max_x"), &hlt_i32, g->metrics.horiBearingX + g->metrics.width);
				hl_dyn_seti (item, hl_hash_utf8 ("min_y"), &hlt_i32, g->metrics.horiBearingY - g->metrics.height);
				hl_dyn_seti (item, hl_hash_utf8 ("max_y"), &hlt_i32, g->metrics.horiBearingY);
				hl_dyn_setp (item, hl_hash_utf8 ("points"), &hlt_array, points);

				delete g;

			}

			hl_dyn_setp (ret, hl_hash_utf8 ("glyphs"), &hlt_array, _glyphs);

			// 'kerning' field
			if (FT_HAS_KERNING (((FT_Face)face))) {

				hl_varray* _kerning = (hl_varray*)hl_alloc_array (&hlt_i32, kern.size ());
				vdynamic** _kerningData = hl_aptr (_kerning, vdynamic*);

				for (i = 0; i < kern.size(); i++) {

					kerning *k = &kern[i];

					vdynamic* item = (vdynamic*)hl_alloc_dynobj ();
					*_kerningData++ = item;
					hl_dyn_seti (item, hl_hash_utf8 ("left_glyph"), &hlt_i32, k->l_glyph);
					hl_dyn_seti (item, hl_hash_utf8 ("right_glyph"), &hlt_i32, k->r_glyph);
					hl_dyn_seti (item, hl_hash_utf8 ("x"), &hlt_i32, k->x);
					hl_dyn_seti (item, hl_hash_utf8 ("y"), &hlt_i32, k->y);

				}

				hl_dyn_setp (ret, hl_hash_utf8 ("kerning"), &hlt_array, _kerning);

			} else {

				hl_dyn_setp (ret, hl_hash_utf8 ("kerning"), &hlt_array, 0);

			}

			return ret;

		}

	}


	int Font::GetAscender () {

		#ifdef LIME_FREETYPE_SWF_METRICS

		// this should more closely match how [Embed] works in AS3 when
		// embedding a font in a SWF

		TT_OS2* os2 = (TT_OS2*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_os2);
		TT_HoriHeader* hhea = (TT_HoriHeader*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_hhea);

		if (os2 && os2->version != 0xFFFFU) {

			return (FT_Short)os2->usWinAscent;

		} else if (hhea) {

			return hhea->Ascender;

		}

		// should never happen, but let's have a fallback to be safe
		return ((FT_Face)face)->ascender;

		#elif defined(LIME_FREETYPE_LEGACY_METRICS)

		// this is FreeType's font metrics algorithm from 2.9.1
		// it behaves more like SWF than the new algorithm

		TT_OS2* os2 = (TT_OS2*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_os2);
		TT_HoriHeader* hhea = (TT_HoriHeader*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_hhea);

		int calculatedAscender = 0;
		int calculatedDescender = 0;

		if (hhea) {

			calculatedAscender = hhea->Ascender;
			calculatedDescender = hhea->Descender;
		}

        if (!( calculatedAscender || calculatedDescender ))
        {
			if (os2 && os2->version != 0xFFFFU)
			{
				if (os2->sTypoAscender || os2->sTypoDescender)
				{

					calculatedAscender = os2->sTypoAscender;
					calculatedDescender = os2->sTypoDescender;

				}
				else
				{

					calculatedAscender = (FT_Short)os2->usWinAscent;
					calculatedDescender = -(FT_Short)os2->usWinDescent;

				}
			}
        }

		if (!calculatedAscender || !calculatedDescender) {

			calculatedAscender = ((FT_Face)face)->ascender;
			calculatedDescender = ((FT_Face)face)->descender;

		}

		return calculatedAscender;

		#else

		return ((FT_Face)face)->ascender;

		#endif

	}


	int Font::GetDescender () {

		#ifdef LIME_FREETYPE_SWF_METRICS

		// this should more closely match how [Embed] works in AS3 when
		// embedding a font in a SWF

		TT_OS2* os2 = (TT_OS2*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_os2);
		TT_HoriHeader* hhea = (TT_HoriHeader*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_hhea);

		if (os2 && os2->version != 0xFFFFU) {

			return -(FT_Short)os2->usWinDescent;

		}
		else if (hhea) {

			return hhea->Descender;

		}

		// should never happen, but let's have a fallback to be safe
		return ((FT_Face)face)->descender;

		#elif defined(LIME_FREETYPE_LEGACY_METRICS)

		// this is FreeType's font metrics algorithm from 2.9.1
		// it behaves more like SWF than the new algorithm

		TT_OS2* os2 = (TT_OS2*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_os2);
		TT_HoriHeader* hhea = (TT_HoriHeader*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_hhea);

		int calculatedAscender = 0;
		int calculatedDescender = 0;

		if (hhea) {

			calculatedAscender = hhea->Ascender;
			calculatedDescender = hhea->Descender;

		}

        if (!( calculatedAscender || calculatedDescender ))
        {
			if (os2 && os2->version != 0xFFFFU)
			{
				if (os2->sTypoAscender || os2->sTypoDescender)
				{

					calculatedAscender = os2->sTypoAscender;
					calculatedDescender = os2->sTypoDescender;

				}
				else
				{

					calculatedAscender = (FT_Short)os2->usWinAscent;
					calculatedDescender = -(FT_Short)os2->usWinDescent;

				}
			}
        }

		if (!calculatedAscender || !calculatedDescender) {

			calculatedAscender = ((FT_Face)face)->ascender;
			calculatedDescender = ((FT_Face)face)->descender;

		}

		return calculatedDescender;

		#else

		return ((FT_Face)face)->descender;

		#endif

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
						#if defined(ANDROID) && !defined(HXCPP_CLANG)
						// Fix some devices (Android 4.x or older) that have a bad stdc implementation
						_mbsrtowcs (family_name, (const char**)&sfnt_name.string, len, 0);
						#else
						mbstowcs (family_name, (const char*)sfnt_name.string, len);
						#endif
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


	int Font::GetGlyphIndex (const char* character) {

		long charCode = readNextChar (character);

		return FT_Get_Char_Index ((FT_Face)face, charCode);

	}


	void* Font::GetGlyphIndices (bool useCFFIValue, const char* characters) {

		if (useCFFIValue) {

			value indices = alloc_array (0);
			unsigned long character;
			int index;

			while (*characters != 0) {

				character = readNextChar (characters);

				if (character == -1)
					break;

				index = FT_Get_Char_Index ((FT_Face)face, character);
				val_array_push (indices, alloc_int (index));

			}

			return indices;

		} else {

			unsigned long character;
			int index;
			int count = 0;
			const char* characters_start = characters;

			while (*characters != 0) {

				character = readNextChar (characters);

				if (character == -1)
					break;

				count++;

			}

			hl_varray* indices = (hl_varray*)hl_alloc_array (&hlt_i32, count);
			int* indicesData = hl_aptr (indices, int);
			characters = characters_start;

			while (*characters != 0) {

				character = readNextChar (characters);

				if (character == -1)
					break;

				*indicesData++ = FT_Get_Char_Index ((FT_Face)face, character);

			}

			return indices;

		}

	}


	void* Font::GetGlyphMetrics (bool useCFFIValue, int index) {

		if (useCFFIValue) {

			initialize ();

			if (FT_Load_Glyph ((FT_Face)face, index, FT_LOAD_NO_BITMAP | FT_LOAD_FORCE_AUTOHINT | FT_LOAD_DEFAULT) == 0) {

				value metrics = alloc_empty_object ();

				alloc_field (metrics, id_height, alloc_int (((FT_Face)face)->glyph->metrics.height));
				alloc_field (metrics, id_horizontalBearingX, alloc_int (((FT_Face)face)->glyph->metrics.horiBearingX));
				alloc_field (metrics, id_horizontalBearingY, alloc_int (((FT_Face)face)->glyph->metrics.horiBearingY));
				alloc_field (metrics, id_horizontalAdvance, alloc_int (((FT_Face)face)->glyph->metrics.horiAdvance));
				alloc_field (metrics, id_verticalBearingX, alloc_int (((FT_Face)face)->glyph->metrics.vertBearingX));
				alloc_field (metrics, id_verticalBearingY, alloc_int (((FT_Face)face)->glyph->metrics.vertBearingY));
				alloc_field (metrics, id_verticalAdvance, alloc_int (((FT_Face)face)->glyph->metrics.vertAdvance));

				return metrics;

			}

			return alloc_null ();

		} else {

			if (FT_Load_Glyph ((FT_Face)face, index, FT_LOAD_NO_BITMAP | FT_LOAD_FORCE_AUTOHINT | FT_LOAD_DEFAULT) == 0) {

				const int id_height = hl_hash_utf8 ("height");
				const int id_horizontalBearingX = hl_hash_utf8 ("horizontalBearingX");
				const int id_horizontalBearingY = hl_hash_utf8 ("horizontalBearingY");
				const int id_horizontalAdvance = hl_hash_utf8 ("horizontalAdvance");
				const int id_verticalBearingX = hl_hash_utf8 ("verticalBearingX");
				const int id_verticalBearingY = hl_hash_utf8 ("verticalBearingY");
				const int id_verticalAdvance = hl_hash_utf8 ("verticalAdvance");

				vdynamic* metrics = (vdynamic*)hl_alloc_dynobj ();

				hl_dyn_seti (metrics, id_height, &hlt_i32, ((FT_Face)face)->glyph->metrics.height);
				hl_dyn_seti (metrics, id_horizontalBearingX, &hlt_i32, ((FT_Face)face)->glyph->metrics.horiBearingX);
				hl_dyn_seti (metrics, id_horizontalBearingY, &hlt_i32, ((FT_Face)face)->glyph->metrics.horiBearingY);
				hl_dyn_seti (metrics, id_horizontalAdvance, &hlt_i32, ((FT_Face)face)->glyph->metrics.horiAdvance);
				hl_dyn_seti (metrics, id_verticalBearingX, &hlt_i32, ((FT_Face)face)->glyph->metrics.vertBearingX);
				hl_dyn_seti (metrics, id_verticalBearingY, &hlt_i32, ((FT_Face)face)->glyph->metrics.vertBearingY);
				hl_dyn_seti (metrics, id_verticalAdvance, &hlt_i32, ((FT_Face)face)->glyph->metrics.vertAdvance);

				return metrics;

			}

			return 0;

		}

	}


	int Font::GetHeight () {

		#ifdef LIME_FREETYPE_SWF_METRICS

		// this should more closely match how [Embed] works in AS3 when
		// embedding a font in a SWF

		TT_OS2* os2 = (TT_OS2*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_os2);
		TT_HoriHeader* hhea = (TT_HoriHeader*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_hhea);

		if (os2 && os2->version != 0xFFFFU) {

			int calculatedAscender = (FT_Short)os2->usWinAscent;
			int calculatedDescender = -(FT_Short)os2->usWinDescent;
			return calculatedAscender - calculatedDescender;

		} else if (hhea) {

			int calculatedAscender = hhea->Ascender;
			int calculatedDescender = hhea->Descender;
			return calculatedAscender - calculatedDescender + hhea->Line_Gap;

		}

		// should never happen, but let's have a fallback to be safe
		return ((FT_Face)face)->height;

		#elif defined(LIME_FREETYPE_LEGACY_METRICS)

		// this is FreeType's font metrics algorithm from 2.9.1
		// it behaves more like SWF than the new algorithm

		TT_OS2* os2 = (TT_OS2*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_os2);
		TT_HoriHeader* hhea = (TT_HoriHeader*)FT_Get_Sfnt_Table(((FT_Face)face), ft_sfnt_hhea);

		int calculatedAscender = 0;
		int calculatedDescender = 0;
		int calculatedHeight = 0;

		if (hhea) {

			calculatedAscender = hhea->Ascender;
			calculatedDescender = hhea->Descender;
			calculatedHeight = calculatedAscender - calculatedDescender + hhea->Line_Gap;

		}

        if (!( calculatedAscender || calculatedDescender ))
        {
			if (os2 && os2->version != 0xFFFFU)
			{
				if (os2->sTypoAscender || os2->sTypoDescender)
				{

					calculatedAscender = os2->sTypoAscender;
					calculatedDescender = os2->sTypoDescender;
					calculatedHeight = calculatedAscender - calculatedDescender + os2->sTypoLineGap;

				}
				else
				{

					calculatedAscender = (FT_Short)os2->usWinAscent;
					calculatedDescender = -(FT_Short)os2->usWinDescent;
					calculatedHeight = calculatedAscender - calculatedDescender;

				}
			}
        }

        if (!calculatedHeight) {

			calculatedHeight = ((FT_Face)face)->height;

		}

		return calculatedHeight;

		#else

		return ((FT_Face)face)->height;

		#endif

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


	int Font::RenderGlyph(int index, Bytes *bytes, int offset)
	{
		if (FT_Load_Glyph((FT_Face)face, index, FT_LOAD_FORCE_AUTOHINT | FT_LOAD_DEFAULT) == 0)
		{
			if (FT_Render_Glyph(((FT_Face)face)->glyph, FT_RENDER_MODE_LCD) == 0)
			{
				FT_Bitmap bitmap = ((FT_Face)face)->glyph->bitmap;

				int height = bitmap.rows;
				int width = bitmap.width / 3; //Due to each pixel now has 3 components (R, G, B)
				int pitch = bitmap.pitch;

				if (width == 0 || height == 0)
					return 0;

				//We calculate the size needed for the glyph image, including metadata and 24-bit RGB color data
				uint32_t size = sizeof(GlyphImage) + (width * height * 4);

				if (bytes->length < size + offset)
				{
					bytes->Resize(size + offset);
				}

				GlyphImage *data = (GlyphImage *)(bytes->b + offset);

				//We should initialize the GlyphImage struct here with zero to avoid uninitialized values
				memset(data, 0, sizeof(GlyphImage));

				data->index = index;
				data->width = width;
				data->height = height;
				data->x = ((FT_Face)face)->glyph->bitmap_left;
				data->y = ((FT_Face)face)->glyph->bitmap_top;

				unsigned char *position = &data->data;

				//Copy the bitmap data row by row, copying each RGB triplet and adding padding for 32-bit alignment
				for (int i = 0; i < height; i++)
				{
					for (int j = 0; j < width; j++)
					{
						unsigned char r = bitmap.buffer[i * pitch + j * 3 + 0];
						unsigned char g = bitmap.buffer[i * pitch + j * 3 + 1];
						unsigned char b = bitmap.buffer[i * pitch + j * 3 + 2];
						unsigned char a = (r + g + b) / 3;

						//Red
						position[(i * width + j) * 4 + 0] = r;
						//Green
						position[(i * width + j) * 4 + 1] = g;
						//Blue
						position[(i * width + j) * 4 + 2] = b;
						//Alpha
						position[(i * width + j) * 4 + 3] = a;
					}
				}

				return size;
			}
		}

		return 0;
	}


	int Font::RenderGlyphs (value indices, Bytes *bytes) {

		int offset = 0;
		int totalOffset = 4;
		uint32_t count = 0;

		int numIndices = val_array_size (indices);

		for (int i = 0; i < numIndices; i++) {

			offset = RenderGlyph (val_int (val_array_i (indices, i)), bytes, totalOffset);

			if (offset > 0) {

				totalOffset += offset;
				count++;

			}

		}

		if (count > 0) {

			*(uint32_t*)(bytes->b) = count;

		}

		return totalOffset;

	}

	void Font::SetSize(size_t size, size_t dpi)
	{
		//We changed the function signature to include a dpi argument which changes this from
		//the default value of 72 for dpi. Any public api that uses this should probably be changed
		//to allow setting the dpi in an appropriate future release.
		size_t hdpi = dpi;
		size_t vdpi = dpi;

		FT_Set_Char_Size(
			(FT_Face)face,						//Handle to the target face object
			0,									//Char width in 1/64th of points (0 means same as height)
			static_cast<int>(size * 64), 		//Char height in 1/64th of points
			hdpi,								//Horizontal DPI
			vdpi								//Vertical DPI
		);
		mSize = size;

	}


}
