#ifndef LIME_UI_WINDOW_EVENT_H
#define LIME_UI_WINDOW_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>
#include <stdint.h>


namespace lime {


	enum WindowEventType {

		WINDOW_ACTIVATE,
		WINDOW_CLOSE,
		WINDOW_DEACTIVATE,
		WINDOW_ENTER,
		WINDOW_EXPOSE,
		WINDOW_FOCUS_IN,
		WINDOW_FOCUS_OUT,
		WINDOW_LEAVE,
		WINDOW_MAXIMIZE,
		WINDOW_MINIMIZE,
		WINDOW_MOVE,
		WINDOW_RESIZE,
		WINDOW_RESTORE,
		WINDOW_SHOW,
		WINDOW_HIDE

	};


	struct WindowEvent {

		hl_type* t;
		int height;
		WindowEventType type;
		int width;
		int windowID;
		int x;
		int y;

		static ValuePointer* callback;
		static ValuePointer* eventObject;

		WindowEvent ();

		static void Dispatch (WindowEvent* event);

	};


}


#endif