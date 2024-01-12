#ifndef LIME_UI_JOYSTICK_EVENT_H
#define LIME_UI_JOYSTICK_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {


	enum JoystickEventType {

		JOYSTICK_AXIS_MOVE = 0,
		JOYSTICK_HAT_MOVE = 1,
		JOYSTICK_BUTTON_DOWN = 3,
		JOYSTICK_BUTTON_UP = 4,
		JOYSTICK_CONNECT = 5,
		JOYSTICK_DISCONNECT = 6

	};


	struct JoystickEvent {

		hl_type* t;
		int id;
		int index;
		JoystickEventType type;
		int eventValue;
		double x;
		double y;

		static ValuePointer* callback;
		static ValuePointer* eventObject;

		JoystickEvent ();

		static void Dispatch (JoystickEvent* event);

	};


}


#endif