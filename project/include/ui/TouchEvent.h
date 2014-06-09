#ifndef LIME_UI_TOUCH_EVENT_H
#define LIME_UI_TOUCH_EVENT_H


#include <hx/CFFI.h>


namespace lime {
	
	
	enum TouchEventType {
		
		TOUCH_START,
		TOUCH_END,
		TOUCH_MOVE
		
	};
	
	
	class TouchEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			TouchEvent ();
			
			static void Dispatch (TouchEvent* event);
			
			int id;
			TouchEventType type;
			double x;
			double y;
		
	};
	
	
}


#endif