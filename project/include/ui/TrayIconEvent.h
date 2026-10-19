#ifndef LIME_UI_TRAY_ICON_EVENT_H
#define LIME_UI_TRAY_ICON_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {


	enum TrayIconEventType {

		TRAY_ICON_CLICK,
		TRAY_ICON_MENU_SELECT,
		TRAY_ICON_RIGHT_CLICK

	};


	struct TrayIconEvent {

		hl_type* t;
		int id;
		int itemID;
		TrayIconEventType type;

		static ValuePointer* callback;
		static ValuePointer* eventObject;

		TrayIconEvent ();

		static void Dispatch (TrayIconEvent* event);

	};


}


#endif
