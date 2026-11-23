#ifndef LIME_UI_MENU_EVENT_H
#define LIME_UI_MENU_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {


	enum MenuEventType {

		MENU_SELECT,
		MENU_DOCK_SELECT,
		MENU_CLOSE_WINDOW,
		MENU_CLOSE_TRAY_ICON,
		MENU_CLOSE_APPLICATION,
		MENU_CLOSE_DOCK

	};


	struct MenuEvent {

		hl_type* t;
		int id;
		MenuEventType type;
		int windowID;

		static ValuePointer* callback;
		static ValuePointer* eventObject;

		MenuEvent ();

		static void Dispatch (MenuEvent* event);

	};


}


#endif
