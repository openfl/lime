#include "SDLMenu.h"
#include "SDLTrayIcon.h"
#include <ui/DockIcon.h>
#include <native_desktop/Desktop.h>
#include <stdint.h>
#include <cstring>

#if defined(HX_LINUX) && !defined(HX_ANDROID) && !defined(SDL_VIDEO_DRIVER_X11)
#define SDL_VIDEO_DRIVER_X11 1
#endif
#include <SDL_syswm.h>

#if defined(HX_LINUX) && defined(LIME_PNG)
#include <graphics/format/PNG.h>
#include <utils/Bytes.h>
#endif


namespace lime {


	enum MenuEventKind {

		MENU_EVENT_SELECTION = 1,
		MENU_EVENT_TRAY_ICON = 2,
		MENU_EVENT_DOCK_SELECTION = 3

	};

	static Uint32 menuEventType = 0;


	static void ForwardDesktopEvent (const native_desktop::Event& event, void*) {

		switch (event.kind) {

			case native_desktop::MENU_EVENT_SELECTION:
				SDLMenu::PushSelection (event.target, event.code);
				break;

			case native_desktop::MENU_EVENT_TRAY_ICON:
				SDLMenu::PushTrayIconEvent (event.target, event.code, event.value);
				break;

			case native_desktop::MENU_EVENT_DOCK_SELECTION:
				SDLMenu::PushDockMenuSelection (event.code);
				break;

		}

	}


	static void ConfigureDesktop () {

		native_desktop::Menu::SetEventSink (ForwardDesktopEvent, NULL);
		native_desktop::Menu::SetKeyNameProvider (SDL_GetKeyName);

		#ifdef LIME_SDL_MENU_GTK
		const char* driver = SDL_GetCurrentVideoDriver ();
		if (driver && strcmp (driver, "x11") == 0) native_desktop::Menu::SetDisplayBackend ("x11");
		#endif

	}


	static bool GetDesktopWindow (SDL_Window* window, native_desktop::Window* result) {

		if (!window) return false;

		SDL_SysWMinfo info;
		SDL_VERSION (&info.version);
		if (!SDL_GetWindowWMInfo (window, &info)) return false;

		result->id = SDL_GetWindowID (window);
		SDL_GetWindowPosition (window, &result->x, &result->y);

		#if defined(LIME_SDL_MENU_WIN32)
		if (info.subsystem != SDL_SYSWM_WINDOWS) return false;
		result->handle = info.info.win.window;
		#elif defined(LIME_SDL_MENU_COCOA)
		if (info.subsystem != SDL_SYSWM_COCOA) return false;
		result->handle = info.info.cocoa.window;
		#elif defined(LIME_SDL_MENU_GTK) && defined(SDL_VIDEO_DRIVER_X11)
		if (info.subsystem != SDL_SYSWM_X11) return false;
		result->display = info.info.x11.display;
		result->handle = (void*)(uintptr_t)info.info.x11.window;
		result->appearance = (int)(intptr_t)SDL_GetWindowData (window, "Lime.WindowAppearance") - 1;
		#else
		return false;
		#endif

		return true;

	}


	static native_desktop::Image GetDesktopImage (ImageBuffer* image) {

		native_desktop::Image result;

		if (image && image->data && image->data->buffer) {

			result.data = image->data->buffer->b;
			result.length = image->data->buffer->length;
			result.width = image->width;
			result.height = image->height;
			result.stride = image->Stride ();
			result.bitsPerPixel = image->bitsPerPixel;

		}

		return result;

	}


	TrayIcon* CreateTrayIcon () {

		return new SDLTrayIcon ();

	}


	int Menu::GetSupport () {

		return SDLMenu::GetSupport ();

	}


	int SDLMenu::GetSupport () {

		ConfigureDesktop ();

		#ifdef LIME_SDL_MENU_GTK
		const char* driver = SDL_GetCurrentVideoDriver ();
		if (driver && strcmp (driver, "x11") != 0) return 0;
		#endif

		int support = native_desktop::Menu::GetSupport ();
		return ((support & native_desktop::MENU_SUPPORT_POPUP) ? MENU_SUPPORT_POPUP : 0)
			| ((support & native_desktop::MENU_SUPPORT_WINDOW) ? MENU_SUPPORT_WINDOW : 0)
			| ((support & native_desktop::MENU_SUPPORT_APPLICATION) ? MENU_SUPPORT_APPLICATION : 0);

	}


	int SDLMenu::Popup (SDL_Window* window, const unsigned char* data, int length, int x, int y, bool atCursor) {

		ConfigureDesktop ();
		native_desktop::Window native;
		return GetDesktopWindow (window, &native) ? native_desktop::Menu::Popup (&native, data, length, x, y, atCursor) : 0;

	}


	void SDLMenu::Remove (SDL_Window* window) {

		native_desktop::Window native;
		if (GetDesktopWindow (window, &native)) native_desktop::Menu::Remove (&native);

	}


	bool SDLMenu::SetApplicationMenu (const unsigned char* data, int length) {

		ConfigureDesktop ();
		return native_desktop::Menu::SetApplicationMenu (data, length);

	}


	bool SDLMenu::SetWindowMenu (SDL_Window* window, const unsigned char* data, int length) {

		ConfigureDesktop ();
		native_desktop::Window native;
		if (!GetDesktopWindow (window, &native)) return false;

		#ifdef LIME_SDL_MENU_WIN32
		bool previous = GetMenu ((HWND)native.handle) != NULL;
		bool preserve = (previous != (data && length > 0))
			&& !(SDL_GetWindowFlags (window) & (SDL_WINDOW_FULLSCREEN | SDL_WINDOW_MAXIMIZED | SDL_WINDOW_MINIMIZED));
		int width, height;
		SDL_GetWindowSize (window, &width, &height);
		#endif

		bool result = native_desktop::Menu::SetWindowMenu (&native, data, length);

		#ifdef LIME_SDL_MENU_WIN32
		if (result && preserve && width > 0 && height > 0) SDL_SetWindowSize (window, width, height);
		#endif

		return result;

	}


	bool SDLMenu::GetSelection (SDL_Event* event, Uint32* windowID, int* id) {

		if (!menuEventType || event->type != menuEventType || (intptr_t)event->user.data1 != MENU_EVENT_SELECTION) return false;
		*windowID = event->user.windowID;
		*id = event->user.code;
		return true;

	}


	bool SDLMenu::GetDockMenuSelection (SDL_Event* event, int* id) {

		if (!menuEventType || event->type != menuEventType || (intptr_t)event->user.data1 != MENU_EVENT_DOCK_SELECTION) return false;
		*id = event->user.code;
		return true;

	}


	bool SDLMenu::GetTrayIconEvent (SDL_Event* event, int* id, int* type, int* item) {

		if (!menuEventType || event->type != menuEventType || (intptr_t)event->user.data1 != MENU_EVENT_TRAY_ICON) return false;
		*id = event->user.windowID;
		*type = event->user.code;
		*item = (int)(intptr_t)event->user.data2;
		return true;

	}


	bool TrayIcon::IsSupported () {

		ConfigureDesktop ();
		return native_desktop::TrayIcon::IsSupported ();

	}


	SDLTrayIcon::SDLTrayIcon () {

		ConfigureDesktop ();
		native_desktop::TrayIcon* icon = new native_desktop::TrayIcon ();
		platform = icon;
		id = icon->GetID ();

	}


	SDLTrayIcon::~SDLTrayIcon () {

		Close ();

	}


	int SDLTrayIcon::GetID () {

		return id;

	}


	void SDLTrayIcon::Close () {

		delete (native_desktop::TrayIcon*)platform;
		platform = NULL;

	}


	int SDLTrayIcon::PopupMenu (const unsigned char* data, int length) {

		return platform ? ((native_desktop::TrayIcon*)platform)->PopupMenu (data, length) : 0;

	}


	bool SDLTrayIcon::SetMenu (const unsigned char* data, int length) {

		return platform && ((native_desktop::TrayIcon*)platform)->SetMenu (data, length);

	}


	void SDLTrayIcon::SetTooltip (const char* text) {

		if (platform) ((native_desktop::TrayIcon*)platform)->SetTooltip (text);

	}


	void SDLTrayIcon::SetIcon (ImageBuffer* image) {

		if (!platform) return;

		native_desktop::Image native = GetDesktopImage (image);

		#if defined(HX_LINUX) && defined(LIME_PNG)
		Bytes png;

		if (image && PNG::Encode (image, &png)) {

			native.png = png.b;
			native.pngLength = png.length;

		}
		#endif

		((native_desktop::TrayIcon*)platform)->SetIcon (image ? &native : NULL);

	}


	void SDLTrayIcon::Update () {

		// SDL already dispatches Win32 and Cocoa events. GTK's context is separate.
		#ifdef LIME_SDL_MENU_GTK
		native_desktop::TrayIcon::Update ();
		#endif

	}


	void DockIcon::Bounce (bool critical) {

		native_desktop::DockIcon::Bounce (critical);

	}


	bool DockIcon::IsSupported () {

		return native_desktop::DockIcon::IsSupported ();

	}


	bool DockIcon::SetMenu (const unsigned char* data, int length) {

		ConfigureDesktop ();
		return native_desktop::DockIcon::SetMenu (data, length);

	}


	void DockIcon::SetIcon (ImageBuffer* image) {

		native_desktop::Image native = GetDesktopImage (image);
		native_desktop::DockIcon::SetIcon (image ? &native : NULL);

	}


	void SDLMenu::PushEvent (int kind, Uint32 target, int code, int value) {

		if (menuEventType == 0) {

			menuEventType = SDL_RegisterEvents (1);

			// SDLApplication treats SDL_USEREVENT as a frame request, so never share it.
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


}
