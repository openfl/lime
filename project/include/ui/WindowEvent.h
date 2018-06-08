#ifndef LIME_UI_WINDOW_EVENT_H
#define LIME_UI_WINDOW_EVENT_H


#include <hl.h>
#include <hx/CFFI.h>
#include <system/ValuePointer.h>
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
	
	
	struct HL_WindowEvent {
		
		hl_type* t;
		int height;
		WindowEventType type;
		int width;
		int windowID;
		int x;
		int y;
		
	};
	
	
	class WindowEvent {
		
		public:
			
			static ValuePointer* callback;
			static ValuePointer* eventObject;
			
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