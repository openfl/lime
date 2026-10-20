#include "SDLMenu.h"
#include "SDLTrayIcon.h"
#include <ui/DockIcon.h>


namespace lime {


	TrayIcon* CreateTrayIcon () {

		return new SDLTrayIcon ();

	}


	int Menu::GetSupport () {

		return 0;

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


	bool SDLMenu::GetSelection (SDL_Event* event, Uint32* windowID, int* id) {

		return false;

	}


	bool SDLMenu::GetDockMenuSelection (SDL_Event* event, int* id) {

		return false;

	}


	bool SDLMenu::GetTrayIconEvent (SDL_Event* event, int* id, int* type, int* item) {

		return false;

	}


	void SDLMenu::PushEvent (int kind, Uint32 target, int code, int value) {}


	void SDLMenu::PushDockMenuSelection (int id) {}


	void SDLMenu::PushSelection (Uint32 windowID, int id) {}


	void SDLMenu::PushTrayIconEvent (int trayIconID, int type, int itemID) {}


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
