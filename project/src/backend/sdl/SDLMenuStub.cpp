#include "SDLMenu.h"
#include "SDLTrayIcon.h"
#include <system/Clipboard.h>
#include <system/System.h>
#include <ui/DockIcon.h>
#include <ui/DragDrop.h>


namespace lime {


	bool SDLMenu::DragWindow (SDL_Window* window, int edges) { return false; }
	bool SDLMenu::OrderWindow (SDL_Window* window, SDL_Window* other, int mode) { return false; }
	bool Clipboard::GetFiles (std::vector<std::string>* files) { return false; }
	bool Clipboard::GetFormatText (int format, std::string* text) { return false; }
	bool Clipboard::GetImage (std::vector<unsigned char>* pixels, int* width, int* height) { return false; }
	bool Clipboard::HasFormat (int format) { return false; }
	bool Clipboard::SetItems (const unsigned char* data, int length) { return false; }
	bool Clipboard::HasDesktopText () { return false; }
	bool Clipboard::SetDesktopText (const char* text) { return false; }


	bool System::MoveToTrash (const char* path) { return false; }


	bool System::GetStorageVolumes (std::string* volumes) { return false; }


	bool DragDrop::IsSupported () { return false; }
	bool DragDrop::SetTarget (Window* window, bool enabled) { return false; }
	int DragDrop::StartDrag (Window* window, const unsigned char* items, int itemsLength, const unsigned char* image, int imageLength, int offsetX, int offsetY, int actions, int id) { return 0; }
	bool DragDrop::GetFiles (std::vector<std::string>* files) { return false; }
	bool DragDrop::GetFormatText (int format, std::string* text) { return false; }
	bool DragDrop::GetImage (std::vector<unsigned char>* pixels, int* width, int* height) { return false; }
	bool DragDrop::HasFormat (int format) { return false; }


	TrayIcon* CreateTrayIcon () {

		return new SDLTrayIcon ();

	}


	bool Menu::GetApplicationMenu (std::vector<unsigned char>* data) {

		return false;

	}


	int Menu::GetSupport () {

		return 0;

	}


	void Menu::GetOpenEvent (int* target, int* menu, int* source) {

		*target = 0;
		*menu = 0;
		*source = 0;

	}


	void Menu::SetOpenCallback (void (*callback) ()) {}


	void Menu::SetOpenItems (const unsigned char* data, int length) {}


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


	bool SDLMenu::GetSelection (SDL_Event* event, Uint32* windowID, int* id) {

		return false;

	}


	bool SDLMenu::GetClose (SDL_Event* event, Uint32* target, int* menu, int* source) {

		return false;

	}


	bool SDLMenu::GetDockMenuSelection (SDL_Event* event, int* id) {

		return false;

	}


	bool SDLMenu::GetTrayIconEvent (SDL_Event* event, int* id, int* type, int* item, int* x, int* y) {

		return false;

	}


	void SDLMenu::PushEvent (int kind, Uint32 target, int code, int value) {}


	void SDLMenu::PushClose (Uint32 target, int menu, int source) {}


	void SDLMenu::PushDockMenuSelection (int id) {}


	void SDLMenu::PushSelection (Uint32 windowID, int id) {}


	void SDLMenu::PushTrayIconEvent (int trayIconID, int type, int itemID, int x, int y) {}


	bool TrayIcon::IsSupported () {

		return false;

	}


	SDLTrayIcon::SDLTrayIcon () {

		id = 0;
		platform = NULL;

	}


	SDLTrayIcon::~SDLTrayIcon () {}


	int SDLTrayIcon::GetID () {

		return id;

	}


	void SDLTrayIcon::Close () {}


	int SDLTrayIcon::PopupMenu (const unsigned char* data, int length) {

		return 0;

	}


	bool SDLTrayIcon::SetMenu (const unsigned char* data, int length) {

		return false;

	}


	void SDLTrayIcon::SetTooltip (const char* text) {}


	void SDLTrayIcon::SetIcon (ImageBuffer* image) {}


	void SDLTrayIcon::Update () {}


	void DockIcon::Bounce (bool critical) {}


	bool DockIcon::IsSupported () {

		return false;

	}


	bool DockIcon::SetMenu (const unsigned char* data, int length) {

		return false;

	}


	void DockIcon::SetIcon (ImageBuffer* image) {}


}
