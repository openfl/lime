#ifndef LIME_UI_GAMEPAD_EVENT_H
#define LIME_UI_GAMEPAD_EVENT_H


#include <hl.h>
#include <hx/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {
	
	
	enum GamepadEventType {
		
		GAMEPAD_AXIS_MOVE,
		GAMEPAD_BUTTON_DOWN,
		GAMEPAD_BUTTON_UP,
		GAMEPAD_CONNECT,
		GAMEPAD_DISCONNECT
		
	};
	
	
	struct HL_GamepadEvent {
		
		hl_type* t;
		int axis;
		int button;
		int id;
		GamepadEventType type;
		double value;
		
	};
	
	
	class GamepadEvent {
		
		public:
			
			static ValuePointer* callback;
			static ValuePointer* eventObject;
			
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