#ifndef LIME_UI_KEY_EVENT_H
#define LIME_UI_KEY_EVENT_H


#include <hx/CFFI.h>
#include <stdint.h>


namespace lime {
	
	
	enum KeyEventType {
		
		KEY_DOWN,
		KEY_UP
		
	};
	
	
	class KeyEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			KeyEvent ();
			
			static void Dispatch (KeyEvent* event);
			
			double keyCode;
			int modifier;
			KeyEventType type;
			uint32_t windowID;
		
	};
	
	
}


#endif