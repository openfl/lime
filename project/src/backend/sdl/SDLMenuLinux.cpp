#include "SDLMenu.h"

#ifdef LIME_SDL_MENU_GTK

// Lime's SDL backend uses the minimal SDL configuration, so enable the X11 window info explicitly
#ifndef SDL_VIDEO_DRIVER_X11
#define SDL_VIDEO_DRIVER_X11 1
#endif

#include <SDL_syswm.h>
#include <dlfcn.h>
#include <stdint.h>
#include <string.h>


namespace lime {


	// GTK 3 is loaded at runtime, so Lime has no build or link dependency on it.
	// Only popup menus are supported: an SDL window cannot host a GTK menu bar.

	typedef void (*GCallbackFunc) (void);
	typedef void (*GtkMenuPositionFunc) (void* menu, int* x, int* y, int* pushIn, void* userData);


	struct GTKLibrary {

		bool initialized;
		bool available;

		void (*gdk_set_allowed_backends) (const char*);
		void* (*g_object_ref_sink) (void*);
		void (*g_object_unref) (void*);
		unsigned long (*g_signal_connect_data) (void*, const char*, GCallbackFunc, void*, void*, int);
		void (*gtk_accel_label_set_accel) (void*, unsigned int, int);
		void* (*gtk_bin_get_child) (void*);
		void* (*gtk_check_menu_item_new_with_mnemonic) (const char*);
		void (*gtk_check_menu_item_set_active) (void*, int);
		void (*gtk_disable_setlocale) (void);
		int (*gtk_events_pending) (void);
		int (*gtk_init_check) (int*, char***);
		void (*gtk_main) (void);
		int (*gtk_main_iteration) (void);
		void (*gtk_main_quit) (void);
		void* (*gtk_menu_item_new_with_mnemonic) (const char*);
		void (*gtk_menu_item_set_submenu) (void*, void*);
		void* (*gtk_menu_new) (void);
		void (*gtk_menu_popup) (void*, void*, void*, GtkMenuPositionFunc, void*, unsigned int, unsigned int);
		void (*gtk_menu_shell_append) (void*, void*);
		void* (*gtk_separator_menu_item_new) (void);
		void (*gtk_widget_destroy) (void*);
		void* (*gtk_widget_get_toplevel) (void*);
		int (*gtk_widget_get_visible) (void*);
		void (*gtk_widget_set_sensitive) (void*, int);
		void (*gtk_widget_show_all) (void*);
		int (*XFlush) (void*);
		int (*XUngrabPointer) (void*, unsigned long);

	};


	struct PopupPosition {

		int x;
		int y;

	};


	static GTKLibrary gtk;
	static int popupSelection = 0;


	static bool LoadGTK () {

		if (gtk.initialized) return gtk.available;

		gtk.initialized = true;

		void* library = dlopen ("libgtk-3.so.0", RTLD_NOW | RTLD_LOCAL);

		if (!library) return false;

		#define LIME_GTK_REQUIRE(name) gtk.name = (decltype (gtk.name))dlsym (library, #name); if (!gtk.name) return false;
		#define LIME_GTK_OPTIONAL(name) gtk.name = (decltype (gtk.name))dlsym (library, #name);

		LIME_GTK_REQUIRE (g_object_ref_sink);
		LIME_GTK_REQUIRE (g_object_unref);
		LIME_GTK_REQUIRE (g_signal_connect_data);
		LIME_GTK_REQUIRE (gtk_bin_get_child);
		LIME_GTK_REQUIRE (gtk_check_menu_item_new_with_mnemonic);
		LIME_GTK_REQUIRE (gtk_check_menu_item_set_active);
		LIME_GTK_REQUIRE (gtk_events_pending);
		LIME_GTK_REQUIRE (gtk_init_check);
		LIME_GTK_REQUIRE (gtk_main);
		LIME_GTK_REQUIRE (gtk_main_iteration);
		LIME_GTK_REQUIRE (gtk_main_quit);
		LIME_GTK_REQUIRE (gtk_menu_item_new_with_mnemonic);
		LIME_GTK_REQUIRE (gtk_menu_item_set_submenu);
		LIME_GTK_REQUIRE (gtk_menu_new);
		LIME_GTK_REQUIRE (gtk_menu_popup);
		LIME_GTK_REQUIRE (gtk_menu_shell_append);
		LIME_GTK_REQUIRE (gtk_separator_menu_item_new);
		LIME_GTK_REQUIRE (gtk_widget_destroy);
		LIME_GTK_REQUIRE (gtk_widget_get_toplevel);
		LIME_GTK_REQUIRE (gtk_widget_get_visible);
		LIME_GTK_REQUIRE (gtk_widget_set_sensitive);
		LIME_GTK_REQUIRE (gtk_widget_show_all);

		LIME_GTK_OPTIONAL (gdk_set_allowed_backends);
		LIME_GTK_OPTIONAL (gtk_accel_label_set_accel);
		LIME_GTK_OPTIONAL (gtk_disable_setlocale);
		LIME_GTK_OPTIONAL (XFlush);
		LIME_GTK_OPTIONAL (XUngrabPointer);

		#undef LIME_GTK_REQUIRE
		#undef LIME_GTK_OPTIONAL

		// Keep the application's locale, and use the same windowing system as SDL
		if (gtk.gtk_disable_setlocale) gtk.gtk_disable_setlocale ();
		if (gtk.gdk_set_allowed_backends) gtk.gdk_set_allowed_backends ("x11");

		if (!gtk.gtk_init_check (NULL, NULL)) return false;

		gtk.available = true;
		return true;

	}


	static unsigned int GetKeyval (int keyCode) {

		// Printable ASCII matches the GDK keysyms (SDL letter keycodes are lowercase)
		if (keyCode >= 0x20 && keyCode < 0x7F) return (unsigned int)keyCode;
		if (keyCode >= SDLK_F1 && keyCode <= SDLK_F12) return 0xFFBE + (keyCode - SDLK_F1);
		if (keyCode >= SDLK_F13 && keyCode <= SDLK_F24) return 0xFFCA + (keyCode - SDLK_F13);

		switch (keyCode) {

			case SDLK_BACKSPACE: return 0xFF08;
			case SDLK_TAB: return 0xFF09;
			case SDLK_RETURN: return 0xFF0D;
			case SDLK_ESCAPE: return 0xFF1B;
			case SDLK_HOME: return 0xFF50;
			case SDLK_LEFT: return 0xFF51;
			case SDLK_UP: return 0xFF52;
			case SDLK_RIGHT: return 0xFF53;
			case SDLK_DOWN: return 0xFF54;
			case SDLK_PAGEUP: return 0xFF55;
			case SDLK_PAGEDOWN: return 0xFF56;
			case SDLK_END: return 0xFF57;
			case SDLK_INSERT: return 0xFF63;
			case SDLK_DELETE: return 0xFFFF;
			default: return 0;

		}

	}


	static int GetModifierMask (int keyModifiers) {

		int mask = 0;

		if (keyModifiers & KMOD_SHIFT) mask |= (1 << 0);
		if (keyModifiers & KMOD_CTRL) mask |= (1 << 2);
		if (keyModifiers & KMOD_ALT) mask |= (1 << 3);
		if (keyModifiers & KMOD_GUI) mask |= (1 << 26);

		return mask;

	}


	static void OnItemActivate (void* widget, void* userData) {

		popupSelection = (int)(intptr_t)userData;

	}


	static void OnMenuDeactivate (void* widget, void* userData) {

		gtk.gtk_main_quit ();

	}


	static void PositionMenu (void* menu, int* x, int* y, int* pushIn, void* userData) {

		PopupPosition* position = (PopupPosition*)userData;
		*x = position->x;
		*y = position->y;
		*pushIn = 1;

	}


	static void AppendMenuItems (void* menu, const std::vector<SDLMenuItem>& items) {

		for (size_t i = 0; i < items.size (); i++) {

			const SDLMenuItem& item = items[i];
			bool hasSubmenu = (item.flags & MENU_ITEM_SUBMENU) != 0;
			void* widget;

			if ((item.flags & MENU_ITEM_SEPARATOR) && !hasSubmenu) {

				widget = gtk.gtk_separator_menu_item_new ();

			} else {

				std::string label = SDLMenu::GetLabel (item.label, '_');

				if ((item.flags & MENU_ITEM_CHECKED) && !hasSubmenu) {

					// Setting the active state emits "activate", so connect afterwards
					widget = gtk.gtk_check_menu_item_new_with_mnemonic (label.c_str ());
					gtk.gtk_check_menu_item_set_active (widget, 1);

				} else {

					widget = gtk.gtk_menu_item_new_with_mnemonic (label.c_str ());

				}

				gtk.gtk_widget_set_sensitive (widget, (item.flags & MENU_ITEM_ENABLED) ? 1 : 0);

				if (hasSubmenu) {

					void* submenu = gtk.gtk_menu_new ();
					AppendMenuItems (submenu, item.submenu);
					gtk.gtk_menu_item_set_submenu (widget, submenu);

				} else {

					unsigned int keyval = item.keyCode != 0 ? GetKeyval (item.keyCode) : 0;
					void* accelLabel = keyval && gtk.gtk_accel_label_set_accel ? gtk.gtk_bin_get_child (widget) : NULL;

					if (accelLabel) {

						gtk.gtk_accel_label_set_accel (accelLabel, keyval, GetModifierMask (item.keyModifiers));

					}

					gtk.g_signal_connect_data (widget, "activate", (GCallbackFunc)OnItemActivate, (void*)(intptr_t)item.id, NULL, 0);

				}

			}

			gtk.gtk_menu_shell_append (menu, widget);

		}

	}


	bool SDLMenu::GetPlatformSelection (SDL_Event* event, Uint32* windowID, int* id) {

		return false;

	}


	int SDLMenu::GetSupport () {

		const char* driver = SDL_GetCurrentVideoDriver ();

		if (driver && strcmp (driver, "x11") != 0) return 0;

		return LoadGTK () ? MENU_SUPPORT_POPUP : 0;

	}


	int SDLMenu::Popup (SDL_Window* window, const unsigned char* data, int length, int x, int y, bool atCursor) {

		SDL_SysWMinfo info;
		SDL_VERSION (&info.version);

		if (!window || !SDL_GetWindowWMInfo (window, &info) || info.subsystem != SDL_SYSWM_X11) return 0;

		std::vector<SDLMenuItem> items;

		if (!Parse (data, length, &items) || !LoadGTK ()) return 0;

		// A pressed mouse button holds an implicit pointer grab on SDL's window, which would stop the menu from taking its own
		if (gtk.XUngrabPointer) {

			gtk.XUngrabPointer (info.info.x11.display, 0);
			if (gtk.XFlush) gtk.XFlush (info.info.x11.display);

		}

		void* menu = gtk.gtk_menu_new ();
		gtk.g_object_ref_sink (menu);

		AppendMenuItems (menu, items);
		gtk.gtk_widget_show_all (menu);
		gtk.g_signal_connect_data (menu, "deactivate", (GCallbackFunc)OnMenuDeactivate, NULL, NULL, 0);

		PopupPosition position;
		SDL_GetWindowPosition (window, &position.x, &position.y);
		position.x += x;
		position.y += y;

		popupSelection = 0;

		gtk.gtk_menu_popup (menu, NULL, NULL, atCursor ? NULL : PositionMenu, atCursor ? NULL : &position, 0, 0);

		// GTK gives up without emitting "deactivate" if it cannot grab the pointer, so only wait for a menu that opened
		if (gtk.gtk_widget_get_visible (gtk.gtk_widget_get_toplevel (menu))) {

			gtk.gtk_main ();

		}

		gtk.gtk_widget_destroy (menu);
		gtk.g_object_unref (menu);

		while (gtk.gtk_events_pending ()) {

			gtk.gtk_main_iteration ();

		}

		return popupSelection;

	}


	void SDLMenu::Remove (SDL_Window* window) {}


	bool SDLMenu::SetApplicationMenu (const unsigned char* data, int length) {

		return false;

	}


	bool SDLMenu::SetWindowMenu (SDL_Window* window, const unsigned char* data, int length) {

		return false;

	}


}


#endif
