#ifndef LIME_UI_WINDOW_EVENT_H
#define LIME_UI_WINDOW_EVENT_H


#include <hx/CFFI.h>
#include <stdint.h>


namespace lime {
	
	
	enum WindowEventType {
		
		WINDOW_ACTIVATE,
		WINDOW_CLOSE,
		WINDOW_DEACTIVATE,
		WINDOW_ENTER,
		WINDOW_EXPOSE,
		WINDOW_FOCUS_IN,
		WINDOW_FOCUS_OUT,
		WINDOW_LEAVE,
		WINDOW_MINIMIZE,
		WINDOW_MOVE,
		WINDOW_RESIZE,
		WINDOW_RESTORE,
		
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
			uint32_t windowID;
			int x;
			int y;
		
	};
	
	
}


#endif