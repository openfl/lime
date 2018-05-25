#ifndef LIME_UI_KEY_EVENT_H
#define LIME_UI_KEY_EVENT_H


#include <hl.h>
#include <hx/CFFI.h>
#include <stdint.h>


namespace lime {
	
	
	enum KeyEventType {
		
		KEY_DOWN,
		KEY_UP
		
	};
	
	
	struct HL_KeyEvent {
		
		hl_type* t;
		int keyCode;
		int modifier;
		KeyEventType type;
		int windowID;
		
	};
	
	
	class KeyEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			KeyEvent ();
			
			static void Dispatch (KeyEvent* event);
			
			double keyCode;
			uint16_t modifier;
			KeyEventType type;
			uint32_t windowID;
		
	};
	
	
}


#endif