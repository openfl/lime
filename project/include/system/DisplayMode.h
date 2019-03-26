#ifndef LIME_SYSTEM_DISPLAY_MODE_H
#define LIME_SYSTEM_DISPLAY_MODE_H


#include <graphics/PixelFormat.h>
#include <system/CFFI.h>


namespace lime {


	class DisplayMode {

		public:

			hl_type* t;
			int height;
			PixelFormat pixelFormat;
			int refreshRate;
			int width;

			DisplayMode ();
			DisplayMode (value DisplayMode);
			DisplayMode (int width, int height, PixelFormat pixelFormat, int refreshRate);

			void CopyFrom (DisplayMode* other);
			void* Value ();

	};


}


#endif