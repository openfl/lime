#include "SDLApplication.h"
#include "SDLMenu.h"
#include "SDLTrayIcon.h"
#include "SDLWindow.h"
#include <system/Clipboard.h>
#include <system/System.h>
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
		MENU_EVENT_DOCK_SELECTION = 3,
		MENU_EVENT_CLOSE = 5

	};

	static Uint32 menuEventType = 0;

	static void (*openCallback) () = 0;
	static native_desktop::Event openEvent = { 0, 0, 0, 0 };
	static std::vector<unsigned char>* openItems = 0;
	static bool openReplaced = false;


	#ifdef NATIVE_DESKTOP_MENU_OPEN_EVENTS
	static void CallOpenCallback (void*) {

		openCallback ();

	}


	// Runs while the system waits to show the menu, so the menu's items can still change
	static bool HandleDesktopOpen (const native_desktop::Event& event, std::vector<unsigned char>* items, void*) {

		if (!openCallback) return false;

		openEvent = event;
		openItems = items;
		openReplaced = false;

		SDLApplication::CallFromEventPump (CallOpenCallback, 0);

		openItems = 0;
		return openReplaced;

	}
	#endif


	static void ForwardDesktopEvent (const native_desktop::Event& event, void*) {

		switch (event.kind) {

			case native_desktop::MENU_EVENT_SELECTION:
				SDLMenu::PushSelection (event.target, event.code);
				break;

			case native_desktop::MENU_EVENT_TRAY_ICON:
				#ifdef NATIVE_DESKTOP_TRAY_ICON_MOUSE_EVENTS
				SDLMenu::PushTrayIconEvent (event.target, event.code, event.value, event.x, event.y);
				#else
				SDLMenu::PushTrayIconEvent (event.target, event.code, event.value);
				#endif
				break;

			case native_desktop::MENU_EVENT_DOCK_SELECTION:
				SDLMenu::PushDockMenuSelection (event.code);
				break;

			#ifdef NATIVE_DESKTOP_MENU_OPEN_EVENTS
			case native_desktop::MENU_EVENT_CLOSE:
				SDLMenu::PushClose (event.target, event.code, event.value);
				break;
			#endif

		}

	}


	static void ConfigureDesktop () {

		native_desktop::Menu::SetEventSink (ForwardDesktopEvent, NULL);
		// native-desktop 1.1.0 has no open events, and onOpen and onClose are not dispatched with it
		#ifdef NATIVE_DESKTOP_MENU_OPEN_EVENTS
		native_desktop::Menu::SetOpenHandler (HandleDesktopOpen, NULL);
		#endif
		native_desktop::Menu::SetKeyNameProvider (SDL_GetKeyName);

		#ifdef LIME_SDL_MENU_GTK
		const char* driver = SDL_GetCurrentVideoDriver ();
		if (driver && strcmp (driver, "x11") == 0) native_desktop::Menu::SetDisplayBackend ("x11");
		#endif

	}


	static bool GetDesktopWindow (SDL_Window* window, native_desktop::Window* result) {

		int type = SDLWindow::GetNativeHandle (window, &result->handle, &result->display);
		if (type == WINDOW_HANDLE_NONE) return false;

		result->id = SDL_GetWindowID (window);
		SDL_GetWindowPosition (window, &result->x, &result->y);

		#if defined(LIME_SDL_MENU_WIN32)
		if (type != WINDOW_HANDLE_WINDOWS) return false;
		#elif defined(LIME_SDL_MENU_COCOA)
		if (type != WINDOW_HANDLE_COCOA) return false;
		#elif defined(LIME_SDL_MENU_GTK) && defined(SDL_VIDEO_DRIVER_X11)
		if (type != WINDOW_HANDLE_X11) return false;
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


	bool Menu::GetApplicationMenu (std::vector<unsigned char>* data) {

		ConfigureDesktop ();
		return native_desktop::Menu::GetApplicationMenu (data);

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


	// A tray icon event carries the screen position as 16 bits beside the kind and the type
	bool SDLMenu::GetTrayIconEvent (SDL_Event* event, int* id, int* type, int* item, int* x, int* y) {

		if (!menuEventType || event->type != menuEventType || ((intptr_t)event->user.data1 & 0xFF) != MENU_EVENT_TRAY_ICON) return false;
		*id = event->user.windowID;
		*type = event->user.code & 0xFF;
		*item = (int)(intptr_t)event->user.data2;
		*x = (Sint16)(((intptr_t)event->user.data1 >> 8) & 0xFFFF);
		*y = (Sint16)((event->user.code >> 8) & 0xFFFF);
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
		#ifdef NATIVE_DESKTOP_CLIPBOARD
		native_desktop::Clipboard::Update ();
		#endif
		#endif

	}


	bool SDLMenu::DragWindow (SDL_Window* window, int edges) {

		#ifdef NATIVE_DESKTOP_WINDOW_CONTROL
		native_desktop::Window desktopWindow;
		if (!GetDesktopWindow (window, &desktopWindow)) return false;
		return edges == 0 ? native_desktop::WindowControl::StartMove (&desktopWindow) : native_desktop::WindowControl::StartResize (&desktopWindow, edges);
		#else
		return false;
		#endif

	}


	bool SDLMenu::OrderWindow (SDL_Window* window, SDL_Window* other, int mode) {

		#ifdef NATIVE_DESKTOP_WINDOW_CONTROL
		native_desktop::Window desktopWindow;
		if (!GetDesktopWindow (window, &desktopWindow)) return false;
		if (mode == 0) return native_desktop::WindowControl::OrderToBack (&desktopWindow);

		native_desktop::Window otherWindow;
		if (!other || !GetDesktopWindow (other, &otherWindow)) return false;
		return mode == 1 ? native_desktop::WindowControl::OrderAbove (&desktopWindow, &otherWindow) : native_desktop::WindowControl::OrderBelow (&desktopWindow, &otherWindow);
		#else
		return false;
		#endif

	}


	#ifdef NATIVE_DESKTOP_CLIPBOARD
	bool Clipboard::GetFiles (std::vector<std::string>* files) { return native_desktop::Clipboard::GetFiles (files); }
	bool Clipboard::GetFormatText (int format, std::string* text) { return native_desktop::Clipboard::GetText (format, text); }
	bool Clipboard::GetImage (std::vector<unsigned char>* pixels, int* width, int* height) { return native_desktop::Clipboard::GetImage (pixels, width, height); }
	bool Clipboard::HasFormat (int format) { return native_desktop::Clipboard::HasFormat (format); }


	bool Clipboard::HasDesktopText () {

		// SDL reads the X11 clipboard by asking its owner and waiting for the answer, but GTK only
		// answers from its own events, which aren't run while SDL waits. SDL then gives up after a
		// second and takes the clipboard with empty text, and GTK waiting on SDL times out the same way.
		#if defined(HX_LINUX) && !defined(HX_ANDROID)
		return native_desktop::Clipboard::IsSupported ();
		#else
		return false;
		#endif

	}


	bool Clipboard::SetDesktopText (const char* text) {

		std::vector<native_desktop::ClipboardItem> items (1);
		items[0].format = native_desktop::CLIPBOARD_TEXT;
		items[0].text = text ? text : "";
		return native_desktop::Clipboard::SetItems (items);

	}


	static bool ReadInt (const unsigned char* data, int length, int* position, int* value) {

		if (*position + 4 > length) return false;
		*value = (int)(data[*position] | (data[*position + 1] << 8) | (data[*position + 2] << 16) | ((unsigned)data[*position + 3] << 24));
		*position += 4;
		return true;

	}


	static bool ReadString (const unsigned char* data, int length, int* position, std::string* text) {

		int size;
		if (!ReadInt (data, length, position, &size) || size < 0 || *position + size > length) return false;
		text->assign ((const char*)data + *position, size);
		*position += size;
		return true;

	}


	bool Clipboard::SetItems (const unsigned char* data, int length) {

		int position = 0;
		int count;
		if (!data || !ReadInt (data, length, &position, &count) || count < 0) return false;

		// GTK takes no empty list of targets, so emptying the clipboard there is setting empty text
		if (count == 0 && HasDesktopText ()) return false;

		std::vector<native_desktop::ClipboardItem> items (count);

		for (int i = 0; i < count; i++) {

			native_desktop::ClipboardItem& item = items[i];
			if (!ReadInt (data, length, &position, &item.format)) return false;

			if (item.format == native_desktop::CLIPBOARD_FILE_LIST) {

				int files;
				if (!ReadInt (data, length, &position, &files) || files < 0) return false;
				item.files.resize (files);
				for (int j = 0; j < files; j++) if (!ReadString (data, length, &position, &item.files[j])) return false;

			} else if (item.format == native_desktop::CLIPBOARD_IMAGE) {

				if (!ReadInt (data, length, &position, &item.width) || !ReadInt (data, length, &position, &item.height)) return false;
				if (item.width < 0 || item.height < 0) return false;
				size_t size = (size_t)item.width * item.height * 4;
				if (position + size > (size_t)length) return false;
				item.pixels.assign (data + position, data + position + size);
				position += (int)size;

			} else {

				if (!ReadString (data, length, &position, &item.text)) return false;

			}

		}

		return native_desktop::Clipboard::SetItems (items);

	}
	#else
	bool Clipboard::GetFiles (std::vector<std::string>* files) { return false; }
	bool Clipboard::GetFormatText (int format, std::string* text) { return false; }
	bool Clipboard::GetImage (std::vector<unsigned char>* pixels, int* width, int* height) { return false; }
	bool Clipboard::HasFormat (int format) { return false; }
	bool Clipboard::SetItems (const unsigned char* data, int length) { return false; }
	bool Clipboard::HasDesktopText () { return false; }
	bool Clipboard::SetDesktopText (const char* text) { return false; }
	#endif


	// System's, as native-desktop is only in desktop builds
	bool System::MoveToTrash (const char* path) {

		#ifdef NATIVE_DESKTOP_TRASH
		return native_desktop::Trash::MoveToTrash (path);
		#else
		return false;
		#endif

	}


	// System's, as native-desktop is only in desktop builds
	bool System::GetStorageVolumes (std::string* volumes) {

		#ifdef NATIVE_DESKTOP_STORAGE_VOLUMES
		std::vector<native_desktop::StorageVolume> list;
		if (!volumes || !native_desktop::StorageVolumes::GetVolumes (&list)) return false;

		volumes->clear ();

		for (size_t i = 0; i < list.size (); i++) {

			const native_desktop::StorageVolume& volume = list[i];
			*volumes += volume.rootDirectory + "\x1F" + volume.name + "\x1F" + volume.fileSystemType + "\x1F" + volume.drive + "\x1F";
			*volumes += volume.isRemovable ? "1\x1F" : "0\x1F";
			*volumes += volume.isWritable ? "1\x1E" : "0\x1E";

		}

		return true;
		#else
		return false;
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


	void Menu::GetOpenEvent (int* target, int* menu, int* source) {

		*target = (int)openEvent.target;
		*menu = openEvent.code;
		*source = openEvent.value;

	}


	void Menu::SetOpenCallback (void (*callback) ()) {

		openCallback = callback;

	}


	void Menu::SetOpenItems (const unsigned char* data, int length) {

		if (!openItems || !data || length <= 0) return;

		openItems->assign (data, data + length);
		openReplaced = true;

	}


	bool SDLMenu::GetClose (SDL_Event* event, Uint32* target, int* menu, int* source) {

		if (!menuEventType || event->type != menuEventType || (intptr_t)event->user.data1 != MENU_EVENT_CLOSE) return false;

		*target = event->user.windowID;
		*menu = event->user.code;
		*source = (int)(intptr_t)event->user.data2;
		return true;

	}


	void SDLMenu::PushClose (Uint32 target, int menu, int source) {

		PushEvent (MENU_EVENT_CLOSE, target, menu, source);

	}


	void SDLMenu::PushDockMenuSelection (int id) {

		PushEvent (MENU_EVENT_DOCK_SELECTION, 0, id, 0);

	}


	void SDLMenu::PushSelection (Uint32 windowID, int id) {

		PushEvent (MENU_EVENT_SELECTION, windowID, id, 0);

	}


	void SDLMenu::PushTrayIconEvent (int trayIconID, int type, int itemID, int x, int y) {

		PushEvent (MENU_EVENT_TRAY_ICON | ((x & 0xFFFF) << 8), (Uint32)trayIconID, (type & 0xFF) | ((y & 0xFFFF) << 8), itemID);

	}


}
