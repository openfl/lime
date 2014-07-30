#ifndef LIME_GRAPHICS_TEXT_H
#define LIME_GRAPHICS_TEXT_H


#include <hb.h>


namespace lime {


	class Font;


	class Text {


		public:

			Text (hb_tag_t direction, const char *script, const char *language);
			~Text ();

			void fromString (Font *font, const char *text);

		private:

			hb_buffer_t *buffer;


	};


}


#endif
