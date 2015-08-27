#ifndef LIME_APP_APPLICATION_EVENT_H
#define LIME_APP_APPLICATION_EVENT_H


#include <hx/CFFI.h>


namespace lime {
	
	
	enum ApplicationEventType {
		
		UPDATE,
		EXIT
		
	};
	
	
	class ApplicationEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			ApplicationEvent ();
			
			static void Dispatch (ApplicationEvent* event);
			
			int deltaTime;
			ApplicationEventType type;
		
	};
	
	
}


#endif