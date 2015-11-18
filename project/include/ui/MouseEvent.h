#ifndef LIME_UI_MOUSE_EVENT_H
#define LIME_UI_MOUSE_EVENT_H


#include <hx/CFFI.h>
#include <stdint.h>


namespace lime {
	
	
	enum MouseEventType {
		
		MOUSE_DOWN,
		MOUSE_UP,
		MOUSE_MOVE,
		MOUSE_WHEEL
		
	};
	
	
	class MouseEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
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