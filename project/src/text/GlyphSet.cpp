#include <text/GlyphSet.h>


namespace lime {
	
	
	static int id_end;
	static int id_glyphs;
	static int id_ranges;
	static int id_start;
	static bool init = false;
	
	
	GlyphSet::GlyphSet (std::wstring glyphs, unsigned long rangeStart, unsigned long rangeEnd) {
		
		//this->glyphs = 0;
		//ranges = new QuickVec<GlyphRange> ();
		
		if (!glyphs.empty ()) {
			
			AddGlyphs (glyphs);
			
		}
		
		if (rangeStart > -1) {
			
			AddRange (rangeStart, rangeEnd);
			
		}
		
	}
	
	
	GlyphSet::GlyphSet (value glyphSet) {
		
		if (!init) {
			
			id_end = val_id ("end");
			id_glyphs = val_id ("glyphs");
			id_ranges = val_id ("ranges");
			id_start = val_id ("start");
			init = true;
			
		}
		
		if (!val_is_null (glyphSet)) {
			
			value glyphs = val_field (glyphSet, id_glyphs);
			
			if (!val_is_null (glyphs)) {
				
				this->glyphs = val_wstring (glyphs);
				
			}
			
			value ranges = val_field (glyphSet, id_ranges);
			int length = val_array_size (ranges);
			
			for (int i = 0; i < length; i++) {
				
				value range = val_array_i (ranges, i);
				AddRange (val_int (val_field (range, id_start)), val_int (val_field (range, id_end)));
				
			}
			
		}
		
	}
	
	
	void GlyphSet::AddGlyphs (std::wstring glyphs) {
		
		if (!glyphs.empty ()) {
			
			this->glyphs += glyphs;
			
		}
		
	}
	
	
	void GlyphSet::AddRange (unsigned long start, unsigned long end) {
		
		ranges.push_back (GlyphRange (start, end));
		
	}
	
	
}