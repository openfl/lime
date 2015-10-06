#ifndef LIME_UI_JOYSTICK_EVENT_H
#define LIME_UI_JOYSTICK_EVENT_H


#include <hx/CFFI.h>


namespace lime {
	
	
	enum JoystickEventType {
		
		JOYSTICK_AXIS_MOVE,
		JOYSTICK_HAT_MOVE,
		JOYSTICK_TRACKBALL_MOVE,
		JOYSTICK_BUTTON_DOWN,
		JOYSTICK_BUTTON_UP,
		JOYSTICK_CONNECT,
		JOYSTICK_DISCONNECT
		
	};
	
	
	class JoystickEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			JoystickEvent ();
			
			static void Dispatch (JoystickEvent* event);
			
			double eventValue;
			int id;
			int index;
			JoystickEventType type;
			int x;
			int y;
		
	};
	
	
}


#endif