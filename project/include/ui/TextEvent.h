#ifndef LIME_UI_TEXT_EVENT_H
#define LIME_UI_TEXT_EVENT_H


#include <hx/CFFI.h>
#include <stdint.h>


namespace lime {
	
	
	enum TextEventType {
		
		TEXT_INPUT,
		TEXT_EDIT
		
	};
	
	
	class TextEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			TextEvent ();
			
			static void Dispatch (TextEvent* event);
			
			long length;
			long start;
			char text[32];
			TextEventType type;
			uint32_t windowID;
		
	};
	
	
}


#endif