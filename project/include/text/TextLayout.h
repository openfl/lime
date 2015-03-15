#ifndef LIME_TEXT_TEXT_LAYOUT_H
#define LIME_TEXT_TEXT_LAYOUT_H


#include <text/Font.h>
#include <utils/ByteArray.h>


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
			
			void Position (Font *font, size_t size, const char *text, ByteArray *bytes);
			void SetDirection (int direction);
			void SetLanguage (const char* language);
			void SetScript (const char* script);
			
		private:
			
			void *mBuffer;
			long mDirection;
			long mScript;
			long mLanguage;
			
	};
	
	
}


#endif
