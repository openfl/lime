#ifndef LIME_SDL_MENU_WINDOWS_APPEARANCE_H
#define LIME_SDL_MENU_WINDOWS_APPEARANCE_H
#include <windows.h>

namespace lime {
	bool WindowsMenuDark (HWND window);
	void RefreshWindowsMenuAppearance (HWND window, bool dark);
	void PrepareWindowsPopupAppearance (HWND window, HMENU menu, bool dark);
	void ReleaseWindowsMenuAppearance (HMENU menu);
}
#endif
