#ifndef LIME_GRAPHICS_FONT_H
#define LIME_GRAPHICS_FONT_H


#include <hx/CFFI.h>
#include <list>
#include <graphics/Image.h>
#include <ft2build.h>
#include FT_FREETYPE_H


namespace lime {


	class Font {


		public:

			Font (const char *fontFace);
			value LoadGlyphs (int size, const char *glyphs, Image *image);

		private:

			FT_Face face;


	};


}


#endif
