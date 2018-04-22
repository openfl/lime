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

#ifdef ANDROID
#include <stdint.h>
#include <wchar.h>
#include <errno.h>
#endif


// from http://stackoverflow.com/questions/2948308/how-do-i-read-utf-8-characters-via-a-pointer
#define IS_IN_RANGE(c, f, l) (((c) >= (f)) && ((c) <= (l)))


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
	
	
	int outline_cubic_to (FVecPtr ctl1, FVecPtr ctl2, FVecPtr to, void *user) {
		
		glyph *g = static_cast<glyph*> (user);
		
		g->pts.push_back (PT_CUBIC);
		g->pts.push_back (ctl1->x - g->x);
		g->pts.push_back (ctl1->y - g->y);
		g->pts.push_back (ctl2->x - ctl1->x);
		g->pts.push_back (ctl2->y - ctl1->y);
		g->pts.push_back (to->x - ctl2->x);
		g->pts.push_back (to->y - ctl2->y);
		
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
						
						Bytes data = Bytes (resource->path);
						faceMemory = (unsigned char*)malloc (data.Length ());
						memcpy (faceMemory, data.Data (), data.Length ());
						
						lime::fclose (file);
						file = 0;
						
						error = FT_New_Memory_Face (library, faceMemory, data.Length (), faceIndex, &face);
						
					}
					
				} else {
					
					faceMemory = (unsigned char*)malloc (resource->data->Length ());
					memcpy (faceMemory, resource->data->Data (), resource->data->Length ());
					error = FT_New_Memory_Face (library, faceMemory, resource->data->Length (), faceIndex, &face);
					
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
	
	
	value Font::Decompose (int em) {
		
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
	
	
	#ifdef ANDROID
	/* 
	* This code was written by Rich Felker in 2010; no copyright is claimed.
	* This code is in the public domain. Attribution is appreciated but
	* unnecessary.
	*/
	#define OOB(c,b) (((((b)>>3)-0x10)|(((b)>>3)+((int32_t)(c)>>26))) & ~7)
	#define R(a,b) ((uint32_t)((a==0x80 ? 0x40-b : -a) << 23))
	#define C(x) ( x<2 ? -1 : ( R(0x80,0xc0) | x ) )
	#define D(x) C((x+16))
	#define E(x) ( ( x==0 ? R(0xa0,0xc0) : \
					x==0xd ? R(0x80,0xa0) : \
					R(0x80,0xc0) ) \
				| ( R(0x80,0xc0) >> 6 ) \
				| x )
	#define F(x) ( ( x>=5 ? 0 : \
					x==0 ? R(0x90,0xc0) : \
					x==4 ? R(0x80,0xa0) : \
					R(0x80,0xc0) ) \
				| ( R(0x80,0xc0) >> 6 ) \
				| ( R(0x80,0xc0) >> 12 ) \
				| x )
	#define SA 0xc2u
	#define SB 0xf4u
	
	const uint32_t bittab[] = {
	              C(0x2),C(0x3),C(0x4),C(0x5),C(0x6),C(0x7),
		C(0x8),C(0x9),C(0xa),C(0xb),C(0xc),C(0xd),C(0xe),C(0xf),
		D(0x0),D(0x1),D(0x2),D(0x3),D(0x4),D(0x5),D(0x6),D(0x7),
		D(0x8),D(0x9),D(0xa),D(0xb),D(0xc),D(0xd),D(0xe),D(0xf),
		E(0x0),E(0x1),E(0x2),E(0x3),E(0x4),E(0x5),E(0x6),E(0x7),
		E(0x8),E(0x9),E(0xa),E(0xb),E(0xc),E(0xd),E(0xe),E(0xf),
		F(0x0),F(0x1),F(0x2),F(0x3),F(0x4)
	};
	
	// includes minor modifications
	
	size_t _mbsrtowcs(wchar_t * ws, const char **src, size_t wn, mbstate_t *st)
	{
		const unsigned char *s = (const unsigned char *)*src;
		size_t wn0 = wn;
		unsigned c = 0;

		if (st && (c = *(unsigned *)st)) {
			if (ws) {
				*(unsigned *)st = 0;
				goto resume;
			} else {
				goto resume0;
			}
		}

		if (!ws) for (;;) {
			if (*s-1u < 0x7f && (uintptr_t)s%4 == 0) {
				while (!(( *(uint32_t*)s | *(uint32_t*)s-0x01010101) & 0x80808080)) {
					s += 4;
					wn -= 4;
				}
			}
			if (*s-1u < 0x7f) {
				s++;
				wn--;
				continue;
			}
			if (*s-SA > SB-SA) break;
			c = bittab[*s++-SA];
	resume0:
			if (OOB(c,*s)) { s--; break; }
			s++;
			if (c&(1U<<25)) {
				if (*s-0x80u >= 0x40) { s-=2; break; }
				s++;
				if (c&(1U<<19)) {
					if (*s-0x80u >= 0x40) { s-=3; break; }
					s++;
				}
			}
			wn--;
			c = 0;
		} else for (;;) {
			if (!wn) {
				*src = (const char *)s;
				return wn0;
			}
			if (*s-1u < 0x7f && (uintptr_t)s%4 == 0) {
				while (wn>=5 && !(( *(uint32_t*)s | *(uint32_t*)s-0x01010101) & 0x80808080)) {
					*ws++ = *s++;
					*ws++ = *s++;
					*ws++ = *s++;
					*ws++ = *s++;
					wn -= 4;
				}
			}
			if (*s-1u < 0x7f) {
				*ws++ = *s++;
				wn--;
				continue;
			}
			if (*s-SA > SB-SA) break;
			c = bittab[*s++-SA];
	resume:
			if (OOB(c,*s)) { s--; break; }
			c = (c<<6) | *s++-0x80;
			if (c&(1U<<31)) {
				if (*s-0x80u >= 0x40) { s-=2; break; }
				c = (c<<6) | *s++-0x80;
				if (c&(1U<<31)) {
					if (*s-0x80u >= 0x40) { s-=3; break; }
					c = (c<<6) | *s++-0x80;
				}
			}
			*ws++ = c;
			wn--;
			c = 0;
		}

		if (!c && !*s) {
			if (ws) {
				*ws = 0;
				*src = 0;
			}
			return wn0-wn;
		}
		errno = EILSEQ;
		if (ws) *src = (const char *)s;
		return -1;
	}
	#endif
	
	
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
						#ifdef ANDROID
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
	
	
	int Font::GetGlyphIndex (char* character) {
		
		long charCode = readNextChar (character);
		
		return FT_Get_Char_Index ((FT_Face)face, charCode);
		 
	}
	
	
	value Font::GetGlyphIndices (char* characters) {
		
		value indices = alloc_array (0);
		unsigned long character;
		int index;
		
		while (*characters != 0) {
			
			character = readNextChar (characters);
			index = FT_Get_Char_Index ((FT_Face)face, character);
			val_array_push (indices, alloc_int (index));
			
		}
		
		return indices;
		
	}
	
	
	value Font::GetGlyphMetrics (int index) {
		
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
	
	
	int Font::RenderGlyph (int index, Bytes *bytes, int offset) {
		
		if (FT_Load_Glyph ((FT_Face)face, index, FT_LOAD_FORCE_AUTOHINT | FT_LOAD_DEFAULT) == 0) {
			
			if (FT_Render_Glyph (((FT_Face)face)->glyph, FT_RENDER_MODE_NORMAL) == 0) {
				
				FT_Bitmap bitmap = ((FT_Face)face)->glyph->bitmap;
				
				int height = bitmap.rows;
				int width = bitmap.width;
				int pitch = bitmap.pitch;
				
				if (width == 0 || height == 0) return 0;
				
				uint32_t size = (4 * 5) + (width * height);
				
				if (bytes->Length () < size + offset) {
					
					bytes->Resize (size + offset);
					
				}
				
				GlyphImage *data = (GlyphImage*)(bytes->Data () + offset);
				
				data->index = index;
				data->width = width;
				data->height = height;
				data->x = ((FT_Face)face)->glyph->bitmap_left;
				data->y = ((FT_Face)face)->glyph->bitmap_top;
				
				unsigned char* position = &data->data;
				
				for (int i = 0; i < height; i++) {
					
					memcpy (position + (i * width), bitmap.buffer + (i * pitch), width);
					
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
			
			*(uint32_t*)(bytes->Data ()) = count;
			
		}
		
		return totalOffset;
		
	}
	
	
	void Font::SetSize (size_t size) {
		
		size_t hdpi = 72;
		size_t vdpi = 72;
		
		FT_Set_Char_Size ((FT_Face)face, (int)(size*64), (int)(size*64), hdpi, vdpi);
		mSize = size;
		
	}
	
	
}
