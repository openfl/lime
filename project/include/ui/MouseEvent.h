#ifndef LIME_UI_MOUSE_EVENT_H
#define LIME_UI_MOUSE_EVENT_H


#include <hl.h>
#include <hx/CFFI.h>
#include <system/ValuePointer.h>
#include <stdint.h>


namespace lime {
	
	
	enum MouseEventType {
		
		MOUSE_DOWN,
		MOUSE_UP,
		MOUSE_MOVE,
		MOUSE_WHEEL
		
	};
	
	
	struct HL_MouseEvent {
		
		hl_type* t;
		int button;
		double movementX;
		double movementY;
		MouseEventType type;
		int windowID;
		double x;
		double y;
		
	};
	
	
	class MouseEvent {
		
		public:
			
			static ValuePointer* callback;
			static ValuePointer* eventObject;
			
			MouseEvent ();
			
			static void Dispatch (MouseEvent* event);
			
			int button;
			double movementX;
			double movementY;
			MouseEventType type;
			uint32_t windowID;
			double x;
			double y;
		
	};
	
	
}


#endif