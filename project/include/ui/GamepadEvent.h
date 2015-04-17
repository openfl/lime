#ifndef LIME_UI_GAMEPAD_EVENT_H
#define LIME_UI_GAMEPAD_EVENT_H


#include <hx/CFFI.h>


namespace lime {
	
	
	enum GamepadEventType {
		
		AXIS_MOVE,
		BUTTON_DOWN,
		BUTTON_UP,
		CONNECT,
		DISCONNECT
		
	};
	
	
	class GamepadEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			GamepadEvent ();
			
			static void Dispatch (GamepadEvent* event);
			
			int axis;
			double axisValue;
			int button;
			int id;
			GamepadEventType type;
		
	};
	
	
}


#endif