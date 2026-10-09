#ifndef LIME_SDL_TRAY_ICON_H
#define LIME_SDL_TRAY_ICON_H


#include <SDL.h>
#include <ui/TrayIcon.h>


namespace lime {


	class SDLTrayIcon : public TrayIcon {

		public:

			SDLTrayIcon ();
			~SDLTrayIcon ();

			virtual void Close ();
			virtual int GetID ();
			virtual int PopupMenu (const unsigned char* data, int length);
			virtual void SetIcon (ImageBuffer* imageBuffer);
			virtual bool SetMenu (const unsigned char* data, int length);
			virtual void SetTooltip (const char* tooltip);

			static void Update ();

			int id;
			void* platform;

	};


}


#endif
