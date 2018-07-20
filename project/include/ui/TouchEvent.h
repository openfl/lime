#ifndef LIME_UI_TOUCH_EVENT_H
#define LIME_UI_TOUCH_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>
#include <stdint.h>


namespace lime {


	enum TouchEventType {

		TOUCH_START,
		TOUCH_END,
		TOUCH_MOVE

	};


	struct TouchEvent {

		hl_type* t;
		int device;
		double dx;
		double dy;
		int id;
		double pressure;
		TouchEventType type;
		double x;
		double y;

		static ValuePointer* callback;
		static ValuePointer* eventObject;

		TouchEvent ();

		static void Dispatch (TouchEvent* event);

	};


}


#endif