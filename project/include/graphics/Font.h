#ifndef LIME_GRAPHICS_FONT_H
#define LIME_GRAPHICS_FONT_H


#include <hx/CFFI.h>
#include <list>
#include <ft2build.h>
#include FT_FREETYPE_H


namespace lime {


	class Image;


	typedef struct {

		unsigned long codepoint;
		unsigned int size;
		FT_UInt index;
		FT_Pos height;

	} GlyphInfo;


	class Font {


		public:

			Font (const char *fontFace);
			void LoadGlyphs (size_t size, const char *glyphs);
			void LoadRange (size_t size, unsigned long start, unsigned long end);
			value renderToImage (Image *image);

			FT_Face face;

		private:

			bool InsertCodepoint (unsigned long codepoint, size_t size);

			std::list<GlyphInfo> glyphList;


	};


}


#endif
