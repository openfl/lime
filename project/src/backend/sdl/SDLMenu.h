#ifndef LIME_SDL_MENU_H
#define LIME_SDL_MENU_H


#include <SDL.h>
#include <ui/Menu.h>

#if defined (HX_WINDOWS) && !defined (HX_WINRT)
#define LIME_SDL_MENU_WIN32
#elif defined (HX_MACOS)
#define LIME_SDL_MENU_COCOA
#elif defined (HX_LINUX) && !defined (HX_ANDROID) && !defined (EMSCRIPTEN)
#define LIME_SDL_MENU_GTK
#endif


namespace lime {


	class SDLMenu {

		public:

			static bool GetDockMenuSelection (SDL_Event* event, int* id);
			static bool GetSelection (SDL_Event* event, Uint32* windowID, int* id);
			static int GetSupport ();
			static bool GetTrayIconEvent (SDL_Event* event, int* trayIconID, int* type, int* itemID);
			static int Popup (SDL_Window* window, const unsigned char* data, int length, int x, int y, bool atCursor);
			static void Remove (SDL_Window* window);
			static bool SetApplicationMenu (const unsigned char* data, int length);
			static bool SetWindowMenu (SDL_Window* window, const unsigned char* data, int length);
			static void PushDockMenuSelection (int id);
			static void PushSelection (Uint32 windowID, int id);
			static void PushTrayIconEvent (int trayIconID, int type, int itemID);

		private:
			static void PushEvent (int kind, Uint32 target, int code, int value);

	};


}


#endif
