#ifndef LIME_GRAPHICS_TEXT_H
#define LIME_GRAPHICS_TEXT_H


#include <hx/CFFI.h>
#include <hb.h>


namespace lime {


	class Font;


	class Text {


		public:

			Text (hb_tag_t direction, const char *script, const char *language);
			~Text ();

			value FromString (Font *font, size_t size, const char *text);

		private:

			hb_buffer_t *buffer;


	};


}


#endif
