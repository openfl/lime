#include <hx/CFFI.h>
#include <app/ApplicationEvent.h>


namespace lime {
	
	
	AutoGCRoot* ApplicationEvent::callback = 0;
	AutoGCRoot* ApplicationEvent::eventObject = 0;
	
	static int id_deltaTime;
	static int id_type;
	static bool init = false;
	
	
	ApplicationEvent::ApplicationEvent () {
		
		deltaTime = 0;
		type = UPDATE;
		
	}
	
	
	void ApplicationEvent::Dispatch (ApplicationEvent* event) {
		
		if (ApplicationEvent::callback) {
			
			if (!init) {
				
				id_deltaTime = val_id ("deltaTime");
				id_type = val_id ("type");
				init = true;
				
			}
			
			value object = (ApplicationEvent::eventObject ? ApplicationEvent::eventObject->get () : alloc_empty_object ());
			
			alloc_field (object, id_deltaTime, alloc_int (event->deltaTime));
			alloc_field (object, id_type, alloc_int (event->type));
			
			val_call0 (ApplicationEvent::callback->get ());
			
		}
		
	}
	
	
}