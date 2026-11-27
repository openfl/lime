#ifndef LIME_UI_DOCK_ICON_H
#define LIME_UI_DOCK_ICON_H


#include <graphics/ImageBuffer.h>


namespace lime {


	class DockIcon {


		public:

			static void Bounce (bool critical);
			static bool IsSupported ();
			static void SetIcon (ImageBuffer* imageBuffer);
			static bool SetMenu (const unsigned char* data, int length);


	};


}


#endif
