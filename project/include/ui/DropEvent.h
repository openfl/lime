#ifndef LIME_UI_DROP_EVENT_H
#define LIME_UI_DROP_EVENT_H


#include <hl.h>
#include <hx/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {
	
	
	enum DropEventType {
		
		DROP_FILE
		
	};
	
	
	struct HL_DropEvent {
		
		hl_type* t;
		vbyte* file;
		DropEventType type;
		
	};
	
	
	class DropEvent {
		
		public:
			
			static ValuePointer* callback;
			static ValuePointer* eventObject;
			
			DropEvent ();
			
			static void Dispatch (DropEvent* event);
			
			char* file;
			DropEventType type;
		
	};
	
	
}


#endif