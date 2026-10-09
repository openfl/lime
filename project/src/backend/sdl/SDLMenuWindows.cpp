#include "SDLMenu.h"

#ifdef LIME_SDL_MENU_WIN32

#include <SDL_syswm.h>
#include <windows.h>
#include <map>
#undef CreateWindow


namespace lime {


	struct MenuBar {

		HMENU menu;
		Uint32 windowID;

	};


	// Keep menu commands clear of the standard dialog command IDs (IDOK, IDCANCEL...)
	static const int MENU_COMMAND_BASE = 0x1000;
	static const int MENU_COMMAND_MAX = 0xFFFF;

	static std::map<HWND, MenuBar> menuBars;


	static HWND GetWindowHandle (SDL_Window* window) {

		if (!window) return NULL;

		SDL_SysWMinfo info;
		SDL_VERSION (&info.version);

		if (!SDL_GetWindowWMInfo (window, &info) || info.subsystem != SDL_SYSWM_WINDOWS) return NULL;

		return info.info.win.window;

	}


	static std::wstring ToWide (const std::string& text) {

		if (text.empty ()) return std::wstring ();

		int size = MultiByteToWideChar (CP_UTF8, 0, text.c_str (), (int)text.size (), NULL, 0);
		if (size <= 0) return std::wstring ();

		std::wstring result (size, L'\0');
		MultiByteToWideChar (CP_UTF8, 0, text.c_str (), (int)text.size (), &result[0], size);
		return result;

	}


	static std::string GetKeyEquivalentText (int keyCode, int keyModifiers) {

		const char* keyName = SDL_GetKeyName ((SDL_Keycode)keyCode);

		if (!keyName || !keyName[0]) return std::string ();

		std::string text;

		if (keyModifiers & KMOD_CTRL) text += "Ctrl+";
		if (keyModifiers & KMOD_SHIFT) text += "Shift+";
		if (keyModifiers & KMOD_ALT) text += "Alt+";
		if (keyModifiers & KMOD_GUI) text += "Win+";

		return text + keyName;

	}


	static bool AppendMenuItems (HMENU menu, const std::vector<SDLMenuItem>& items) {

		for (size_t i = 0; i < items.size (); i++) {

			const SDLMenuItem& item = items[i];

			UINT itemFlags = MF_STRING;
			if (!(item.flags & MENU_ITEM_ENABLED)) itemFlags |= MF_GRAYED;

			if (item.flags & MENU_ITEM_SUBMENU) {

				HMENU submenu = CreatePopupMenu ();

				if (!submenu) return false;

				if (!AppendMenuItems (submenu, item.submenu) || !AppendMenuW (menu, itemFlags | MF_POPUP, (UINT_PTR)submenu, ToWide (item.label).c_str ())) {

					DestroyMenu (submenu);
					return false;

				}

			} else if (item.flags & MENU_ITEM_SEPARATOR) {

				AppendMenuW (menu, MF_SEPARATOR, 0, NULL);

			} else {

				std::string label = item.label;

				if (item.keyCode != 0) {

					std::string keyText = GetKeyEquivalentText (item.keyCode, item.keyModifiers);
					if (!keyText.empty ()) label += "\t" + keyText;

				}

				if (item.flags & MENU_ITEM_CHECKED) itemFlags |= MF_CHECKED;

				// WM_COMMAND only carries the low word of a menu item identifier
				int command = MENU_COMMAND_BASE + item.id;

				if (command > MENU_COMMAND_MAX) {

					command = 0;
					itemFlags |= MF_GRAYED;

				}

				AppendMenuW (menu, itemFlags, (UINT_PTR)command, ToWide (label).c_str ());

			}

		}

		return true;

	}


	static HMENU CreateMenuFromData (const unsigned char* data, int length, bool popup) {

		std::vector<SDLMenuItem> items;

		if (!SDLMenu::Parse (data, length, &items)) return NULL;

		HMENU menu = popup ? CreatePopupMenu () : CreateMenu ();

		if (menu && !AppendMenuItems (menu, items)) {

			DestroyMenu (menu);
			return NULL;

		}

		return menu;

	}


	bool SDLMenu::GetPlatformSelection (SDL_Event* event, Uint32* windowID, int* id) {

		if (event->type != SDL_SYSWMEVENT || !event->syswm.msg || event->syswm.msg->subsystem != SDL_SYSWM_WINDOWS) return false;

		const SDL_SysWMmsg* msg = event->syswm.msg;

		// Menu commands have a zero notification code and no control handle (accelerators use 1)
		if (msg->msg.win.msg != WM_COMMAND || HIWORD (msg->msg.win.wParam) != 0 || msg->msg.win.lParam != 0) return false;

		int command = LOWORD (msg->msg.win.wParam);
		std::map<HWND, MenuBar>::iterator it = menuBars.find (msg->msg.win.hwnd);

		if (command <= MENU_COMMAND_BASE || it == menuBars.end ()) return false;

		*windowID = it->second.windowID;
		*id = command - MENU_COMMAND_BASE;
		return true;

	}


	int SDLMenu::GetSupport () {

		return MENU_SUPPORT_POPUP | MENU_SUPPORT_WINDOW;

	}


	int SDLMenu::Popup (SDL_Window* window, const unsigned char* data, int length, int x, int y, bool atCursor) {

		HWND hwnd = GetWindowHandle (window);

		if (!hwnd) return 0;

		HMENU menu = CreateMenuFromData (data, length, true);

		if (!menu) return 0;

		POINT point;

		if (atCursor) {

			GetCursorPos (&point);

		} else {

			point.x = x;
			point.y = y;
			ClientToScreen (hwnd, &point);

		}

		UINT flags = TPM_RETURNCMD | TPM_NONOTIFY | TPM_RIGHTBUTTON;
		flags |= GetSystemMetrics (SM_MENUDROPALIGNMENT) ? TPM_RIGHTALIGN : TPM_LEFTALIGN;

		int command = (int)TrackPopupMenuEx (menu, flags, point.x, point.y, hwnd, NULL);

		DestroyMenu (menu);
		return command > MENU_COMMAND_BASE ? command - MENU_COMMAND_BASE : 0;

	}


	void SDLMenu::Remove (SDL_Window* window) {

		// The attached menu is destroyed along with the window
		HWND hwnd = GetWindowHandle (window);
		if (hwnd) menuBars.erase (hwnd);

	}


	bool SDLMenu::SetApplicationMenu (const unsigned char* data, int length) {

		return false;

	}


	bool SDLMenu::SetWindowMenu (SDL_Window* window, const unsigned char* data, int length) {

		HWND hwnd = GetWindowHandle (window);

		if (!hwnd) return false;

		HMENU menu = NULL;

		if (data && length > 0) {

			menu = CreateMenuFromData (data, length, false);
			if (!menu) return false;

		}

		std::map<HWND, MenuBar>::iterator it = menuBars.find (hwnd);
		HMENU previous = (it != menuBars.end ()) ? it->second.menu : NULL;

		Uint32 windowFlags = SDL_GetWindowFlags (window);
		bool preserveSize = ((previous != NULL) != (menu != NULL)) && !(windowFlags & (SDL_WINDOW_FULLSCREEN | SDL_WINDOW_MAXIMIZED | SDL_WINDOW_MINIMIZED));

		int width = 0;
		int height = 0;
		SDL_GetWindowSize (window, &width, &height);

		if (!::SetMenu (hwnd, menu)) {

			if (menu) DestroyMenu (menu);
			return false;

		}

		if (previous) DestroyMenu (previous);

		if (menu) {

			MenuBar menuBar;
			menuBar.menu = menu;
			menuBar.windowID = SDL_GetWindowID (window);
			menuBars[hwnd] = menuBar;

			// Menu commands arrive as WM_COMMAND, which SDL only forwards as SDL_SYSWMEVENT
			SDL_EventState (SDL_SYSWMEVENT, SDL_ENABLE);

		} else {

			menuBars.erase (hwnd);

		}

		DrawMenuBar (hwnd);

		// Adding or removing the menu bar changes the client area, so restore the previous content size
		if (preserveSize && width > 0 && height > 0) {

			SDL_SetWindowSize (window, width, height);

		}

		return true;

	}


}


#endif
