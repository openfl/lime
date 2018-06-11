#ifndef LIME_APP_APPLICATION_EVENT_H
#define LIME_APP_APPLICATION_EVENT_H


#include <system/CFFI.h>
#include <system/ValuePointer.h>


namespace lime {
	
	
	enum ApplicationEventType {
		
		UPDATE,
		EXIT
		
	};
	
	
	struct HL_ApplicationEvent {
		
		hl_type* t;
		int deltaTime;
		ApplicationEventType type;
		
	};
	
	
	class ApplicationEvent {
		
		public:
			
			static ValuePointer* callback;
			static ValuePointer* eventObject;
			
			ApplicationEvent ();
			
			static void Dispatch (ApplicationEvent* event);
			
			int deltaTime;
			ApplicationEventType type;
		
	};
	
	
}


#endif