#ifndef LIME_GRAPHICS_FONT_H
#define LIME_GRAPHICS_FONT_H


#include <hx/CFFI.h>
#include <list>
#include <graphics/ImageBuffer.h>

#ifdef LIME_FREETYPE
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_BITMAP_H
#include FT_SFNT_NAMES_H
#include FT_TRUETYPE_IDS_H
#include FT_GLYPH_H
#include FT_OUTLINE_H
#endif


namespace lime {
	
	
	class Image;
	
	
	#ifdef LIME_FREETYPE
	typedef struct {
		
		unsigned long codepoint;
		size_t size;
		FT_UInt index;
		FT_Pos height;
		
	} GlyphInfo;
	#else
	typedef struct {
		
		unsigned long codepoint;
		size_t size;
		int index;
		int height;
		
	} GlyphInfo;
	#endif
	
	
	class Font {
		
		
		public:
			
			Font (const char *fontFace);
			
			value Decompose (int em);
			value GetFamilyName ();
			void LoadGlyphs (const char *glyphs);
			void LoadRange (unsigned long start, unsigned long end);
			value RenderToImage (ImageBuffer *image);
			void SetSize (size_t size);
			
			#ifdef LIME_FREETYPE
			FT_Face face;
			#else
			void* face;
			#endif
			
		private:
			
			bool InsertCodepoint (unsigned long codepoint);
			
			std::list<GlyphInfo> glyphList;
			size_t mSize;
		
	};
	
	
}


#endif
