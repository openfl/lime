#include "SDLMenu.h"

#ifdef LIME_SDL_MENU_WIN32

// Native menus and tray icons for Windows

#include "SDLTrayIcon.h"
#include <ui/TrayIconEvent.h>
#include <SDL_syswm.h>
#include <windows.h>
#include <windowsx.h>
#include <shellapi.h>
#include <map>
#include <vector>
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


	bool TrayIcon::IsSupported () {

		return true;

	}


	// Tray icons use Shell_NotifyIcon, with a hidden window that receives their notifications
	// and owns their context menus. It is a top-level window (not message-only) so that it can
	// take the foreground, which a tray context menu needs to close when clicking elsewhere.

	struct Win32TrayIcon {

		HICON icon;
		POINT anchor;
		bool hasAnchor;
		std::wstring tooltip;

	};


	static const UINT TRAY_ICON_MESSAGE = WM_APP + 1;
	static const wchar_t* TRAY_ICON_WINDOW_CLASS = L"LimeTrayIconWindow";

	static int nextTrayIconID = 0;
	static UINT taskbarCreatedMessage = 0;
	static HWND trayIconWindow = NULL;
	static std::map<int, SDLTrayIcon*> trayIcons;


	static bool UpdateNotifyIcon (SDLTrayIcon* trayIcon, DWORD action);


	static LRESULT CALLBACK TrayIconWindowProc (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {

		if (message == TRAY_ICON_MESSAGE) {

			// With NOTIFYICON_VERSION_4, the event is in the low word and the icon ID in the high word
			int id = HIWORD (lParam);
			std::map<int, SDLTrayIcon*>::iterator it = trayIcons.find (id);

			if (it != trayIcons.end () && it->second->platform) {

				Win32TrayIcon* data = (Win32TrayIcon*)it->second->platform;

				switch (LOWORD (lParam)) {

					case NIN_SELECT:
					case NIN_KEYSELECT:

						SDLMenu::PushTrayIconEvent (id, TRAY_ICON_CLICK, 0);
						break;

					case WM_CONTEXTMENU:

						data->anchor.x = GET_X_LPARAM (wParam);
						data->anchor.y = GET_Y_LPARAM (wParam);
						data->hasAnchor = true;
						SDLMenu::PushTrayIconEvent (id, TRAY_ICON_RIGHT_CLICK, 0);
						break;

					default: break;

				}

			}

			return 0;

		}

		if (taskbarCreatedMessage != 0 && message == taskbarCreatedMessage) {

			// Explorer restarted, so the icons have to be added again
			for (std::map<int, SDLTrayIcon*>::iterator it = trayIcons.begin (); it != trayIcons.end (); ++it) {

				UpdateNotifyIcon (it->second, NIM_ADD);

			}

			return 0;

		}

		return DefWindowProcW (hwnd, message, wParam, lParam);

	}


	static HWND GetTrayIconWindow () {

		if (trayIconWindow) return trayIconWindow;

		HINSTANCE instance = NULL;
		GetModuleHandleExW (GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, (LPCWSTR)&TrayIconWindowProc, &instance);

		WNDCLASSEXW windowClass;
		ZeroMemory (&windowClass, sizeof (windowClass));
		windowClass.cbSize = sizeof (windowClass);
		windowClass.lpfnWndProc = TrayIconWindowProc;
		windowClass.hInstance = instance;
		windowClass.lpszClassName = TRAY_ICON_WINDOW_CLASS;
		RegisterClassExW (&windowClass);

		trayIconWindow = CreateWindowExW (WS_EX_TOOLWINDOW, TRAY_ICON_WINDOW_CLASS, L"", WS_POPUP, 0, 0, 0, 0, NULL, NULL, instance, NULL);
		taskbarCreatedMessage = RegisterWindowMessageW (L"TaskbarCreated");

		return trayIconWindow;

	}


	static HICON GetDefaultIcon () {

		int size = GetSystemMetrics (SM_CXSMICON);

		// Lime executables embed the application icon as resource 1
		HICON icon = (HICON)LoadImageW (GetModuleHandleW (NULL), MAKEINTRESOURCEW (1), IMAGE_ICON, size, size, LR_SHARED);
		return icon ? icon : LoadIcon (NULL, IDI_APPLICATION);

	}


	static HICON CreateIconFromImage (ImageBuffer* imageBuffer) {

		if (!imageBuffer || !imageBuffer->data || !imageBuffer->data->buffer || imageBuffer->width <= 0 || imageBuffer->height <= 0 || imageBuffer->bitsPerPixel != 32) {

			return NULL;

		}

		int width = imageBuffer->width;
		int height = imageBuffer->height;

		if (imageBuffer->data->buffer->length < imageBuffer->Stride () * height) return NULL;

		BITMAPV5HEADER header;
		ZeroMemory (&header, sizeof (header));
		header.bV5Size = sizeof (header);
		header.bV5Width = width;
		header.bV5Height = -height;
		header.bV5Planes = 1;
		header.bV5BitCount = 32;
		header.bV5Compression = BI_BITFIELDS;
		header.bV5RedMask = 0x00FF0000;
		header.bV5GreenMask = 0x0000FF00;
		header.bV5BlueMask = 0x000000FF;
		header.bV5AlphaMask = 0xFF000000;

		void* bits = NULL;
		HDC dc = GetDC (NULL);
		HBITMAP color = CreateDIBSection (dc, (BITMAPINFO*)&header, DIB_RGB_COLORS, &bits, NULL, 0);
		ReleaseDC (NULL, dc);

		if (!color) return NULL;

		// Lime images are RGBA, Windows bitmaps are BGRA
		const unsigned char* source = imageBuffer->data->buffer->b;
		unsigned char* dest = (unsigned char*)bits;
		int stride = imageBuffer->Stride ();

		for (int y = 0; y < height; y++) {

			const unsigned char* sourceRow = source + y * stride;
			unsigned char* destRow = dest + y * width * 4;

			for (int x = 0; x < width; x++) {

				destRow[x * 4 + 0] = sourceRow[x * 4 + 2];
				destRow[x * 4 + 1] = sourceRow[x * 4 + 1];
				destRow[x * 4 + 2] = sourceRow[x * 4 + 0];
				destRow[x * 4 + 3] = sourceRow[x * 4 + 3];

			}

		}

		// The alpha channel is used for transparency, so the mask only needs to exist
		std::vector<unsigned char> maskBits (((width + 15) / 16) * 2 * height, 0);
		HBITMAP mask = CreateBitmap (width, height, 1, 1, &maskBits[0]);

		ICONINFO info;
		info.fIcon = TRUE;
		info.xHotspot = 0;
		info.yHotspot = 0;
		info.hbmMask = mask;
		info.hbmColor = color;

		HICON icon = CreateIconIndirect (&info);

		DeleteObject (mask);
		DeleteObject (color);
		return icon;

	}


	static bool UpdateNotifyIcon (SDLTrayIcon* trayIcon, DWORD action) {

		Win32TrayIcon* data = (Win32TrayIcon*)trayIcon->platform;

		if (!data) return false;

		NOTIFYICONDATAW notifyIcon;
		ZeroMemory (&notifyIcon, sizeof (notifyIcon));
		notifyIcon.cbSize = sizeof (notifyIcon);
		notifyIcon.hWnd = GetTrayIconWindow ();
		notifyIcon.uID = trayIcon->id;
		notifyIcon.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP | NIF_SHOWTIP;
		notifyIcon.uCallbackMessage = TRAY_ICON_MESSAGE;
		notifyIcon.hIcon = data->icon ? data->icon : GetDefaultIcon ();
		wcsncpy_s (notifyIcon.szTip, data->tooltip.c_str (), _TRUNCATE);

		if (!Shell_NotifyIconW (action, &notifyIcon)) return false;

		if (action == NIM_ADD) {

			notifyIcon.uVersion = NOTIFYICON_VERSION_4;
			Shell_NotifyIconW (NIM_SETVERSION, &notifyIcon);

		}

		return true;

	}


	SDLTrayIcon::SDLTrayIcon () {

		id = ++nextTrayIconID;

		Win32TrayIcon* data = new Win32TrayIcon ();
		data->icon = NULL;
		data->hasAnchor = false;
		platform = data;

		trayIcons[id] = this;
		UpdateNotifyIcon (this, NIM_ADD);

	}


	SDLTrayIcon::~SDLTrayIcon () {

		Close ();

	}


	void SDLTrayIcon::Close () {

		Win32TrayIcon* data = (Win32TrayIcon*)platform;

		if (!data) return;

		NOTIFYICONDATAW notifyIcon;
		ZeroMemory (&notifyIcon, sizeof (notifyIcon));
		notifyIcon.cbSize = sizeof (notifyIcon);
		notifyIcon.hWnd = GetTrayIconWindow ();
		notifyIcon.uID = id;
		Shell_NotifyIconW (NIM_DELETE, &notifyIcon);

		if (data->icon) DestroyIcon (data->icon);

		delete data;
		platform = NULL;
		trayIcons.erase (id);

	}


	int SDLTrayIcon::PopupMenu (const unsigned char* data, int length) {

		Win32TrayIcon* trayData = (Win32TrayIcon*)platform;

		if (!trayData) return 0;

		HMENU menu = CreateMenuFromData (data, length, true);

		if (!menu) return 0;

		HWND hwnd = GetTrayIconWindow ();
		POINT point = trayData->anchor;

		if (!trayData->hasAnchor) GetCursorPos (&point);
		trayData->hasAnchor = false;

		// Without the foreground, the menu would stay open when clicking elsewhere
		SetForegroundWindow (hwnd);

		UINT flags = TPM_RETURNCMD | TPM_NONOTIFY | TPM_RIGHTBUTTON | TPM_BOTTOMALIGN;
		flags |= GetSystemMetrics (SM_MENUDROPALIGNMENT) ? TPM_RIGHTALIGN : TPM_LEFTALIGN;

		int command = (int)TrackPopupMenuEx (menu, flags, point.x, point.y, hwnd, NULL);

		// Lets the menu close properly after it is dismissed (see TrackPopupMenu)
		PostMessageW (hwnd, WM_NULL, 0, 0);

		DestroyMenu (menu);
		return command > MENU_COMMAND_BASE ? command - MENU_COMMAND_BASE : 0;

	}


	void SDLTrayIcon::SetIcon (ImageBuffer* imageBuffer) {

		Win32TrayIcon* data = (Win32TrayIcon*)platform;

		if (!data) return;

		HICON previous = data->icon;
		data->icon = CreateIconFromImage (imageBuffer);
		UpdateNotifyIcon (this, NIM_MODIFY);

		if (previous) DestroyIcon (previous);

	}


	bool SDLTrayIcon::SetMenu (const unsigned char* data, int length) {

		// The menu is shown by PopupMenu when the icon is right-clicked
		return false;

	}


	void SDLTrayIcon::SetTooltip (const char* tooltip) {

		Win32TrayIcon* data = (Win32TrayIcon*)platform;

		if (!data) return;

		data->tooltip = ToWide (tooltip ? std::string (tooltip) : std::string ());
		UpdateNotifyIcon (this, NIM_MODIFY);

	}


	void SDLTrayIcon::Update () {}


}


#endif
