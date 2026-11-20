#include "SDLMenu.h"
#include "SDLTrayIcon.h"
#include "SDLWindow.h"
#include <system/Clipboard.h>
#include <ui/DockIcon.h>
#include <ui/DragDrop.h>
#include <ui/DragEvent.h>
#include <native_desktop/Desktop.h>
#include <stdint.h>
#include <cstring>
#include <map>

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

	static void FinishDrag (int id, int action);


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

			#ifdef NATIVE_DESKTOP_DRAG_DROP
			case native_desktop::DRAG_EVENT_COMPLETE:
				FinishDrag ((int)event.target, event.value);
				break;
			#endif

		}

	}


	#ifdef NATIVE_DESKTOP_DRAG_DROP
	static int DesktopDragHandler (const native_desktop::DragEvent& event, native_desktop::DragData* data, void*);
	#endif


	static void ConfigureDesktop () {

		native_desktop::Menu::SetEventSink (ForwardDesktopEvent, NULL);
		#ifdef NATIVE_DESKTOP_DRAG_DROP
		native_desktop::DragDrop::SetHandler (DesktopDragHandler, NULL);
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
		#ifdef NATIVE_DESKTOP_CLIPBOARD
		native_desktop::Clipboard::Update ();
		#endif
		#endif

		// X11 drags talk to other applications on native-desktop's own connection
		#ifdef NATIVE_DESKTOP_DRAG_DROP
		native_desktop::DragDrop::Update ();
		#endif

	}


	#ifdef NATIVE_DESKTOP_CLIPBOARD
	bool Clipboard::GetFiles (std::vector<std::string>* files) { return native_desktop::Clipboard::GetFiles (files); }
	bool Clipboard::GetFormatText (int format, std::string* text) { return native_desktop::Clipboard::GetText (format, text); }
	bool Clipboard::GetImage (std::vector<unsigned char>* pixels, int* width, int* height) { return native_desktop::Clipboard::GetImage (pixels, width, height); }
	bool Clipboard::HasFormat (int format) { return native_desktop::Clipboard::HasFormat (format); }


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


	// Little-endian Int32 values: count, then for each item its format and either length and UTF-8 text, a
	// count of files each with length and UTF-8 path, or width, height and the pixels
	static bool ParseDesktopItems (const unsigned char* data, int length, std::vector<native_desktop::ClipboardItem>* result) {

		int position = 0;
		int count;
		if (!data || !ReadInt (data, length, &position, &count) || count < 0) return false;

		std::vector<native_desktop::ClipboardItem>& items = *result;
		items.resize (count);

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

		return true;

	}


	bool Clipboard::SetItems (const unsigned char* data, int length) {

		std::vector<native_desktop::ClipboardItem> items;
		return ParseDesktopItems (data, length, &items) && native_desktop::Clipboard::SetItems (items);

	}
	#else
	bool Clipboard::GetFiles (std::vector<std::string>* files) { return false; }
	bool Clipboard::GetFormatText (int format, std::string* text) { return false; }
	bool Clipboard::GetImage (std::vector<unsigned char>* pixels, int* width, int* height) { return false; }
	bool Clipboard::HasFormat (int format) { return false; }
	bool Clipboard::SetItems (const unsigned char* data, int length) { return false; }
	#endif


	#ifdef NATIVE_DESKTOP_DRAG_DROP
	// What is dragged over a window, while its event is dispatched
	static native_desktop::DragData* currentDragData = NULL;

	// The windows drags out started from, by drag ID, for the mouse up their drag took
	static std::map<int, Uint32> dragWindows;


	static int DesktopDragHandler (const native_desktop::DragEvent& event, native_desktop::DragData* data, void*) {

		DragEvent dragEvent;
		dragEvent.action = 0;
		dragEvent.allowedActions = event.allowedActions;
		dragEvent.type = event.type;
		dragEvent.windowID = event.window;
		dragEvent.x = event.x;
		dragEvent.y = event.y;

		#ifdef LIME_SDL_MENU_WIN32
		// Windows gives client pixels, and SDL's window coordinates are scaled where it scales for DPI
		SDL_Window* window = SDL_GetWindowFromID (event.window);

		if (window) {

			int width, height, pixelWidth, pixelHeight;
			SDL_GetWindowSize (window, &width, &height);
			SDL_GetWindowSizeInPixels (window, &pixelWidth, &pixelHeight);

			if (pixelWidth > 0 && pixelHeight > 0) {

				dragEvent.x = event.x * (double)width / pixelWidth;
				dragEvent.y = event.y * (double)height / pixelHeight;

			}

		}
		#endif

		native_desktop::DragData* previous = currentDragData;
		currentDragData = data;
		DragEvent::Dispatch (&dragEvent);
		currentDragData = previous;

		return dragEvent.action;

	}


	static void FinishDrag (int id, int action) {

		DragEvent dragEvent;
		dragEvent.action = action;
		dragEvent.type = DRAG_COMPLETE;
		dragEvent.windowID = id;
		DragEvent::Dispatch (&dragEvent);

		std::map<int, Uint32>::iterator found = dragWindows.find (id);
		if (found == dragWindows.end ()) return;

		Uint32 windowID = found->second;
		dragWindows.erase (found);

		#ifndef LIME_SDL_MENU_WIN32
		// macOS and X11 take the button's release for the drag, so SDL never hears it. Windows' SDL finds it
		// on the next mouse move.
		SDL_Window* window = SDL_GetWindowFromID (windowID);
		if (!window) return;

		int x = 0, y = 0;
		SDL_GetMouseState (&x, &y);

		SDL_Event release;
		SDL_zero (release);
		release.type = SDL_MOUSEBUTTONUP;
		release.button.windowID = windowID;
		release.button.button = SDL_BUTTON_LEFT;
		release.button.state = SDL_RELEASED;
		release.button.clicks = 1;
		release.button.x = x;
		release.button.y = y;
		release.button.timestamp = SDL_GetTicks ();
		SDL_PushEvent (&release);
		#else
		(void)windowID;
		#endif

	}


	bool DragDrop::IsSupported () {

		return native_desktop::DragDrop::IsSupported ();

	}


	bool DragDrop::SetTarget (Window* window, bool enabled) {

		native_desktop::Window native;
		if (!window || !GetDesktopWindow (((SDLWindow*)window)->sdlWindow, &native)) return false;
		return native_desktop::DragDrop::SetTarget (&native, enabled);

	}


	int DragDrop::StartDrag (Window* window, const unsigned char* items, int itemsLength, const unsigned char* image, int imageLength, int offsetX, int offsetY, int actions, int id) {

		native_desktop::Window native;
		std::vector<native_desktop::ClipboardItem> parsed;
		if (!window || !GetDesktopWindow (((SDLWindow*)window)->sdlWindow, &native) || !ParseDesktopItems (items, itemsLength, &parsed)) return 0;

		native_desktop::Image picture;
		int position = 0, width = 0, height = 0;

		if (image && ReadInt (image, imageLength, &position, &width) && ReadInt (image, imageLength, &position, &height) && width > 0 && height > 0 && (size_t)imageLength >= 8 + (size_t)width * height * 4) {

			picture.data = image + 8;
			picture.length = (size_t)width * height * 4;
			picture.width = width;
			picture.height = height;
			picture.stride = width * 4;

		}

		dragWindows[id] = native.id;
		int result = native_desktop::DragDrop::StartDrag (&native, parsed, picture.Valid () ? &picture : NULL, offsetX, offsetY, actions, id);
		if (result >= 0) dragWindows.erase (id);
		return result;

	}


	bool DragDrop::GetFiles (std::vector<std::string>* files) { return currentDragData && currentDragData->GetFiles (files); }
	bool DragDrop::GetFormatText (int format, std::string* text) { return currentDragData && currentDragData->GetText (format, text); }
	bool DragDrop::GetImage (std::vector<unsigned char>* pixels, int* width, int* height) { return currentDragData && currentDragData->GetImage (pixels, width, height); }
	bool DragDrop::HasFormat (int format) { return currentDragData && currentDragData->HasFormat (format); }
	#else
	static void FinishDrag (int id, int action) {}
	bool DragDrop::IsSupported () { return false; }
	bool DragDrop::SetTarget (Window* window, bool enabled) { return false; }
	int DragDrop::StartDrag (Window* window, const unsigned char* items, int itemsLength, const unsigned char* image, int imageLength, int offsetX, int offsetY, int actions, int id) { return 0; }
	bool DragDrop::GetFiles (std::vector<std::string>* files) { return false; }
	bool DragDrop::GetFormatText (int format, std::string* text) { return false; }
	bool DragDrop::GetImage (std::vector<unsigned char>* pixels, int* width, int* height) { return false; }
	bool DragDrop::HasFormat (int format) { return false; }
	#endif


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
