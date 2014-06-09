#ifndef LIME_UI_WINDOW_EVENT_H
#define LIME_UI_WINDOW_EVENT_H


#include <hx/CFFI.h>


namespace lime {
	
	
	enum WindowEventType {
		
		WINDOW_ACTIVATE,
		WINDOW_DEACTIVATE
		
	};
	
	
	class WindowEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			WindowEvent ();
			
			static void Dispatch (WindowEvent* event);
			
			WindowEventType type;
		
	};
	
	
}


#endif