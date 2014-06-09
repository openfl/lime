#ifndef LIME_APP_UPDATE_EVENT_H
#define LIME_APP_UPDATE_EVENT_H


#include <hx/CFFI.h>


namespace lime {
	
	
	enum UpdateEventType {
		
		UPDATE
		
	};
	
	
	class UpdateEvent {
		
		public:
			
			static AutoGCRoot* callback;
			static AutoGCRoot* eventObject;
			
			UpdateEvent ();
			
			static void Dispatch (UpdateEvent* event);
			
			int deltaTime;
			UpdateEventType type;
		
	};
	
	
}


#endif