#include <ui/Window.h>

#ifdef LIME_SDL
#include <SDL.h>
#if defined(HX_LINUX) && !defined(RASPBERRYPI) && !defined(SDL_VIDEO_DRIVER_X11)
// Lime builds SDL against its minimal configuration; expose X11 window info as in SDLWindow.cpp.
#define SDL_VIDEO_DRIVER_X11 1
#endif
#include <SDL_syswm.h>
#endif

#if defined(LIME_SDL) && defined(HX_WINDOWS) && !defined(HX_WINRT)
#include <commctrl.h>
#include <dwmapi.h>
#ifdef LIME_NATIVE_DESKTOP
#include <native_desktop/WindowsAppearance.h>
#endif
#endif

namespace lime {

#if defined(LIME_SDL) && defined(HX_MACOS)
	void SetCocoaWindowAppearance (SDL_Window* window, int appearance);
	int GetCocoaWindowAppearance (SDL_Window* window);
#endif

#if defined(LIME_SDL) && defined(HX_WINDOWS) && !defined(HX_WINRT)
	static const wchar_t* APPEARANCE_PROPERTY = L"Lime.WindowAppearance";
	static const UINT_PTR APPEARANCE_SUBCLASS = 0x4C494D45;

	static bool HighContrast () {
		HIGHCONTRASTW contrast = {};
		contrast.cbSize = sizeof (contrast);
		return SystemParametersInfoW (SPI_GETHIGHCONTRAST, sizeof (contrast), &contrast, 0) && (contrast.dwFlags & HCF_HIGHCONTRASTON);
	}

	static bool SystemDark () {
		// A missing preference uses the native light appearance on older Windows versions.
		DWORD light = 1, value = 1, length = sizeof (value), type = 0;
		HKEY key;
		if (RegOpenKeyExW (HKEY_CURRENT_USER, L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize", 0, KEY_QUERY_VALUE, &key) == ERROR_SUCCESS) {
			if (RegQueryValueExW (key, L"AppsUseLightTheme", NULL, &type, (LPBYTE)&value, &length) == ERROR_SUCCESS && type == REG_DWORD && length == sizeof (value)) light = value;
			RegCloseKey (key);
		}
		return light == 0;
	}

	static HMODULE DwmLibrary () {
		static HMODULE library = LoadLibraryW (L"dwmapi.dll");
		return library;
	}

	static void ApplyWindowsAppearance (HWND window, int appearance) {
		typedef HRESULT (WINAPI *SetAttribute) (HWND, DWORD, LPCVOID, DWORD);
		static SetAttribute set = DwmLibrary () ? (SetAttribute)GetProcAddress (DwmLibrary (), "DwmSetWindowAttribute") : NULL;
		BOOL dark = !HighContrast () && (appearance == 2 || (appearance == 0 && SystemDark ()));
		#ifdef LIME_NATIVE_DESKTOP
		native_desktop::SetWindowsMenuAppearance (window, appearance);
		#endif
		// DWMWA_USE_IMMERSIVE_DARK_MODE; older systems reject it without changing the window.
		if (set && SUCCEEDED (set (window, 20, &dark, sizeof (dark))))
			RedrawWindow (window, NULL, NULL, RDW_INVALIDATE | RDW_FRAME);
	}

	static LRESULT CALLBACK AppearanceWindowProc (HWND window, UINT message, WPARAM wParam, LPARAM lParam, UINT_PTR id, DWORD_PTR data) {
		if (message == WM_NCDESTROY) {
			RemovePropW (window, APPEARANCE_PROPERTY);
			RemoveWindowSubclass (window, AppearanceWindowProc, id);
		} else if (message == WM_SETTINGCHANGE || message == WM_THEMECHANGED || message == WM_SYSCOLORCHANGE) {
			HANDLE stored = GetPropW (window, APPEARANCE_PROPERTY);
			if (stored) ApplyWindowsAppearance (window, (int)(INT_PTR)stored - 1);
		}
		return DefSubclassProc (window, message, wParam, lParam);
	}
#endif

#if defined(LIME_SDL) && defined(HX_LINUX) && defined(SDL_VIDEO_DRIVER_X11)
	struct X11AppearanceAPI {
		void* library;
		Atom (*intern) (::Display*, const char*, Bool);
		int (*change) (::Display*, ::Window, Atom, Atom, int, int, const unsigned char*, int);
		int (*remove) (::Display*, ::Window, Atom);
		int (*get) (::Display*, ::Window, Atom, long, long, Bool, Atom, Atom*, int*, unsigned long*, unsigned long*, unsigned char**);
		int (*release) (void*);
		int (*flush) (::Display*);
		X11AppearanceAPI () {
			library = SDL_LoadObject ("libX11.so.6");
			intern = library ? (decltype(intern))SDL_LoadFunction (library, "XInternAtom") : NULL;
			change = library ? (decltype(change))SDL_LoadFunction (library, "XChangeProperty") : NULL;
			remove = library ? (decltype(remove))SDL_LoadFunction (library, "XDeleteProperty") : NULL;
			get = library ? (decltype(get))SDL_LoadFunction (library, "XGetWindowProperty") : NULL;
			release = library ? (decltype(release))SDL_LoadFunction (library, "XFree") : NULL;
			flush = library ? (decltype(flush))SDL_LoadFunction (library, "XFlush") : NULL;
		}
		bool ready () const { return intern && change && remove && get && release && flush; }
	};
#endif

	void SetWindowAppearance (Window* window, int appearance) {
		if (!window || appearance < 0 || appearance > 2) return;
		#ifdef LIME_SDL
		SDL_Window* native = SDL_GetWindowFromID (window->GetID ());
		if (!native) return;
		#if defined(HX_MACOS)
		SetCocoaWindowAppearance (native, appearance);
		#else
		SDL_SysWMinfo info;
		SDL_VERSION (&info.version);
		if (!SDL_GetWindowWMInfo (native, &info)) return;
		#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		if (info.subsystem != SDL_SYSWM_WINDOWS) return;
		HWND handle = info.info.win.window;
		if (!SetWindowSubclass (handle, AppearanceWindowProc, APPEARANCE_SUBCLASS, 0)) return;
		if (!SetPropW (handle, APPEARANCE_PROPERTY, (HANDLE)(INT_PTR)(appearance + 1))) return;
		ApplyWindowsAppearance (handle, appearance);
		#elif defined(HX_LINUX) && defined(SDL_VIDEO_DRIVER_X11)
		if (info.subsystem != SDL_SYSWM_X11) return;
		SDL_SetWindowData (native, "Lime.WindowAppearance", (void*)(intptr_t)(appearance + 1));
		static X11AppearanceAPI x11;
		if (!x11.ready ()) return;
		::Display* display = info.info.x11.display;
		Atom property = x11.intern (display, "_GTK_THEME_VARIANT", False);
		if (appearance == 0) x11.remove (display, info.info.x11.window, property);
		else {
			const char* theme = appearance == 2 ? "dark" : "light";
			x11.change (display, info.info.x11.window, property, x11.intern (display, "UTF8_STRING", False), 8, PropModeReplace,
				(const unsigned char*)theme, (int)SDL_strlen (theme));
		}
		x11.flush (display);
		#endif
		#endif
		#endif
	}

	int GetWindowAppearance (Window* window) {
		#ifdef LIME_SDL
		if (!window) return 0;
		SDL_Window* native = SDL_GetWindowFromID (window->GetID ());
		if (!native) return 0;
		#if defined(HX_MACOS)
		return GetCocoaWindowAppearance (native);
		#else
		SDL_SysWMinfo info;
		SDL_VERSION (&info.version);
		if (!SDL_GetWindowWMInfo (native, &info)) return 0;
		#if defined(HX_WINDOWS) && !defined(HX_WINRT)
		if (info.subsystem != SDL_SYSWM_WINDOWS) return 0;
		typedef HRESULT (WINAPI *GetAttribute) (HWND, DWORD, PVOID, DWORD);
		static GetAttribute get = DwmLibrary () ? (GetAttribute)GetProcAddress (DwmLibrary (), "DwmGetWindowAttribute") : NULL;
		BOOL dark = FALSE;
		return get && SUCCEEDED (get (info.info.win.window, 20, &dark, sizeof (dark))) ? (dark ? 2 : 1) : 0;
		#elif defined(HX_LINUX) && defined(SDL_VIDEO_DRIVER_X11)
		if (info.subsystem != SDL_SYSWM_X11) return 0;
		static X11AppearanceAPI x11;
		if (!x11.ready ()) return 0;
		Atom actualType; int format; unsigned long count, remaining; unsigned char* value = NULL;
		int result = 0;
		if (x11.get (info.info.x11.display, info.info.x11.window, x11.intern (info.info.x11.display, "_GTK_THEME_VARIANT", False),
			0, 16, False, AnyPropertyType, &actualType, &format, &count, &remaining, &value) == Success && value && format == 8) {
			if (count == 4 && SDL_memcmp (value, "dark", 4) == 0) result = 2;
			if (count == 5 && SDL_memcmp (value, "light", 5) == 0) result = 1;
		}
		if (value) x11.release (value);
		return result;
		#endif
		#endif
		#endif
		return 0;
	}
}
