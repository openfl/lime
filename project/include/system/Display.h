#ifndef LIME_SYSTEM_DISPLAY_H
#define LIME_SYSTEM_DISPLAY_H

#include <math/Rectangle.h>

namespace lime {


	class Display {


		public:

			static void GetSafeAreaInsets (int displayIndex, Rectangle * rect);


	};

}

#endif