#ifndef LIME_SDL_MENU_H
#define LIME_SDL_MENU_H


#include <SDL.h>
#include <ui/Menu.h>
#include <string>
#include <vector>

#if defined (HX_WINDOWS) && !defined (HX_WINRT)
#define LIME_SDL_MENU_WIN32
#elif defined (HX_MACOS)
#define LIME_SDL_MENU_COCOA
#elif defined (HX_LINUX) && !defined (HX_ANDROID) && !defined (EMSCRIPTEN)
#define LIME_SDL_MENU_GTK
#endif


namespace lime {


	enum SDLMenuItemFlags {

		MENU_ITEM_ENABLED = 0x01,
		MENU_ITEM_CHECKED = 0x02,
		MENU_ITEM_SEPARATOR = 0x04,
		MENU_ITEM_SUBMENU = 0x08

	};


	struct SDLMenuItem {

		int flags;
		int id;
		int keyCode;
		int keyModifiers;
		std::string label;
		std::vector<SDLMenuItem> submenu;

	};


	class SDLMenu {

		public:

			static bool GetSelection (SDL_Event* event, Uint32* windowID, int* id);
			static int GetSupport ();
			static int Popup (SDL_Window* window, const unsigned char* data, int length, int x, int y, bool atCursor);
			static void Remove (SDL_Window* window);
			static bool SetApplicationMenu (const unsigned char* data, int length);
			static bool SetWindowMenu (SDL_Window* window, const unsigned char* data, int length);

			static std::string GetLabel (const std::string& label, char mnemonicPrefix);
			static bool Parse (const unsigned char* data, int length, std::vector<SDLMenuItem>* items);
			static void PushSelection (Uint32 windowID, int id);

		private:

			static bool GetPlatformSelection (SDL_Event* event, Uint32* windowID, int* id);

	};


}


#endif
