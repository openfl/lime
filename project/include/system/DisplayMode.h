#ifndef LIME_SYSTEM_DISPLAY_MODE_H
#define LIME_SYSTEM_DISPLAY_MODE_H


#include <graphics/PixelFormat.h>
#include <system/CFFI.h>


namespace lime {


	struct HL_DisplayMode {

		hl_type* t;
		int height;
		PixelFormat pixelFormat;
		int refreshRate;
		int width;

	};


	class DisplayMode {

		public:

			DisplayMode ();
			DisplayMode (value DisplayMode);
			DisplayMode (HL_DisplayMode* DisplayMode);
			DisplayMode (int width, int height, PixelFormat pixelFormat, int refreshRate);

			void* Value ();

			int height;
			PixelFormat pixelFormat;
			int refreshRate;
			int width;

		private:

			HL_DisplayMode* _mode;

	};


}


#endif