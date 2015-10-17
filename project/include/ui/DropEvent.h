#ifndef LIME_UI_DROP_EVENT_H
#define LIME_UI_DROP_EVENT_H


#include <hx/CFFI.h>
#include <stdint.h>


namespace lime {
	
	
	enum DropEventType {
		
		DROP_FILE
		
	};
	
	
	class DropEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			DropEvent ();
			
			static void Dispatch (DropEvent* event);
			
			char* file;
			DropEventType type;
		
	};
	
	
}


#endif