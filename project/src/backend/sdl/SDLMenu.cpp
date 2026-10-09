#include "SDLMenu.h"
#include "SDLTrayIcon.h"
#include <ui/DockIcon.h>
#include <stdint.h>


namespace lime {


	// Menu data is written by NativeMenu.hx as little-endian Int32 values:
	//
	//   menu := itemCount, item[itemCount]
	//   item := id, flags, keyCode, keyModifiers, labelLength, label, [menu if flags & MENU_ITEM_SUBMENU]
	//
	// Labels are UTF-8, with "&" marking the mnemonic and "&&" for a literal ampersand.

	enum MenuEventKind {

		MENU_EVENT_SELECTION = 1,
		MENU_EVENT_TRAY_ICON = 2,
		MENU_EVENT_DOCK_SELECTION = 3

	};


	static const int MAX_MENU_DEPTH = 32;
	static Uint32 menuEventType = 0;


	static bool ReadInt (const unsigned char* data, int length, int* position, int* result) {

		if (length - *position < 4) return false;

		const unsigned char* bytes = data + *position;
		*result = (int)((Uint32)bytes[0] | ((Uint32)bytes[1] << 8) | ((Uint32)bytes[2] << 16) | ((Uint32)bytes[3] << 24));
		*position += 4;
		return true;

	}


	static bool ParseItems (const unsigned char* data, int length, int* position, std::vector<SDLMenuItem>* items, int depth) {

		int count;

		if (depth > MAX_MENU_DEPTH || !ReadInt (data, length, position, &count) || count < 0) return false;

		items->resize (count);

		for (int i = 0; i < count; i++) {

			SDLMenuItem* item = &(*items)[i];
			int labelLength;

			if (!ReadInt (data, length, position, &item->id) || !ReadInt (data, length, position, &item->flags)
				|| !ReadInt (data, length, position, &item->keyCode) || !ReadInt (data, length, position, &item->keyModifiers)
				|| !ReadInt (data, length, position, &labelLength) || labelLength < 0 || length - *position < labelLength) {

				return false;

			}

			item->label.assign ((const char*)(data + *position), labelLength);
			*position += labelLength;

			if ((item->flags & MENU_ITEM_SUBMENU) && !ParseItems (data, length, position, &item->submenu, depth + 1)) {

				return false;

			}

		}

		return true;

	}


	TrayIcon* CreateTrayIcon () {

		return new SDLTrayIcon ();

	}


	int Menu::GetSupport () {

		return SDLMenu::GetSupport ();

	}


	std::string SDLMenu::GetLabel (const std::string& label, char mnemonicPrefix) {

		if (mnemonicPrefix == '&') return label;

		std::string result;
		result.reserve (label.size ());

		for (size_t i = 0; i < label.size (); i++) {

			char c = label[i];

			if (c == '&') {

				if (i + 1 < label.size () && label[i + 1] == '&') {

					result += '&';
					i++;

				} else if (mnemonicPrefix) {

					result += mnemonicPrefix;

				}

			} else if (mnemonicPrefix && c == mnemonicPrefix) {

				result += mnemonicPrefix;
				result += mnemonicPrefix;

			} else {

				result += c;

			}

		}

		return result;

	}


	bool SDLMenu::GetDockMenuSelection (SDL_Event* event, int* id) {

		if (menuEventType == 0 || event->type != menuEventType || (intptr_t)event->user.data1 != MENU_EVENT_DOCK_SELECTION) return false;

		*id = event->user.code;
		return true;

	}


	bool SDLMenu::GetSelection (SDL_Event* event, Uint32* windowID, int* id) {

		if (menuEventType != 0 && event->type == menuEventType && (intptr_t)event->user.data1 == MENU_EVENT_SELECTION) {

			*windowID = event->user.windowID;
			*id = event->user.code;
			return true;

		}

		return GetPlatformSelection (event, windowID, id);

	}


	bool SDLMenu::GetTrayIconEvent (SDL_Event* event, int* trayIconID, int* type, int* itemID) {

		if (menuEventType == 0 || event->type != menuEventType || (intptr_t)event->user.data1 != MENU_EVENT_TRAY_ICON) return false;

		*trayIconID = (int)event->user.windowID;
		*type = event->user.code;
		*itemID = (int)(intptr_t)event->user.data2;
		return true;

	}


	bool SDLMenu::Parse (const unsigned char* data, int length, std::vector<SDLMenuItem>* items) {

		int position = 0;
		return data && length > 0 && ParseItems (data, length, &position, items, 0);

	}


	void SDLMenu::PushEvent (int kind, Uint32 target, int code, int value) {

		if (menuEventType == 0) {

			menuEventType = SDL_RegisterEvents (1);

			// SDLApplication treats SDL_USEREVENT as a frame request, so never share it
			if (menuEventType == SDL_USEREVENT) menuEventType = SDL_RegisterEvents (1);

			if (menuEventType == (Uint32)-1) {

				menuEventType = 0;
				return;

			}

		}

		SDL_Event event;
		SDL_zero (event);
		event.type = menuEventType;
		event.user.windowID = target;
		event.user.code = code;
		event.user.data1 = (void*)(intptr_t)kind;
		event.user.data2 = (void*)(intptr_t)value;
		SDL_PushEvent (&event);

	}


	void SDLMenu::PushDockMenuSelection (int id) {

		PushEvent (MENU_EVENT_DOCK_SELECTION, 0, id, 0);

	}


	void SDLMenu::PushSelection (Uint32 windowID, int id) {

		PushEvent (MENU_EVENT_SELECTION, windowID, id, 0);

	}


	void SDLMenu::PushTrayIconEvent (int trayIconID, int type, int itemID) {

		PushEvent (MENU_EVENT_TRAY_ICON, (Uint32)trayIconID, type, itemID);

	}


	int SDLTrayIcon::GetID () {

		return id;

	}


#ifndef LIME_SDL_MENU_COCOA

	// The Dock only exists on macOS

	void DockIcon::Bounce (bool critical) {}


	bool DockIcon::IsSupported () {

		return false;

	}


	void DockIcon::SetIcon (ImageBuffer* imageBuffer) {}


	bool DockIcon::SetMenu (const unsigned char* data, int length) {

		return false;

	}

#endif


#if !defined (LIME_SDL_MENU_WIN32) && !defined (LIME_SDL_MENU_COCOA) && !defined (LIME_SDL_MENU_GTK)

	bool SDLMenu::GetPlatformSelection (SDL_Event* event, Uint32* windowID, int* id) {

		return false;

	}


	int SDLMenu::GetSupport () {

		return 0;

	}


	int SDLMenu::Popup (SDL_Window* window, const unsigned char* data, int length, int x, int y, bool atCursor) {

		return 0;

	}


	void SDLMenu::Remove (SDL_Window* window) {}


	bool SDLMenu::SetApplicationMenu (const unsigned char* data, int length) {

		return false;

	}


	bool SDLMenu::SetWindowMenu (SDL_Window* window, const unsigned char* data, int length) {

		return false;

	}


	bool TrayIcon::IsSupported () {

		return false;

	}


	SDLTrayIcon::SDLTrayIcon () {

		id = 0;
		platform = 0;

	}


	SDLTrayIcon::~SDLTrayIcon () {}


	void SDLTrayIcon::Close () {}


	int SDLTrayIcon::PopupMenu (const unsigned char* data, int length) {

		return 0;

	}


	void SDLTrayIcon::SetIcon (ImageBuffer* imageBuffer) {}


	bool SDLTrayIcon::SetMenu (const unsigned char* data, int length) {

		return false;

	}


	void SDLTrayIcon::SetTooltip (const char* tooltip) {}


	void SDLTrayIcon::Update () {}

#endif


}
