#include "SDLMenu.h"


namespace lime {


	// Menu data is written by NativeMenu.hx as little-endian Int32 values:
	//
	//   menu := itemCount, item[itemCount]
	//   item := id, flags, keyCode, keyModifiers, labelLength, label, [menu if flags & MENU_ITEM_SUBMENU]
	//
	// Labels are UTF-8, with "&" marking the mnemonic and "&&" for a literal ampersand.

	static const int MAX_MENU_DEPTH = 32;
	static Uint32 selectionEventType = 0;


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


	bool SDLMenu::GetSelection (SDL_Event* event, Uint32* windowID, int* id) {

		if (selectionEventType != 0 && event->type == selectionEventType) {

			*windowID = event->user.windowID;
			*id = event->user.code;
			return true;

		}

		return GetPlatformSelection (event, windowID, id);

	}


	bool SDLMenu::Parse (const unsigned char* data, int length, std::vector<SDLMenuItem>* items) {

		int position = 0;
		return data && length > 0 && ParseItems (data, length, &position, items, 0);

	}


	void SDLMenu::PushSelection (Uint32 windowID, int id) {

		if (selectionEventType == 0) {

			selectionEventType = SDL_RegisterEvents (1);

			// SDLApplication treats SDL_USEREVENT as a frame request, so never share it
			if (selectionEventType == SDL_USEREVENT) selectionEventType = SDL_RegisterEvents (1);

			if (selectionEventType == (Uint32)-1) {

				selectionEventType = 0;
				return;

			}

		}

		SDL_Event event;
		SDL_zero (event);
		event.type = selectionEventType;
		event.user.windowID = windowID;
		event.user.code = id;
		SDL_PushEvent (&event);

	}


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

#endif


}
