#ifndef LIME_UI_TRAY_ICON_H
#define LIME_UI_TRAY_ICON_H


#include <graphics/ImageBuffer.h>


namespace lime {


	class TrayIcon {


		public:

			virtual ~TrayIcon () {};

			virtual void Close () = 0;
			virtual int GetID () = 0;
			virtual int PopupMenu (const unsigned char* data, int length) = 0;
			virtual void SetIcon (ImageBuffer* imageBuffer) = 0;
			virtual bool SetMenu (const unsigned char* data, int length) = 0;
			virtual void SetTooltip (const char* tooltip) = 0;

			static bool IsSupported ();


	};


	TrayIcon* CreateTrayIcon ();


}


#endif
