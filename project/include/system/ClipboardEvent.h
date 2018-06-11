#ifndef LIME_SYSTEM_CLIPBOARD_EVENT_H
#define LIME_SYSTEM_CLIPBOARD_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {
	
	
	enum ClipboardEventType {
		
		CLIPBOARD_UPDATE
		
	};
	
	
	struct HL_ClipboardEvent {
		
		hl_type* t;
		ClipboardEventType type;
		
	};
	
	
	class ClipboardEvent {
		
		public:
			
			static ValuePointer* callback;
			static ValuePointer* eventObject;
			
			ClipboardEvent ();
			
			static void Dispatch (ClipboardEvent* event);
			
			ClipboardEventType type;
		
	};
	
	
}


#endif