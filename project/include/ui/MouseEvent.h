#ifndef LIME_UI_MOUSE_EVENT_H
#define LIME_UI_MOUSE_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>
#include <stdint.h>


namespace lime {


	enum MouseEventType {

		MOUSE_DOWN,
		MOUSE_UP,
		MOUSE_MOVE,
		MOUSE_WHEEL

	};


	struct MouseEvent {

		hl_type* t;
		int button;
		double movementX;
		double movementY;
		MouseEventType type;
		int windowID;
		double x;
		double y;
		int clickCount;

		static ValuePointer* callback;
		static ValuePointer* eventObject;

		MouseEvent ();

		static void Dispatch (MouseEvent* event);

	};


}


#endif