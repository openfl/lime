#ifndef LIME_TEXT_TEXT_LAYOUT_H
#define LIME_TEXT_TEXT_LAYOUT_H


#include <text/Font.h>
#include <utils/Bytes.h>


namespace lime {
	
	
	typedef struct {
		
		uint32_t index;
		float advanceX;
		float advanceY;
		float offsetX;
		float offsetY;
		
	} GlyphPosition;
	
	class TextLayout {
		
		
		public:
			
			TextLayout (int direction, const char *script, const char *language);
			~TextLayout ();
			
			void Position (Font *font, size_t size, const char *text, Bytes *bytes);
			void SetDirection (int direction);
			void SetLanguage (const char* language);
			void SetScript (const char* script);
			
		private:
			
			Font *mFont;
			void *mHBFont;
			void *mBuffer;
			int mDirection;
			int mScript;
			void *mLanguage;
			
	};
	
	
}


#endif
