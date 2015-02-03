#ifndef LIME_UI_TEXT_EVENT_H
#define LIME_UI_TEXT_EVENT_H


#include <hx/CFFI.h>


namespace lime {
	
	
	enum TextEventType {
		
		TEXT_DOWN,
		TEXT_UP
		
	};
	
	
	class TextEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			TextEvent ();
			
			static void Dispatch (TextEvent* event);
			
			char text[32];
		
	};
	
	
}


#endif
