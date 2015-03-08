#ifndef LIME_TEXT_TEXT_LAYOUT_H
#define LIME_TEXT_TEXT_LAYOUT_H


#include <text/Font.h>
#include <hx/CFFI.h>


namespace lime {
	
	
	class TextLayout {
		
		
		public:
			
			TextLayout (int direction, const char *script, const char *language);
			~TextLayout ();
			
			value Layout (Font *font, size_t size, const char *text);
			
		private:
			
			void *mBuffer;
			long mDirection;
			long mScript;
			long mLanguage;
			
	};
	
	
}


#endif
