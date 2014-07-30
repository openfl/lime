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
		FT_UInt index;
		FT_Pos height;

	} GlyphInfo;


	class Font {


		public:

			Font (const char *fontFace);
			void LoadGlyphs (int size, const char *glyphs);
			value createImage (Image *image);

			FT_Face face;

		private:

			std::list<GlyphInfo> glyphList;


	};


}


#endif
