#ifndef LIME_TEXT_GLYPH_SET_H
#define LIME_TEXT_GLYPH_SET_H


#include <hx/CFFI.h>
#include <utils/QuickVec.h>
#include <string>


namespace lime {
	
	
	struct GlyphRange {
		
		unsigned long start, end;
		
		GlyphRange () : start (-1), end (-1) {}
		GlyphRange (unsigned long start, unsigned long end) : start (start), end (end) {}
		
	};
	
	
	class GlyphSet {
		
		
		public:
			
			GlyphSet (std::wstring glyphs = NULL, unsigned long rangeStart = -1, unsigned long rangeEnd = -1);
			GlyphSet (value glyphSet);
			
			void AddGlyphs (std::wstring glyphs);
			void AddRange (unsigned long start = 0, unsigned long end = -1);
			
			std::wstring glyphs;
			QuickVec<GlyphRange> ranges;
		
		
	};
	
	
}


#endif
