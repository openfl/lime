#ifndef LIME_UI_WINDOW_EVENT_H
#define LIME_UI_WINDOW_EVENT_H


#include <hx/CFFI.h>


namespace lime {
	
	
	enum WindowEventType {
		
		WINDOW_ACTIVATE,
		WINDOW_CLOSE,
		WINDOW_DEACTIVATE,
		WINDOW_FOCUS_IN,
		WINDOW_FOCUS_OUT,
		WINDOW_MOVE,
		WINDOW_RESIZE
		
	};
	
	
	class WindowEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			WindowEvent ();
			
			static void Dispatch (WindowEvent* event);
			
			int height;
			WindowEventType type;
			int width;
			int x;
			int y;
		
	};
	
	
}


#endif