#ifndef LIME_TEXT_FONT_H
#define LIME_TEXT_FONT_H


#include <graphics/ImageBuffer.h>
#include <utils/Resource.h>
#include <hx/CFFI.h>
#include <list>


namespace lime {
	
	
	class Image;
	
	
	typedef struct {
		
		unsigned long codepoint;
		size_t size;
		int index;
		int height;
		
	} GlyphInfo;
	
	
	class Font {
		
		
		public:
			
			Font (void* face = 0);
			Font (Resource *resource, int faceIndex = 0);
			~Font ();
			
			value Decompose (int em);
			wchar_t *GetFamilyName ();
			bool InsertCodepointFromIndex (unsigned long codepoint);
			void LoadGlyphs (const char *glyphs);
			void LoadRange (unsigned long start, unsigned long end);
			value RenderToImage (ImageBuffer *image);
			void SetSize (size_t size);
			
			void* face;
			
		private:
			
			bool InsertCodepoint (unsigned long codepoint, bool b = true);
			
			std::list<GlyphInfo> glyphList;
			size_t mSize;
		
	};
	
	
}


#endif
