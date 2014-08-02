#ifndef LIME_GRAPHICS_FONT_H
#define LIME_GRAPHICS_FONT_H


#include <graphics/ImageBuffer.h>

#ifdef LIME_FREETYPE
#include <ft2build.h>
#include FT_FREETYPE_H
#endif


namespace lime {
	
	
	class Font {
		
		
		public:
			
			Font (const char *fontFace);
			value LoadGlyphs (int size, const char *glyphs, ImageBuffer *imageBuffer);
		
		private:
			
			#ifdef LIME_FREETYPE
			FT_Face face;
			#else
			void* face;
			#endif
		
		
	};


}


#endif
