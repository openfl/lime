#ifndef LIME_UI_JOYSTICK_EVENT_H
#define LIME_UI_JOYSTICK_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>


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
	
	
	struct HL_JoystickEvent {
		
		hl_type* t;
		int id;
		int index;
		JoystickEventType type;
		int value;
		double x;
		double y;
		
	};
	
	
	class JoystickEvent {
		
		public:
			
			static ValuePointer* callback;
			static ValuePointer* eventObject;
			
			JoystickEvent ();
			
			static void Dispatch (JoystickEvent* event);
			
			int eventValue;
			int id;
			int index;
			JoystickEventType type;
			double x;
			double y;
		
	};
	
	
}


#endif