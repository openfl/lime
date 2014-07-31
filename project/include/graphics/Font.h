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
		size_t size;
		FT_UInt index;
		FT_Pos height;

	} GlyphInfo;


	class Font {


		public:

			Font (const char *fontFace);
			void LoadGlyphs (const char *glyphs);
			void LoadRange (unsigned long start, unsigned long end);
			void SetSize (size_t size);
			value RenderToImage (Image *image);

			FT_Face face;

		private:

			bool InsertCodepoint (unsigned long codepoint);

			std::list<GlyphInfo> glyphList;
			size_t mSize;


	};


}


#endif
