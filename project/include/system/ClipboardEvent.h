#ifndef LIME_SYSTEM_CLIPBOARD_EVENT_H
#define LIME_SYSTEM_CLIPBOARD_EVENT_H


#include <hx/CFFI.h>


namespace lime {
	
	
	enum ClipboardEventType {
		
		CLIPBOARD_UPDATE
		
	};
	
	
	class ClipboardEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			ClipboardEvent ();
			
			static void Dispatch (ClipboardEvent* event);
			
			ClipboardEventType type;
		
	};
	
	
}


#endif